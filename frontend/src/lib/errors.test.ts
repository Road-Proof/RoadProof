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
  it('detects the user rejecting in the wallet', () => {
    expect(describeError(new UserRejectedRequestError(new Error('no')))).toMatch(/cancelled/)
  })
  it('translates TechnicalDirectorNotAuthorized', () => {
    expect(describeError(revert(registryAbi, 'TechnicalDirectorNotAuthorized'))).toMatch(/not authorized/)
  })
  it('translates DuplicateInspection', () => {
    expect(describeError(revert(registryAbi, 'DuplicateInspection'))).toMatch(/already exists/)
  })
  it('translates DirectorAlreadyAuthorized from the authorization contract', () => {
    expect(describeError(revert(authorizationAbi, 'DirectorAlreadyAuthorized'))).toMatch(/already authorized/)
  })
  it('uses the short message for other viem errors', () => {
    expect(describeError(new BaseError('network failure'))).toBe('network failure')
  })
  it('returns a sensible message for unknown errors', () => {
    expect(describeError('boom')).toBe('Unknown error.')
  })
})
