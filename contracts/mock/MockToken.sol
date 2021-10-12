// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../SLDCommon.sol";

/**
 * @notice Mock BEP20 tokens used for testing.
 */
contract MockToken is BEP20 {
    mapping(address => bool) public claimed;

    constructor(string memory name, string memory symbol)
        public
        BEP20(name, symbol)
    {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mintToken() public {
        require(!claimed[msg.sender], "claimed");
        _mint(msg.sender, 50000 * 1e18);
        claimed[msg.sender] = true;
    }
}
