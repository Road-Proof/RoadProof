import { useState } from 'react'
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi'
import { QRCodeSVG } from 'qrcode.react'
import type { Hex } from 'viem'
import { TARGET } from '../wagmi'
import { AUTHORIZATION, REGISTRY, RESULTS, authorizationAbi, registryAbi } from '../lib/contracts'
import { fileToHash, plateToBytes32, short, toBytes32 } from '../lib/hash'
import { TxStatus } from '../lib/ui'

/** Technical Director screen: registers an inspection by signing with their wallet. */
export function Register({ wrongChain }: { wrongChain: boolean }) {
  const { address, isConnected } = useAccount()
  const [workshop, setWorkshop] = useState('')
  const [idText, setIdText] = useState('')
  const [plate, setPlate] = useState('')
  const [result, setResult] = useState<number>(0)
  const [reportHash, setReportHash] = useState<Hex>()
  const [fileName, setFileName] = useState('')

  const { data: authorized } = useReadContract({
    address: AUTHORIZATION, abi: authorizationAbi, functionName: 'isAuthorized',
    args: [toBytes32(workshop), address!], chainId: TARGET.id,
    query: { enabled: !!address && !!workshop.trim() },
  })
  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract()
  const { isLoading: confirming, isSuccess } = useWaitForTransactionReceipt({ hash, chainId: TARGET.id })

  const ready = isConnected && !wrongChain && workshop.trim() && idText.trim() && plate.trim() && reportHash

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    if (!reportHash) return
    try {
      await writeContractAsync({
        address: REGISTRY, abi: registryAbi, functionName: 'registerInspection', chainId: TARGET.id,
        args: [toBytes32(idText), reportHash, plateToBytes32(plate), toBytes32(workshop), result],
      })
    } catch { /* the error is shown from the hook */ }
  }

  const link = `${window.location.origin}${window.location.pathname}?id=${encodeURIComponent(idText.trim())}`

  return (
    <section className="card">
      <h2>Register an inspection</h2>
      <p className="hint">Only a wallet authorized for the given workshop can register. Authorization for one workshop does not apply to another.</p>
      {!isConnected && <p className="info">Connect your wallet to register.</p>}

      <form onSubmit={submit} className="col">
        <label>Workshop
          <input value={workshop} onChange={(e) => setWorkshop(e.target.value)} placeholder="Workshop ID (e.g. WORKSHOP-001)" />
        </label>
        {workshop.trim() && <p className="small">You will register for workshop <code>{short(toBytes32(workshop))}</code></p>}
        {isConnected && workshop.trim() && authorized === true && <p className="okmsg">✔ Your wallet is authorized for this workshop.</p>}
        {isConnected && workshop.trim() && authorized === false && <p className="errmsg">✘ Your wallet is NOT authorized for this workshop; the transaction will be rejected.</p>}

        <label>Inspection ID
          <span className="row">
            <input value={idText} onChange={(e) => setIdText(e.target.value)} placeholder="RTO-2026-000123" />
            <button type="button" className="ghost" onClick={() => setIdText(`RTO-${Date.now()}`)}>Generate</button>
          </span>
        </label>
        <label>Vehicle license plate
          <input value={plate} onChange={(e) => setPlate(e.target.value)} placeholder="AB123CD" />
        </label>
        <label>Result
          <select value={result} onChange={(e) => setResult(Number(e.target.value))}>
            {RESULTS.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
          </select>
        </label>
        <label>Inspection report (file)
          <input type="file" onChange={async (e) => {
            const f = e.target.files?.[0]
            setReportHash(f ? await fileToHash(f) : undefined); setFileName(f?.name ?? '')
          }} />
        </label>
        {reportHash && <p className="small">Hash of “{fileName}”: <code>{reportHash}</code></p>}

        <button disabled={!ready || isPending || confirming}>Sign and register</button>
      </form>

      <TxStatus hash={hash} pending={isPending} confirming={confirming} success={isSuccess} error={error} />

      {isSuccess && (
        <div className="qr">
          <QRCodeSVG value={link} size={168} />
          <div>
            <p>Inspection registered. This QR code leads to the verification screen:</p>
            <p className="small"><a href={link}>{link}</a></p>
            <button className="ghost" onClick={() => { reset(); setIdText(''); setReportHash(undefined); setFileName('') }}>Register another</button>
          </div>
        </div>
      )}
    </section>
  )
}
