// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./Aggregator.sol";
import "./SLDCommon.sol";

/**
 * @notice Factory of Aggregator contracts.
 */
contract AggregatorFactory is Ownable {
    mapping(uint256 => Aggregator) private _aggregators;

    mapping(address => bool) public keeperMap;

    /**
     * @dev The event indicates that a new Aggregator contract is created.
     */
    event AggregatorCreated(
        address indexed token1,
        address indexed token2,
        uint256 index
    );

    /**
     * @dev The event indicates that a Keeper auth is set.
     */
    event SetKeeper(address keeper, bool auth);

    /**
     * @dev Creates a new Aggregator contract(price feeder of a token pair) for the keeper.
     * Keeper can create multiple aggregators by invoking this method multiple times.
     * However, every aggregator has its unique index and other contract could get certain
     * aggregato`r by its index.
     * @param _token1 token1 address of a token pair.
     * @param _token2 token2 address of a token pair.
     * @param _index index of an aggregator.
     * @param _aggregatorAddr address of an aggregator(provided by Chainlink).
     */
    function createAggregator(
        string memory _name,
        address _token1,
        address _token2,
        uint256 _index,
        address _aggregatorAddr,
        bool _reverse
    ) public onlyKeeper(msg.sender) returns (Aggregator) {
        require(
            address(_aggregators[_index]) == address(0x0),
            "aggregator exists."
        );

        Aggregator aggregator = new Aggregator(
            _name,
            _token1,
            _token2,
            _aggregatorAddr,
            _reverse
        );
        _aggregators[_index] = aggregator;

        return aggregator;
    }

    /**
     * @dev Retrives the Aggregator contract by index.
     * @param _index Index of the Aggregator.
     */
    function getAggregator(uint256 _index) public view returns (Aggregator) {
        return _aggregators[_index];
    }

    /**
     * @dev Throws if called by any account that does not the keeper.
     */
    modifier onlyKeeper(address addr) {
        require(isKeeper(addr), "caller is not the keeper");
        _;
    }

    function setKeeper(address addr, bool auth) public onlyOwner {
        keeperMap[addr] = auth;
        emit SetKeeper(addr, auth);
    }

    function isKeeper(address addr) public view returns (bool) {
        return keeperMap[addr];
    }
}
