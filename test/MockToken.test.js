const assert = require('assert');
const { expectRevert } = require('@openzeppelin/test-helpers');

const BigNumber = require('bignumber.js');

const MockToken = artifacts.require("MockToken");

contract("Test Mock Token", async ([deployer, user1]) => {
    let mockToken;
    before(async () => {
        mockToken = await MockToken.new("Mock Token", "Mock");
    });

    it("Owner should mint", async () => {
        const mintTokenAmount = BigNumber(100000).times(1e18).toString(10);

        let beforeMint = await mockToken.balanceOf(deployer);

        await mockToken.mint(deployer, mintTokenAmount, {
            from: deployer
        });

        let afterMint = await mockToken.balanceOf(deployer);

        assert.ok(BigNumber(mintTokenAmount).isEqualTo(BigNumber(afterMint).minus(beforeMint)));
    })

    it("User should claim", async () => {
        let beforeClaim = await mockToken.balanceOf(user1);

        await mockToken.mintToken({
            from: user1
        });

        let afterClaim = await mockToken.balanceOf(user1);
        assert.ok(BigNumber(50000).times(1e18).isEqualTo(BigNumber(afterClaim).minus(beforeClaim)));
    });

    it("User should only claim once", async () => {
        const claimed = await mockToken.claimed(user1);
        assert.ok(claimed);

        await expectRevert.unspecified(mockToken.mintToken({
            from: user1
        }));
    });
});

