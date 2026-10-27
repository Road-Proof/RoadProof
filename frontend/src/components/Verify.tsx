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

/** Pantalla pública (sin wallet): consulta un registro y verifica la integridad de un informe. */
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
      try { // la fecha vive en el evento, no en el struct
        const logs = await fetchRegistered(client as unknown as LogsClient, id)
        timestamp = logs[0]?.timestamp; tx = logs[0]?.tx
      } catch { /* sin fecha si el RPC no permite getLogs */ }
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
      <h2>Verificar una revisión</h2>
      <p className="hint">Es la pantalla a la que apunta el QR del certificado. No requiere wallet.</p>
      <form className="row" onSubmit={(e) => { e.preventDefault(); load(idText) }}>
        <input value={idText} onChange={(e) => setIdText(e.target.value)} placeholder="ID de revisión (ej. RTO-2026-000123)" />
        <button disabled={!idText.trim() || state === 'loading'}>{state === 'loading' ? 'Consultando…' : 'Consultar'}</button>
      </form>

      {state === 'notfound' && <p className="errmsg">No existe una revisión registrada con ese ID.</p>}
      {state === 'error' && <p className="errmsg">{msg}</p>}

      {rec && res && (
        <>
          <div className={`badge ${res.cls}`}>{res.label}</div>
          <dl>
            <dt>Director Técnico</dt><dd><code>{rec.director}</code></dd>
            <dt>Taller (ID hash)</dt><dd><code>{short(rec.workshopId)}</code></dd>
            <dt>Fecha de registro</dt>
            <dd>{rec.timestamp ? new Date(Number(rec.timestamp) * 1000).toLocaleString('es-AR') : 'No disponible'}</dd>
            <dt>Hash del informe (on-chain)</dt><dd><code>{rec.reportHash}</code></dd>
            {rec.tx && <><dt>Transacción</dt><dd>{tx ? <a href={tx} target="_blank" rel="noreferrer">{short(rec.tx)}</a> : <code>{short(rec.tx)}</code>}</dd></>}
          </dl>

          <h3>Comprobar integridad del informe</h3>
          <p className="hint">Subí el informe original. Se calcula su hash localmente (keccak256 de los bytes del archivo) y se compara con el registrado.</p>
          <input type="file" onChange={(e) => onFile(e.target.files?.[0])} />
          {intact === true && <p className="okmsg">✔ Íntegro: «{fileName}» coincide con el hash registrado.</p>}
          {intact === false && <p className="errmsg">✘ No coincide: «{fileName}» fue modificado o no es el informe original.</p>}
          {msg && state === 'idle' && <p className="errmsg">{msg}</p>}
          <p className="hint small">La coincidencia prueba que el archivo es el mismo que se selló; no prueba que la inspección original fuera veraz.</p>

          <h3>Comprobar vehículo (opcional)</h3>
          <input value={plate} onChange={(e) => setPlate(e.target.value)} placeholder="Patente (ej. AB123CD)" />
          {plate.trim() && (plateToBytes32(plate) === rec.vehicleRefHash
            ? <p className="okmsg">✔ La patente coincide con la referencia registrada.</p>
            : <p className="errmsg">✘ La patente no coincide con la registrada.</p>)}
        </>
      )}
    </section>
  )
}
