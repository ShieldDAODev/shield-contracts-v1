const fs = require("fs");
const path = require("path");

const SLDRewards = artifacts.require("SLDRewards");
const config = require("./config.json");

const deployRewardContract = async (deployer, network, accounts) => {
    if (network == "test") return;

    const rewardAddr = config.RewardAddr;

    if (!rewardAddr) {
        console.log("Deploying reward contract...");

        const rewards = await deployer.deploy(
            SLDRewards,
            config.SLDAddr,
            config.DAIPublicPoolAddr,
            config.USDTPublicPoolAddr,
            config.USDCPublicPoolAddr);

        console.log(`Rewards contract has been deployed on ${rewards.address}`);

        config.RewardAddr = rewards.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const rewards = await SLDRewards.at(config.RewardAddr);
        console.log(`Rewards contract has been deployed on ${rewards.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployRewardContract(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
