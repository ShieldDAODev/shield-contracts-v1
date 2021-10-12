const fs = require("fs");
const path = require("path");

const config = require("./config.json");

const AggregatorFactory = artifacts.require("AggregatorFactory");
const Aggregator = artifacts.require("Aggregator");

const deployAggregatorFactory = async (deployer, network, accounts) => {
    if (network == "test") return;

    const aggregatorFactoryAddr = config.AggregatorFactoryAddr;
    if (!aggregatorFactoryAddr) {
        const aggregatorFactory = await deployer.deploy(AggregatorFactory);

        console.log(`Aggregator Factory has been deployed on ${aggregatorFactory.address}`);

        await aggregatorFactory.setKeeper(accounts[0], true);

        await aggregatorFactory.createAggregator("ETHUSDT", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", 0, "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7", false);
        await aggregatorFactory.createAggregator("BTCUSDT", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", 1, "0x5741306c21795FdCBb9b265Ea0255F499DFe515C", false);
        await aggregatorFactory.createAggregator("BNBUSD", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", 2, "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526", false);

        const ETHUSDAggreagator = await aggregatorFactory.getAggregator(0);
        const BTCUSDAggreagator = await aggregatorFactory.getAggregator(1);
        const BNBUSDAggreagator = await aggregatorFactory.getAggregator(2)
        console.log("\tThe address of ETH/USD Aggregator is: ", ETHUSDAggreagator);
        console.log("\tThe address of BTC/USD Aggregator is: ", BTCUSDAggreagator);
        console.log("\tThe address of BNB/USD Aggregator is: ", BNBUSDAggreagator);

        config.AggregatorFactoryAddr = aggregatorFactory.address;
        config.ETHUSDAggreagator = ETHUSDAggreagator;
        config.BTCUSDAggreagator = BTCUSDAggreagator;
        config.BNBUSDAggreagator = BNBUSDAggreagator;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const aggregatorFactory = await AggregatorFactory.at(aggregatorFactoryAddr);
        console.log(`Using aggregator factory deployed on ${aggregatorFactoryAddr}`);

        const aggregator1Addr = await aggregatorFactory.getAggregator(0);
        const aggregator1 = await Aggregator.at(aggregator1Addr);

        console.log(`Aggregator ${await aggregator1.name()} has deployed on ${aggregator1Addr}`)

        const aggregator2Addr = await aggregatorFactory.getAggregator(1);
        const aggregator2 = await Aggregator.at(aggregator2Addr);

        console.log(`Aggregator ${await aggregator2.name()} has deployed on ${aggregator2Addr}`)

        const aggregator3Addr = await aggregatorFactory.getAggregator(2);
        const aggregator3 = await Aggregator.at(aggregator3Addr);

        console.log(`Aggregator ${await aggregator3.name()} has deployed on ${aggregator3Addr}`)
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployAggregatorFactory(deployer, network, accounts))
        .catch(error => {
            console.log(error);
            process.exit(1);
        });
};
