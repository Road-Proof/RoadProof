# RoadProof · Frontend

dApp en React + Vite + wagmi/viem para interactuar con `RoadProofAuthorization` y `RoadProofRegistry`.

## Pantallas
La interfaz y todo el código fuente (nombres, comentarios, mensajes y tests) están en inglés; este README es la única pieza en español.

- **Verify** (sin wallet): consulta una revisión por ID (el QR apunta a `?id=...`), muestra resultado, DT, fecha y hash, y compara un archivo contra el hash on-chain (`verifyIntegrity`).
- **Register inspection** (wallet del DT): comprueba `isAuthorized` para el taller indicado, calcula el hash del informe y llama a `registerInspection`. Al confirmar genera el QR.
- **By plate**: historial de revisiones de un vehículo. El contrato no indexa `vehicleRefHash`, así que se leen los eventos `InspectionRegistered` y se filtra en el cliente.
- **Admin** (wallet owner): `authorizeTechnicalDirector` / `revokeTechnicalDirector` por taller.

## Uso

Requiere Node.js 22 (22.12 o posterior) o 24, y npm. Desde la raíz del repositorio:

```bash
cd frontend
cp .env.example .env.local   # completar direcciones desplegadas
npm ci
```

Antes de iniciar Vite, editar `frontend/.env.local`:

| Variable | Uso |
|---|---|
| `VITE_CHAIN` | `anvil` para desarrollo local o `sepolia` (predeterminado). |
| `VITE_AUTHORIZATION_ADDRESS` | Dirección desplegada de `RoadProofAuthorization`. |
| `VITE_REGISTRY_ADDRESS` | Dirección desplegada de `RoadProofRegistry`. |
| `VITE_SEPOLIA_RPC_URL` | RPC de Sepolia; vacío utiliza el predeterminado de la cadena. |
| `VITE_WALLETCONNECT_PROJECT_ID` | Opcional; habilita WalletConnect. |
| `VITE_DEPLOY_BLOCK` | Bloque de despliegue del registro; por defecto se consulta desde cero. |

Para probar en local, seguir el [despliegue con Anvil del README principal](../README.md#despliegue-local-con-anvil), que utiliza `forge create` para cada contrato. Mantener Anvil activo en `http://127.0.0.1:8545`, configurar `VITE_CHAIN=anvil` y copiar las direcciones obtenidas en los dos despliegues. La wallet debe usar esa misma red, con Chain ID `31337`, y una cuenta local con fondos de prueba.

Para Sepolia, configurar `VITE_CHAIN=sepolia`, las direcciones desplegadas en esa red y, si corresponde, un RPC propio. La wallet debe usar Chain ID `11155111` y disponer de ETH de prueba para enviar transacciones. Las direcciones locales no son válidas para este despliegue.

Desde `frontend/`:

```bash
npm run dev                  # abrir la URL que imprime Vite, normalmente http://localhost:5173
```

Reiniciar Vite tras cambiar `.env.local`. Para compilar y revisar la versión de producción:

```bash
npm run build                # genera frontend/dist/
npm run preview              # vista previa local de dist/
```

Las variables `VITE_*` quedan expuestas en el navegador. Las firmas se realizan mediante la wallet; no colocar claves privadas en esta configuración.

## Flujo de prueba manual

1. En **Admin**, conectar la wallet propietaria de `RoadProofAuthorization` y autorizar al director técnico para un taller.
2. Cambiar a la wallet del director técnico y abrir **Register inspection**. Completar el mismo taller, un ID de revisión nuevo, la patente, el resultado y el archivo del informe.
3. Firmar la transacción y esperar su confirmación. La aplicación muestra un QR que enlaza a **Verify** con el identificador de la revisión.
4. En **Verify**, consultar la revisión y seleccionar el mismo archivo para comprobar su integridad; un archivo con contenido modificado debe producir una comparación negativa.
5. En **By plate**, consultar la patente para ver las revisiones obtenidas de los eventos.

Este procedimiento describe cómo validar el flujo; la evidencia de una ejecución completa con una wallet real aún está pendiente.

## Wallets
MetaMask y otras wallets del navegador funcionan sin configuración. Para WalletConnect (wallets móviles) completá `VITE_WALLETCONNECT_PROJECT_ID` con un projectId gratuito de https://cloud.reown.com.

## Tests

Desde `frontend/`:

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
- La fecha se lee de los logs del evento `InspectionRegistered`; si no se puede recuperar, se muestra "Not available". Configurar `VITE_DEPLOY_BLOCK` ayuda.
- El reintento por tramos puede omitir registros anteriores a la ventana de aproximadamente 500.000 bloques.
- No hay un servicio integrado para subir o recuperar informes: el hash se calcula a partir del archivo local seleccionado.
- Un QR generado en `localhost` apunta a esa dirección; para consultarlo desde otro dispositivo, la aplicación y su RPC deben ser accesibles desde ese dispositivo.
