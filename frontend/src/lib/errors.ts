import { BaseError, ContractFunctionRevertedError, UserRejectedRequestError } from 'viem'

const MESSAGES: Record<string, string> = {
  TechnicalDirectorNotAuthorized: 'Your wallet is not authorized as Technical Director for that workshop.',
  DuplicateInspection: 'An inspection with that ID already exists. Use a different identifier.',
  InspectionNotFound: 'No inspection exists with that ID.',
  InvalidIdentifier: 'The inspection or workshop ID is not valid (it cannot be zero).',
  InvalidHash: 'The report hash or the vehicle reference is missing.',
  InvalidAddress: 'The Technical Director address is not valid.',
  DirectorAlreadyAuthorized: 'That Technical Director is already authorized for the workshop.',
  DirectorNotAuthorized: 'That Technical Director is not authorized for the workshop; there is nothing to revoke.',
  OwnableUnauthorizedAccount: 'Only the contract administrator (owner) can do this.',
}

/** Translates wallet, network and contract custom errors into readable messages. */
export function describeError(err: unknown): string {
  if (!(err instanceof BaseError)) return 'Unknown error.'
  if (err.walk((e) => e instanceof UserRejectedRequestError)) return 'You cancelled the operation in your wallet.'
  const revert = err.walk((e) => e instanceof ContractFunctionRevertedError)
  if (revert instanceof ContractFunctionRevertedError) {
    const name = revert.data?.errorName
    if (name) return MESSAGES[name] ?? `The contract rejected the operation (${name}).`
  }
  return err.shortMessage
}
