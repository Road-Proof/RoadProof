import { keccak256, stringToHex, isHex, type Hex } from 'viem'

/** Reserved frontend marker for an omitted report; the registry rejects zero hashes. */
export const NO_REPORT_HASH = keccak256(stringToHex('RoadProof:no-report:v1'))

/**
 * Project convention (same as `keccak256("TEXT")` in the Foundry scripts):
 * a text is converted to bytes32 with keccak256 of its UTF-8 bytes.
 * If the user already pastes a bytes32 (0x + 64 hex), it is used as-is.
 */
export const toBytes32 = (text: string): Hex => {
  const t = text.trim()
  return isHex(t, { strict: true }) && t.length === 66 ? (t as Hex) : keccak256(stringToHex(t))
}

/** Normalized license plate (uppercase, no spaces or hyphens) -> bytes32. */
export const plateToBytes32 = (plate: string): Hex => toBytes32(plate.toUpperCase().replace(/[\s-]/g, ''))

/** Report hash: keccak256 of the exact file bytes. It must be the same when registering and verifying. */
export const fileToHash = async (file: File): Promise<Hex> => keccak256(new Uint8Array(await file.arrayBuffer()))

export const short = (h: string) => `${h.slice(0, 10)}…${h.slice(-8)}`
