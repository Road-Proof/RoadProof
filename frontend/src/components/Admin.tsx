import { useEffect, useState } from 'react'
import { isAddress, type Address } from 'viem'
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi'
import { TARGET } from '../wagmi'
import { AUTHORIZATION, authorizationAbi } from '../lib/contracts'
import { short, toBytes32 } from '../lib/hash'
import { TxStatus } from '../lib/ui'

/** Administrator screen (owner of RoadProofAuthorization): authorizes and revokes Technical Directors per workshop. */
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
    try { await writeContractAsync({ ...base, functionName: fn }) } catch { /* shown from the hook */ }
  }

  const canSend = isConnected && !wrongChain && isOwner && valid && !isPending && !confirming

  return (
    <section className="card">
      <h2>Technical Director administration</h2>
      <p className="hint">Contract administrator: <code>{owner ?? '…'}</code></p>
      {isConnected && owner && !isOwner && <p className="errmsg">Your wallet is not the administrator; you can only check status.</p>}
      {!isConnected && <p className="info">Connect the administrator wallet to operate.</p>}

      <div className="col">
        <label>Workshop
          <input value={workshop} onChange={(e) => setWorkshop(e.target.value)} placeholder="Workshop ID (e.g. WORKSHOP-001)" />
        </label>
        {workshop.trim() && <p className="small">On-chain workshop ID: <code>{short(toBytes32(workshop))}</code></p>}
        <label>Technical Director wallet
          <input value={director} onChange={(e) => setDirector(e.target.value)} placeholder="0x…" />
        </label>
        {director && !isAddress(director) && <p className="errmsg">Invalid address.</p>}
        {valid && current !== undefined && (
          <p className={current ? 'okmsg' : 'info'}>Current status: {current ? 'AUTHORIZED' : 'not authorized'} for this workshop.</p>
        )}
        <div className="row">
          <button disabled={!canSend} onClick={() => run('authorizeTechnicalDirector')}>Authorize</button>
          <button disabled={!canSend} className="danger" onClick={() => run('revokeTechnicalDirector')}>Revoke</button>
        </div>
      </div>
      <TxStatus hash={hash} pending={isPending} confirming={confirming} success={isSuccess} error={error} />
    </section>
  )
}
