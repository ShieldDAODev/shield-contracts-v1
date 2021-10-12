// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
//pragma experimental ABIEncoderV2;
import "./SLDInterfaces.sol";
import "./DateTime.sol";
import "./UnderlyingAsset.sol";

/**
 * @notice Option contract DAI token.
 */
contract SLDOption is ISLDContract, Ownable {
    using SafeMath for uint256;
    using DateTime for uint256;

    uint256 internal constant PRICE_DECIMALS = 1e18;

    address public tokenAddr; // Base fiat token address
    StableCoinType public tokenType; // Base fiat token type. 1-DAI, 2-USDT, 3-USDC
    address public riskFundAddr; // risk fund address
    address public buybackAddr; // contract address for buyback
    address public brokerAddr; // contract address for broker
    address public liquidatorAddr; // contract address for liquidator

    // Function selectors for BEP20
    bytes4 private constant SELECTOR_TRANSFER_FROM =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant SELECTOR_APPROVE =
        bytes4(keccak256(bytes("approve(address,uint256)")));

    // address => AccountInfo:
    //              + depositAmount: total fiat token amount user deposited
    //              + availableAmount: DAI amount could be withdrawn
    //              + liquidationFee: reserved amount for liquidation
    mapping(address => AccountInfo) public userAccount;
    mapping(address => uint256[]) public userOrders;
    mapping(uint256 => uint256) public userOrderIDMapping;

    uint256 public migrationPeriod = 1; // It indicates how many times migration happens in 24hours.
    mapping(uint256 => MigrationDetail) public migrationInfo; // store all migration period of all orders

    Order[] public orders; // Order list

    uint256 public nextMgFeeRate = (10 * 1e18) / 100; // mean 10%, indicates the following migration fee rate

    uint256 public brokerPortion = 40; // means 40% of trading fee will transfer to broker, if the trader has a broker
    uint256 public buybackPortion = 50; // means 50% of trading fee will transfer to buyback pool

    uint256 public minDepositAmount = 1e18; // minimum deposit amount

    IPublicPool public pubPool; // Public pool contract address
    IPrivatePool public privPool; // Public pool contract address

    mapping(string => UnderlyingAsset) private assetsNameMapping;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier ensure(uint256 _deadline) {
        require(_deadline >= block.timestamp, "EXPIRED");
        _;
    }

    /**
     * @dev Contract constructor.
     * @param _pubPool Public pool address.
     * @param _priPool Private pool address.
     * @param _riskFundAddr Risk fund address.
     * @param _tokenAddr Fiat token address(DAI/USDT/USDC).
     * @param _type Fiat token type(1-DAI, 2-USDT, 3-USDC).
     */
    constructor(
        address _pubPool,
        address _priPool,
        address _riskFundAddr,
        address _tokenAddr,
        StableCoinType _type
    ) public {
        privPool = IPrivatePool(_priPool);
        pubPool = IPublicPool(_pubPool);

        riskFundAddr = _riskFundAddr;

        tokenAddr = _tokenAddr;
        tokenType = _type;

        // Approve unlimited allowance to private pool and public pool
        _safeApprove(tokenAddr, address(privPool), uint256(-1));
        _safeApprove(tokenAddr, address(pubPool), uint256(-1));
    }

    /**
     * @dev Deposit underlying assets to call/put options.
     * @param _amount Amount of fiat token to deposit.
     */
    function deposit(uint256 _amount) public {
        require(_amount >= minDepositAmount, "too small");

        _safeTransferFrom(tokenAddr, msg.sender, address(this), _amount);

        AccountInfo storage userAcc = userAccount[msg.sender];
        userAcc.depositAmount = userAcc.depositAmount.add(_amount);
        userAcc.availableAmount = userAcc.availableAmount.add(_amount);

        emit SLDDeposit(msg.sender, address(this), _amount);

        emit BalanceOfTaker(
            msg.sender,
            userAcc.depositAmount,
            userAcc.availableAmount,
            userAcc.liquidationFee
        );
    }

    /**
     * @dev Withdraw underlying assets from smart contract.
     * @param _amount Amount of fiat token to withdraw.
     */
    function withdraw(uint256 _amount) public lock {
        AccountInfo storage userAcc = userAccount[msg.sender];

        require(userAcc.availableAmount >= _amount, "exceed");

        userAcc.depositAmount = userAcc.depositAmount.sub(_amount);
        userAcc.availableAmount = userAcc.availableAmount.sub(_amount);

        emit BalanceOfTaker(
            msg.sender,
            userAcc.depositAmount,
            userAcc.availableAmount,
            userAcc.liquidationFee
        );

        _safeTransfer(tokenAddr, msg.sender, _amount);

        emit SLDWithdraw(address(this), msg.sender, _amount);
    }

    /**
     * @dev Make a call or put transation on an option.
     * @param _exchangeType Exchange type of a transaction (i.e. ETHDAI, BTCDAI).
     * @param _number Amount of underlying asset to call or put.
     * @param _contractType Option type, call or put.
     * @param _inviter Broker address.
     * @param _slideDownPrice Used to calculate price slippage.
     * @param _slideUpPrice Used to calculate price slippage.
     * @param _deadline Transaction expired timestamp.
     */
    function creatContract(
        string memory _exchangeType,
        uint256 _number,
        ContractType _contractType,
        address _inviter,
        uint256 _slideDownPrice,
        uint256 _slideUpPrice,
        uint256 _deadline
    ) public lock ensure(_deadline) {
        require(
            _contractType == ContractType.LONG ||
                _contractType == ContractType.SHORT,
            "wrong type"
        );

        require(
            address(assetsNameMapping[_exchangeType]) != address(0x0),
            "unsupport"
        );

        UnderlyingAsset asset = assetsNameMapping[_exchangeType];

        require(_number >= asset.minAmount(), "to small");

        // calculate fees
        Fees memory fee;
        {
            (
                fee.total, // total fee
                fee.tradingFee, // trading fee
                fee.fundingFee, // funding fee
                fee.liquidationFee, // liquidation fee
                fee.currentPrice // price when the transaction executed
            ) = asset.fees(_number, _contractType, migrationPeriod);
        }
        require(
            (_contractType == ContractType.LONG &&
                fee.currentPrice <= _slideUpPrice) ||
                (_contractType == ContractType.SHORT &&
                    fee.currentPrice >= _slideDownPrice),
            "slippage"
        );

        {
            uint256 total = fee.total;
            uint256 tradingFee = fee.tradingFee;
            uint256 fundingFee = fee.fundingFee;
            uint256 liquidationFee = fee.liquidationFee;

            AccountInfo storage userAcc = userAccount[msg.sender];
            require(userAcc.availableAmount >= total, "exceed");
            userAcc.availableAmount = userAcc.availableAmount.sub(
                tradingFee.add(fundingFee.div(migrationPeriod)).add(
                    liquidationFee
                )
            );
            userAcc.depositAmount = userAcc.depositAmount.sub(tradingFee);
            userAcc.liquidationFee = userAcc.liquidationFee.add(liquidationFee);

            emit BalanceOfTaker(
                msg.sender,
                userAcc.depositAmount,
                userAcc.availableAmount,
                userAcc.liquidationFee
            );
        }

        {
            emit SLDOpenContract(
                msg.sender,
                orders.length,
                _contractType,
                State.ACTIVE,
                _exchangeType,
                _number,
                fee.tradingFee,
                fee.liquidationFee,
                fee.fundingFee,
                0,
                fee.fundingFee.div(migrationPeriod),
                fee.currentPrice
            );
        }

        {
            // get pools to match
            (uint256 marginAmount, uint256 marginFee) = UnderlyingAsset(
                assetsNameMapping[_exchangeType]
            ).getLockedAmount(_number, fee.currentPrice, 2); // Use formula
            if (
                // order matched with private pool
                !privPool.lock(
                    orders.length,
                    marginAmount,
                    marginFee,
                    fee.tradingFee
                )
            ) {
                (marginAmount, marginFee) = UnderlyingAsset(
                    assetsNameMapping[_exchangeType]
                ).getLockedAmount(_number, fee.currentPrice, 1); // Use formula
                pubPool.lock(orders.length, marginAmount, marginFee); // order matched with public pool
            }

            // Initialize migration Time
            MigrationDetail storage detail = migrationInfo[orders.length];
            detail.migrationTime = block.timestamp;
            detail.regulatedTime = DateTime.regulateTimeAfter(
                block.timestamp,
                migrationPeriod
            );
            detail.inPeriodHours = DateTime.getInPeriodHours(migrationPeriod);

            userOrderIDMapping[orders.length] = userOrders[msg.sender].length;
            userOrders[msg.sender].push(orders.length);

            orders.push(
                Order(
                    msg.sender, // option holder
                    _contractType, // CALL or PUT
                    State.ACTIVE, // order status
                    _exchangeType, // i.e. ETHDAI, BTCDAI
                    _number, // option amount
                    fee.tradingFee, // trading fee
                    fee.liquidationFee, // liquidation fee
                    fee.fundingFee, // initial funding fee
                    0, // funding fee which already deducted
                    fee.fundingFee.div(migrationPeriod), // pre-deducted funding fee
                    fee.currentPrice, // price when the transaction executed
                    block.timestamp, // order created time
                    0 // price when the option is closed
                )
            );
        }

        {
            // calculate broker rewards
            uint256 tradingFee = fee.tradingFee;
            uint256 brokerFee = (fee.tradingFee * brokerPortion) / 100;
            uint256 buybackFee = (fee.tradingFee * buybackPortion) / 100;
            address brokerAddress = ISLDBroker(brokerAddr)
                .addInviteRelationAndCalc(
                    _inviter,
                    msg.sender,
                    uint256(tokenType),
                    brokerFee
                );
            if (brokerAddress == address(0)) {
                // if there is no broker, broker fee and buyback fee will both transfer to buyback pool
                _safeTransfer(
                    tokenAddr,
                    buybackAddr,
                    brokerFee.add(buybackFee)
                );
            } else {
                // transfer buyback fee to buyback pool
                _safeTransfer(tokenAddr, buybackAddr, buybackFee);
                // transfer broker fee to broker
                _safeTransfer(tokenAddr, brokerAddr, brokerFee);
            }

            // remaining trading fee transfer to risk fund
            _safeTransfer(
                tokenAddr,
                riskFundAddr,
                tradingFee.sub(brokerFee).sub(buybackFee)
            );
        }
    }

    /**
     * @dev Close an option order.
     * @param _orderID Order id.
     * @param _slideDownPrice Used to calculate price slippage.
     * @param _slideUpPrice Used to calculate price slippage.
     */
    function closecontract(
        uint256 _orderID,
        uint256 _slideDownPrice,
        uint256 _slideUpPrice
    ) public lock {
        // Just for testing
        // function closecontract(uint256 _orderID, uint256 currentPrice) public lock {

        Order memory order = orders[_orderID];
        require(order.holder == msg.sender, "wrong holder");
        require(order.state == State.ACTIVE, "wrong state");
        uint256 contractType = uint256(order.contractType);

        require(
            address(assetsNameMapping[order.exchangeType]) != address(0x0),
            "wrong asset"
        );
        UnderlyingAsset asset = assetsNameMapping[order.exchangeType];

        uint256 currentPrice = asset.getPrice(); // use latest price feeding by ChainLink

        require(
            (order.contractType == ContractType.LONG &&
                currentPrice >= _slideDownPrice) ||
                (order.contractType == ContractType.SHORT &&
                    currentPrice <= _slideUpPrice),
            "slippage"
        );

        uint256 profit = payProfit(currentPrice, _orderID); // calculate user profit
        {
            uint256 inPeriondFee = orders[_orderID].newLockFee;
            order.lockFee = order.lockFee.add(inPeriondFee);
            order.newLockFee = 0;
        }

        require(checkOrder(_orderID) > 0, "mismatched");

        uint256 userProfit;
        bool isAgreement;
        if (checkOrder(_orderID) == 2) {
            (userProfit, isAgreement) = privPool.close(
                _orderID,
                profit,
                order.lockFee
            );
        } else {
            (userProfit, isAgreement) = pubPool.close(
                _orderID,
                profit,
                order.lockFee
            );
        }

        if (!isAgreement) {
            order.state = State.CLOSED;
        } else {
            order.state = State.AGREEMENT;
        }

        if (userProfit > 0) {
            if (contractType == uint256(ContractType.LONG)) {
                order.closePrice =
                    order.openPrice +
                    userProfit.mul(PRICE_DECIMALS) /
                    order.number;
            } else {
                order.closePrice =
                    order.openPrice -
                    userProfit.mul(PRICE_DECIMALS) /
                    order.number;
            }
        } else {
            order.closePrice = currentPrice;
        }

        userOrders[msg.sender][userOrderIDMapping[_orderID]] = uint256(-1);

        emit SLDCloseContract(
            _orderID,
            order.state,
            order.lockFee,
            order.newLockFee,
            order.closePrice
        );

        {
            AccountInfo storage userAcc = userAccount[msg.sender];
            uint256 reserveAmount = order.liquidationFee;
            userAcc.availableAmount = userAcc
                .availableAmount
                .add(userProfit)
                .add(reserveAmount);
            userAcc.liquidationFee = userAcc.liquidationFee.sub(reserveAmount);
            userAcc.depositAmount = userAcc.depositAmount.add(userProfit).sub(
                order.lockFee
            );

            orders[_orderID] = order;
            delete migrationInfo[_orderID];

            emit BalanceOfTaker(
                msg.sender,
                userAcc.depositAmount,
                userAcc.availableAmount,
                userAcc.liquidationFee
            );
        }
    }

    /**
     * @dev Order migration used to accumulated funding fee.
     * @param orderIDs The array of order ids need to be migrated.
     */
    function migrationContract(uint256[] memory orderIDs) public lock {
        uint256 totalGas;
        bool flag = false;

        for (uint256 i = 0; i < orderIDs.length; i++) {
            uint256 orderID = orderIDs[i];
            Order memory order = orders[orderID];
            MigrationDetail memory detail = migrationInfo[orderID];
            if (order.state != State.ACTIVE) continue;

            if (block.timestamp <= detail.migrationTime) continue;

            uint256 beforeGas = gasleft();

            (uint256 intervalPeriods, uint256 intervalPeriodsInHours) = DateTime
                .getIntervalPeriods(
                    detail.regulatedTime,
                    block.timestamp,
                    migrationPeriod
                );

            if (intervalPeriods > 0) {
                migration(orderID, intervalPeriodsInHours);

                detail.migrationTime = block.timestamp;
                detail.regulatedTime = DateTime.regulateTimeAfter(
                    block.timestamp,
                    migrationPeriod
                );
                detail.inPeriodHours = detail.inPeriodHours.add(
                    intervalPeriodsInHours
                );
                migrationInfo[orderID] = detail;
                flag = true;
            }
            totalGas += beforeGas - gasleft();
        }
        if (flag) {
            ISLDLiquidator(liquidatorAddr).calcLiquidatorAmount(
                msg.sender,
                uint256(tokenType),
                totalGas
            );
        }
    }

    /**
     * @dev Internal function use to migrate order.
     * @param _orderID The order id need to be migrated.
     * @param _intervalPeriodsInHours Interval migration hours from the last migration time to regulated current time.
     */
    function migration(uint256 _orderID, uint256 _intervalPeriodsInHours)
        internal
    {
        Order memory order = orders[_orderID];

        require(
            address(assetsNameMapping[order.exchangeType]) != address(0x0),
            "unsupport"
        );
        UnderlyingAsset asset = assetsNameMapping[order.exchangeType];
        uint256 currentPrice = asset.getPrice(); //real

        order.lockFee = order.lockFee.add(order.newLockFee);
        (bool succ, uint256 newHoldFee) = addFeesForUser(
            _orderID,
            order.firstMgFee,
            _intervalPeriodsInHours
        );
        address holder = orders[_orderID].holder;
        AccountInfo storage userAcc = userAccount[holder];
        if (!succ) {
            uint256 profit = payProfit(currentPrice, _orderID); // calculate profit

            order.newLockFee = 0;

            uint256 puborPriPool = checkOrder(_orderID);
            require(puborPriPool > 0, "mismatched");
            bool isAgreement;

            if (puborPriPool == 2) {
                (profit, isAgreement) = privPool.close(
                    _orderID,
                    profit,
                    order.lockFee
                );
            } else {
                (profit, isAgreement) = pubPool.close(
                    _orderID,
                    profit,
                    order.lockFee
                );
            }

            if (!isAgreement) {
                order.state = State.FORCE_CLOSED;
            } else {
                order.state = State.AGREEMENT;
            }
            userOrders[order.holder][userOrderIDMapping[_orderID]] = uint256(
                -1
            );

            // update user account info
            uint256 reserveAmount = order.liquidationFee;
            userAcc.availableAmount = userAcc.availableAmount.add(profit);
            userAcc.liquidationFee = userAcc.liquidationFee.sub(reserveAmount);
            userAcc.depositAmount = userAcc.depositAmount.add(profit).sub(
                order.lockFee.add(reserveAmount)
            );

            if (profit > 0) {
                if (order.contractType == ContractType.LONG) {
                    order.closePrice =
                        order.openPrice +
                        profit.mul(PRICE_DECIMALS) /
                        order.number;
                } else {
                    order.closePrice =
                        order.openPrice -
                        profit.mul(PRICE_DECIMALS) /
                        order.number;
                }
            } else {
                order.closePrice = currentPrice;
            }
            // transfer liquidor fee to risk fund
            _safeTransfer(tokenAddr, riskFundAddr, reserveAmount);
        } else {
            order.newLockFee = newHoldFee;
            userAcc.availableAmount = userAcc.availableAmount.sub(newHoldFee);
        }

        orders[_orderID] = order;

        emit SLDMigration(
            _orderID,
            order.state,
            order.lockFee,
            order.newLockFee,
            order.closePrice
        );
        // Need to be removed on Mainnet launch
        emit BalanceOfTaker(
            order.holder,
            userAcc.depositAmount,
            userAcc.availableAmount,
            userAcc.liquidationFee
        );
    }

    /**
     * @dev Use to trigger risk control by liquidator.
     * @param _orderIDs The array of order ids need to be risk control.
     */
    function riskControl(uint256[] calldata _orderIDs) public lock {
        // Just for testing
        // function riskControl(uint256[] calldata _orderIDs, uint256 currentPrice) public lock {
        uint256 totalGas;

        bool flag = false;
        for (uint256 i = 0; i < _orderIDs.length; i++) {
            if (orders[_orderIDs[i]].state == State.ACTIVE) {
                uint256 beforeGas = gasleft();
                require(
                    address(
                        assetsNameMapping[orders[_orderIDs[i]].exchangeType]
                    ) != address(0x0),
                    "unsupport"
                );
                UnderlyingAsset asset = assetsNameMapping[
                    orders[_orderIDs[i]].exchangeType
                ];
                uint256 currentPrice = asset.getPrice();
                uint256 calProfit = payProfit(currentPrice, _orderIDs[i]);

                riskHandle(_orderIDs[i], calProfit, currentPrice);
                flag = true;
                totalGas += beforeGas - gasleft();
            }
        }
        if (flag) {
            ISLDLiquidator(liquidatorAddr).calcLiquidatorAmount(
                msg.sender,
                uint256(tokenType),
                totalGas
            );
        }
    }

    /**
     * @dev Internal function use to trigger risk control.
     * @param _orderID The order id need to be risk controlled.
     * @param _profit Order profit.
     * @param _currentPrice Price when trigger the risk control.
     */
    function riskHandle(
        uint256 _orderID,
        uint256 _profit,
        uint256 _currentPrice
    ) internal {
        Order memory order = orders[_orderID];
        uint256 puborPriPool = checkOrder(_orderID);
        require(puborPriPool > 0, "mismatched");
        uint256 inPeriondFee = orders[_orderID].newLockFee;

        uint256 holdFee = order.lockFee.add(inPeriondFee);
        bool flag;
        bool isAgreement;
        uint256 realProfit;
        if (puborPriPool == 2) {
            require(_profit > getLpMarginAmount(_orderID), "fail");
            (flag, realProfit, isAgreement) = privPool.riskClose(
                _orderID,
                order.number,
                holdFee,
                _profit,
                order.openPrice,
                _currentPrice
            );
        } else {
            //riskClose(uint256 id, uint256 number,uint256 profit,uint256 currPrice)
            require(
                _profit > getLpMarginAmount(_orderID).mul(50).div(100),
                "fail"
            );
            (flag, realProfit, isAgreement) = pubPool.riskClose(
                _orderID,
                _profit,
                holdFee
            );
        }

        if (flag) {
            // force close
            if (!isAgreement) {
                order.state = State.FORCE_CLOSED;
            } else {
                order.state = State.AGREEMENT;
            }

            order.lockFee = holdFee;
            order.newLockFee = 0;

            userOrders[order.holder][userOrderIDMapping[_orderID]] = uint256(
                -1
            );

            if (realProfit > 0) {
                if (order.contractType == ContractType.LONG) {
                    order.closePrice =
                        order.openPrice +
                        realProfit.mul(PRICE_DECIMALS) /
                        order.number;
                } else {
                    order.closePrice =
                        order.openPrice -
                        realProfit.mul(PRICE_DECIMALS) /
                        order.number;
                }
            } else {
                order.closePrice = _currentPrice;
            }

            uint256 reserveAmount = order.liquidationFee;

            AccountInfo storage userAcc = userAccount[order.holder];
            userAcc.availableAmount = userAcc.availableAmount.add(realProfit);
            userAcc.liquidationFee = userAcc.liquidationFee.sub(reserveAmount);
            userAcc.depositAmount = userAcc
                .depositAmount
                .add(realProfit)
                .sub(holdFee)
                .sub(reserveAmount);
            orders[_orderID] = order;

            emit BalanceOfTaker(
                order.holder,
                userAcc.depositAmount,
                userAcc.availableAmount,
                userAcc.liquidationFee
            );
            emit SLDRiskHandle(
                _orderID,
                order.state,
                order.lockFee,
                order.newLockFee,
                order.closePrice
            );

            _safeTransfer(tokenAddr, riskFundAddr, reserveAmount);
        }
    }

    /**
     * @dev Get Margin amount locked in private market maker's fund.
     * @param _orderID Order id.
     */
    function getLpMarginAmount(uint256 _orderID)
        internal
        view
        returns (uint256 marginAmount)
    {
        uint256 puborPriPool = checkOrder(_orderID);
        if (puborPriPool == 0) return 0;
        if (puborPriPool == 2) {
            //lp2RiskControl
            (marginAmount, ) = privPool.getMarginAmount(_orderID);
        } else {
            (marginAmount, ) = pubPool.getMarginAmount(_orderID);
        }
    }

    /**
     * @dev Get Margin amount locked in private market maker's fund.
     * @param _orderID Order id.
     */
    function getLpMarginAmountAndMarginFee(uint256 _orderID)
        public
        view
        returns (uint256 marginAmount, uint256 marginFee)
    {
        uint256 puborPriPool = checkOrder(_orderID);
        if (puborPriPool == 0) return (0, 0);
        if (puborPriPool == 2) {
            //lp2RiskControl
            (marginAmount, marginFee) = privPool.getMarginAmount(_orderID);
        } else {
            (marginAmount, marginFee) = pubPool.getMarginAmount(_orderID);
        }
    }

    /**
     * @dev Check whether the order is as risk.
     * @param _orderID Order id.
     */
    function checkOrderIsAtRisk(uint256 _orderID) public view returns (bool) {
        Order memory order = orders[_orderID];
        require(order.state == State.ACTIVE, "wrong state");
        uint256 puborPriPool = checkOrder(_orderID);
        require(puborPriPool > 0, "mismatched");

        require(
            address(assetsNameMapping[order.exchangeType]) != address(0x0),
            "unsupport"
        );
        UnderlyingAsset asset = assetsNameMapping[order.exchangeType];
        uint256 currentPrice = asset.getPrice(); //real
        uint256 calProfit = payProfit(currentPrice, _orderID);
        uint256 marginAmount;
        if (puborPriPool == 2) {
            //lp2RiskControl
            (marginAmount, ) = privPool.getMarginAmount(_orderID);
            if (calProfit > marginAmount) return true;
        } else {
            (marginAmount, ) = pubPool.getMarginAmount(_orderID);
            if (calProfit > marginAmount.mul(50).div(100)) return true;
        }
    }

    /**
     * @dev Get the length of the order array.
     */
    function getOrdersLen() public view returns (uint256 _ordersLen) {
        _ordersLen = orders.length;
    }

    function getFundingFeeInfo(uint256 _orderID)
        public
        view
        returns (
            uint256 _paidFundingFee,
            uint256 _initalFundingfee,
            uint256 _pendingFundingfee,
            uint256 _periods,
            uint256 _periodsInHours
        )
    {
        Order memory order = orders[_orderID];
        _paidFundingFee = order.lockFee + order.newLockFee;
        _initalFundingfee = order.firstMgFee;

        (_periods, _periodsInHours) = DateTime.getIntervalPeriods(
            migrationInfo[_orderID].regulatedTime,
            block.timestamp,
            migrationPeriod
        );

        _pendingFundingfee = getFundingFeeByOrderID(
            _initalFundingfee,
            _periodsInHours,
            migrationInfo[_orderID].inPeriodHours
        );
    }

    /**
     * @dev Calculate funding fee.
     * @param _initialFundingFee Initial funnding fee charged at the first place.
     * @param _intervalPeriodsInHours Interval migration hours from the last migration time to regulated current time.
     * @param _inPeriodHours Hours which funding fees paid.
     */
    function getFundingFeeByOrderID(
        uint256 _initialFundingFee,
        uint256 _intervalPeriodsInHours,
        uint256 _inPeriodHours
    ) internal view returns (uint256 _fundingFee) {
        if (_inPeriodHours >= 24) {
            _fundingFee = _initialFundingFee
                .mul(_intervalPeriodsInHours)
                .mul(nextMgFeeRate)
                .div(24)
                .div(PRICE_DECIMALS);
        } else if (_intervalPeriodsInHours + _inPeriodHours <= 24) {
            _fundingFee = _initialFundingFee.mul(_intervalPeriodsInHours).div(
                24
            );
        } else if (_intervalPeriodsInHours + _inPeriodHours > 24) {
            _fundingFee = (uint256(24).sub(_inPeriodHours))
                .mul(_initialFundingFee)
                .div(24);
            _fundingFee += _intervalPeriodsInHours
                .add(_inPeriodHours)
                .sub(24)
                .mul(_initialFundingFee)
                .mul(nextMgFeeRate)
                .div(24)
                .div(PRICE_DECIMALS);
        } else {
            // never should happen
            _fundingFee = _initialFundingFee
                .mul(_inPeriodHours)
                .mul(nextMgFeeRate)
                .div(24)
                .div(PRICE_DECIMALS);
        }
    }

    /**
     * @dev Calculate funding fee.
     * @param _orderID Order ID.
     * @param _initialFundingFee Initial funnding fee charged at the first place.
     * @param _intervalPeriodsInHours Interval migration hours from the last migration time to regulated current time.
     */
    function addFeesForUser(
        uint256 _orderID,
        uint256 _initialFundingFee,
        uint256 _intervalPeriodsInHours
    ) internal view returns (bool _succ, uint256 _newFundingFee) {
        uint256 fundingFee = getFundingFeeByOrderID(
            _initialFundingFee,
            _intervalPeriodsInHours,
            migrationInfo[_orderID].inPeriodHours
        );
        address holder = orders[_orderID].holder;
        if (userAccount[holder].availableAmount >= fundingFee) {
            _newFundingFee = fundingFee;
            _succ = true;
        }
    }

    /**
     * @dev Check pool type the order matched(public pool or private pool)
     * @param _orderID Order ID.
     */
    function checkOrder(uint256 _orderID)
        public
        view
        returns (uint256 _lpFlag)
    {
        if (privPool.matchIds(_orderID) > 0) {
            return 2;
        } else if (pubPool.matchIds(_orderID) > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    function getUserOrders(address _addr)
        public
        view
        returns (uint256[] memory _orders)
    {
        _orders = userOrders[_addr];
    }

    /**
     * @dev Calculte taker profit of an order.
     * @param _currentPrice Current price of the according underlying asset.
     * @param _orderID Order id.
     */
    function payProfit(uint256 _currentPrice, uint256 _orderID)
        internal
        view
        returns (uint256 profit)
    {
        Order memory order = orders[_orderID];
        if (order.contractType == ContractType.LONG) {
            // CALL
            if (order.openPrice < _currentPrice)
                profit = order.number.mul(_currentPrice - order.openPrice).div(
                    PRICE_DECIMALS
                );
        } else {
            // PUT
            if (order.openPrice > _currentPrice)
                // calculate profit
                profit = order.number.mul(order.openPrice - _currentPrice).div(
                    PRICE_DECIMALS
                );
        }
    }

    /**
     * @dev Add a new underlying asset or update exisiting underlying asset.
     * @param _exchangeType  Exchange type name.
     * @param _underlyingAsset Underlying asset contract address.
     */
    function addOrUpdateUnderlyingAsset(
        string memory _exchangeType,
        address _underlyingAsset
    ) public onlyOwner {
        require(_underlyingAsset != address(0x0), "ZERO");

        assetsNameMapping[_exchangeType] = UnderlyingAsset(_underlyingAsset);
    }

    /**
     * @dev Remove inactive orders to recover storage space
     * @param _orderIDs Order ids.
     */
    function removeOrders(uint256[] memory _orderIDs) public onlyOwner {
        for (uint256 i = 0; i < _orderIDs.length; i++) {
            if (orders[_orderIDs[i]].state != State.ACTIVE) {
                delete orders[_orderIDs[i]];
            }
        }
    }

    /**
     * @dev Set private & public pool address
     * @param _priPool Private pool address.
     * @param _pubPool Public pool address.
     */
    function setPriAndPubPool(address _priPool, address _pubPool)
        public
        onlyOwner
    {
        require(
            address(_priPool) != address(0x0) &&
                address(_pubPool) != address(0x0),
            "ZERO"
        );
        privPool = IPrivatePool(_priPool);
        pubPool = IPublicPool(_pubPool);
    }

    /**
     * @dev Set risk fund address
     * @param _riskFundAddr Risk fund address.
     */
    function setRiskFundAddr(address _riskFundAddr) public onlyOwner {
        require(address(_riskFundAddr) != address(0x0), "ZERO");
        riskFundAddr = _riskFundAddr;
    }

    /**
     * @dev Set broker contract address
     * @param _brokerAddr Broker contract address.
     */
    function setBrokerAddr(address _brokerAddr) public onlyOwner {
        require(address(_brokerAddr) != address(0x0), "ZERO");
        brokerAddr = _brokerAddr;
    }

    /**
     * @dev Set liquidation contract address
     * @param _liquidatorAddr Liquidation contract address.
     */
    function setLiquidatorAddr(address _liquidatorAddr) public onlyOwner {
        require(address(_liquidatorAddr) != address(0x0), "ZERO");
        liquidatorAddr = _liquidatorAddr;
    }

    /**
     * @dev Set buyback contract address
     * @param _buybackAddr Buyback contract address.
     */
    function setBuybackAddr(address _buybackAddr) public onlyOwner {
        require(address(_buybackAddr) != address(0x0), "ZERO");
        buybackAddr = _buybackAddr;
    }

    /**
     * @dev Set migration fee rate
     * @param _nextMgFee Migration fee rate.
     */
    function setMigrationNextFee(uint256 _nextMgFee) public onlyOwner {
        nextMgFeeRate = _nextMgFee.div(100);
    }

    /**
     * @dev Set migration period
     * @param _migrationPeriod Migration period.
     */
    function setMigrationPeriod(uint256 _migrationPeriod) public onlyOwner {
        require(_migrationPeriod < 24 && 24 % _migrationPeriod == 0, "INVALID");
        migrationPeriod = _migrationPeriod;
    }

    /**
     * @dev Set minimum deposit amount
     * @param _minDepositAmount Minimum deposit amount.
     */
    function setMinDepositAmount(uint256 _minDepositAmount) public onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @dev Set allocation rate of trading fee
     * @param _brokerPortion Portion allocate to broker.
     * @param _buybackPortion Portion allocate to buyback pool.
     */
    function setTradingFeeAllocation(
        uint256 _brokerPortion,
        uint256 _buybackPortion
    ) public onlyOwner {
        require(brokerPortion + buybackPortion <= 100, "Exceed");
        brokerPortion = _brokerPortion;
        buybackPortion = _buybackPortion;
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER_FROM, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_APPROVE, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
