const fs = require("fs");
const path = require("path");

const PublicPool = artifacts.require("SLDPublicPool");
const config = require("./config.json");

const deployPublicPool = async (deployer, network, accounts) => {
    if (network == "test") return;

    const riskFundAddr = config.RiskFundAddr;
    const DAIPublicPoolAddr = config.DAIPublicPoolAddr;

    if (!DAIPublicPoolAddr) {
        console.log("Deploying DAI public pool contract...");

        if (config.FormulaAddr && formula.address != config.FormulaAddr) {
            formula = await Formula.at(config.FormulaAddr);
        }

        const publicPool = await deployer.deploy(PublicPool, "Shield reDAI Token", "reDAI", riskFundAddr, config.DAIAddr, config.ETHUSDFormulaAddr);

        console.log(`DAI Public pool has been deployed on ${publicPool.address}`);

        config.DAIPublicPoolAddr = publicPool.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const publicPool = await PublicPool.at(DAIPublicPoolAddr);
        console.log(`DAI Public Pool has been deployed on ${publicPool.address}`);
    }

    const USDTPublicPoolAddr = config.USDTPublicPoolAddr;

    if (!USDTPublicPoolAddr) {
        console.log("Deploying USDT public pool contract...");

        if (config.FormulaAddr && formula.address != config.FormulaAddr) {
            formula = await Formula.at(config.FormulaAddr);
        }

        const publicPool = await deployer.deploy(PublicPool, "Shield reUSDT Token", "reUSDT", riskFundAddr, config.USDTAddr, config.ETHUSDFormulaAddr);

        console.log(`USDT Public pool has been deployed on ${publicPool.address}`);

        config.USDTPublicPoolAddr = publicPool.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const publicPool = await PublicPool.at(USDTPublicPoolAddr);
        console.log(`USDT Public Pool has been deployed on ${publicPool.address}`);
    }

    const USDCPublicPoolAddr = config.USDCPublicPoolAddr;

    if (!USDCPublicPoolAddr) {
        console.log("Deploying USDC public pool contract...");

        if (config.FormulaAddr && formula.address != config.FormulaAddr) {
            formula = await Formula.at(config.FormulaAddr);
        }

        const publicPool = await deployer.deploy(PublicPool, "Shield reUSDC Token", "reUSDC", riskFundAddr, config.USDCAddr, config.ETHUSDFormulaAddr);

        console.log(`USDC Public pool has been deployed on ${publicPool.address}`);

        config.USDCPublicPoolAddr = publicPool.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const publicPool = await PublicPool.at(USDCPublicPoolAddr);
        console.log(`USDC Public Pool has been deployed on ${publicPool.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployPublicPool(deployer, network, accounts))
        .catch(error => {
            // console.log(error);
            process.exit(1);
        });
};
