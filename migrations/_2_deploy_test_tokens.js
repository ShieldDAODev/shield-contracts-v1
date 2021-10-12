const config = require("./config.json");

const MockToken = artifacts.require("MockToken");

const deployTokens = async (deployer, network, accounts) => {
    if (network == "test") return;

    const sldAddr = config.SLDAddr;
    const usdtAddr = config.USDTAddr;
    const usdcAddr = config.USDCAddr;
    const daiAddr = config.DAIAddr;

    if (!sldAddr) {
        console.log("Deploying SLD token...")
        const mockToken = await deployer.deploy(MockToken, "ShieldEx Token", "SLD");
        await mockToken.mint(accounts[0], "1000000000000000000000000000");
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    } else {
        const mockToken = await MockToken.at(sldAddr);
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    }

    if (!usdtAddr) {
        console.log("Deploying USDT token...")
        const mockToken = await deployer.deploy(MockToken, "ShieldEx USDT", "USDT");
        await mockToken.mint(accounts[0], "100000000000000000000000000000");
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    } else {
        const mockToken = await MockToken.at(usdtAddr);
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    }

    if (!usdcAddr) {
        console.log("Deploying USDC token...")
        const mockToken = await deployer.deploy(MockToken, "ShieldEx USDC", "USDC");
        await mockToken.mint(accounts[0], "100000000000000000000000000000");
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    } else {
        const mockToken = await MockToken.at(usdcAddr);
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    }

    if (!daiAddr) {
        console.log("Deploying DAI token...")
        const mockToken = await deployer.deploy(MockToken, "ShieldEx DAI", "DAI");
        await mockToken.mint(accounts[0], "100000000000000000000000000000");
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    } else {
        const mockToken = await MockToken.at(daiAddr);
        console.log(`${await mockToken.name()} contract has been deployed on ${mockToken.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployTokens(deployer, network, accounts))
        .catch(error => {
            console.log(error);
            process.exit(1);
        });
};
