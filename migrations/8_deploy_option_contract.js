const fs = require("fs");
const path = require("path");

const SLDOption = artifacts.require("SLDOption");

const config = require("./config.json");

const deployOptionContract = async (deployer, network, accounts) => {
    if (network == "test") return;

    const DAIOptionAddr = config.DAIOptionAddr;

    if (!DAIOptionAddr) {
        const option = await deployer.deploy(
            SLDOption,
            config.DAIPublicPoolAddr,
            config.DAIPrivatePoolAddr,
            config.RiskFundAddr,
            config.DAIAddr,
            1,
        );
        console.log(`DAI option has been deployed on ${option.address}`);

        config.DAIOptionAddr = option.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const option = await SLDOption.at(DAIOptionAddr);
        console.log(`DAI option has been deployed on ${option.address}`);
    }

    const USDTOptionAddr = config.USDTOptionAddr;

    if (!USDTOptionAddr) {
        const option = await deployer.deploy(
            SLDOption,
            config.USDTPublicPoolAddr,
            config.USDTPrivatePoolAddr,
            config.RiskFundAddr,
            config.USDTAddr,
            2,
        );
        console.log(`USDT option has been deployed on ${option.address}`);

        config.USDTOptionAddr = option.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const option = await SLDOption.at(USDTOptionAddr);
        console.log(`USDT option has been deployed on ${option.address}`);
    }

    const USDCOptionAddr = config.USDCOptionAddr;

    if (!USDCOptionAddr) {
        const option = await deployer.deploy(
            SLDOption,
            config.USDCPublicPoolAddr,
            config.USDCPrivatePoolAddr,
            config.RiskFundAddr,
            config.USDCAddr,
            3,
        );
        console.log(`USDC option has been deployed on ${option.address}`);

        config.USDCOptionAddr = option.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const option = await SLDOption.at(USDCOptionAddr);
        console.log(`USDC option has been deployed on ${option.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployOptionContract(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
