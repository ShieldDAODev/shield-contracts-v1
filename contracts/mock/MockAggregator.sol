// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../SLDCommon.sol";

/**
 * @notice MockAggregator contract.
 */
contract MockAggregator is Ownable {
    using SafeMath for uint256;

    string public name;
    address public token1;
    address public token2;
    address public aggregatorAddr;

    uint256 public multiplier = 1e18;
    bool public reverse = false;

    int256 price;
    uint8 decimals;

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
        aggregatorAddr = _aggregatorAddr;
        reverse = _reverse;
    }

    /**
     * @dev Get mock price.
     */
    function latestRoundData() external view returns (uint256, uint8) {
        return (uint256(price), decimals);
    }

    /**
     * @dev Retrives two tokens address of token pair.
     */
    function getTokenPair() public view returns (address, address) {
        return (token1, token2);
    }

    function setPrice(int256 _price) public onlyOwner {
        price = _price;
    }

    function setDecimals(uint8 _decimals) public onlyOwner {
        decimals = _decimals;
    }

    function setMultiplier(uint256 _multiplier) public onlyOwner {
        multiplier = _multiplier;
    }

    function setReverse(bool _reverse) public onlyOwner {
        reverse = _reverse;
    }
}
