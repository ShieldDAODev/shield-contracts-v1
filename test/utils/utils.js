const BigNumber = require('bignumber.js');

module.exports = {
    formatOrder: function formatOrder(o) {
        return {
            holder: o.holder,
            contractType: o.contractType.toNumber(),
            state: o.state.toNumber(),
            exchangeType: o.exchangeType,
            number: BigNumber(o.number).toString(),
            tradingFee: BigNumber(o.tradingFee).toString(),
            liquidationFee: BigNumber(o.liquidationFee).toString(),
            firstMgFee: BigNumber(o.firstMgFee).toString(),
            lockFee: BigNumber(o.lockFee).toString(),
            newLockFee: BigNumber(o.newLockFee).toString(),
            openPrice: BigNumber(o.openPrice).toString(),
            startTime: new Date(BigNumber(o.startTime).toNumber()).getDate(),
            closePrice: BigNumber(o.closePrice).toString(),
        }
    },

    formatOrderForPrinting: function formatOrderForPrinting(o) {
        return {
            holder: o.holder,
            contractType: o.contractType == 1 ? "LONG" : "SHORT",
            state: o.state,
            exchangeType: o.exchangeType,
            number: BigNumber(o.number).dividedBy(1e18).toString(),
            tradingFee: BigNumber(o.tradingFee).dividedBy(1e18).toString(),
            liquidationFee: BigNumber(o.liquidationFee).dividedBy(1e18).toString(),
            firstMgFee: BigNumber(o.firstMgFee).dividedBy(1e18).toString(),
            lockFee: BigNumber(o.lockFee).dividedBy(1e18).toString(),
            newLockFee: BigNumber(o.newLockFee).dividedBy(1e18).toString(),
            openPrice: BigNumber(o.openPrice).dividedBy(1e18).toString(),
            startTime: new Date(BigNumber(o.startTime).toNumber()).getDate(),
            closePrice: BigNumber(o.closePrice).dividedBy(1e18).toString(),
        }
    },

    formatPrivateMakerOrder: function formatPrivateMakerOrder(o) {
        return {
            takerId: o.takerId,
            marginAmount: BigNumber(o.marginAmount).toString(),
            marginFee: BigNumber(o.marginFee).toString(),
            pubPriFlag: o.pubPriFlag,
            changePrice: BigNumber(o.changePrice).toString(),
            makerAddr: o.makerAddr,
            locked: o.locked,
        }
    },

    formatPrivateMakerOrderForPrinting: function formatPrivateMakerOrderForPrinting(o) {
        return {
            takerId: o.takerId,
            marginAmount: BigNumber(o.marginAmount).dividedBy(1e18).toString(),
            marginFee: BigNumber(o.marginFee).dividedBy(1e18).toString(),
            pubPriFlag: o.pubPriFlag == 2 ? "PRIVATE" : "PUBLIC",
            changePrice: BigNumber(o.changePrice).dividedBy(1e18).toString(),
            makerAddr: o.makerAddr,
            locked: o.locked,
        }
    },
    // formatTakerBalance: function formatTakerBalance(o) {
    //     return {
    //         takerId: o.takerId.toNumber(),
    //         marginAmount: BigNumber(o.marginAmount).dividedBy(1e18).toString(),
    //         marginFee: BigNumber(o.marginFee).dividedBy(1e18).toString(),
    //         pubPriFlag: o.pubPriFlag.toNumber() == 2 ? "PRIVATE" : "PUBLIC",
    //         changePrice: BigNumber(o.changePrice).dividedBy(1e18).toString(),
    //         makerAddr: o.makerAddr,
    //         locked: o.locked,
    //     }
    // }
}