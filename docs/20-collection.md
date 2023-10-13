# Collection v2

The `collection` contract is a `FA2` contract that has been made as an extension of [ligoExtendableFA2](https://github.com/smart-chain-fr/ligoExtendableFA2),
which itself is reusing code from [contract-catalogue](https://github.com/ligolang/contract-catalogue).
The contract is using the `multi_asset` variant of these contracts.

The contract entry points follows the FA2 standard with additional functionalities.

Each asset in the collection represents a fidelity card, and follows the `FA2`
standard of non-fungible tokens.

The NFT contract implements standard entry points (`Transfer`, `Balance_of`,
`Update_operators`), and extra entry points related to the fidelity card managment
(`Premint`, `ChangeCollectionMetadata`, `ChangeTokenMetadata`, `Authorize`, `Unauthorize`, `UseWhitelist`,`ChangeAdmin`, `ApproveAdmin`).

Each card of the collection has:

-   a specific token_id
-   a reputation

Each picture specifies the royalties to apply on secondary market.  
These royalties are written in the metadata and are specified during the creation
of the asset (`Premint` entrypoint).  

The royalties section of the JSON is expected to be formatted as specified in
the "How can I list my own FA2 contract on objkt.com?" from [OBJKT FAQ](https://objkt.com/faq) FAQ.

### The Premint entrypoint

Anyone can claim a new fidelity card by calling the `premint` entrypoint.

It creates a new asset in the collection with a reputation level at 0. 

This entrypoints allows anyone to create multiple card in a single invocation. 

The Premint entrypoint can define multiple asset in a single invocation and each asset must define the following fields:

| Field                         | Type                  | Description                                                               |
| ----------------------------- | --------------------- | ------------------------------------------------------------------------- |
| **_metas_**                   | `(string,bytes) map`  | Metadata associated to a token (IPFS link)                                |

### The Transfer entrypoint (FA2 standard)

The owner of a token can transfer one or more copies of the picture to someone else (with the _Transfer_ entrypoint), without any royalties/fees. Allocations are not applied during a transfer.

If a user tries to transfer more tokens than he possesses , it will fail.

This entrypoint is usefull for allowing marketplaces to sell/buy tokens on a secondary market.

### The Update_operators entrypoint (FA2 standard)

The owner of a token can delegate transfers to someone else. This delegated role is called operator and can transfer on behalf of the owner any number of editions of a pictures. This delegation is setup per pictures.

This entrypoint is usefull for allowing marketplaces to sell/buy tokens on a secondary market. The marketplace must be an operator of the sold token in order to be able to transfer it to someone else

### The Balance_of entrypoint (FA2 standard)

This entrypoint allows any contract to interact with the NFT contract to retrieve ownership of given token_id.

### ChangeCollectionMetadata entrypoint

This entrypoint allows the administrator to change the collection metadata.

### ChangeTokensMetadata entrypoint

This entrypoint allows the administrator to change asset metadata (which includes the `reputation` field).
This entrypoint can be applied to many asset in a single invocation. It expects a `reputation` field for each asset as arguments. 

### The UpdateTokens entrypoint

This entrypoint updates either a token metadata (and/or other field).

This entrypoint can also be applied to many asset in a single invocation.

### Marketplace interaction

The `FA2` must specify royalties that must be applied on other marketplaces.

An extra Marketplace smart contract has been provided to illustrate how to make
a secondary market on these Nft. The Marketplace contract allows Nft owners to
sell their pictures on a secondary market. The Marketplace contract allows users
to accept a sell proposal.

The Marketplace smart contract is not meant for production purpose.


## Data Structures

### asset_info

`asset_info` is a record that holds informations specific to a token.

| Field                      | Type                 | Description                                                                   |
| -------------------------- | -------------------- | ----------------------------------------------------------------------------- |
| **_reputation_**           | `nat`                | the reputation points   |


## Storage

Additionally to the [FA2 base storage](https://github.com/smart-chain-fr/ligoExtendableFA2/blob/main/lib/multi_asset/storage.mligo#L13),
the collection contract contains following fields in the `extension` of FA2:

| Field                         | Type                             | Description                                            |
| ----------------------------- | -------------------------------- | ------------------------------------------------------ |
| **_admin_**                   | `address`                        | the collection owner address                           |
| **_requested_admin_**         | `address option`                 | the newly proposed address as admin                    |
| **_use_whitelist_**           | `bool`                           | flag indicates if the whitelist is used in premint     |
| **_whitelist_**               | `(address, bool) big_map`        | map of authorized user                                 |
| **_asset_infos_**             | `(nat, asset_info) big_map`      | stores tokens non-standard informations                |
| **_next_token_id_**           | `nat`                            | stores next token id key for the big_map               |
| **_metadata_**                | `(string, bytes) big_map`        | [tzip-16](https://tzip.tezosagora.org/proposal/tzip-16/) metadata of the collection |


### Entry points

| Entrypoint                   | Parameters                                                                                      | Description                                                              | Permission       |
| ---------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ---------------- |
| **premint**                  | `(nat, nat, asset_info) list`           | create token with given asset info                                       | anyone |
| **changeCollectionMetadata** | `(string, bytes) big_map`               | change [tzip-16](https://tzip.tezosagora.org/proposal/tzip-16/) metadata | admin or creator |
| **changeTokensMetadata**     | `nat, (string, bytes) map`              | change a token metadata  (can be applied to many assets)        | admin or creator |
| **retrieveLockedXtz**        | `unit`                                  | transfer tez from the contract to the admin address                      | admin            |
| **updateTokens**             | `nat, (string, bytes) map option, tez option, ((address, nat) map * nat) option, bool options ` | update a token metadata and infos (can be applied to many assets)                                       | admin or creator |

| **changeAdmin**              | `address`         | set **_requested_admin_**       | admin           |
| **approveAdmin**             | `unit`            | set **_admin_** to **_requested admin_**, unset **_requested_admin_** | requested_admin |
| **authorize**                | `address list`    | add entries to **_whitelist_**                   | admin           |
| **unauthorize**              | `address list`    | remove entries from **_whitelist_**              | admin           |
| **useWhiteList**             | `bool`            | set **_use_whitelist_**                          | admin           |
