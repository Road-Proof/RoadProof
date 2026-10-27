import { useState } from 'react'
import { useAccount, useConnect, useDisconnect, useSwitchChain } from 'wagmi'
import { TARGET } from './wagmi'
import { AUTHORIZATION, CONFIGURED, REGISTRY } from './lib/contracts'
import { short } from './lib/hash'
import { Verify } from './components/Verify'
import { Register } from './components/Register'
import { Admin } from './components/Admin'
import { ByPlate } from './components/ByPlate'

const tabs = [
  { key: 'verify', label: 'Verify' },
  { key: 'plate', label: 'By plate' },
  { key: 'register', label: 'Register inspection' },
  { key: 'admin', label: 'Admin' },
] as const

export default function App() {
  const initialId = new URLSearchParams(window.location.search).get('id') ?? ''
  const [verifyId, setVerifyId] = useState(initialId)
  const [tab, setTab] = useState<(typeof tabs)[number]['key']>('verify')
  const { address, isConnected, chainId } = useAccount()
  const { connect, connectors, isPending } = useConnect()
  const { disconnect } = useDisconnect()
  const { switchChain } = useSwitchChain()
  const wrongChain = isConnected && chainId !== TARGET.id

  return (
    <div className="app">
      <header>
        <div>
          <h1>RoadProof</h1>
          <p className="hint">RTO traceability on Ethereum · {TARGET.name}</p>
        </div>
        {isConnected ? (
          <div className="row">
            <code>{short(address!)}</code>
            <button className="ghost" onClick={() => disconnect()}>Disconnect</button>
          </div>
        ) : (
          <div className="row">
            {connectors.map((c) => (
              <button key={c.uid} disabled={isPending} onClick={() => connect({ connector: c })}>
                {c.name === 'Injected' ? 'Browser wallet' : c.name}
              </button>
            ))}
          </div>
        )}
      </header>

      {!CONFIGURED && (
        <p className="errmsg banner">Contract addresses are missing. Copy <code>.env.example</code> to <code>.env.local</code> and fill in <code>VITE_AUTHORIZATION_ADDRESS</code> and <code>VITE_REGISTRY_ADDRESS</code>.</p>
      )}
      {wrongChain && (
        <p className="errmsg banner">
          Your wallet is on a different network. <button onClick={() => switchChain({ chainId: TARGET.id })}>Switch to {TARGET.name}</button>
        </p>
      )}

      <nav>
        {tabs.map((t) => (
          <button key={t.key} className={tab === t.key ? 'active' : ''} onClick={() => setTab(t.key)}>{t.label}</button>
        ))}
      </nav>

      {CONFIGURED && (
        <main>
          {tab === 'verify' && <Verify key={verifyId} initialId={verifyId} />}
          {tab === 'plate' && <ByPlate onOpen={(id) => { setVerifyId(id); setTab('verify') }} />}
          {tab === 'register' && <Register wrongChain={wrongChain} />}
          {tab === 'admin' && <Admin wrongChain={wrongChain} />}
        </main>
      )}

      <footer className="small">
        Registry <code>{CONFIGURED ? short(REGISTRY) : '—'}</code> · Authorization <code>{CONFIGURED ? short(AUTHORIZATION) : '—'}</code>
      </footer>
    </div>
  )
}
