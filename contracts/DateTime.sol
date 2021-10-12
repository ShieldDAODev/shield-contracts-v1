// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./SLDCommon.sol";

library DateTime {
    using SafeMath for uint256;

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant HOUR_IN_DAY = 24;

    function getInPeriodHours(uint256 _period) internal pure returns (uint256) {
        return HOUR_IN_DAY.div(_period);
    }

    function regulateTime(uint256 _timestamp, uint256 _period)
        internal
        pure
        returns (uint256)
    {
        uint256 period = DAY_IN_SECONDS.div(_period);
        uint256 remainder = _timestamp.mod(period);

        return _timestamp.sub(remainder);
    }

    function regulateTimeAfter(uint256 _timestamp, uint256 _period)
        internal
        pure
        returns (uint256)
    {
        uint256 period = DAY_IN_SECONDS.div(_period);
        uint256 remainder = _timestamp.mod(period);

        return _timestamp.sub(remainder).add(period);
    }

    function getIntervalPeriods(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _period
    )
        internal
        pure
        returns (uint256 _intervalPeriods, uint256 _intervalPeriodsInHours)
    {
        uint256 period = DAY_IN_SECONDS.div(_period);
        if (_endTime.add(period) >= regulateTime(_startTime, _period)) {
            _intervalPeriods = _endTime
                .add(period)
                .sub(regulateTime(_startTime, _period))
                .div(period);
            _intervalPeriodsInHours = regulateTimeAfter(_endTime, _period)
                .sub(_startTime)
                .div(HOUR_IN_SECONDS);
        }
    }
}
