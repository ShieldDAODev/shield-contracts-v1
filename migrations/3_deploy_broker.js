const fs = require("fs");
const path = require("path");

const config = require("./config.json");
const SLDBroker = artifacts.require("SLDBroker");

const deploySLDBroker = async (deployer, network, accounts) => {
    if (network == "test") return;

    if (!config.BrokerAddr) {
        console.log("Deploying broker contract...");
        const broker = await deployer.deploy(SLDBroker, config.DAIAddr, config.USDTAddr, config.USDCAddr);
        console.log(`Broker has been deployed on ${broker.address}`);

        config.BrokerAddr = broker.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const broker = await SLDBroker.at(config.BrokerAddr);
        console.log(`Broker has been deployed on ${broker.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deploySLDBroker(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
