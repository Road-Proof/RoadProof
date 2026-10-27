import { useEffect, useState } from 'react'
import { isAddress, type Address } from 'viem'
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi'
import { TARGET } from '../wagmi'
import { AUTHORIZATION, authorizationAbi } from '../lib/contracts'
import { short, toBytes32 } from '../lib/hash'
import { TxStatus } from '../lib/ui'

/** Pantalla del administrador (owner de RoadProofAuthorization): autoriza y revoca Directores Técnicos por taller. */
export function Admin({ wrongChain }: { wrongChain: boolean }) {
  const { address, isConnected } = useAccount()
  const [workshop, setWorkshop] = useState('')
  const [director, setDirector] = useState('')

  const { data: owner } = useReadContract({ address: AUTHORIZATION, abi: authorizationAbi, functionName: 'owner', chainId: TARGET.id })
  const isOwner = !!address && !!owner && owner.toLowerCase() === address.toLowerCase()
  const valid = !!workshop.trim() && isAddress(director)

  const { data: current, refetch } = useReadContract({
    address: AUTHORIZATION, abi: authorizationAbi, functionName: 'authorizedDirectorsByWorkshop',
    args: [toBytes32(workshop), director as Address], chainId: TARGET.id, query: { enabled: valid },
  })
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract()
  const { isLoading: confirming, isSuccess } = useWaitForTransactionReceipt({ hash, chainId: TARGET.id })
  useEffect(() => { if (isSuccess) refetch() }, [isSuccess]) // eslint-disable-line react-hooks/exhaustive-deps

  async function run(fn: 'authorizeTechnicalDirector' | 'revokeTechnicalDirector') {
    const base = { address: AUTHORIZATION, abi: authorizationAbi, chainId: TARGET.id, args: [toBytes32(workshop), director as Address] } as const
    try { await writeContractAsync({ ...base, functionName: fn }) } catch { /* se muestra desde el hook */ }
  }

  const canSend = isConnected && !wrongChain && isOwner && valid && !isPending && !confirming

  return (
    <section className="card">
      <h2>Administración de Directores Técnicos</h2>
      <p className="hint">Administrador del contrato: <code>{owner ?? '…'}</code></p>
      {isConnected && owner && !isOwner && <p className="errmsg">Tu wallet no es la administradora; solo podés consultar el estado.</p>}
      {!isConnected && <p className="info">Conectá la wallet administradora para operar.</p>}

      <div className="col">
        <label>Taller
          <input value={workshop} onChange={(e) => setWorkshop(e.target.value)} placeholder="ID de taller (ej. WORKSHOP-001)" />
        </label>
        {workshop.trim() && <p className="small">ID de taller on-chain: <code>{short(toBytes32(workshop))}</code></p>}
        <label>Wallet del Director Técnico
          <input value={director} onChange={(e) => setDirector(e.target.value)} placeholder="0x…" />
        </label>
        {director && !isAddress(director) && <p className="errmsg">Dirección inválida.</p>}
        {valid && current !== undefined && (
          <p className={current ? 'okmsg' : 'info'}>Estado actual: {current ? 'AUTORIZADO' : 'no autorizado'} para este taller.</p>
        )}
        <div className="row">
          <button disabled={!canSend} onClick={() => run('authorizeTechnicalDirector')}>Autorizar</button>
          <button disabled={!canSend} className="danger" onClick={() => run('revokeTechnicalDirector')}>Revocar</button>
        </div>
      </div>
      <TxStatus hash={hash} pending={isPending} confirming={confirming} success={isSuccess} error={error} />
    </section>
  )
}
