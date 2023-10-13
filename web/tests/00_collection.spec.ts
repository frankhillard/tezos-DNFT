import dotenv from "dotenv";
import "mocha";
import * as assert from "assert";
import { MichelsonMap } from "@taquito/michelson-encoder";
import { buf2hex, char2Bytes } from "@taquito/utils";
import { packDataBytes, Parser } from "@taquito/michel-codec";
import { Utils } from "./helpers/utils";
import collection from "../deployments/collection";
import getConfig from "../config";
import { confirmOperation } from "../scripts/confirmation";
// import code from "../../compiled/collection.json";

dotenv.config();

const { accounts } = getConfig(process.env.NETWORK);

describe("Collection", async () => {
  let utils: Utils;
  let collectionContractAddr: string;

  before("setup", async () => {
    utils = new Utils();

    await utils.init(accounts.admin.sk);

    collectionContractAddr = collection;
  });

  // it("should deploy a collection contract", async () => {
  //     const storage = {
  //         ledger: new MichelsonMap(),
  //         token_metadata: new MichelsonMap(),
  //         operators: new MichelsonMap(),
  //         extension: {
  //           admin: accounts.admin.pkh,
  //           requested_admin: undefined,
  //           use_whitelist: true,
  //           whitelist: new MichelsonMap(),
  //           next_token_id: 0,
  //           asset_infos: new MichelsonMap(),
  //         },
  //         metadata: MichelsonMap.fromLiteral({
  //             "": buf2hex(Buffer.from("tezos-storage:contents")),
  //             contents: buf2hex(
  //                 Buffer.from(
  //                     JSON.stringify({
  //                         name: "TEST",
  //                         description: "TESTING",
  //                         version: "1.0.0",
  //                         homepage: "https://testing.io",
  //                         interfaces: ["TZIP-012", "TZIP-016", "TZIP-021"],
  //                     })
  //                 )
  //             ),
  //         }),
  //       };
  //     const op = await utils.tezos.contract.originate({ code, storage });
  //     await confirmOperation(utils.tezos, op.hash);
  //     // console.log(`[OK] ${op.contractAddress}`);
  //     collectionContractAddr = op.contractAddress;
  //     console.log(`[OK] collection addr: ${collectionContractAddr}`);
  // });

  it("should authorize admin in whitelist", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const op = await instance.methodsObject
      .authorize([accounts.admin.pkh])
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const auth = await storage.extension.whitelist.get(accounts.admin.pkh);
    assert.equal(auth, true);
  });

  it("should premint (tokenId=0)", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const premintParam = 42; //{ reputation: 42 };
    const op = await instance.methodsObject.premint([premintParam]).send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const balance = await storage.ledger.get([accounts.admin.pkh, 0]);
    assert.equal(balance, 1);
  });

  it("should remove admin from whitelist", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const op = await instance.methodsObject
      .unauthorize([accounts.admin.pkh])
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const auth = await storage.extension.whitelist.get(accounts.admin.pkh);
    assert.equal(auth, undefined);
  });

  it("should disable whitelist", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const op = await instance.methodsObject.useWhiteList(false).send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const use_wl = await storage.extension.use_whitelist;
    assert.equal(use_wl, false);
  });

  it("should premint (tokenId=1)", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const premintParam = 42; //{ reputation: 42 };
    const op = await instance.methodsObject.premint([premintParam]).send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const balance = await storage.ledger.get([accounts.admin.pkh, 1]);
    assert.equal(balance, 1);
  });

  it("should premint (tokenId=2)", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const premintParam = 42; //{ reputation: 42 };
    const op = await instance.methodsObject.premint([premintParam]).send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const balance = await storage.ledger.get([accounts.admin.pkh, 2]);
    assert.equal(balance, 1);
  });

  // it("Should transfer XTZ locked on the contract to admin", async () => {
  //     const instance = await utils.tezos.contract.at(collectionContractAddr);
  //     const balance = await utils.tezos.tz.getBalance(collectionContractAddr);
  //     console.log(balance.toString());
  //     const op = await instance.methodsObject.retrieveLockedXtz().send();
  //     await confirmOperation(utils.tezos, op.hash);
  // });

  it("should change collection metadata", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const newContent = buf2hex(
      Buffer.from(
        JSON.stringify({
          name: "TEST UPDATED",
          description: "TESTING UPDATED",
          version: "1.0.1",
          homepage: "https://testing.io",
          interfaces: ["TZIP-012", "TZIP-016", "TZIP-021"],
        })
      )
    );
    const newMeta = MichelsonMap.fromLiteral({
      "": buf2hex(Buffer.from("tezos-storage:contents")),
      contents: newContent,
    });
    const op = await instance.methodsObject
      .changeCollectionMetadata(newMeta)
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    assert.strictEqual(await storage.metadata.get("contents"), newContent);
  });

  it("should change token metadata (tokenId=0)", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    // const newReputation = char2Bytes("10");
    // const newClass = char2Bytes("Bronze");
    // const newMeta = MichelsonMap.fromLiteral({
    //   reputation: newReputation,
    //   class: newClass,
    // });

    const newContent = buf2hex(
      Buffer.from(
        JSON.stringify({
          reputation: 10,
          class: "Bronze",
        })
      )
    );
    const newMeta = MichelsonMap.fromLiteral({
      "": char2Bytes("tezos-storage:contents"),
      contents: newContent,
    });

    const newTokenMeta = MichelsonMap.fromLiteral({
      0: newMeta,
    });
    const op = await instance.methodsObject
      .changeTokensMetadata(newTokenMeta)
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const tokenMeta = await storage.token_metadata.get(0);
    const tokenInfo = await tokenMeta["token_info"];
    // assert.strictEqual(tokenInfo.get("reputation"), newReputation);
    // assert.strictEqual(tokenInfo.get("class"), newClass);
    assert.strictEqual(tokenInfo.get("contents"), newContent);
    // assert.ok(await storage.token_metadata.get(1));
  });

  it("should update token (tokenId=1)", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const newMetaUri = char2Bytes("ipfs://new-ipfs-addr-2");
    const newMeta = MichelsonMap.fromLiteral({
      "": newMetaUri,
    });

    // const newCurrency = { xTZ: null };

    // const newTokensParam = MichelsonMap.fromLiteral({
    //   1: {
    //     new_metadata: newMeta,
    //   },
    // });
    const newTokensParam = MichelsonMap.fromLiteral({
      1: newMeta,
    });
    const op = await instance.methodsObject.updateTokens(newTokensParam).send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const tokenMeta = await storage.token_metadata.get(1);
    const tokenInfo = await tokenMeta["token_info"];
    assert.strictEqual(tokenInfo.get(""), newMetaUri);
    // const assetInfos = await storage.extension.asset_infos.get(1);
    // assert.equal(assetInfos["reputation"], 0);
    assert.ok(await storage.token_metadata.get(0));
  });

  it("should increase reputation by 15 (tokenId=2)", async () => {
    const instance = await utils.tezos.contract.at(collectionContractAddr);
    const reputationAmounts = MichelsonMap.fromLiteral({
      2: 15,
    });
    const op = await instance.methodsObject
      .increaseReputation(reputationAmounts)
      .send();
    await confirmOperation(utils.tezos, op.hash);
    const storage: Storage = await instance.storage();
    const tokenMeta = await storage.token_metadata.get(2);
    const tokenInfo = await tokenMeta["token_info"];

    // const data = {
    //   prim: "Pair",
    //   args: [{ nat: 15 }, { string: "extra_0" }],
    // };
    // const typ = {
    //   prim: "pair",
    //   args: [{ prim: "nat" }, { prim: "string" }],
    // };
    const data = `15`;
    const typ = `nat`;
    const p = new Parser();
    const dataJSON = p.parseMichelineExpression(data);
    const typeJSON = p.parseMichelineExpression(typ);
    const expected_reputation = packDataBytes(dataJSON, typeJSON).bytes;

    const reputation = tokenInfo.get("reputation");
    assert.strictEqual(reputation, expected_reputation);
    assert.ok(await storage.token_metadata.get(0));
    assert.ok(await storage.token_metadata.get(1));
  });
});
