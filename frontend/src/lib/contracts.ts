import { parseAbi, type Address } from 'viem'

export const REGISTRY = (import.meta.env.VITE_REGISTRY_ADDRESS ?? '0x') as Address
export const AUTHORIZATION = (import.meta.env.VITE_AUTHORIZATION_ADDRESS ?? '0x') as Address
export const CONFIGURED = /^0x[0-9a-fA-F]{40}$/.test(REGISTRY) && /^0x[0-9a-fA-F]{40}$/.test(AUTHORIZATION)
export const DEPLOY_BLOCK = BigInt(import.meta.env.VITE_DEPLOY_BLOCK || 0)

/** Mismo orden que el enum InspectionResult del contrato: PASS, CONDITIONAL, REJECTED. */
export const RESULTS = [
  { value: 0, label: 'APTO', cls: 'ok' },
  { value: 1, label: 'CONDICIONAL', cls: 'warn' },
  { value: 2, label: 'RECHAZADO', cls: 'bad' },
] as const

export const registryAbi = parseAbi([
  'function registerInspection(bytes32 inspectionId, bytes32 reportHash, bytes32 vehicleRefHash, bytes32 workshopId, uint8 result)',
  'function inspections(bytes32) view returns (bytes32 reportHash, bytes32 vehicleRefHash, bytes32 workshopId, uint8 result, address technicalDirector)',
  'function inspectionExists(bytes32) view returns (bool)',
  'function verifyIntegrity(bytes32 inspectionId, bytes32 computedHash) view returns (bool intact)',
  'event InspectionRegistered(bytes32 indexed inspectionId, bytes32 indexed workshopId, bytes32 vehicleRefHash, address indexed technicalDirector, uint8 result, bytes32 reportHash, uint256 timestamp)',
  'error InvalidIdentifier()',
  'error InvalidHash()',
  'error TechnicalDirectorNotAuthorized()',
  'error DuplicateInspection()',
  'error InspectionNotFound()',
])

export const authorizationAbi = parseAbi([
  'function owner() view returns (address)',
  'function isAuthorized(bytes32 workshopId, address technicalDirector) view returns (bool)',
  'function authorizedDirectorsByWorkshop(bytes32, address) view returns (bool)',
  'function authorizeTechnicalDirector(bytes32 workshopId, address technicalDirector)',
  'function revokeTechnicalDirector(bytes32 workshopId, address technicalDirector)',
  'error InvalidIdentifier()',
  'error InvalidAddress()',
  'error DirectorAlreadyAuthorized()',
  'error DirectorNotAuthorized()',
  'error OwnableUnauthorizedAccount(address account)',
])
