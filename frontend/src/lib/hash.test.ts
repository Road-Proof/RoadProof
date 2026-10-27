import { describe, expect, it } from 'vitest'
import { keccak256 } from 'viem'
import { fileToHash, plateToBytes32, short, toBytes32 } from './hash'

describe('toBytes32', () => {
  it('coincide con vectores conocidos de keccak256', () => {
    expect(toBytes32('abc')).toBe('0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45')
    expect(toBytes32('')).toBe('0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470')
  })
  it('ignora espacios alrededor del texto', () => {
    expect(toBytes32('  abc ')).toBe(toBytes32('abc'))
  })
  it('usa tal cual un bytes32 ya calculado', () => {
    const h = toBytes32('WORKSHOP-001')
    expect(toBytes32(h)).toBe(h)
  })
  it('no confunde un hex de otra longitud con un bytes32', () => {
    expect(toBytes32('0x1234')).not.toBe('0x1234')
  })
})

describe('plateToBytes32', () => {
  it('normaliza mayúsculas, espacios y guiones', () => {
    expect(plateToBytes32('ab 123-cd')).toBe(plateToBytes32('AB123CD'))
  })
  it('distingue patentes distintas', () => {
    expect(plateToBytes32('AB123CD')).not.toBe(plateToBytes32('AB123CE'))
  })
})

describe('fileToHash', () => {
  it('es keccak256 de los bytes exactos del archivo', async () => {
    const bytes = new Uint8Array([1, 2, 3, 4])
    expect(await fileToHash(new File([bytes], 'a.pdf'))).toBe(keccak256(bytes))
  })
  it('un solo byte distinto cambia el hash (caso de informe adulterado)', async () => {
    const a = await fileToHash(new File([new Uint8Array([1, 2, 3, 4])], 'a.pdf'))
    const b = await fileToHash(new File([new Uint8Array([1, 2, 3, 5])], 'a.pdf'))
    expect(a).not.toBe(b)
  })
})

describe('short', () => {
  it('abrevia hashes largos', () => {
    expect(short(toBytes32('x'))).toMatch(/^0x[0-9a-f]{8}…[0-9a-f]{8}$/)
  })
})
