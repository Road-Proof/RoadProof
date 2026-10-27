import { getAbiItem, type Address, type Hex } from 'viem'
import { DEPLOY_BLOCK, REGISTRY, registryAbi } from './contracts'
import { plateToBytes32 } from './hash'

const event = getAbiItem({ abi: registryAbi, name: 'InspectionRegistered' })

export type Registered = {
  inspectionId: Hex; workshopId: Hex; vehicleRefHash: Hex; technicalDirector: Address
  result: number; reportHash: Hex; timestamp: bigint; tx: Hex; block: bigint
}

/** Subset of the public client that we use (makes testing easier). */
export type LogsClient = {
  getBlockNumber(): Promise<bigint>
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  getLogs(args: any): Promise<any[]>
}

/**
 * Reads the InspectionRegistered events (optionally for a single inspectionId, which is indexed).
 * If the RPC rejects the full range, it retries in chunks over the last `chunk * maxChunks` blocks.
 */
export async function fetchRegistered(
  client: LogsClient, inspectionId?: Hex, opts = { chunk: 5000n, maxChunks: 100 },
): Promise<Registered[]> {
  const base = { address: REGISTRY, event, ...(inspectionId ? { args: { inspectionId } } : {}) }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let raw: any[]
  try {
    raw = await client.getLogs({ ...base, fromBlock: DEPLOY_BLOCK, toBlock: 'latest' })
  } catch {
    const latest = await client.getBlockNumber()
    const span = opts.chunk * BigInt(opts.maxChunks)
    let from = latest - span > DEPLOY_BLOCK ? latest - span : DEPLOY_BLOCK
    raw = []
    while (from <= latest) {
      const to = from + opts.chunk - 1n > latest ? latest : from + opts.chunk - 1n
      raw.push(...(await client.getLogs({ ...base, fromBlock: from, toBlock: to })))
      from = to + 1n
    }
  }
  return raw.map((l) => ({ ...l.args, tx: l.transactionHash, block: l.blockNumber }) as Registered)
}

/**
 * Inspections of a vehicle. The contract does not index `vehicleRefHash` in the event,
 * so the events are read and filtered on the client. Newest first.
 */
export async function findByPlate(client: LogsClient, plate: string): Promise<Registered[]> {
  const ref = plateToBytes32(plate)
  const all = await fetchRegistered(client)
  return all.filter((r) => r.vehicleRefHash === ref).sort((a, b) => (a.timestamp < b.timestamp ? 1 : -1))
}
