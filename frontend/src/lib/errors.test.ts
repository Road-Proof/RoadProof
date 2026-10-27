import { describe, expect, it } from 'vitest'
import { BaseError, ContractFunctionRevertedError, UserRejectedRequestError, encodeErrorResult } from 'viem'
import { describeError } from './errors'
import { registryAbi, authorizationAbi } from './contracts'

const revert = (abi: typeof registryAbi | typeof authorizationAbi, errorName: string) =>
  new ContractFunctionRevertedError({
    abi, functionName: 'x',
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    data: encodeErrorResult({ abi, errorName } as any),
  })

describe('describeError', () => {
  it('detecta el rechazo del usuario en la wallet', () => {
    expect(describeError(new UserRejectedRequestError(new Error('no')))).toMatch(/Cancelaste/)
  })
  it('traduce TechnicalDirectorNotAuthorized', () => {
    expect(describeError(revert(registryAbi, 'TechnicalDirectorNotAuthorized'))).toMatch(/no está autorizada/)
  })
  it('traduce DuplicateInspection', () => {
    expect(describeError(revert(registryAbi, 'DuplicateInspection'))).toMatch(/Ya existe/)
  })
  it('traduce DirectorAlreadyAuthorized del contrato de autorización', () => {
    expect(describeError(revert(authorizationAbi, 'DirectorAlreadyAuthorized'))).toMatch(/ya está autorizado/)
  })
  it('usa el mensaje corto para otros errores de viem', () => {
    expect(describeError(new BaseError('fallo de red'))).toBe('fallo de red')
  })
  it('responde algo razonable ante errores desconocidos', () => {
    expect(describeError('boom')).toBe('Error desconocido.')
  })
})
