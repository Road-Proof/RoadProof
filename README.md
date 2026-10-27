# RoadProof

**Sistema de registro y verificación de integridad de revisiones técnicas vehiculares mediante blockchain Ethereum.**

RoadProof es un proyecto académico que utiliza contratos inteligentes para registrar revisiones técnicas vehiculares y permitir la verificación de la integridad de sus informes mediante hashes criptográficos.

El sistema busca proporcionar trazabilidad y evidencia verificable de los registros, dificultando la modificación no detectada de los resultados de las revisiones.

Los informes completos y los datos sensibles del vehículo no se almacenan directamente en la blockchain. El contrato registra identificadores y hashes que permiten verificar la integridad de la información almacenada fuera de ella.

## Índice

1. [Objetivo y alcance](#objetivo-y-alcance)
2. [Arquitectura](#arquitectura)
3. [Tecnologías](#tecnologías)
4. [Requisitos previos](#requisitos-previos)
5. [Instalación del proyecto](#instalación-del-proyecto)
6. [Estructura del repositorio](#estructura-del-repositorio)
7. [Contratos inteligentes](#contratos-inteligentes)
8. [Flujo funcional](#flujo-funcional)
9. [Compilación y pruebas automatizadas](#compilación-y-pruebas-automatizadas)
10. [Despliegue local con Anvil](#despliegue-local-con-anvil)
11. [Prueba de interacción entre contratos](#prueba-de-interacción-entre-contratos)
12. [Pruebas manuales con Cast](#pruebas-manuales-con-cast)
13. [Configuración para Sepolia](#configuración-para-sepolia)
14. [Integración con el frontend](#integración-con-el-frontend)
15. [Seguridad y buenas prácticas](#seguridad-y-buenas-prácticas)
16. [Estado del proyecto y tareas pendientes](#estado-del-proyecto-y-tareas-pendientes)
17. [Roadmap](#roadmap)
18. [Referencias](#referencias)

---

## Objetivo y alcance

El propósito de RoadProof es registrar resultados de Revisiones Técnicas Obligatorias (RTO) de forma verificable mediante una blockchain compatible con Ethereum.

El proyecto contempla los siguientes objetivos:

- Registrar revisiones técnicas vehiculares.
- Asociar cada revisión con un identificador de taller.
- Restringir el registro a directores técnicos autorizados para el taller correspondiente.
- Registrar el resultado de la revisión.
- Almacenar hashes de la información relevante para verificar su integridad.
- Emitir eventos que permitan identificar y seguir las operaciones realizadas.
- Permitir la consulta de los registros y la verificación de sus hashes.
- Proporcionar una base para una futura integración con una aplicación frontend.

### Alcance de la primera implementación

La implementación actual se concentra en los contratos inteligentes y en la validación de sus operaciones mediante Foundry y Anvil.

El despliegue público en Sepolia, la verificación del código fuente en un explorador y la integración con el frontend constituyen etapas posteriores.

## Arquitectura

RoadProof separa la autorización de los directores técnicos del registro de las revisiones.

```text
                   Administrador
                        |
                        v
              RoadProofAuthorization
              - Autorizar DT por taller
              - Revocar autorización
              - Consultar autorización
                        |
                        | isAuthorized()
                        v
Director técnico --> RoadProofRegistry
                     - Validar autorización
                     - Registrar revisión
                     - Guardar hashes
                     - Emitir evento
                            |
                            v
                      Blockchain
```

### Responsabilidades de los componentes

**RoadProofAuthorization**

Administra qué direcciones de Ethereum están autorizadas como directores técnicos para cada taller.

**RoadProofRegistry**

Valida la autorización del director técnico antes de registrar una revisión y almacena la información verificable del registro.

**Frontend**

Será el punto de interacción de los usuarios con los contratos desplegados. Su implementación e integración están pendientes.

**Almacenamiento externo**

Los informes completos y la información complementaria se mantienen fuera de la blockchain. Los hashes registrados permiten contrastar posteriormente esos datos con los originales.

### Modelo de datos

Cada revisión se consulta mediante `inspectionId`. El struct `Inspection` almacena:

- `reportHash`: hash del informe.
- `vehicleRefHash`: hash de referencia del vehículo.
- `workshopId`: identificador del taller.
- `result`: resultado de la revisión.
- `technicalDirector`: dirección de Ethereum que registró la revisión como director técnico.

La fecha y hora del registro se incluye únicamente en el evento `InspectionRegistered`, no en el estado almacenado de la revisión.

Los hashes no permiten recuperar por sí solos el contenido original. Para verificar la integridad, debe calcularse nuevamente el hash de los datos originales y compararlo con el registrado.

## Tecnologías

| Tecnología | Utilización |
|---|---|
| Solidity | Desarrollo de contratos inteligentes. |
| Foundry | Entorno de desarrollo, compilación, pruebas y despliegue. |
| Forge | Compilación, ejecución de pruebas y scripts. |
| Cast | Consultas y envío de transacciones a redes EVM. |
| Anvil | Blockchain local de desarrollo. |
| OpenZeppelin Contracts | Componentes reutilizables, incluido el control de propiedad. |
| Ethereum / EVM | Entorno de ejecución de los contratos. |
| Git y GitHub | Control de versiones y colaboración. |

## Requisitos previos

Se necesita:

- Linux, macOS o Windows con WSL2 y Ubuntu.
- Git.
- Foundry instalado.
- Acceso a una terminal.
- Conexión a Internet para clonar el repositorio y descargar dependencias.

Verificar las herramientas instaladas:

```bash
forge --version
cast --version
anvil --version
```

## Instalación del proyecto

### 1. Clonar el repositorio

```bash
git clone https://github.com/Road-Proof/RoadProof.git
cd RoadProof
```
### 2. Inicializar las dependencias

```bash
git submodule update --init --recursive
```

Comprobar que estén disponibles:

```bash
ls lib
```

El proyecto utiliza `forge-std` para los scripts y las pruebas, y OpenZeppelin Contracts para componentes reutilizables.

### 3. Compilar inicialmente

```bash
forge build
```

La compilación debe finalizar sin errores.

## Estructura del repositorio

La estructura relevante para la implementación actual es:

```text
roadproof/
├── src/
│   ├── IRoadProofAuthorization.sol
│   ├── RoadProofAuthorization.sol
│   └── RoadProofRegistry.sol
├── test/
│   ├── RoadProofAuthorization.t.sol
│   └── RoadProofRegistry.t.sol
├── script/
│   ├── DeployRoadProof.s.sol
│   └── InteractRoadProof.s.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── broadcast/
│   └── ...
├── cache/
│   └── ...
├── foundry.lock
├── foundry.toml
├── .gitmodules
├── .gitignore
├── LICENSE
└── README.md
```

Los directorios `broadcast/` y `cache/` son utilizados por Foundry para almacenar resultados y datos auxiliares de las ejecuciones.

La estructura puede variar según la rama y el avance de la integración. Para consultar los archivos presentes en una copia del repositorio:

```bash
find src test script -maxdepth 2 -type f
```

### Configuración de Foundry

El archivo `foundry.toml` define, entre otros parámetros, las rutas del proyecto, la versión del compilador y la configuración del optimizador.

La configuración actual utiliza Solidity `0.8.37`, el entorno EVM `cancun`, optimización habilitada y 200 ejecuciones del optimizador.

## Contratos inteligentes

Los identificadores de contratos, funciones, parámetros, tipos, eventos, errores y pruebas se mantienen en inglés, tal como aparecen en el código fuente.

### 1. RoadProofAuthorization.sol

Este contrato administra las autorizaciones de los directores técnicos.

Su relación de autorización es específica por taller:

```text
workshopId + technicalDirector -> authorized (true / false)
```

#### Funcionalidades

**`authorizeTechnicalDirector(bytes32 workshopId, address technicalDirector)`**

Autoriza una dirección para actuar como director técnico de un taller.

**`revokeTechnicalDirector(bytes32 workshopId, address technicalDirector)`**

Revoca la autorización previamente otorgada.

**`isAuthorized(bytes32 workshopId, address technicalDirector)`**

Consulta si una dirección está autorizada para un taller.

El contrato utiliza control de propiedad mediante OpenZeppelin `Ownable2Step`. Las operaciones administrativas requieren que la transacción sea ejecutada por el propietario del contrato.

La transferencia de propiedad se realiza en dos pasos: el propietario actual propone una dirección mediante `transferOwnership(newOwner)` y esa dirección confirma mediante `acceptOwnership()`. Hasta la aceptación, el propietario actual conserva sus permisos y puede reemplazar la propuesta o cancelarla con `transferOwnership(address(0))`. La dirección propuesta puede consultarse mediante `pendingOwner()`.

`renounceOwnership()` está deshabilitada: las llamadas del propietario revierten con `OwnershipRenunciationDisabled`, para evitar que las autorizaciones de los directores técnicos queden sin administración.

La relación se almacena mediante el mapeo `authorizedDirectorsByWorkshop`.

### 2. IRoadProofAuthorization.sol

Define la interfaz utilizada por el contrato de registro para consultar las autorizaciones.

La función principal es:

```solidity
function isAuthorized(bytes32 workshopId, address technicalDirector)
    external
    view
    returns (bool authorized);
```

Esta interfaz desacopla la consulta de autorización de la implementación concreta que administra los permisos.

### 3. RoadProofRegistry.sol

Es el contrato responsable de registrar y consultar las revisiones técnicas.

#### Resultados admitidos

```solidity
enum InspectionResult {
    PASS,
    CONDITIONAL,
    REJECTED
}
```

Los valores numéricos correspondientes son `0`, `1` y `2`, respectivamente.

#### Funcionalidades principales

**`registerInspection(...)`**

Registra una revisión si se cumplen las validaciones del contrato, incluida la autorización del director técnico para el taller indicado.

```solidity
function registerInspection(
    bytes32 inspectionId,
    bytes32 reportHash,
    bytes32 vehicleRefHash,
    bytes32 workshopId,
    InspectionResult result
) external;
```

**`inspectionExists(bytes32 inspectionId)`**

Permite consultar si existe un registro para un identificador de revisión.

**`inspections(bytes32 inspectionId)`**

Permite consultar la información almacenada para una revisión.

**`verifyIntegrity(bytes32 inspectionId, bytes32 computedHash)`**

Permite comprobar si el hash proporcionado coincide con el hash del informe registrado.

El contrato mantiene una referencia al contrato de autorización mediante `authorizationContract`.

#### Validaciones relevantes

El contrato verifica, entre otras condiciones:

- Que los identificadores y hashes obligatorios no sean nulos.
- Que no se registre dos veces el mismo identificador de revisión.
- Que el director técnico esté autorizado para el taller correspondiente.
- Que el contrato de autorización sea válido al inicializar el registro.

Si una validación falla, la operación se revierte y no se completa el registro.

#### Eventos

Las operaciones relevantes emiten eventos para facilitar la trazabilidad de las transacciones. El evento `InspectionRegistered` permite identificar el registro realizado y consultar los datos asociados a esa operación en los logs de la blockchain.

## Flujo funcional

### 1. Autorización de un director técnico

1. El administrador ejecuta `authorizeTechnicalDirector`.
2. El contrato almacena la autorización para la combinación de taller y dirección.
3. La autorización queda disponible para las siguientes operaciones de registro.

### 2. Registro de una revisión

1. El director técnico prepara los datos de la revisión.
2. Se invoca `registerInspection`.
3. El contrato consulta `isAuthorized` para el taller indicado.
4. Si la dirección no está autorizada, la operación se revierte.
5. Si está autorizada y las restantes validaciones se cumplen, la revisión se registra.
6. El contrato emite `InspectionRegistered`.

### 3. Verificación de integridad

1. Se recupera el informe original almacenado fuera de la blockchain.
2. Se calcula nuevamente el hash utilizando el mismo procedimiento.
3. Se compara el hash calculado con el hash registrado.
4. Si ambos coinciden, la verificación de integridad resulta positiva.

La comparación demuestra que los datos utilizados para calcular el hash coinciden con el compromiso criptográfico registrado. No demuestra, por sí sola, que el contenido original sea verdadero ni que el procedimiento de inspección se haya realizado correctamente.

## Compilación y pruebas automatizadas

Todos los comandos siguientes deben ejecutarse desde la raíz del repositorio.

### 1. Compilar los contratos

```bash
forge build
```

Compila los contratos y scripts del proyecto.

### 2. Ejecutar todas las pruebas

```bash
forge test
```

Ejecuta la suite de pruebas detectada por Foundry.

Esta es la validación general que debe ejecutarse después de modificar los contratos o las pruebas.

### 3. Ejecutar las pruebas de RoadProof

```bash
forge test --match-path 'test/RoadProof*.t.sol' -vv
```

`RoadProofAuthorization.t.sol` contiene las pruebas de autorizaciones y consultas de permisos. `RoadProofRegistry.t.sol` contiene las pruebas del registro, la integridad de los informes y la integración con el contrato de autorización.

Para obtener más información durante la ejecución:

```bash
forge test --match-path 'test/RoadProof*.t.sol' -vvv
```

### 4. Ejecutar una prueba específica

Para comprobar el rechazo de un director técnico no autorizado:

```bash
forge test \
  --match-test testUnauthorizedDirectorCannotRegisterInspection \
  -vv
```

Foundry debe confirmar que la prueba pasa cuando la llamada se revierte con el error esperado.

### 5. Calcular cobertura

```bash
forge coverage
```

El informe incluye métricas de líneas, instrucciones, ramas y funciones.

Para obtener información detallada del código ejecutado y no cubierto:

```bash
forge coverage --report debug
```

El requisito académico establecido para el proyecto es superar el 40 % en cada métrica reportada. Antes de la entrega, se deben conservar los resultados definitivos de cobertura y verificar las métricas específicas de los contratos de RoadProof.

No se debe interpretar la cobertura como una garantía de ausencia de vulnerabilidades.

### 6. Formatear el código

Aplicar el formato de Foundry:

```bash
forge fmt
```

Comprobar el formato sin modificar los archivos:

```bash
forge fmt --check
```

### 7. Consultar el consumo de gas

```bash
forge snapshot
```

Este comando genera o actualiza las referencias de consumo de gas de las pruebas. Antes de confirmar cambios en Git, revisar los archivos modificados y los cambios en los valores de referencia.

## Despliegue local con Anvil

Esta sección permite reproducir el despliegue de los dos contratos en una blockchain local.

### 1. Iniciar Anvil

Abrir una terminal y ejecutar:

```bash
anvil
```

Anvil inicia un nodo local, normalmente accesible mediante:

```text
http://127.0.0.1:8545
```

La red local utiliza normalmente el identificador de cadena `31337`.

Anvil muestra cuentas de prueba y sus claves privadas. Estas cuentas tienen fondos ficticios dentro de la red local.

**No cerrar ni reiniciar Anvil durante la prueba**, porque al iniciar una instancia nueva se pierde el estado local anterior, salvo que se restaure explícitamente.

### 2. Verificar la conexión

En otra terminal:

```bash
cast chain-id --rpc-url http://127.0.0.1:8545
```

Consultar el bloque actual:

```bash
cast block-number --rpc-url http://127.0.0.1:8545
```

### 3. Desplegar los contratos

Desplegar primero `RoadProofAuthorization` y después `RoadProofRegistry`, pasando la dirección del primero al constructor del segundo.

El archivo actual `script/DeployRoadProof.s.sol` contiene un contrato llamado `InteractRoadProof` que interactúa con direcciones existentes. Para desplegar los contratos, utilizar `forge create` como se muestra a continuación.

En la terminal del proyecto, definir `ANVIL_OWNER_PK` con la clave privada de la primera cuenta de prueba de la instancia actual de Anvil:

```bash
export ANVIL_OWNER_PK="<ANVIL_OWNER_PRIVATE_KEY>"
```

Reemplazar el marcador de posición por la clave correspondiente, sin incluirla en archivos versionados.

Desplegar el contrato de autorización:

```bash
forge create src/RoadProofAuthorization.sol:RoadProofAuthorization \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --private-key "$ANVIL_OWNER_PK"
```

Guardar la dirección indicada en `Deployed to`:

```bash
export AUTHORIZATION_ADDRESS="<AUTHORIZATION_CONTRACT_ADDRESS>"
```

Desplegar el registro con esa dirección como argumento `authorizationAddress`:

```bash
forge create src/RoadProofRegistry.sol:RoadProofRegistry \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --private-key "$ANVIL_OWNER_PK" \
  --constructor-args "$AUTHORIZATION_ADDRESS"
```

Guardar también la dirección de `RoadProofRegistry`:

```bash
export REGISTRY_ADDRESS="<REGISTRY_CONTRACT_ADDRESS>"
```

El despliegue debe informar las direcciones de ambos contratos y el resultado de las transacciones.

**Importante:** las direcciones de los contratos locales no deben considerarse direcciones de Sepolia ni de una red productiva.

### 4. Guardar las direcciones obtenidas

Registrar en las notas de ejecución local:

- Dirección de `RoadProofAuthorization`.
- Dirección de `RoadProofRegistry`.
- Identificador de cadena.
- Hashes de las transacciones de despliegue.
- Fecha de la ejecución.

Las direcciones deben corresponder a la misma instancia de Anvil que se está utilizando.

## Prueba de interacción entre contratos

El script `script/InteractRoadProof.s.sol` permite reproducir el flujo principal de autorización y registro.

### 1. Configurar la clave del director técnico

Se necesita una segunda cuenta de prueba de Anvil, distinta de la cuenta propietaria que desplegó los contratos.

En la terminal donde se ejecutarán los scripts:

```bash
export DIRECTOR_PK="<ANVIL_DIRECTOR_PRIVATE_KEY>"
```

Usar la clave de una cuenta de prueba de la instancia actual de Anvil.

Comprobar que la variable está configurada sin mostrar su contenido:

```bash
test -n "$DIRECTOR_PK" && echo "DIRECTOR_PK is configured"
```

### 2. Ejecutar el script de interacción

```bash
forge script script/InteractRoadProof.s.sol:InteractRoadProof \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --private-key "$ANVIL_OWNER_PK"
```

El script utiliza las direcciones de los contratos desplegados localmente. Si se realiza un nuevo despliegue, deben actualizarse las direcciones que utiliza el script.

La ejecución realiza las siguientes operaciones:

1. Calcula identificadores y hashes de prueba.
2. Autoriza al director técnico para `WORKSHOP-001`.
3. Registra una revisión con resultado `PASS`, utilizando la cuenta del director técnico.
4. Comprueba que el identificador de revisión existe.
5. Verifica que el hash del informe coincida con el almacenado.
6. Comprueba que se guardó la referencia del vehículo.

El resultado esperado es una ejecución exitosa y dos transacciones confirmadas: la autorización y el registro.

### 3. Evidencia de la ejecución local

Durante la validación local se obtuvo una ejecución exitosa con los siguientes resultados:

- `authorizeTechnicalDirector`: bloque 2.
- `registerInspection`: bloque 3.
- Gas utilizado por la autorización: 49.002 unidades.
- Gas utilizado por el registro: 166.250 unidades.
- Estado de ejecución: `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL`.

Los valores de gas corresponden a esa ejecución local y no deben interpretarse como estimaciones definitivas de consumo en Sepolia o en la red principal.

## Pruebas manuales con Cast

Además de las pruebas automatizadas, se realizaron transacciones manuales contra los contratos desplegados en Anvil.

Estas pruebas permiten observar el comportamiento del contrato ante una llamada permitida y otra rechazada.

### 1. Preparar los datos de prueba

En la terminal donde se ejecutarán los comandos:

```bash
WORKSHOP_ID=$(cast keccak "WORKSHOP-001")
INSPECTION_ID=$(cast keccak "UNAUTHORIZED-INSPECTION-001")
REPORT_HASH=$(cast keccak "UNAUTHORIZED-REPORT")
VEHICLE_REF_HASH=$(cast keccak "UNAUTHORIZED-VEHICLE")
```

Los identificadores se calculan utilizando `keccak256` y corresponden exclusivamente a datos ficticios de prueba.

### 2. Intento de registro con un director no autorizado

Ejecutar la transacción con la clave de la cuenta propietaria, que no fue autorizada como director técnico para ese taller:

```bash
cast send "$REGISTRY_ADDRESS" \
  "registerInspection(bytes32,bytes32,bytes32,bytes32,uint8)" \
  "$INSPECTION_ID" \
  "$REPORT_HASH" \
  "$VEHICLE_REF_HASH" \
  "$WORKSHOP_ID" \
  0 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key "$ANVIL_OWNER_PK"
```

Antes de ejecutar el comando, definir la dirección del registro desplegado:

```bash
export REGISTRY_ADDRESS=YOUR_REGISTRY_CONTRACT_ADDRESS
```

El resultado esperado es un rechazo con el error personalizado:

```text
TechnicalDirectorNotAuthorized
```

Con la ABI actual, el selector de `TechnicalDirectorNotAuthorized()` es `0xda13c00f`. El mensaje de `cast send` puede incluir:

```text
Failed to estimate gas
execution reverted: custom error 0xda13c00f
TechnicalDirectorNotAuthorized
```

Si la llamada se rechaza durante la estimación de gas, no llega a minarse como una transacción fallida.

### 3. Repetir la operación con un director autorizado

Utilizar el mismo taller y los mismos datos, pero firmar la transacción con la clave de la cuenta autorizada:

```bash
cast send "$REGISTRY_ADDRESS" \
  "registerInspection(bytes32,bytes32,bytes32,bytes32,uint8)" \
  "$INSPECTION_ID" \
  "$REPORT_HASH" \
  "$VEHICLE_REF_HASH" \
  "$WORKSHOP_ID" \
  0 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key "$DIRECTOR_PK"
```

El resultado esperado es una transacción exitosa.

En la ejecución validada se obtuvo:

- Bloque: `4`.
- Estado: `1 (success)`.
- Gas utilizado: `166.250`.
- Hash de transacción: `0x9a8359a0890cdf755d5d08b472809a44fd7711ffc56f1878e20a229b4bbc4745`.

### 4. Consultar si la revisión existe

```bash
cast call "$REGISTRY_ADDRESS" \
  "inspectionExists(bytes32)(bool)" \
  "$INSPECTION_ID" \
  --rpc-url http://127.0.0.1:8545
```

La respuesta obtenida fue:

```text
true
```

Esto confirma que la revisión del segundo intento quedó registrada.

### 5. Consultar la autorización

También se puede consultar el estado de autorización para el taller y la dirección del director:

```bash
DIRECTOR_ADDRESS=$(cast wallet address --private-key "$DIRECTOR_PK")
```

Definir la dirección del contrato de autorización:

```bash
export AUTHORIZATION_ADDRESS=YOUR_AUTHORIZATION_CONTRACT_ADDRESS
```

Consultar:

```bash
cast call "$AUTHORIZATION_ADDRESS" \
  "isAuthorized(bytes32,address)(bool)" \
  "$WORKSHOP_ID" \
  "$DIRECTOR_ADDRESS" \
  --rpc-url http://127.0.0.1:8545
```

La respuesta debe ser `true` cuando la autorización se encuentre vigente.

### Conclusión de las pruebas manuales

Las transacciones locales demostraron que:

- Una dirección sin autorización para el taller no puede registrar una revisión.
- Una dirección autorizada sí puede registrarla.
- El registro emite un evento `InspectionRegistered`.
- La consulta posterior confirma la existencia de la revisión.

Estas comprobaciones validan el control de autorización y el registro en la instancia local utilizada. No equivalen todavía a una validación en una red pública ni a una auditoría integral de seguridad.

## Configuración para Sepolia

El despliegue en Sepolia está previsto como siguiente etapa de desarrollo.

El procedimiento debe mantener la misma arquitectura del despliegue local, pero utilizar una red pública de pruebas y una configuración independiente.

### 1. Requisitos

Se necesita:

- Acceso a Sepolia mediante un proveedor RPC.
- Una billetera o cuenta administradora para desplegar los contratos.
- ETH de prueba de Sepolia para cubrir el gas.
- La dirección de la cuenta que actuará como administradora.
- Las direcciones obtenidas después de desplegar ambos contratos.
- Acceso a un explorador compatible para consultar las transacciones y verificar el código fuente.

### 2. Configuración mediante variables de entorno

Definir la URL RPC y la clave privada de despliegue en el entorno local:

```bash
export SEPOLIA_RPC_URL="YOUR_SEPOLIA_RPC_URL"
export SEPOLIA_PRIVATE_KEY="<SEPOLIA_TESTNET_PRIVATE_KEY>"
```

Los valores anteriores son marcadores de posición y deben reemplazarse localmente.

No incorporar claves privadas, frases semilla ni tokens de proveedor RPC en el repositorio.

### 3. Desplegar en Sepolia

Una vez configuradas las variables y verificado que la cuenta dispone de ETH de prueba:

```bash
forge create src/RoadProofAuthorization.sol:RoadProofAuthorization \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast \
  --private-key "$SEPOLIA_PRIVATE_KEY"
```

Guardar la dirección indicada en `Deployed to` y utilizarla para desplegar el registro:

```bash
export SEPOLIA_AUTHORIZATION_ADDRESS="<SEPOLIA_AUTHORIZATION_CONTRACT_ADDRESS>"

forge create src/RoadProofRegistry.sol:RoadProofRegistry \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast \
  --private-key "$SEPOLIA_PRIVATE_KEY" \
  --constructor-args "$SEPOLIA_AUTHORIZATION_ADDRESS"
```

Antes de considerar finalizado el despliegue, comprobar:

- Que las dos transacciones de despliegue se hayan confirmado.
- Que se hayan registrado las direcciones de ambos contratos.
- Que `RoadProofRegistry` apunte a la dirección correcta de `RoadProofAuthorization`.
- Que las direcciones correspondan a la cadena Sepolia.
- Que las transacciones puedan consultarse en el explorador de la red.

### 4. Verificación del código fuente

Después del despliegue, verificar el código fuente de ambos contratos en el explorador compatible.

La verificación debe utilizar la misma versión del compilador y configuración relevante que se emplearon para compilar el contrato desplegado.

También deben documentarse los argumentos del constructor y las direcciones de las dependencias utilizadas.

### 5. Registrar la evidencia del despliegue

Completar la siguiente información una vez realizado el despliegue:

| Dato | Valor |
|---|---|
| Red | Sepolia |
| Chain ID | 11155111 |
| Dirección de `RoadProofAuthorization` | Pendiente |
| Dirección de `RoadProofRegistry` | Pendiente |
| Transacción de despliegue de autorización | Pendiente |
| Transacción de despliegue del registro | Pendiente |
| Enlace al contrato verificado de autorización | Pendiente |
| Enlace al contrato verificado del registro | Pendiente |
| Cuenta administradora | Pendiente |

Los enlaces deben incorporarse únicamente después de confirmar las direcciones y transacciones reales.

### 6. Pruebas posteriores al despliegue

Una vez desplegados los contratos en Sepolia, repetir al menos las siguientes comprobaciones:

- Consultar la autorización de un DT para un taller.
- Autorizar un DT mediante la cuenta administradora.
- Registrar una revisión con la cuenta autorizada.
- Intentar registrar una revisión con una cuenta no autorizada.
- Consultar la existencia de la revisión.
- Verificar la integridad del hash del informe.
- Consultar los eventos emitidos.
- Registrar los hashes de las transacciones y sus enlaces públicos.

El resultado de estas pruebas debe documentarse por separado de las pruebas locales.

## Integración con el frontend

La integración con el frontend permitirá que los usuarios interactúen con los contratos sin tener que utilizar comandos de terminal.

La integración deberá realizarse contra las direcciones de los contratos desplegados en la red seleccionada.

### 1. Información que necesita el frontend

El frontend deberá disponer de:

- Red de destino y Chain ID.
- Dirección de `RoadProofAuthorization`.
- Dirección de `RoadProofRegistry`.
- ABI de los contratos.
- Cuenta del usuario conectado.
- Identificadores y hashes necesarios para cada operación.

Las direcciones de Anvil no deben utilizarse como direcciones de Sepolia.

### 2. Lecturas y transacciones

**Operaciones de lectura**

Entre las consultas disponibles se encuentran:

- `isAuthorized(workshopId, technicalDirector)`.
- `inspectionExists(inspectionId)`.
- `inspections(inspectionId)`.
- `verifyIntegrity(inspectionId, computedHash)`.

Estas funciones permiten consultar el estado de los contratos sin modificarlo.

**Operaciones que requieren transacción**

Las siguientes operaciones modifican el estado de la blockchain:

- `authorizeTechnicalDirector`.
- `revokeTechnicalDirector`.
- `registerInspection`.

La autorización y revocación deben ejecutarse con la cuenta administradora. El registro de una revisión debe firmarse con la cuenta del director técnico autorizado.

El frontend debe contemplar estados de conexión, firma pendiente, transacción enviada, confirmación, rechazo por el usuario y errores de ejecución.

### 3. Flujo propuesto para el registro

1. El usuario conecta su billetera.
2. El frontend comprueba que la red seleccionada sea la esperada.
3. Se preparan los identificadores y hashes de la revisión.
4. Se envía la transacción a `RoadProofRegistry`.
5. El contrato valida la autorización del director técnico.
6. Si la transacción se confirma, el frontend informa el resultado y conserva el hash de la transacción.
7. El usuario puede consultar la revisión y verificar la integridad del informe.

### 4. Consideraciones de integración

- El frontend no debe asumir que una transacción fue exitosa antes de recibir la confirmación correspondiente.
- Las validaciones del frontend mejoran la experiencia de usuario, pero no reemplazan las validaciones de los contratos.
- Los informes completos no deben almacenarse en eventos públicos ni publicarse en la blockchain si contienen información sensible.
- Debe definirse el procedimiento para generar y reproducir los hashes del informe.
- Las direcciones de los contratos y la configuración de red deben estar separadas por entorno.

La integración de extremo a extremo todavía debe completarse y documentarse con evidencia.

## Seguridad y buenas prácticas

Durante el desarrollo se aplican o se contemplan las siguientes medidas:

- Control de acceso administrativo mediante OpenZeppelin `Ownable2Step`, con aceptación explícita del nuevo propietario.
- Renuncia de propiedad deshabilitada para conservar la administración de permisos.
- Autorización del director técnico específica por taller.
- Rechazo de revisiones duplicadas.
- Validación de identificadores y hashes.
- Errores personalizados para condiciones de rechazo.
- Eventos para registrar operaciones relevantes.
- Separación entre informes externos y sus hashes en la blockchain.
- Pruebas de caminos exitosos y de errores esperados.

### Aspectos pendientes de revisión

Antes de la entrega académica, revisar y documentar:

- Cobertura definitiva de líneas, instrucciones, ramas y funciones.
- Calidad y completitud de la documentación NatSpec.
- Resultados del análisis estático con Slither.
- Advertencias y hallazgos relevantes.
- Consumo de gas y uso del almacenamiento.
- Comportamiento ante revocación de autorización.
- Comportamiento de las funciones administrativas ante usuarios no autorizados.
- Validación de hashes y tratamiento de datos sensibles.
- Consistencia entre el código desplegado y el código fuente verificado.

Las pruebas actuales constituyen evidencia del comportamiento probado, pero no deben presentarse como una auditoría formal ni como garantía de ausencia de vulnerabilidades.

## Estado del proyecto y tareas pendientes

### Implementado y probado localmente

- [x] Contrato de autorización de directores técnicos por taller.
- [x] Interfaz de autorización utilizada por el registro.
- [x] Contrato de registro de revisiones técnicas.
- [x] Validación de autorización antes del registro.
- [x] Registro de hashes y resultado de la revisión.
- [x] Consulta de existencia de una revisión.
- [x] Verificación de integridad del hash del informe.
- [x] Despliegue local de ambos contratos mediante Foundry.
- [x] Interacción entre los contratos mediante un script de Foundry.
- [x] Prueba automatizada de rechazo de un director no autorizado.
- [x] Ejecución manual en Anvil que demuestra el rechazo de una dirección no autorizada.
- [x] Ejecución manual en Anvil que demuestra el registro exitoso de una dirección autorizada.
- [x] Consulta posterior que confirma la existencia de la revisión registrada.

### Pendiente de completar

- [ ] Consolidar y registrar el informe definitivo de cobertura.
- [ ] Completar la revisión de NatSpec y calidad del código.
- [ ] Ejecutar y documentar el análisis estático con Slither.
- [ ] Revisar el conjunto completo de pruebas de autorización, revocación, integridad y duplicados.
- [ ] Desplegar ambos contratos en Sepolia.
- [ ] Verificar el código fuente de ambos contratos en el explorador.
- [ ] Registrar direcciones y hashes de transacciones públicas.
- [ ] Integrar el frontend con los contratos desplegados.
- [ ] Probar el flujo de extremo a extremo desde el frontend.
- [ ] Incorporar evidencia reproducible para la entrega académica.

## Roadmap

Luego del hito de la entrega, se propone continuar con los siguientes pasos:

1. **Piloto con talleres:** probar el flujo completo con un grupo reducido de usuarios en testnet y ajustar la interfaz según sus comentarios.
2. **Mejoras de consulta:** incorporar un historial de revisiones por referencia de vehículo, filtros por taller y fecha y una opción de consulta con código QR en el frontend y/o interfaz mobile.
3. **Gestión de informes:** integrar almacenamiento externo con acceso controlado para recuperar los informes, calcular sus hashes y comprobar su integridad mediante `verifyIntegrity`.
4. **Seguridad y escalamiento:** ampliar las pruebas de permisos y casos límite, realizar una revisión de seguridad antes de un uso real y medir el consumo de gas para evaluar una red EVM de menor costo para escalar el sistema.

## Referencias

- Repositorio de RoadProof: https://github.com/Road-Proof/RoadProof
- Foundry Book: https://book.getfoundry.sh/
- Solidity: https://docs.soliditylang.org/
- OpenZeppelin Contracts: https://docs.openzeppelin.com/contracts/
- Ethereum Sepolia: https://sepolia.etherscan.io/
