import { createConfig, http } from 'wagmi'
import { sepolia, foundry } from 'wagmi/chains'
import { injected, walletConnect } from 'wagmi/connectors'

/** Network the app targets (VITE_CHAIN=anvil for local testing). */
export const TARGET = import.meta.env.VITE_CHAIN === 'anvil' ? foundry : sepolia

const wcProjectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID

export const config = createConfig({
  chains: [sepolia, foundry],
  // WalletConnect is only enabled when a projectId is set (free at https://cloud.reown.com)
  connectors: [injected(), ...(wcProjectId ? [walletConnect({ projectId: wcProjectId })] : [])],
  transports: {
    [sepolia.id]: http(import.meta.env.VITE_SEPOLIA_RPC_URL || undefined),
    [foundry.id]: http(),
  },
})
