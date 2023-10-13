import getAccounts, { Accounts } from "./accounts";

type Config = {
  [key: string]: NetworkConfig;
};

export type NetworkConfig = {
  nodeUrl: string;
  accounts: Accounts;
  confirmationPollingTimeoutSecond: number;
  syncInterval: number;
  confirmTimeout: number;
  assetsDir: string;
};

const common = {
  assetsDir: "./assets",
};

const config: Config = {
  testnet: {
    nodeUrl: "https://rpc.tzkt.io/mumbainet",
    accounts: getAccounts("testnet"),
    confirmationPollingTimeoutSecond: 500000,
    syncInterval: 5000,
    confirmTimeout: 180000,
    ...common,
  },
  ghostnet: {
    // nodeUrl: "https://rpc.ghostnet.teztnets.xyz",   //  unreliable on the week of 1st August 2022
    nodeUrl: "https://rpc.tzkt.io/ghostnet",
    accounts: getAccounts("ghostnet"),
    confirmationPollingTimeoutSecond: 500000,
    syncInterval: 5000,
    confirmTimeout: 180000,
    ...common,
  },
  sandbox: {
    nodeUrl: "http://localhost:20000",
    accounts: getAccounts("sandbox"),
    confirmationPollingTimeoutSecond: 500000,
    syncInterval: 0,
    confirmTimeout: 90000,
    ...common,
  },
  mainnet: {
    nodeUrl: "https://mainnet.tezos.marigold.dev/",
    accounts: getAccounts("mainnet"),
    confirmationPollingTimeoutSecond: 1000000,
    syncInterval: 5000,
    confirmTimeout: 360000,
    ...common,
  },
};

export default (env: string): NetworkConfig => config[env];
