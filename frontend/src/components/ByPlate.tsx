import { useState } from 'react'
import { usePublicClient } from 'wagmi'
import { TARGET } from '../wagmi'
import { RESULTS } from '../lib/contracts'
import { short } from '../lib/hash'
import { describeError } from '../lib/errors'
import { findByPlate, type LogsClient, type Registered } from '../lib/logs'

/** Historial de revisiones de un vehículo, reconstruido desde los eventos (el contrato no indexa por patente). */
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
      <h2>Historial por patente</h2>
      <p className="hint">Reconstruido leyendo los eventos <code>InspectionRegistered</code> y filtrando por la referencia hash del vehículo. Puede tardar si hay muchos registros.</p>
      <form className="row" onSubmit={search}>
        <input value={plate} onChange={(e) => setPlate(e.target.value)} placeholder="Patente (ej. AB123CD)" />
        <button disabled={!plate.trim() || loading}>{loading ? 'Buscando…' : 'Buscar'}</button>
      </form>
      {err && <p className="errmsg">{err}</p>}
      {rows && rows.length === 0 && <p className="info">No hay revisiones registradas para esa patente.</p>}
      {rows?.map((r) => {
        const res = RESULTS[r.result]
        return (
          <div key={r.inspectionId} className="item">
            <span className={`badge ${res.cls}`}>{res.label}</span>
            <span className="small">{new Date(Number(r.timestamp) * 1000).toLocaleString('es-AR')} · DT <code>{short(r.technicalDirector)}</code></span>
            <button className="ghost" onClick={() => onOpen(r.inspectionId)}>Ver y verificar</button>
          </div>
        )
      })}
    </section>
  )
}
