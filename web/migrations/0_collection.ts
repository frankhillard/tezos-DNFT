import dotenv from "dotenv";
import path from "path";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { char2Bytes } from "@taquito/utils";
import { getSigner, saveContractAddress } from "../scripts/helpers";
import { confirmOperation } from "../scripts/confirmation";
import getConfig from "../config";
import code from "../../compiled/collection.json";
import metadataJson from "./collection.json";
import metadataDevJson from "./collection.dev.json";
// import { NONAME } from "dns";

// Read environment variables from .env file
dotenv.config({ path: path.join(__dirname, "../..", ".env") });

const network = process.env.NETWORK;
const { nodeUrl, accounts } = getConfig(network);

// Initialize RPC connection
const Tezos = new TezosToolkit(nodeUrl);

// Deploy to configured node with configured secret key
const deploy = async () => {
  try {
    const signer = await getSigner(accounts.admin?.sk);
    const adminPkh = await signer.publicKeyHash();
    Tezos.setProvider({ signer });

    const metadataContentsJson =
      network === "mainnet" ? metadataJson : metadataDevJson;

    const storage = {
      ledger: new MichelsonMap(),
      token_metadata: new MichelsonMap(),
      operators: new MichelsonMap(),
      extension: {
        admin: adminPkh,
        requested_admin: undefined,
        use_whitelist: true,
        whitelist: new MichelsonMap(),
        next_token_id: 0,
        asset_infos: new MichelsonMap(),
      },
      metadata: MichelsonMap.fromLiteral({
        "": char2Bytes("tezos-storage:contents"),
        contents: char2Bytes(JSON.stringify(metadataContentsJson)),
      }),
    };

    const op = await Tezos.contract.originate({ code, storage });
    await confirmOperation(Tezos, op.hash);
    console.log(`[OK] ${op.contractAddress}`);
    saveContractAddress("collection", op.contractAddress);
  } catch (e) {
    if (e.statusText === "CONDITIONS_OF_USE_NOT_SATISFIED") {
      console.log("Aborted.");
    } else {
      console.log(e);
    }
  }
};

deploy();
