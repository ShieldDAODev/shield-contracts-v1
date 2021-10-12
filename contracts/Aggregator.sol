// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./interfaces/IAggregatorV3.sol";
import "./SLDCommon.sol";

/**
 * @notice Aggregator contract.
 */
contract Aggregator is Ownable {
    using SafeMath for uint256;

    IAggregatorV3 public aggregator;

    string public name;
    address public token1;
    address public token2;

    uint256 public multiplier = 1e18;
    bool public reverse = false;

    mapping(address => bool) public keeperMap;

    /**
     * @dev The event indicates that a Keeper auth is set.
     */
    event SetKeeper(address keeper, bool auth);

    /**
     * @dev A transaction is invoked on the Aggregator.
     */
    event Invoked(address indexed targetAddress, uint256 value, bytes data);

    constructor(
        string memory _name,
        address _token1,
        address _token2,
        address _aggregatorAddr,
        bool _reverse
    ) public {
        name = _name;
        token1 = _token1;
        token2 = _token2;
        aggregator = IAggregatorV3(_aggregatorAddr);
        reverse = _reverse;
    }

    /**
     * @dev Get latest data of aggregator.
     */
    function latestRoundData() external view returns (uint256, uint8) {
        uint8 decimals = aggregator.decimals();
        (, int256 price, , , ) = aggregator.latestRoundData();
        uint256 latestPrice = uint256(price);
        if (reverse) {
            latestPrice = uint256(10**uint256(decimals))
                .div(uint256(price))
                .mul((10**uint256(decimals)));
        }
        return (latestPrice, decimals);
    }

    /**
     * @dev Retrives two tokens address of token pair.
     */
    function getTokenPair() public view returns (address, address) {
        return (token1, token2);
    }

    /**
     * @dev Update keeper.
     */
    function setKeeper(address addr, bool auth) public onlyOwner {
        keeperMap[addr] = auth;
        emit SetKeeper(addr, auth);
    }

    function isKeeper(address addr) public view returns (bool) {
        return keeperMap[addr];
    }

    function setAggregator(uint256 _aggregatorAddr) public onlyOwner {
        aggregator = IAggregatorV3(_aggregatorAddr);
    }

    function setMultiplier(uint256 _multiplier) public onlyOwner {
        multiplier = _multiplier;
    }

    function setReverse(bool _reverse) public onlyOwner {
        reverse = _reverse;
    }
}
