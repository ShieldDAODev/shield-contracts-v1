const fs = require("fs");
const path = require("path");

const PrivatePool = artifacts.require("SLDPrivatePool");
const config = require("./config.json");

const deployPrivatePool = async (deployer, network, accounts) => {
    if (network == "test") return;

    const DAIPrivatePoolAddr = config.DAIPrivatePoolAddr;

    if (!DAIPrivatePoolAddr) {
        const privatePool = await deployer.deploy(
            PrivatePool,
            config.DAIPublicPoolAddr,
            config.DAIAddr,
            config.RewardAddr,
            config.RiskFundAddr);

        console.log(`DAI Private pool contract has been deployed on ${privatePool.address}`);

        config.DAIPrivatePoolAddr = privatePool.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const privatePool = await PrivatePool.at(DAIPrivatePoolAddr);
        console.log(`DAI Private Pool has been deployed on ${privatePool.address}`);
    }

    const USDTPrivatePoolAddr = config.USDTPrivatePoolAddr;

    if (!USDTPrivatePoolAddr) {
        const privatePool = await deployer.deploy(
            PrivatePool,
            config.USDTPublicPoolAddr,
            config.USDTAddr,
            config.RewardAddr,
            config.RiskFundAddr);

        console.log(`USDT Private pool contract has been deployed on ${privatePool.address}`);

        config.USDTPrivatePoolAddr = privatePool.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const privatePool = await PrivatePool.at(USDTPrivatePoolAddr);
        console.log(`USDT Private Pool has been deployed on ${privatePool.address}`);
    }

    const USDCPrivatePoolAddr = config.USDCPrivatePoolAddr;

    if (!USDCPrivatePoolAddr) {
        const privatePool = await deployer.deploy(
            PrivatePool,
            config.USDCPublicPoolAddr,
            config.USDCAddr,
            config.RewardAddr,
            config.RiskFundAddr);

        console.log(`USDC Private pool contract has been deployed on ${privatePool.address}`);

        config.USDCPrivatePoolAddr = privatePool.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const privatePool = await PrivatePool.at(USDCPrivatePoolAddr);
        console.log(`USDC Private Pool has been deployed on ${privatePool.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployPrivatePool(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
