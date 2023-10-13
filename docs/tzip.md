# TZIP

## Contracts

- A factory contract implementing TZIP-016
- A [NFT asset contract (FA2)](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md#nft-asset-contract)
implementing TZIP-012, TZIP-016, TZIP-021

## Contract metadata (TZIP-012, TZIP-016)

As specified in [TZIP-016](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-16/tzip-16.md),
all of the contracts storages includes a `%metadata` field.

As specified in [TZIP-012](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md#token-metadata),
the NFT contract metadata also includes "symbol" and "decimals" fields.

## Token metadata (TZIP-012, TZIP-021)

As specified in [TZIP-012](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md#token-metadata),
the contract provides access to the token-metadata.

Tokens follows [TZIP-021](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-21/tzip-21.md)
standards and recommendations

```json
{
    "name": "LYZI - asset title",
    "symbol": "LYZI",
    "decimals": 0,
    "description": "LYZI NFT asset - catchphrase",
    "identifier": "http://source-asset.somewhere/this-is-true-trust-me",
    "isBooleanAmount": false
}
```
