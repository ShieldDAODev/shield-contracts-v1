const config = require("./config.json");
const Token = artifacts.require("MockToken");
const SLDBroker = artifacts.require("SLDBroker");
const PublicPool = artifacts.require("SLDPublicPool");
const PrivatePool = artifacts.require("SLDPrivatePool");
const Reward = artifacts.require("SLDRewards");
const Options = artifacts.require("SLDOption");
const SLDLiquidator = artifacts.require("SLDLiquidator");

const setConfigs = async (deployer, network, accounts) => {
    if (network == "test") return;

    let broker = await SLDBroker.at(config.BrokerAddr);
    let DAIToken = await Token.at(config.DAIAddr);
    let USDTToken = await Token.at(config.USDTAddr);
    let USDCToken = await Token.at(config.USDCAddr);
    let DAIPublicPool = await PublicPool.at(config.DAIPublicPoolAddr);
    let USDTPublicPool = await PublicPool.at(config.USDTPublicPoolAddr);
    let USDCPublicPool = await PublicPool.at(config.USDCPublicPoolAddr);
    let DAIPrivatePool = await PrivatePool.at(config.DAIPrivatePoolAddr);
    let USDTPrivatePool = await PrivatePool.at(config.USDTPrivatePoolAddr);
    let USDCPrivatePool = await PrivatePool.at(config.USDCPrivatePoolAddr);
    let reward = await Reward.at(config.RewardAddr);;
    let DAIOption = await Options.at(config.DAIOptionAddr);
    let USDTOption = await Options.at(config.USDTOptionAddr);
    let USDCOption = await Options.at(config.USDCOptionAddr);
    let liquidator = await SLDLiquidator.at(config.LiquidatorAddr);

    console.log("Approve tokens...");
    await DAIToken.approve(config.DAIOptionAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await DAIToken.approve(config.RewardAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await DAIToken.approve(config.LiquidatorAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await USDTToken.approve(config.DAIOptionAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await USDTToken.approve(config.RewardAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await USDTToken.approve(config.LiquidatorAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await USDCToken.approve(config.DAIOptionAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await USDCToken.approve(config.RewardAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });
    await USDCToken.approve(config.LiquidatorAddr, "9999999999999999999999999999", {
        from: config.RiskFundAddr
    });

    console.log("Set Fiat tokens contract for public pools...");
    await DAIPublicPool.setPoolTokenAddr(config.DAIAddr, {
        from: accounts[0]
    });
    await USDTPublicPool.setPoolTokenAddr(config.USDTAddr, {
        from: accounts[0]
    });
    await USDCPublicPool.setPoolTokenAddr(config.USDCAddr, {
        from: accounts[0]
    });

    console.log("Set Fiat tokens contract for Broker...");
    await broker.setStableContractAddress(config.DAIAddr, config.USDTAddr, config.USDCAddr, {
        from: accounts[0]
    });

    console.log("Set Keeper for Rewards...");
    await reward.setKeeper(DAIPrivatePool.address, true, {
        from: accounts[0]
    });
    await reward.setKeeper(USDTPrivatePool.address, true, {
        from: accounts[0]
    });
    await reward.setKeeper(USDCPrivatePool.address, true, {
        from: accounts[0]
    });
    await reward.setKeeper(liquidator.address, true, {
        from: accounts[0]
    });

    console.log("Set Keeper for Broker...");
    await broker.setKeeper(DAIOption.address, true, {
        from: accounts[0]
    });
    await broker.setKeeper(USDTOption.address, true, {
        from: accounts[0]
    });
    await broker.setKeeper(USDCOption.address, true, {
        from: accounts[0]
    });

    console.log("Set Keepers for DAI Public Pool...");
    await DAIPublicPool.setKeeper(DAIOption.address, {
        from: accounts[0]
    });
    await DAIPublicPool.setLP2Keeper(DAIPrivatePool.address, {
        from: accounts[0]
    });

    console.log("Set Keepers for USDT Public Pool...");
    await USDTPublicPool.setKeeper(USDTOption.address, {
        from: accounts[0]
    });
    await USDTPublicPool.setLP2Keeper(USDTPrivatePool.address, {
        from: accounts[0]
    });

    console.log("Set Keepers for USDC Public Pool...");
    await USDCPublicPool.setKeeper(USDCOption.address, {
        from: accounts[0]
    });
    await USDCPublicPool.setLP2Keeper(USDCPrivatePool.address, {
        from: accounts[0]
    });

    console.log("Set Keeper for DAI Private Pool...");
    await DAIPrivatePool.setKeeper(DAIOption.address, {
        from: accounts[0]
    });

    console.log("Set Keeper for USDT Private Pool...");
    await USDTPrivatePool.setKeeper(USDTOption.address, {
        from: accounts[0]
    });

    console.log("Set Keeper for USDC Private Pool...");
    await USDCPrivatePool.setKeeper(USDCOption.address, {
        from: accounts[0]
    });

    console.log("Set configs for Liquidator...");
    await liquidator.setSLDReward(reward.address, {
        from: accounts[0]
    });
    await liquidator.setRiskFundAddr(config.RiskFundAddr, {
        from: accounts[0]
    });

    console.log("Set Keeper for Liquidator...");
    await liquidator.setKeeper(DAIOption.address, true, {
        from: accounts[0]
    });
    await liquidator.setKeeper(USDTOption.address, true, {
        from: accounts[0]
    });
    await liquidator.setKeeper(USDCOption.address, true, {
        from: accounts[0]
    });

    console.log("Set Underlying Assets for Options...");
    await DAIOption.addOrUpdateUnderlyingAsset("ETHDAI", config.ETHUnderlyingAsset, {
        from: accounts[0]
    });
    await USDTOption.addOrUpdateUnderlyingAsset("ETHUSDT", config.ETHUnderlyingAsset, {
        from: accounts[0]
    });
    await USDCOption.addOrUpdateUnderlyingAsset("ETHUSDC", config.ETHUnderlyingAsset, {
        from: accounts[0]
    });
    await DAIOption.addOrUpdateUnderlyingAsset("BTCDAI", config.BTCUnderlyingAsset, {
        from: accounts[0]
    });
    await USDTOption.addOrUpdateUnderlyingAsset("BTCUSDT", config.BTCUnderlyingAsset, {
        from: accounts[0]
    });
    await USDCOption.addOrUpdateUnderlyingAsset("BTCUSDC", config.BTCUnderlyingAsset, {
        from: accounts[0]
    });

    console.log("Set Broker for Options...");
    await DAIOption.setBrokerAddr(config.BrokerAddr, {
        from: accounts[0]
    });
    await USDTOption.setBrokerAddr(config.BrokerAddr, {
        from: accounts[0]
    });
    await USDCOption.setBrokerAddr(config.BrokerAddr, {
        from: accounts[0]
    });

    console.log("Set Liquidator for Options...");
    await DAIOption.setLiquidatorAddr(config.LiquidatorAddr, {
        from: accounts[0]
    });
    await USDTOption.setLiquidatorAddr(config.LiquidatorAddr, {
        from: accounts[0]
    });
    await USDCOption.setLiquidatorAddr(config.LiquidatorAddr, {
        from: accounts[0]
    });

    console.log("Set Buyback pool for Options...");
    await DAIOption.setBuybackAddr(config.BuyBackAddr, {
        from: accounts[0]
    });
    await USDTOption.setBuybackAddr(config.BuyBackAddr, {
        from: accounts[0]
    });
    await USDCOption.setBuybackAddr(config.BuyBackAddr, {
        from: accounts[0]
    });

    console.log("Set reTokens for reward pool...");
    await reward.setReTokens(config.DAIPublicPoolAddr, 1, {
        from: accounts[0]
    });
    await reward.setReTokens(config.USDTPublicPoolAddr, 2, {
        from: accounts[0]
    });
    await reward.setReTokens(config.USDCPublicPoolAddr, 3, {
        from: accounts[0]
    });

    console.log("========================= Deployment Summary =========================");
    console.log(config);
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => setConfigs(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
