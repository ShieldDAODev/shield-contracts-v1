/*
 * Mock BEP20 tokens used for testing.
 * 
 * Usage: truffle exec ./scripts/createMockTokens.js --network <network_name> --to <which address the tokens mint to>
 * 
 * Example: truffle exec ./scripts/createMockTokens.js --network bsctestnet --to 0xb8ad5499D2e073b03270184ce3CBa44596564596
 * 
 */
const argv = require('yargs')
    .option('to', {
        string: true
    }).argv;
const MockToken = artifacts.require("MockToken");

const TOKENS = [
    {
        "name": "ShieldEx Token",
        "symbol": "SLD",
        "supply": "1000000000000000000000000000",
    },
    {
        "name": "ShieldEx USDT",
        "symbol": "USDT",
        "supply": "100000000000000000000000000000",
    },
    {
        "name": "ShieldEx USDC",
        "symbol": "USDC",
        "supply": "100000000000000000000000000000",
    },
    {
        "name": "ShieldEx DAI",
        "symbol": "DAI",
        "supply": "100000000000000000000000000000",
    },
]

module.exports = async function (callback) {
    try {
        if (!argv.to) {
            console.error("Missing --to parameter!");
            callback(new Error("Missing --to parameter!"));
        }
        for (var i = 0; i < TOKENS.length; i++) {
            const mockToken = await MockToken.new(TOKENS[i].name, TOKENS[i].symbol);
            console.log(`${TOKENS[i].name} contract has been deployed on ${mockToken.address}`);

            await mockToken.mint(argv.to, TOKENS[i].supply);
            console.log(`${TOKENS[i].supply} ${TOKENS[i].symbol} has been minted to ${argv.to}`);
        }

        callback();
    } catch (e) {
        callback(e);
    }
}