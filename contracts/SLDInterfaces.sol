// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./SLDCommon.sol";

interface ISLDCommon {
    enum ContractType {
        INVALID,
        LONG,
        SHORT
    }
    enum StableCoinType {
        INVALID,
        DAI,
        USDT,
        USDC
    }
    enum PoolFlag {
        INVALID,
        PUBLIC,
        PRIVATE
    }
}

interface ISLDContract is ISLDCommon {
    event SLDDeposit(
        address indexed sender,
        address indexed toAddr,
        uint256 motageAmount
    );
    event SLDWithdraw(
        address indexed sender,
        address indexed toAddr,
        uint256 motageAmount
    );

    event SetFormula(address indexed addr);

    event BalanceOfTaker(
        address indexed taker,
        uint256 depositAmount,
        uint256 availableAmount,
        uint256 liquidationFee
    );

    event SLDOpenContract(
        address indexed holder,
        uint256 orderID,
        ContractType contractType,
        State state,
        string exchangeType,
        uint256 number,
        uint256 tradingFee,
        uint256 liquidationFee,
        uint256 firstMgFee,
        uint256 lockFee,
        uint256 newLockFee,
        uint256 openPrice
    );

    event SLDCloseContract(
        uint256 orderID,
        State state,
        uint256 lockFee,
        uint256 newLockFee,
        uint256 closePrice
    );

    event SLDMigration(
        uint256 orderID,
        State state,
        uint256 lockFee,
        uint256 newLockFee,
        uint256 closePrice
    );

    event SLDRiskHandle(
        uint256 orderID,
        State state,
        uint256 lockFee,
        uint256 newLockFee,
        uint256 closePrice
    );

    enum State {
        PENDING,
        ACTIVE,
        CLOSED,
        FORCE_CLOSED,
        AGREEMENT
    }

    struct Order {
        address payable holder;
        ContractType contractType;
        State state;
        string exchangeType;
        uint256 number;
        uint256 tradingFee;
        uint256 liquidationFee;
        uint256 firstMgFee;
        uint256 lockFee;
        uint256 newLockFee;
        uint256 openPrice;
        uint256 startTime;
        uint256 closePrice;
    }

    struct AccountInfo {
        uint256 depositAmount;
        uint256 availableAmount;
        uint256 liquidationFee;
    }

    struct Fees {
        uint256 total;
        uint256 tradingFee;
        uint256 fundingFee;
        uint256 liquidationFee;
        uint256 currentPrice;
    }

    struct MigrationDetail {
        uint256 migrationTime;
        uint256 regulatedTime;
        uint256 inPeriodHours;
    }
}

interface IPublicPool {
    function lock(
        uint256 id,
        uint256 marginAmount,
        uint256 marginFee
    ) external returns (bool);

    function close(
        uint256 id,
        uint256 profit,
        uint256 fundingFee
    ) external returns (uint256 userProfit, bool isAgreement);

    function riskClose(
        uint256 id,
        uint256 profit,
        uint256 fundingFee
    )
        external
        returns (
            bool flag,
            uint256 userProfit,
            bool isAgreement
        );

    function matchIds(uint256 orderId) external view returns (uint256);

    function getMarginAmount(uint256 orderID)
        external
        view
        returns (uint256 marginAmount, uint256 marginFee);

    function getLP2ToLp1MovePrice(uint256 takerOrderId)
        external
        view
        returns (bool, uint256);
}

interface IPrivatePool {
    function lock(
        uint256 id,
        uint256 marginAmount,
        uint256 marginFee,
        uint256 exchgFee
    ) external returns (bool);

    function close(
        uint256 id,
        uint256 profit,
        uint256 fundingFee
    ) external returns (uint256 userProfit, bool isAgreement);

    function riskClose(
        uint256 orderID,
        uint256 number,
        uint256 fundingFee,
        uint256 profit,
        uint256 openPrice,
        uint256 currPrice
    )
        external
        returns (
            bool flag,
            uint256 userProfit,
            bool isAgreement
        );

    function matchIds(uint256 orderId) external view returns (uint256);

    function getMarginAmount(uint256 orderID)
        external
        view
        returns (uint256 marginAmount, uint256 marginFee);
}

interface ISLDLiquidityPool is ISLDCommon {
    event LockInPrivatePool(
        uint256 orderID,
        address maker,
        uint256 makerID,
        uint256 marginAmount,
        uint256 marginFee
    );

    event LockInPublicPool(
        uint256 orderID,
        uint256 makerID,
        uint256 marginAmount,
        uint256 marginFee
    );

    event CloseInPrivatePool(
        address maker,
        uint256 makerID,
        uint256 orderID,
        uint256 userProfit
    );

    event CloseInPublicPool(
        uint256 makerID,
        uint256 orderID,
        uint256 userProfit
    );

    event RiskInPrivatePool(
        address maker,
        uint256 makerID,
        uint256 orderID,
        uint256 userProfit
    );

    event RiskInPubicPool(uint256 makerID, uint256 orderID, uint256 userProfit);

    event MoveToPublic(
        uint256 id,
        uint256 profit,
        uint256 moveProfit,
        uint256 openPrice,
        uint256 movePrice
    );

    event BalanceofMaker(
        address maker,
        uint256 amount,
        uint256 availableAmount,
        uint256 lockedAmount,
        uint256 marginFee
    );

    event BalanceofPublic(
        uint256 depositTotal,
        uint256 lockedAmount,
        uint256 availAmount
    );

    struct LiquidityMarket {
        uint256 takerId;
        uint256 marginAmount;
        uint256 marginFee;
        uint256 pubPriFlag; //1 - public pool, 2 - private pool
        uint256 changePrice;
        address makerAddr;
        bool locked;
    }

    struct LP1Account {
        address payable holder;
        uint256 reTokenAmount;
    }

    struct LP2Account {
        address payable holder;
        uint256 amount;
        uint256 availableAmount;
        uint256 lockedAmount;
        uint256 marginFee;
        bool isRejectOrder;
    }

    struct P1AmountInfo {
        uint256 plDepositTotal;
        uint256 pl1lockedAmount;
        uint256 pl1AvailAmount;
    }

    struct CloseOrder {
        uint256 number;
        uint256 orderID;
        uint256 matchID;
        uint256 profit;
        uint256 openPrice;
        uint256 currPrice;
        uint256 fundingFee;
        uint256 totalMarginAmount;
    }

    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event ProvideLP2(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event AddMargin(
        address indexed account,
        uint256 orderID,
        uint256 amount,
        uint256 margin
    );

    function totalBalance() external view returns (uint256 amount);
}

interface IFormulaContracts is ISLDCommon {
    using SafeMath for uint256;
    struct Settings {
        uint256 realVolatility;
        uint256 historyVolatility;
        uint256 delta;
    }
}

interface ISLDBroker {
    function addInviteRelationAndCalc(
        address inviter,
        address invitee,
        uint256 tokenType,
        uint256 amount
    ) external returns (address);
}

interface ISLDLiquidator {
    function calcLiquidatorAmount(
        address liquidor,
        uint256 tokenType,
        uint256 gasUsed
    ) external returns (bool);
}

interface ISLDRewards {
    function stakeRewardsForLP1(
        address lp,
        uint256 tokenType,
        uint256 oriTokenAmount,
        uint256 reTokenAmount
    ) external returns (bool);

    function calcAndSendRewardsForLP1(
        address lp,
        uint256 tokenType,
        uint256 reTokenAmount
    ) external returns (bool);

    function calcAndSendRewardsForLP2(address lp, uint256 orderFee)
        external
        returns (bool);

    function calcAndSendRewardsForLiquidator(address liquidor, uint256 gasUsed)
        external
        returns (bool);

    function calcAndSendRewardsForLiquidatorWeekly(
        address liquidor,
        uint256 rank
    ) external returns (bool);
}
