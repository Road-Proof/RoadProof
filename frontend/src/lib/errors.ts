import { BaseError, ContractFunctionRevertedError, UserRejectedRequestError } from 'viem'

const MESSAGES: Record<string, string> = {
  TechnicalDirectorNotAuthorized: 'Tu wallet no está autorizada como Director Técnico para ese taller.',
  DuplicateInspection: 'Ya existe una revisión con ese ID. Usá otro identificador.',
  InspectionNotFound: 'No existe una revisión con ese ID.',
  InvalidIdentifier: 'El ID de revisión o de taller no es válido (no puede ser cero).',
  InvalidHash: 'Falta el hash del informe o la referencia del vehículo.',
  InvalidAddress: 'La dirección del Director Técnico no es válida.',
  DirectorAlreadyAuthorized: 'Ese Director Técnico ya está autorizado para el taller.',
  DirectorNotAuthorized: 'Ese Director Técnico no está autorizado para el taller; no hay nada que revocar.',
  OwnableUnauthorizedAccount: 'Solo el administrador (owner) del contrato puede hacer esto.',
}

/** Traduce errores de wallet, red y custom errors del contrato a mensajes legibles. */
export function describeError(err: unknown): string {
  if (!(err instanceof BaseError)) return 'Error desconocido.'
  if (err.walk((e) => e instanceof UserRejectedRequestError)) return 'Cancelaste la operación en la wallet.'
  const revert = err.walk((e) => e instanceof ContractFunctionRevertedError)
  if (revert instanceof ContractFunctionRevertedError) {
    const name = revert.data?.errorName
    if (name) return MESSAGES[name] ?? `El contrato rechazó la operación (${name}).`
  }
  return err.shortMessage
}
