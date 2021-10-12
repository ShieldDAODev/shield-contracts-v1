const fs = require("fs");
const path = require("path");

const config = require("./config.json");
const SLDLiquidator = artifacts.require("SLDLiquidator");

const deployLiquidator = async (deployer, network, accounts) => {
    if (network == "test") return;

    if (!config.LiquidatorAddr) {
        console.log("Deploying liquidator contract...");
        const liquidator = await deployer.deploy(SLDLiquidator,
            config.RewardAddr,
            config.RiskFundAddr,
            config.BNBUSDAggreagator,
            config.DAIAddr,
            config.USDTAddr,
            config.USDCAddr);
        console.log(`Liquidator has been deployed on ${liquidator.address}`);

        config.LiquidatorAddr = liquidator.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const liquidator = await SLDLiquidator.at(config.LiquidatorAddr);
        console.log(`Liquidator has been deployed on ${liquidator.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployLiquidator(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
