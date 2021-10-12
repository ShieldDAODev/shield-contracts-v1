const fs = require("fs");
const path = require("path");

const Formula = artifacts.require("Formula");
const config = require("./config.json");

const deployFormula = async (deployer, network, accounts) => {
    if (network == "test") return;

    const ETHUSDFormulaAddr = config.ETHUSDFormulaAddr;
    const BTCUSDFormulaAddr = config.BTCUSDFormulaAddr;

    if (!ETHUSDFormulaAddr) {
        const ethPriceTMs = [
            "1619827200",
            "1619913600",
            "1620000000",
            "1620086400",
            "1620172800",
            "1620259200",
            "1620345600",
            "1620432000",
            "1620518400",
            "1620604800",
            "1620691200",
            "1620777600",
            "1620864000",
            "1620950400",
            "1621036800",
            "1621123200",
            "1621209600",
            "1621296000",
            "1621382400",
            "1621468800",
            "1621555200",
            "1621641600",
            "1621728000",
            "1621814400",
            "1621900800",
            "1621987200",
            "1622073600",
            "1622160000",
            "1622246400",
            "1622332800",
            "1622419200"
        ];

        const ethPrices = [
            "2774740000000000000000",
            "2947660000000000000000",
            "2953500000000000000000",
            "3430416540340000000000",
            "3247650000000000000000",
            "3519880000000000000000",
            "3489954529590000000000",
            "3488436531710000000000",
            "3903490106100000000000",
            "3928482035620000000000",
            "4013090000000000000000",
            "4176600000000000000000",
            "4085448053770000000000",
            "3725481254280000000000",
            "4084203348240000000000",
            "3651465650740000000000",
            "3845052808750000000000",
            "3275699499040000000000",
            "3385480000000000000000",
            "2506836925640000000000",
            "2764790000000000000000",
            "2270445447640000000000",
            "2376051470310000000000",
            "2115556466970000000000",
            "2635211068340000000000",
            "2534846933100000000000",
            "2819860729890000000000",
            "2783311910290000000000",
            "2783311910290000000000",
            "2783311910290000000000",
            "2391680446680000000000"
        ];

        console.log("Deploying ETHUSD formula contract...");
        const formula = await deployer.deploy(Formula, "ETHUSD Formula", config.ETHUSDAggreagator, ethPriceTMs, ethPrices);
        console.log(`ETHUSD Formula has been deployed on ${formula.address}`);

        config.ETHUSDFormulaAddr = formula.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const formula = await Formula.at(ETHUSDFormulaAddr);
        console.log(`ETHUSD Formula has been deployed on ${formula.address}`);
    }

    if (!BTCUSDFormulaAddr) {
        const btcPriceTMs = [
            "1619827200",
            "1619913600",
            "1620000000",
            "1620086400",
            "1620172800",
            "1620259200",
            "1620345600",
            "1620432000",
            "1620518400",
            "1620604800",
            "1620691200",
            "1620777600",
            "1620864000",
            "1620950400",
            "1621036800",
            "1621123200",
            "1621209600",
            "1621296000",
            "1621382400",
            "1621468800",
            "1621555200",
            "1621641600",
            "1621728000",
            "1621814400",
            "1621900800",
            "1621987200",
            "1622073600",
            "1622160000",
            "1622246400",
            "1622332800",
            "1622419200"
        ];

        const btcPrices = [
            "57824004642760000000000",
            "57847507241770000000000",
            "56608014068280000000000",
            "57200000000000000000000",
            "53419545000000000000000",
            "57396940000000000000000",
            "56440499059920000000000",
            "57360505574990000000000",
            "58790360000000000000000",
            "58238789925750000000000",
            "55751595000000000000000",
            "56777858200790000000000",
            "54476970599160000000000",
            "49595125606830000000000",
            "49958748487510000000000",
            "46846701001660000000000",
            "46418972740700000000000",
            "43544763497310000000000",
            "42996067817040000000000",
            "38237815206770000000000",
            "39931661605000000000000",
            "35412417127280000000000",
            "38351110000000000000000",
            "34870140620410000000000",
            "38664861655630000000000",
            "38269170000000000000000",
            "39321175444440000000000",
            "38458035034200000000000",
            "38107172849610000000000",
            "38107172849610000000000",
            "36209000000000000000000"
        ];

        console.log("Deploying BTCUSD formula contract...");
        const formula = await deployer.deploy(Formula, "BTCUSD Formula", config.BTCUSDAggreagator, btcPriceTMs, btcPrices);
        console.log(`BTCUSD Formula has been deployed on ${formula.address}`);

        config.BTCUSDFormulaAddr = formula.address;

        fs.writeFileSync(path.resolve(__dirname, "./config.json"), JSON.stringify(config, null, 4));
    } else {
        const formula = await Formula.at(BTCUSDFormulaAddr);
        console.log(`BTCUSD Formula has been deployed on ${formula.address}`);
    }
}

module.exports = function (deployer, network, accounts) {
    deployer
        .then(() => deployFormula(deployer, network, accounts))
        .catch(error => {
            process.exit(1);
        });
};
