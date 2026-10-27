import { keccak256, stringToHex, isHex, type Hex } from 'viem'

/**
 * Convención del proyecto (igual que `keccak256("TEXTO")` en los scripts de Foundry):
 * un texto se convierte a bytes32 con keccak256 de sus bytes UTF-8.
 * Si el usuario ya pega un bytes32 (0x + 64 hex), se usa tal cual.
 */
export const toBytes32 = (text: string): Hex => {
  const t = text.trim()
  return isHex(t, { strict: true }) && t.length === 66 ? (t as Hex) : keccak256(stringToHex(t))
}

/** Patente normalizada (mayúsculas, sin espacios ni guiones) -> bytes32. */
export const plateToBytes32 = (plate: string): Hex => toBytes32(plate.toUpperCase().replace(/[\s-]/g, ''))

/** Hash del informe: keccak256 de los bytes exactos del archivo. Debe ser el mismo al registrar y al verificar. */
export const fileToHash = async (file: File): Promise<Hex> => keccak256(new Uint8Array(await file.arrayBuffer()))

export const short = (h: string) => `${h.slice(0, 10)}…${h.slice(-8)}`
