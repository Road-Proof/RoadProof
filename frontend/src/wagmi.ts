import { createConfig, http } from 'wagmi'
import { sepolia, foundry } from 'wagmi/chains'
import { injected, walletConnect } from 'wagmi/connectors'

/** Red a la que apunta la app (VITE_CHAIN=anvil para pruebas locales). */
export const TARGET = import.meta.env.VITE_CHAIN === 'anvil' ? foundry : sepolia

const wcProjectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID

export const config = createConfig({
  chains: [sepolia, foundry],
  // WalletConnect solo se habilita si hay projectId (gratis en https://cloud.reown.com)
  connectors: [injected(), ...(wcProjectId ? [walletConnect({ projectId: wcProjectId })] : [])],
  transports: {
    [sepolia.id]: http(import.meta.env.VITE_SEPOLIA_RPC_URL || undefined),
    [foundry.id]: http(),
  },
})
