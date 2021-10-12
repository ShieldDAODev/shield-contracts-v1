// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "../SLDCommon.sol";

contract SLDToken is BEP20("ShieldEx Token", "SLD"), Ownable {
    constructor() public {
        _mint(_msgSender(), 1000000000 * 1e18);
    }
}
