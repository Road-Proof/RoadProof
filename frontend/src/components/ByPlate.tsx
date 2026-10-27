import { useState } from 'react'
import { usePublicClient } from 'wagmi'
import { TARGET } from '../wagmi'
import { RESULTS } from '../lib/contracts'
import { short } from '../lib/hash'
import { describeError } from '../lib/errors'
import { findByPlate, type LogsClient, type Registered } from '../lib/logs'

/** Inspection history of a vehicle, rebuilt from events (the contract does not index by plate). */
export function ByPlate({ onOpen }: { onOpen: (inspectionId: string) => void }) {
  const client = usePublicClient({ chainId: TARGET.id })
  const [plate, setPlate] = useState('')
  const [rows, setRows] = useState<Registered[] | null>(null)
  const [loading, setLoading] = useState(false)
  const [err, setErr] = useState('')

  async function search(e: React.FormEvent) {
    e.preventDefault()
    if (!client || !plate.trim()) return
    setLoading(true); setErr(''); setRows(null)
    try { setRows(await findByPlate(client as unknown as LogsClient, plate)) }
    catch (e) { setErr(describeError(e)) }
    finally { setLoading(false) }
  }

  return (
    <section className="card">
      <h2>History by license plate</h2>
      <p className="hint">Rebuilt by reading the <code>InspectionRegistered</code> events and filtering by the vehicle reference hash. It may take a while with many records.</p>
      <form className="row" onSubmit={search}>
        <input value={plate} onChange={(e) => setPlate(e.target.value)} placeholder="License plate (e.g. AB123CD)" />
        <button disabled={!plate.trim() || loading}>{loading ? 'Searching…' : 'Search'}</button>
      </form>
      {err && <p className="errmsg">{err}</p>}
      {rows && rows.length === 0 && <p className="info">No inspections are registered for that license plate.</p>}
      {rows?.map((r) => {
        const res = RESULTS[r.result]
        return (
          <div key={r.inspectionId} className="item">
            <span className={`badge ${res.cls}`}>{res.label}</span>
            <span className="small">{new Date(Number(r.timestamp) * 1000).toLocaleString('en-US')} · DT <code>{short(r.technicalDirector)}</code></span>
            <button className="ghost" onClick={() => onOpen(r.inspectionId)}>View and verify</button>
          </div>
        )
      })}
    </section>
  )
}
