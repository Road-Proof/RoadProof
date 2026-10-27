import { useEffect, useState } from 'react'
import { usePublicClient } from 'wagmi'
import type { Address, Hex } from 'viem'
import { TARGET } from '../wagmi'
import { REGISTRY, RESULTS, registryAbi } from '../lib/contracts'
import { fetchRegistered, type LogsClient } from '../lib/logs'
import { toBytes32, plateToBytes32, fileToHash, short } from '../lib/hash'
import { describeError } from '../lib/errors'
import { txUrl } from '../lib/ui'

type Rec = {
  id: Hex; reportHash: Hex; vehicleRefHash: Hex; workshopId: Hex; result: number
  director: Address; timestamp?: bigint; tx?: Hex
}

/** Public screen (no wallet): looks up a record and verifies the integrity of a report. */
export function Verify({ initialId }: { initialId: string }) {
  const client = usePublicClient({ chainId: TARGET.id })
  const [idText, setIdText] = useState(initialId)
  const [rec, setRec] = useState<Rec | null>(null)
  const [state, setState] = useState<'idle' | 'loading' | 'notfound' | 'error'>('idle')
  const [msg, setMsg] = useState('')
  const [intact, setIntact] = useState<boolean | null>(null)
  const [fileName, setFileName] = useState('')
  const [plate, setPlate] = useState('')

  async function load(text: string) {
    if (!client || !text.trim()) return
    setState('loading'); setRec(null); setIntact(null); setFileName(''); setMsg('')
    try {
      const id = toBytes32(text)
      const exists = await client.readContract({ address: REGISTRY, abi: registryAbi, functionName: 'inspectionExists', args: [id] })
      if (!exists) return setState('notfound')
      const [reportHash, vehicleRefHash, workshopId, result, director] = await client.readContract({
        address: REGISTRY, abi: registryAbi, functionName: 'inspections', args: [id],
      })
      let timestamp: bigint | undefined, tx: Hex | undefined
      try { // the date lives in the event, not in the struct
        const logs = await fetchRegistered(client as unknown as LogsClient, id)
        timestamp = logs[0]?.timestamp; tx = logs[0]?.tx
      } catch { /* no date if the RPC does not allow getLogs */ }
      setRec({ id, reportHash, vehicleRefHash, workshopId, result, director, timestamp, tx })
      setState('idle')
    } catch (e) { setState('error'); setMsg(describeError(e)) }
  }

  useEffect(() => { if (initialId) load(initialId) }, []) // eslint-disable-line react-hooks/exhaustive-deps

  async function onFile(f?: File) {
    if (!f || !client || !rec) return
    setFileName(f.name); setIntact(null); setMsg('')
    try {
      const computedHash = await fileToHash(f)
      setIntact(await client.readContract({
        address: REGISTRY, abi: registryAbi, functionName: 'verifyIntegrity', args: [rec.id, computedHash],
      }))
    } catch (e) { setMsg(describeError(e)) }
  }

  const res = rec ? RESULTS[rec.result] : undefined
  const tx = rec?.tx ? txUrl(rec.tx) : undefined

  return (
    <section className="card">
      <h2>Verify an inspection</h2>
      <p className="hint">This is the screen the certificate QR code points to. No wallet required.</p>
      <form className="row" onSubmit={(e) => { e.preventDefault(); load(idText) }}>
        <input value={idText} onChange={(e) => setIdText(e.target.value)} placeholder="Inspection ID (e.g. RTO-2026-000123)" />
        <button disabled={!idText.trim() || state === 'loading'}>{state === 'loading' ? 'Looking up…' : 'Look up'}</button>
      </form>

      {state === 'notfound' && <p className="errmsg">No inspection is registered with that ID.</p>}
      {state === 'error' && <p className="errmsg">{msg}</p>}

      {rec && res && (
        <>
          <div className={`badge ${res.cls}`}>{res.label}</div>
          <dl>
            <dt>Technical Director</dt><dd><code>{rec.director}</code></dd>
            <dt>Workshop (ID hash)</dt><dd><code>{short(rec.workshopId)}</code></dd>
            <dt>Registration date</dt>
            <dd>{rec.timestamp ? new Date(Number(rec.timestamp) * 1000).toLocaleString('en-US') : 'Not available'}</dd>
            <dt>Report hash (on-chain)</dt><dd><code>{rec.reportHash}</code></dd>
            {rec.tx && <><dt>Transaction</dt><dd>{tx ? <a href={tx} target="_blank" rel="noreferrer">{short(rec.tx)}</a> : <code>{short(rec.tx)}</code>}</dd></>}
          </dl>

          <h3>Check report integrity</h3>
          <p className="hint">Upload the original report. Its hash is computed locally (keccak256 of the file bytes) and compared with the registered one.</p>
          <input type="file" onChange={(e) => onFile(e.target.files?.[0])} />
          {intact === true && <p className="okmsg">✔ Intact: “{fileName}” matches the registered hash.</p>}
          {intact === false && <p className="errmsg">✘ Mismatch: “{fileName}” was modified or is not the original report.</p>}
          {msg && state === 'idle' && <p className="errmsg">{msg}</p>}
          <p className="hint small">A match proves the file is the same one that was sealed; it does not prove the original inspection was truthful.</p>

          <h3>Check vehicle (optional)</h3>
          <input value={plate} onChange={(e) => setPlate(e.target.value)} placeholder="License plate (e.g. AB123CD)" />
          {plate.trim() && (plateToBytes32(plate) === rec.vehicleRefHash
            ? <p className="okmsg">✔ The license plate matches the registered reference.</p>
            : <p className="errmsg">✘ The license plate does not match the registered one.</p>)}
        </>
      )}
    </section>
  )
}
