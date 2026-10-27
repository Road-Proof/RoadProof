import { describe, expect, it, vi } from 'vitest'
import { fetchRegistered, findByPlate, type LogsClient } from './logs'
import { plateToBytes32, toBytes32 } from './hash'

const log = (id: string, plate: string, timestamp: bigint) => ({
  args: {
    inspectionId: toBytes32(id), workshopId: toBytes32('W'), vehicleRefHash: plateToBytes32(plate),
    technicalDirector: '0x0000000000000000000000000000000000000001', result: 0,
    reportHash: toBytes32('r'), timestamp,
  },
  transactionHash: toBytes32(`tx-${id}`), blockNumber: 10n,
})

const client = (logs: ReturnType<typeof log>[]): LogsClient => ({
  getBlockNumber: async () => 100n,
  getLogs: vi.fn(async () => logs),
})

describe('findByPlate', () => {
  it('filtra por vehículo y ordena de más reciente a más antigua', async () => {
    const c = client([log('A', 'AB123CD', 100n), log('B', 'ZZ999ZZ', 150n), log('C', 'ab-123 cd', 300n)])
    const rows = await findByPlate(c, 'AB123CD')
    expect(rows.map((r) => r.inspectionId)).toEqual([toBytes32('C'), toBytes32('A')])
    expect(rows[0].tx).toBe(toBytes32('tx-C'))
  })
  it('devuelve vacío si no hay coincidencias', async () => {
    expect(await findByPlate(client([log('A', 'AB123CD', 1n)]), 'XX000XX')).toEqual([])
  })
})

describe('fetchRegistered', () => {
  it('reintenta por tramos si el RPC rechaza el rango completo', async () => {
    const getLogs = vi.fn()
      .mockRejectedValueOnce(new Error('range too large'))
      .mockResolvedValue([log('A', 'AB123CD', 1n)])
    const rows = await fetchRegistered({ getBlockNumber: async () => 25n, getLogs }, undefined, { chunk: 10n, maxChunks: 100 })
    // 1 intento completo + tramos [0-9], [10-19], [20-25]
    expect(getLogs).toHaveBeenCalledTimes(4)
    expect(rows).toHaveLength(3)
  })
  it('filtra por inspectionId cuando se pide un solo registro', async () => {
    const c = client([])
    await fetchRegistered(c, toBytes32('A'))
    expect(c.getLogs).toHaveBeenCalledWith(expect.objectContaining({ args: { inspectionId: toBytes32('A') } }))
  })
})
