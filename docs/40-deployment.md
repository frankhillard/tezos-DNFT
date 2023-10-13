# Deployment

There is a [tezos sandbox](https://gitlab.com/tezos/flextesa) integrated in this
repository, if you wish to use it, run `make sandbox-start`.

Then, just run `make deploy` to deploy the contract on the sandbox.

If you wish to deploy on other networks, you need to edit the `.env` at the root
of this repository, it should have been generated when you ran `make install`.

When deploying smart contract , the metadata of NFT must be specified in bytes format.
The following command helps translating string to bytes.

```sh
./tezos-client hash data '"Hello world"' of type string
```

When deploying smart contract, the metadata of NFT are specified as `(string, bytes) map`. The image and royalties are specified in NFT metadata.

The royalties follows the data structure:

```json
{
    [...],
    "royalties": {
        "decimals": 3,
        "shares": {
             "tz1UxbPFjP22Hmc4tz2cxEXUx3cz17W4L7ow": 50,
             "tz1WXJFG5GNMQ7uTAfSUsgFHXSF33Jur99QC": 25
        }
    }
    [...]
}
```

### Mainnet

When deploying on mainnet, you want to use a ledger, to do so, you have to set
`USE_LEDGER` environment variable to `1`

You also have to set `NETWORK` to `mainnet`.

Then, just run `make deploy`. Make sure that `main` account is configured
with the right address. (see [accounts.ts](./accounts.ts))





