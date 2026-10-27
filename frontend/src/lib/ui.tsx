import { TARGET } from '../wagmi'
import { describeError } from './errors'

export const txUrl = (hash: string) =>
  TARGET.blockExplorers ? `${TARGET.blockExplorers.default.url}/tx/${hash}` : undefined

/** Transaction status: awaiting signature, confirming, confirmed or failed. */
export function TxStatus(p: { hash?: string; pending: boolean; confirming: boolean; success: boolean; error: unknown }) {
  const url = p.hash ? txUrl(p.hash) : undefined
  return (
    <div className="status">
      {p.pending && <p className="info">Waiting for your signature in the wallet…</p>}
      {p.confirming && <p className="info">Transaction sent, waiting for confirmation…</p>}
      {p.success && <p className="okmsg">Transaction confirmed.</p>}
      {p.error ? <p className="errmsg">{describeError(p.error)}</p> : null}
      {p.hash && (
        <p className="small">
          Tx: {url ? <a href={url} target="_blank" rel="noreferrer">{p.hash}</a> : <code>{p.hash}</code>}
        </p>
      )}
    </div>
  )
}
