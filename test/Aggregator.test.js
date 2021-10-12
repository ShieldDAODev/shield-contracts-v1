const assert = require('assert');

const { expectRevert } = require('@openzeppelin/test-helpers');
const Aggregator = artifacts.require("Aggregator");

let aggregator;
let price1;

const fakeAddr = "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7";

// Chainlink on BSC testnet:
//  - https://docs.chain.link/docs/binance-smart-chain-addresses/
const ETHUSD = "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7";
const BUSDETH = "0x5ea7D6A33D3655F661C298ac8086708148883c34";

contract("Aggregator", async ([deployer, user1]) => {
    it("should getTokenPair", async () => {
        aggregator = await Aggregator.new("ETHUSD", fakeAddr, fakeAddr, ETHUSD, false, { from: deployer });

        const tokenPair = await aggregator.getTokenPair();
        assert.equal(tokenPair[0], fakeAddr);
        assert.equal(tokenPair[1], fakeAddr);
    });

    it("should get latestRoundData", async () => {
        await aggregator.setKeeper(deployer, true, { from: deployer });
        const latestData = await aggregator.latestRoundData();
        price1 = latestData["0"] / (10 ** latestData["1"]);

        assert.ok(price1 >= 1500 && price1 <= 15000);
    });

    it("should update aggregator", async () => {
        await aggregator.setAggregator(BUSDETH, { from: deployer });
        await aggregator.setMultiplier("1000000000", { from: deployer });
        await aggregator.setReverse(true, { from: deployer });

        assert.equal((await aggregator.aggregator()), BUSDETH);
        assert.equal((await aggregator.multiplier()).toString(), "1000000000");
        assert.equal((await aggregator.reverse()), true);
    });

    it("should cal right price using reverse aggregator", async () => {
        aggregator = await Aggregator.new("BUSDETH", fakeAddr, fakeAddr, BUSDETH, true);
        const latestData = await aggregator.latestRoundData();
        let price2 = latestData["0"] / (10 ** latestData["1"]);

        assert.ok(Math.abs(price1 - price2) <= 50);
    });

    it("should not allow set any params by not owner", async () => {
        await expectRevert.unspecified(aggregator.setAggregator(BUSDETH, { from: user1 }));
        await expectRevert.unspecified(aggregator.setMultiplier("10000000000", { from: user1 }));
        await expectRevert.unspecified(aggregator.setReverse(false, { from: user1 }));
    });
});
