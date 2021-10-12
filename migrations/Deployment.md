# Instructions on Deployment

This documentation is used to help developers to deploy Shield v1 Protocol contract on EVM-compatible blockchains.

Following the instructions below, you will get all the development environment prepared and get all the smart contracts deployed. If you encounter some troubles or have some questions to ask, please be free to open an issue on our GitHub repo.

## 0x00 Install Node.js

You could find further instuctions [here](https://nodejs.org/en/):
```
https://nodejs.org/en/
```

## 0x01 Install Dependencies

Just type the following command, if you get your `node` and `npm` ready:

```
npm install
```

## 0x02 Filling out Configs

### truffle config

copy `truffle-config.template.js` into `truffle-config.js`, then fill out `truffle-config.js` with your own configs.

### migration config

copy `migrations/config.template.json` into `migrations/config.json`, then fill out `migrations/config.json` with your own configs.

Please Note:

If you have already deployed `SLD Token`, `USDT Token`, `USDC Token` and `DAI Token`, you just need fill out the `migrations/config.json` with the exsisting contract address of these token.

If not, you need to execute the `scripts/createMockTokens.js` first, then fill out the the `migrations/config.json` with the execution output printed on your screen.

Further intructions on how to execute the `scripts/createMockTokens.js`, you could find the answers on looking through the scirpt itself :-)

## 0x03 Deploy Smart Contract

You could get all the contract deployed by using:

```
truffle migrate --network <REPLACE_WITH_YOUR_NETWORK_NAME_IN_TRUFFLE_CONFIG> --reset
```

## 0x04 Running Tests

```
truffle test --network <REPLACE_WITH_YOUR_NETWORK_NAME_IN_TRUFFLE_CONFIG>
```