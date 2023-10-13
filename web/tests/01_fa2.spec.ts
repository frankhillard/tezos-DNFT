import dotenv from "dotenv";
import "mocha";
import * as assert from "assert";
import { Utils } from "./helpers/utils";
import collection from "../deployments/collection";
import getConfig from "../config";
import { confirmOperation } from "../scripts/confirmation";
import BigNumber from "bignumber.js";

dotenv.config();

const { accounts } = getConfig(process.env.NETWORK);

// This test suite makes sure that the standard FA2 behaviour remains unchanged
// This test expects a NFT collection with two tokens owned by admin (tokenId 0 and 1)

describe("FA2", async () => {
  let utils: Utils;
  let collectionContractAddr: string;

  before("setup", async () => {
    utils = new Utils();

    await utils.init(accounts.admin.sk);

    collectionContractAddr = collection;
  });

  it("should transfer", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const tokenId = 0;
    const op = await instance.methodsObject
      .transfer([
        {
          from_: accounts.admin.pkh,
          txs: [
            {
              to_: accounts.user.pkh,
              token_id: tokenId,
              amount: 1,
            },
          ],
        },
      ])
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const balance = await storage.ledger.get([accounts.user.pkh, tokenId]);
    assert.equal(balance, 1);
  });

  it("should update operator", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const tokenId = 1;
    const op = await instance.methodsObject
      .update_operators([
        {
          add_operator: {
            owner: accounts.admin.pkh,
            operator: accounts.user.pkh,
            token_id: tokenId,
          },
        },
      ])
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const tokens = await storage.operators.get([
      accounts.admin.pkh,
      accounts.user.pkh,
    ]);
    assert.ok(tokens.map((bn: BigNumber) => Number(bn)).includes(tokenId));
  });

  it("should transfer as operator", async () => {
    utils.setProvider(accounts.user.sk);
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const tokenId = 1;
    const op = await instance.methodsObject
      .transfer([
        {
          from_: accounts.admin.pkh,
          txs: [
            {
              to_: accounts.user.pkh,
              token_id: tokenId,
              amount: 1,
            },
          ],
        },
      ])
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const admin_bal = await storage.ledger.get([accounts.admin.pkh, tokenId]);
    const user_bal = await storage.ledger.get([accounts.user.pkh, tokenId]);
    assert.equal(user_bal, 1);
    assert.equal(admin_bal, 0);
  });
});
