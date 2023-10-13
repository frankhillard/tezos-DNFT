import dotenv from "dotenv";
import { TransactionOperation, TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";
import { BigNumber } from "bignumber.js";
import { confirmOperation } from "../../scripts/confirmation";
import getConfig from "../../config";

dotenv.config();

const { nodeUrl, confirmationPollingTimeoutSecond } = getConfig(
  process.env.NETWORK
);

export class Utils {
  tezos: TezosToolkit;

  async init(providerSK: string): Promise<TezosToolkit> {
    this.tezos = new TezosToolkit(nodeUrl);
    this.tezos.setProvider({
      config: {
        confirmationPollingTimeoutSecond,
      },
      signer: await InMemorySigner.fromSecretKey(providerSK),
    });

    return this.tezos;
  }

  static async createTezos(providerSK: string): Promise<TezosToolkit> {
    const tezos: TezosToolkit = new TezosToolkit(nodeUrl);

    tezos.setProvider({
      config: {
        confirmationPollingTimeoutSecond,
      },
      signer: await InMemorySigner.fromSecretKey(providerSK),
    });

    return tezos;
  }

  async setProvider(newProviderSK: string): Promise<void> {
    this.tezos.setProvider({
      signer: await InMemorySigner.fromSecretKey(newProviderSK),
    });
  }

  async bakeBlocks(count: number) {
    for (let i = 0; i < count; ++i) {
      const operation: TransactionOperation =
        await this.tezos.contract.transfer({
          to: await this.tezos.signer.publicKeyHash(),
          amount: 1,
        });

      await confirmOperation(this.tezos, operation.hash);
    }
  }

  async getLastBlockTimestamp(): Promise<number> {
    return Date.parse((await this.tezos.rpc.getBlockHeader()).timestamp);
  }

  async getLastBlock(): Promise<BigNumber> {
    return new BigNumber((await this.tezos.rpc.getBlock()).header.level);
  }

  static parseOnChainViewError(json: any[]): string {
    for (let i = 0; i < json.length; ++i) {
      for (const key in json[i]) {
        if (key === "with") {
          return json[i][key]["string"];
        }
      }
    }

    return "";
  }

  static parseLambdaViewError(err: any): string {
    const strErr = String(err);

    return strErr.slice(strErr.indexOf('"with"', 0) + 18, strErr.length - 4);
  }
}
