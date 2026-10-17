# RoadProof

**Sistema de registro y verificación de integridad de revisiones técnicas vehiculares mediante blockchain Ethereum.**

RoadProof es un proyecto académico que utiliza contratos inteligentes para registrar revisiones técnicas vehiculares y permitir la verificación de la integridad de sus informes mediante hashes criptográficos.

El objetivo es proporcionar trazabilidad y evidencia verificable de los registros, reduciendo la posibilidad de modificaciones no detectadas en los resultados de las revisiones.

> Los informes completos se almacenan fuera de la blockchain. El contrato registra sus hashes y los datos necesarios para verificar su integridad.

## Tecnologías

- **Solidity:** desarrollo de contratos inteligentes.
- **Foundry:** compilación, pruebas, cobertura y herramientas de desarrollo.
- **Forge:** compilación y ejecución de pruebas.
- **Cast:** interacción con contratos y redes EVM desde la terminal.
- **Anvil:** nodo blockchain local para desarrollo.
- **OpenZeppelin Contracts:** componentes reutilizables para control de acceso.
- **Ethereum / EVM:** entorno de ejecución de los contratos inteligentes.

## Requisitos previos

- Linux, macOS o Windows mediante WSL2 con Ubuntu.
- Foundry instalado.
- Git.
- Acceso a una terminal.

Verificar la instalación de Foundry:

```bash
forge --version
cast --version
anvil --version
```

## Instalación

Clonar el repositorio y acceder al directorio del proyecto:

```bash
git clone https://github.com/Road-Proof/RoadProof.git
cd RoadProof
```

Inicializar y actualizar las dependencias Git, si corresponde:

```bash
git submodule update --init --recursive
```

Comprobar que las dependencias estén disponibles:

```bash
ls lib
```

## Estructura del proyecto

```text
roadproof/
├── src/
│   ├── RoadProofRegistry.sol
│   └── Counter.sol
├── test/
│   ├── RoadProofRegistry.t.sol
│   └── Counter.t.sol
├── script/
│   └── Counter.s.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── foundry.toml
├── .gitmodules
├── .gitignore
└── README.md
```

**Nota:** `Counter.sol`, `Counter.t.sol` y `Counter.s.sol` son archivos de ejemplo de Foundry. Se conservan durante el desarrollo y podrán eliminarse cuando se confirme que ya no son necesarios.

## Contrato principal

### `RoadProofRegistry.sol`

El contrato principal permite:

- Autorizar directores técnicos para un taller.
- Revocar la autorización de directores técnicos.
- Registrar revisiones técnicas vehiculares.
- Asociar cada revisión con el taller, el vehículo, el director técnico, el resultado y la fecha de registro.
- Verificar la integridad de un informe mediante su hash.
- Emitir eventos para facilitar la trazabilidad de las operaciones.
- Restringir las operaciones administrativas al propietario del contrato.

Los resultados admitidos son:

- `APTO`
- `CONDICIONAL`
- `RECHAZADO`

El registro de una revisión requiere que el director técnico esté autorizado para el taller correspondiente.

## Desarrollo y pruebas

Ejecutar los siguientes comandos desde la raíz del proyecto.

### 1. Compilar los contratos

```bash
forge build
```

Compila los contratos Solidity y muestra errores o advertencias del compilador.

Debe ejecutarse después de modificar contratos o dependencias.

### 2. Ejecutar todas las pruebas

```bash
forge test
```

Ejecuta las pruebas de todos los archivos de test encontrados por Foundry.

Las pruebas incluyen los casos del contrato principal y los ejemplos que todavía se conservan en el proyecto.

**Resultado esperado:** todas las pruebas deben finalizar correctamente, sin fallos.

### 3. Ejecutar únicamente las pruebas de RoadProof

```bash
forge test --match-path test/RoadProofRegistry.t.sol -vv
```

Ejecuta exclusivamente las pruebas del registro de revisiones.

La opción `-vv` muestra información adicional de las pruebas, lo que facilita identificar qué casos pasan y cuáles fallan.

Para obtener todavía más detalle:

```bash
forge test --match-path test/RoadProofRegistry.t.sol -vvv
```

### 4. Calcular la cobertura de las pruebas

```bash
forge coverage
```

Ejecuta las pruebas y calcula qué porcentaje del código está cubierto.

El informe presenta cuatro métricas principales:

- **Lines:** líneas de código ejecutadas.
- **Statements:** instrucciones ejecutadas.
- **Branches:** ramas de decisión cubiertas.
- **Funcs:** funciones cubiertas.

El requisito académico es superar el **40 % en cada métrica reportada**, verificando especialmente las métricas del contrato `RoadProofRegistry.sol`.

La cobertura global también incluye otros archivos detectados por Foundry, por lo que debe distinguirse del resultado del contrato principal.

### 5. Identificar código no cubierto

```bash
forge coverage --report debug
```

Genera un informe detallado que ayuda a identificar las partes del código que no fueron ejecutadas por las pruebas.

Se utiliza para detectar casos pendientes y decidir si es necesario agregar nuevas pruebas.

### 6. Formatear el código Solidity

```bash
forge fmt
```

Aplica el formato estándar de Foundry a los archivos Solidity compatibles.

Para comprobar el formato sin modificar los archivos:

```bash
forge fmt --check
```

Conviene ejecutar este control antes de confirmar cambios en Git.

### 7. Consultar el consumo de gas

```bash
forge snapshot
```

Genera o actualiza el archivo de referencia de consumo de gas de las pruebas.

Permite comparar el consumo entre versiones y detectar aumentos innecesarios.

**Importante:** ejecutar nuevamente este comando puede actualizar los valores de referencia. Revisar los cambios antes de confirmarlos en Git.

### 8. Ejecutar un nodo blockchain local

```bash
anvil
```

Inicia una blockchain local de desarrollo compatible con Ethereum.

Anvil muestra cuentas de prueba, claves privadas de desarrollo y datos de conexión RPC.

Se utiliza para probar despliegues e interacciones sin utilizar una red pública.

**Seguridad:** las claves proporcionadas por Anvil son únicamente para desarrollo local. Nunca deben utilizarse como claves de una billetera real ni publicarse secretos personales en el repositorio.

## Herramientas de interacción

### Cast

Cast permite consultar una red EVM, leer datos de contratos y enviar transacciones.

Consultar la ayuda:

```bash
cast --help
```

Ejemplos de comandos útiles:

```bash
cast chain-id --rpc-url http://127.0.0.1:8545
```

Consulta el identificador de la cadena local de Anvil.

```bash
cast block-number --rpc-url http://127.0.0.1:8545
```

Consulta el número del bloque actual de la red local.

Para interactuar con un contrato desplegado se necesitarán su dirección, la URL RPC y la firma o los parámetros correspondientes a la función.

## Despliegue

El despliegue del contrato principal se documentará cuando se seleccione y configure la red de destino.

Antes del despliegue se deberán definir:

- La red EVM de destino.
- La URL RPC.
- La dirección administradora del contrato.
- Las direcciones de los contratos que integren la solución.
- El procedimiento de verificación del código fuente.
- Las transacciones de prueba que demuestren el funcionamiento del flujo principal.

No se deben incorporar claves privadas, frases semilla, tokens de API ni otros secretos al repositorio.

Las variables de entorno y la configuración de despliegue se documentarán cuando se implemente ese proceso.

## Calidad y seguridad

Antes de la entrega se deben verificar los siguientes puntos:

- Compilación sin errores.
- Pruebas automatizadas aprobadas.
- Cobertura superior al mínimo académico requerido en todas las métricas.
- Pruebas de operaciones correctas y de errores esperados.
- Documentación NatSpec completa.
- Uso de errores personalizados de Solidity cuando corresponda.
- Eventos para las operaciones relevantes.
- Control de acceso y permisos administrativos.
- Revisión de consumo de gas y almacenamiento.
- Análisis estático con Slither.
- Revisión y justificación de advertencias o hallazgos relevantes.

## Documentación oficial

- Foundry Book: https://book.getfoundry.sh/
- Solidity: https://docs.soliditylang.org/
- OpenZeppelin Contracts: https://docs.openzeppelin.com/contracts/
- GitHub de RoadProof: https://github.com/Road-Proof/RoadProof

## Estado de la implementación

El proyecto se encuentra en desarrollo.

La compilación y las pruebas del contrato principal se están utilizando para validar progresivamente el comportamiento del registro y la verificación de integridad.

Los siguientes puntos se completarán a medida que avance la implementación:

- [ ] Completar la revisión de cobertura y los casos de prueba pendientes.
- [ ] Revisar calidad y seguridad del contrato.
- [ ] Implementar y probar la interacción entre contratos.
- [ ] Desplegar y verificar los contratos en una red EVM.
- [ ] Registrar enlaces de los contratos y transacciones reales.
- [ ] Integrar el frontend con los contratos desplegados.
- [ ] Documentar el flujo de uso de extremo a extremo.
- [ ] Preparar la demostración final del proyecto.
