type AccountsConf = {
  [key: string]: Accounts;
};

export type Accounts = {
  [key: string]: Account;
};

export type Account = {
  pkh: string;
  sk?: string;
};

// These accounts are used by deploy scripts and integration tests

const accounts: AccountsConf = {
  sandbox: {
    admin: {
      pkh: "tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb",
      sk: "edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq",
    },
    user: {
      pkh: "tz1heWEsRWZz77PgAdZqBLXoUgXePe8TQixB",
      sk: "edsk3RfpoFRtkizoSxkTMyV9vCfkQGACWe6ve91d4hgdGz9jhQnbzu",
    },
  },
  testnet: {
    admin: {
      pkh: "tz1UxbPFjP22Hmc4tz2cxEXUx3cz17W4L7ow",
      sk: "edskRgwZgrAsBSN4tN3b6iy6opofPVxsRkn2obRkP156p6bkprxL98hZyxExv6LyBm82BkAYo97uWyZgy96rDjuVM5FehPQMz2",
    },
    user: {
      pkh: "tz1WXJFG5GNMQ7uTAfSUsgFHXSF33Jur99QC",
      sk: "edsk2gAAMBQ5eVRcgnmbb2vsFYSG4khtoNjbZ1Xx7bezC6Swn9rnYa",
    },
  },
  ghostnet: {
    admin: {
      pkh: "tz1UxbPFjP22Hmc4tz2cxEXUx3cz17W4L7ow",
      sk: "edskRgwZgrAsBSN4tN3b6iy6opofPVxsRkn2obRkP156p6bkprxL98hZyxExv6LyBm82BkAYo97uWyZgy96rDjuVM5FehPQMz2",
    },
    user: {
      pkh: "tz1WXJFG5GNMQ7uTAfSUsgFHXSF33Jur99QC",
      sk: "edsk2gAAMBQ5eVRcgnmbb2vsFYSG4khtoNjbZ1Xx7bezC6Swn9rnYa",
    },
  },
  mainnet: {
    admin: {
      pkh: "tz1VA3gHrGZpSCcSzZ7M2tbdvku6Uo3et1EY",
    },
  },
};

export default (network: string): Accounts => accounts[network];
