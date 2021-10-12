const fs = require("fs");
const path = require("path");

const UnderlyingAsset = artifacts.require("UnderlyingAsset");
const config = require("./config.json");

const deployUnderlyingAssets = async (deployer, network, accounts) => {
    if (network == "test") return;

    if (!config.ETHUnderlyingAsset) {
        console.log("Deploying ETH underlying asset contract...");
        const underlyingAsset = await deployer.deploy(
            UnderlyingAsset,
            "ETH",
            config.ETHUSDFormulaAddr,
        );
        console.log(`ETH underlying asset has been deployed on ${underlyingAsset.address}`);

        config.ETHUnderlyingAsset = underlyingAsset.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const underlyingAsset = await UnderlyingAsset.at(config.ETHUnderlyingAsset);
        console.log(`ETH underlying asset has been deployed on ${underlyingAsset.address}`);
    }

    if (!config.BTCUnderlyingAsset) {
        console.log("Deploying BTC underlying asset contract...");
        const underlyingAsset = await deployer.deploy(
            UnderlyingAsset,
            "BTC",
            config.BTCUSDFormulaAddr,
        );
        console.log(`BTC underlying asset has been deployed on ${underlyingAsset.address}`);

        config.BTCUnderlyingAsset = underlyingAsset.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const underlyingAsset = await UnderlyingAsset.at(config.BTCUnderlyingAsset);
        console.log(`BTC underlying asset has been deployed on ${underlyingAsset.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployUnderlyingAssets(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
