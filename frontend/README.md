# RoadProof · Frontend

dApp en React + Vite + wagmi/viem para interactuar con `RoadProofAuthorization` y `RoadProofRegistry`.

## Pantallas
La interfaz y todo el código fuente (nombres, comentarios, mensajes y tests) están en inglés; este README es la única pieza en español.

- **Verify** (sin wallet): consulta una revisión por ID (el QR apunta a `?id=...`), muestra resultado, DT, fecha y hash, y compara un archivo contra el hash on-chain (`verifyIntegrity`).
- **Register inspection** (wallet del DT): comprueba `isAuthorized` para el taller indicado, calcula el hash del informe y llama a `registerInspection`. Al confirmar genera el QR.
- **By plate**: historial de revisiones de un vehículo. El contrato no indexa `vehicleRefHash`, así que se leen los eventos `InspectionRegistered` y se filtra en el cliente.
- **Admin** (wallet owner): `authorizeTechnicalDirector` / `revokeTechnicalDirector` por taller.

## Uso
```bash
cd frontend
cp .env.example .env.local   # completar direcciones desplegadas
npm install
npm run dev                  # http://localhost:5173
npm run build                # genera dist/ (desplegable en Vercel / Cloudflare Pages)
```

Para probar en local con Anvil: `VITE_CHAIN=anvil` y las direcciones que imprime `forge script ... DeployRoadProof`.

## Wallets
MetaMask y otras wallets del navegador funcionan sin configuración. Para WalletConnect (wallets móviles) completá `VITE_WALLETCONNECT_PROJECT_ID` con un projectId gratuito de https://cloud.reown.com.

## Tests
```bash
npm test
```
Cubren la convención de hashes (vectores keccak256 conocidos, normalización de patente, hash de archivo), la traducción de errores del contrato y la lectura/filtrado de eventos. No hay tests de componentes ni e2e contra una wallet real.

## Convención de hashes (debe ser idéntica al registrar y al verificar)
- IDs de revisión y de taller: `keccak256` de los bytes UTF-8 del texto (igual que `keccak256("WORKSHOP-001")` en los scripts). Si se pega un `0x` + 64 hex, se usa tal cual.
- Patente: se normaliza (mayúsculas, sin espacios ni guiones) y se aplica `keccak256`.
- Informe: `keccak256` de los bytes exactos del archivo.

## Limitaciones del MVP
- La búsqueda por patente y la fecha se leen de los logs. Si el RPC limita `getLogs`, se reintenta por tramos sobre los últimos ~500.000 bloques; usá un RPC sin límite de rango y configurá `VITE_DEPLOY_BLOCK`. Es válido para un MVP, pero no escala a muchos registros (el roadmap sería un indexador como The Graph o un evento con `vehicleRefHash` indexado).
- La fecha se lee de los logs del evento `InspectionRegistered`; si el RPC limita `getLogs`, se muestra "No disponible". Configurar `VITE_DEPLOY_BLOCK` ayuda.
