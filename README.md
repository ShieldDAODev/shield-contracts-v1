# Shield Contracts v1

Shield is building a one-of-a-kind decentralized protocol based on a fully non-cooperative game for future derivatives infrastructure, enabling global borderless access to finance.
Perpetual options is our first academic-level innovative product based on Shield derivatives protocol. We will continue to build Standard Perpetual Contracts and Structured products based on the Shield protocol, and open-source the protocol to developers worldwide.
We hold a belief that decentralized derivatives protocol built based on blockchain technology and non-cooperative game, will become the infrastructure for the next generation of global derivatives trading markets. It is in line with the following revolutionary DeFi features:

-  Non-custodial: Always control of your funds, rather than third party custody;

-  Transparent: Traceable and genuine transactions enforced by the blockchain;

-  0 intermediary tax: Non-profit trading protocol to eliminate centralized intermediary tax;

-  Trustless: Trust is no longer limited by branding, but by open-source verifiability code; Code is the law;

-  Easily accessible: No registration and KYC is required; thus no more administrative controls that prevent access to the market.

# Building

This documentation is used to help developers to deploy Shield v1 Protocol contract on EVM-compatible blockchains.

Following the instructions below, you will get all the development environment prepared and get all the smart contracts deployed. If you encounter some troubles or have some questions to ask, please be free to open an issue on our GitHub repo.

## Install Node.js

You could find further instuctions [here](https://nodejs.org/en/):
```
https://nodejs.org/en/
```

## Install Dependencies

Just type the following command, if you get your `node` and `npm` ready:

```
npm install
```

## Filling out Configs

### truffle config

copy `truffle-config.template.js` into `truffle-config.js`, then fill out `truffle-config.js` with your own configs.

### migration config

copy `migrations/config.template.json` into `migrations/config.json`, then fill out `migrations/config.json` with your own configs.

Please Note:

If you have already deployed `SLD Token`, `USDT Token`, `USDC Token` and `DAI Token`, you just need fill out the `migrations/config.json` with the exsisting contract address of these token.

If not, you need to execute the `scripts/createMockTokens.js` first, then fill out the the `migrations/config.json` with the execution output printed on your screen.

Further intructions on how to execute the `scripts/createMockTokens.js`, you could find the answers on looking through the scirpt itself :-)

## Deploy Smart Contract

You could get all the contract deployed by using:

```
truffle migrate --network <REPLACE_WITH_YOUR_NETWORK_NAME_IN_TRUFFLE_CONFIG> --reset
```

## Running Tests

```
truffle test --network <REPLACE_WITH_YOUR_NETWORK_NAME_IN_TRUFFLE_CONFIG>
```