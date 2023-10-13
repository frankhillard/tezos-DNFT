import dotenv from "dotenv";
import path from "path";

import {
    OperationContentsAndResultOrigination,
    OperationContentsAndResult,
    OperationContents,
    OperationEntry,
    BlockResponse,
} from "@taquito/rpc";
import { TezosToolkit, OpKind } from "@taquito/taquito";
import getConfig from "../config";

dotenv.config({ path: path.join(__dirname, "../..", ".env") });

const { syncInterval, confirmTimeout } = getConfig(process.env.NETWORK);

export type ConfirmOperationOptions = {
    initializedAt?: number;
    fromBlockLevel?: number;
    signal?: AbortSignal;
};

export async function confirmOperation(
    tezos: TezosToolkit,
    opHash: string,
    { initializedAt, fromBlockLevel, signal }: ConfirmOperationOptions = {}
): Promise<OperationEntry> {
    if (!initializedAt) {
        initializedAt = Date.now();
    }

    if (initializedAt && initializedAt + confirmTimeout < Date.now()) {
        throw new Error("Confirmation polling timed out");
    }

    const startedAt: number = Date.now();
    let currentBlockLevel: number;

    try {
        const currentBlock = await tezos.rpc.getBlock();

        currentBlockLevel = currentBlock.header.level;

        for (
            let i: number = fromBlockLevel ?? currentBlockLevel;
            i <= currentBlockLevel;
            i++
        ) {
            const block =
                i === currentBlockLevel
                    ? currentBlock
                    : await tezos.rpc.getBlock({ block: i.toString() });
            const opEntry = await findOperation(block, opHash);

            if (opEntry) {
                return opEntry;
            }
        }
    } catch (err) {
        if (process.env.NODE_ENV === "development") {
            console.error(err);
        }
    }

    if (signal?.aborted) {
        throw new Error("Cancelled");
    }

    const timeToWait: number = Math.max(
        startedAt + syncInterval - Date.now(),
        0
    );

    await new Promise((r) => setTimeout(r, timeToWait));

    return confirmOperation(tezos, opHash, {
        initializedAt,
        fromBlockLevel: currentBlockLevel
            ? currentBlockLevel + 1
            : fromBlockLevel,
        signal,
    });
}

export async function findOperation(
    block: BlockResponse,
    opHash: string
): Promise<OperationEntry> {
    for (let i = 3; i >= 0; i--) {
        for (const op of block.operations[i]) {
            if (op.hash === opHash) {
                return op;
            }
        }
    }

    return null;
}

export function getOriginatedContractAddress(opEntry: OperationEntry): string {
    const results: (OperationContents | OperationContentsAndResult)[] =
        Array.isArray(opEntry.contents) ? opEntry.contents : [opEntry.contents];
    const originationOp: OperationContentsAndResultOrigination = results.find(
        (op) => op.kind === OpKind.ORIGINATION
    ) as OperationContentsAndResultOrigination | undefined;

    return (
        originationOp?.metadata?.operation_result?.originated_contracts?.[0] ??
        null
    );
}
