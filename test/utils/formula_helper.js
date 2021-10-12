const formularjs = require("@formulajs/formulajs");


module.exports = {
    getHistoryVolatility: function (prices) {
        const N = prices.length;

        const X = [];
        let X_SUM = 0;
        for (var i = 0; i < N; i++) {
            if (i > 0) {
                const d = (prices[i] - prices[i - 1]) / prices[i - 1];
                X_SUM += d;
                X.push(d);
            }
        }

        let X_AVG = X_SUM / N;
        let X_EXP = 0;

        for (var i = 0; i < X.length; i++) {
            X_EXP += ((X[i] - X_AVG) * (X[i] - X_AVG));
        }

        return Math.sqrt(X_EXP / (N - 1)) * Math.sqrt(365);
    },

    getPremium: function () {

    },
}

function callOpt(stock, exercise, maturity, rate, volatility) {
    let d1 = (Math.log(stock / exercise) + (rate + volatility * volatility / 2) * maturity) / (volatility * Math.sqrt(maturity));
    let d2 = d1 - volatility * Math.sqrt(maturity);

    return stock * NormS(d1) - exercise * Math.exp(-rate * maturity) * NormS(d2);
}

function NormS(n) {
    return formularjs.NORMSDIST(n, true);
}

const call = callOpt(3303.8589257700, 3303.8589257700, 1 / 365, 0.1, 1.119704248);
console.log(call)