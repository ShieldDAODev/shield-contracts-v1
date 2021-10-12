const fs = require("fs");
const path = require("path");

const SLDBuyBack = artifacts.require("SLDBuyBack");
const config = require("./config.json");

const deployBuyback = async (deployer, network, accounts) => {
    if (network == "test") return;

    if (!config.BuyBackAddr) {
        console.log("Deploying buyback contract...");
        const buyback = await deployer.deploy(
            SLDBuyBack,
            config.SLDAddr,
            config.DAIAddr,
            config.USDTAddr,
            config.USDCAddr,
        );
        console.log(`Buyback has been deployed on ${buyback.address}`);

        config.BuyBackAddr = buyback.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const buyback = await SLDBuyBack.at(config.BuyBackAddr);
        console.log(`Buyback has been deployed on ${buyback.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployBuyback(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
