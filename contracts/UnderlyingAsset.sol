// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
import "./SLDFormula.sol";
import "./Aggregator.sol";
import "./SLDInterfaces.sol";
import "./DateTime.sol";

contract UnderlyingAsset is ISLDContract, Ownable {
    using SafeMath for uint256;
    using DateTime for uint256;

    string public name;

    uint256 public tradingFeeRate = (1 * 1e18) / 1000; // means 0.1%
    uint256 public liquidationFeeRate = (1 * 1e18) / 1000; // means 0.1%
    uint256 public minAmount = 1e16;

    uint256 public constant TOKEN_DECIMALS = 1e18;
    uint256 private constant PRICE_DECIMALS = 1e18;
    uint256 private constant ROUND_DECIMALS = 1e6;

    bool private priceThirdFlag;
    uint256 private thirdProxyPrice;

    Formula public formula;

    constructor(string memory _name, address _formula) public {
        name = _name;
        formula = Formula(_formula);
    }

    function getPrice() public view returns (uint256) {
        if (priceThirdFlag) {
            return thirdProxyPrice;
        }

        (uint256 price, uint8 decimals) = formula.getPriceByAggregator();

        uint256 latestPrice = (price * TOKEN_DECIMALS) /
            (10**uint256(decimals));

        return latestPrice;
    }

    function getFundingFee(
        uint256 _amount,
        uint256 _openPrice,
        ContractType _contractType
    ) public view returns (uint256 _fee) {
        _fee = formula.getFundingFee(
            _amount,
            _openPrice,
            _openPrice,
            1,
            _contractType
        );
    }

    /**
     * @dev Get funding fee rate within this period.
     * @param _contractType LONG or SHORT
     * @return _fundingFeeRate
     */
    function getFundingFeeRate(ContractType _contractType)
        public
        view
        returns (uint256 _fundingFeeRate)
    {
        uint256 currentPrice = getPrice();
        uint256 number = 1e18;

        uint256 amount = number.mul(currentPrice).div(PRICE_DECIMALS);
        uint256 fundingFee = getFundingFee(number, currentPrice, _contractType);

        _fundingFeeRate = fundingFee.mul(1e8).div(amount);
    }

    function fees(
        uint256 _number,
        ContractType _contractType,
        uint256 _period
    )
        public
        view
        returns (
            uint256 total,
            uint256 tradingFee,
            uint256 fundingFee,
            uint256 liquidationFee,
            uint256 currentPrice
        )
    {
        currentPrice = getPrice();

        uint256 amount = _number.mul(currentPrice).div(PRICE_DECIMALS);
        tradingFee = amount.mul(tradingFeeRate).div(PRICE_DECIMALS);
        fundingFee = getFundingFee(_number, currentPrice, _contractType);
        liquidationFee = amount.mul(liquidationFeeRate).div(PRICE_DECIMALS);
        total = tradingFee.add(fundingFee.div(_period)).add(liquidationFee);
    }

    function getLockedAmount(
        uint256 _amount,
        uint256 _currentPrice,
        uint256 _poolType
    ) public view returns (uint256 marginFee, uint256 forceFee) {
        (marginFee, forceFee) = formula.getMargin(
            _amount,
            _currentPrice,
            _poolType
        );
    }

    function getMaxOpenAmount(
        uint256 _amount,
        ContractType _contractType,
        uint256 _period
    ) public view returns (uint256) {
        require(_amount > 0, "param is invalid");

        (
            ,
            uint256 tradingFee,
            uint256 fundingFee,
            uint256 liquidationFee,

        ) = fees(TOKEN_DECIMALS, _contractType, _period);

        uint256 totalFee = tradingFee.add(fundingFee.div(_period)).add(
            liquidationFee
        );

        return
            _amount.mul(TOKEN_DECIMALS).div(totalFee).div(ROUND_DECIMALS).mul(
                ROUND_DECIMALS
            );
    }

    function setFormula(address _formula) public onlyOwner {
        require(address(_formula) != address(0x0), "ADDRESS_ZERO");
        formula = Formula(_formula);
        emit SetFormula(address(_formula));
    }

    function setMinAmount(uint256 _minAmount) public onlyOwner {
        require(_minAmount > 0, "INVALID");
        minAmount = _minAmount;
    }

    function setTradingFeeRate(uint256 _tradingFeeRate) public onlyOwner {
        require(_tradingFeeRate > 0, "WRONG FEE RATE");
        tradingFeeRate = _tradingFeeRate;
    }

    function setliquidationFeeRate(uint256 _liquidationFeeRate)
        public
        onlyOwner
    {
        require(_liquidationFeeRate > 0, "ZERO");
        liquidationFeeRate = _liquidationFeeRate;
    }

    function setPriceThirdProxy(bool _priceThirdFlag, uint256 _thirdProxyPrice)
        public
        onlyOwner
    {
        require(_thirdProxyPrice > 0, "thirdProxyPrice zero");
        priceThirdFlag = _priceThirdFlag;
        thirdProxyPrice = _thirdProxyPrice;
    }

    function getThirdPriceAndFlag() public view returns (bool, uint256) {
        return (priceThirdFlag, thirdProxyPrice);
    }
}
