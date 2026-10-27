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
  { key: 'verify', label: 'Verificar' },
  { key: 'plate', label: 'Por patente' },
  { key: 'register', label: 'Registrar revisión' },
  { key: 'admin', label: 'Administración' },
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
          <p className="hint">Trazabilidad de la RTO sobre Ethereum · {TARGET.name}</p>
        </div>
        {isConnected ? (
          <div className="row">
            <code>{short(address!)}</code>
            <button className="ghost" onClick={() => disconnect()}>Desconectar</button>
          </div>
        ) : (
          <div className="row">
            {connectors.map((c) => (
              <button key={c.uid} disabled={isPending} onClick={() => connect({ connector: c })}>
                {c.name === 'Injected' ? 'Wallet del navegador' : c.name}
              </button>
            ))}
          </div>
        )}
      </header>

      {!CONFIGURED && (
        <p className="errmsg banner">Faltan las direcciones de los contratos. Copiá <code>.env.example</code> a <code>.env.local</code> y completá <code>VITE_AUTHORIZATION_ADDRESS</code> y <code>VITE_REGISTRY_ADDRESS</code>.</p>
      )}
      {wrongChain && (
        <p className="errmsg banner">
          Tu wallet está en otra red. <button onClick={() => switchChain({ chainId: TARGET.id })}>Cambiar a {TARGET.name}</button>
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
