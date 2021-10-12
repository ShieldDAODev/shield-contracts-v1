const assert = require('assert');

const { expectRevert } = require('@openzeppelin/test-helpers');
const AggregatorFactory = artifacts.require("AggregatorFactory");
const Aggregator = artifacts.require("Aggregator");

let factory;

const fakeAddr = "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7";

// Chainlink on BSC testnet:
//  - https://docs.chain.link/docs/binance-smart-chain-addresses/
const ETHUSD = "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7";
const BUSDETH = "0x5ea7D6A33D3655F661C298ac8086708148883c34";

contract("Aggregator", async ([deployer, user1]) => {
    before(async () => {
        factory = await AggregatorFactory.new();
        await factory.setKeeper(deployer, true);
    });

    it("should create Aggregator", async () => {
        await factory.createAggregator("ETHUSD", fakeAddr, fakeAddr, 0, ETHUSD, false, {
            from: deployer
        });

        const aggregator = await factory.getAggregator(0);
        assert.ok(aggregator !== "0x0000000000000000000000000000000000000000")
    });

    it("should use Aggregator returned by factory", async () => {
        const aggregatorAddr = await factory.getAggregator(0);
        const aggregator = await Aggregator.at(aggregatorAddr);

        const latestData = await aggregator.latestRoundData();
        price1 = latestData["0"] / (10 ** latestData["1"]);

        assert.ok(price1 >= 1500 && price1 <= 15000);
    });

    it("should not allow create aggregator by same index", async () => {
        await expectRevert.unspecified(factory.createAggregator("ETHUSD", fakeAddr, fakeAddr, 0, ETHUSD, false, {
            from: deployer
        }));
    });

    it("should not allow create aggregator by not keeper", async () => {
        await expectRevert.unspecified(factory.createAggregator("ETHUSD", fakeAddr, fakeAddr, 0, ETHUSD, false, {
            from: user1
        }));
    });

    it("should not allow set keeper by not owner", async () => {
        await expectRevert.unspecified(factory.setKeeper(deployer, false, {
            from: user1
        }));
    });
});
