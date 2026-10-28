# Análisis estático de RoadProof con Slither

Revisión del 27 de octubre de 2026 sobre el árbol de trabajo local. Se analizaron `RoadProofRegistry`, `RoadProofAuthorization`, su interfaz y las tres dependencias de OpenZeppelin utilizadas. Slither produjo **4 hallazgos: 1 medio, 1 bajo y 2 informativos**. Todos tienen una resolución documentada; **no quedan hallazgos de esta revisión pendientes de corrección**.

La revisión complementaria del compilador identificó `SOL-2026-7`. Se actualizó Solidity de **0.8.37 a 0.8.38** y se repitieron Slither y las pruebas. Las **38 pruebas pasan**, el formato es correcto y las firmas públicas de ambos contratos se mantienen iguales.

## D. Análisis estático con Slither

- [x] Se ejecutó Slither sobre al menos el contrato principal del flujo del proyecto: `RoadProofRegistry`, junto con `RoadProofAuthorization`.
- [x] Los hallazgos que requerían corrección fueron corregidos. Los cuatro avisos de Slither no requieren cambios funcionales; se corrigió la versión del compilador tras contrastar sus errores conocidos.
- [x] Los hallazgos que permanecen están identificados como aceptados o falsos positivos, con el origen en dependencias indicado cuando corresponde.
- [x] Todo hallazgo aceptado tiene una breve justificación técnica.
- [x] No quedó pendiente un problema relevante de seguridad u optimización identificado en esta revisión que requiriera corrección.

La evidencia final se actualizó después de sustituir el indicador de existencia por una consulta al hash almacenado y de añadir las pruebas de regresión correspondientes.

## Alcance y evidencia

Slither **0.11.6**, con `crytic-compile` **0.4.2** y Forge **1.8.3**, ejecutó sus **102 detectores predeterminados** sobre 6 contratos e interfaces. No se excluyeron detectores, severidades ni rutas de dependencias. El adaptador de Foundry excluye de la compilación de Slither los directorios `test/` y `script/`; el alcance es el código de producción importado desde `src/`. Las pruebas se ejecutaron por separado con `forge test`.

La compilación final usa `0.8.38+commit.1835d247`, EVM `cancun` y optimizador habilitado con 200 ejecuciones. OpenZeppelin corresponde al commit `cab19933c33c2ad1d4c7a84864a3601dddfd16f3`, cuyo paquete declara la versión 5.7.0.

| Evidencia | Contenido |
| --- | --- |
| [before.json](before.json) | Salida original de Slither con Solidity 0.8.37. |
| [after.json](after.json) | Salida final completa de Slither con Solidity 0.8.38. |
| [slither-output.txt](slither-output.txt) | Salida de consola de la ejecución final y comandos de compilación. |
| [forge-test.txt](forge-test.txt) | Compilación y ejecución final de las 38 pruebas. |
| [manifest.json](manifest.json) | Versiones, commits, hashes SHA-256 de fuentes y configuración, compiladores efectivos, hashes de ABI y resultados antes y después. |
| [requirements.txt](requirements.txt) | Versiones fijadas de Slither y su adaptador de compilación. |

El análisis corresponde a archivos locales, incluidos sus cambios sin commit; los hashes del manifiesto identifican exactamente las fuentes analizadas. La salida final contiene `success: true` y `error: null`, y se comprobó además que el build-info y los metadatos de los contratos usan Solidity 0.8.38. Esta comprobación adicional evita confundir artefactos antiguos con una compilación nueva si Foundry falla.

## Corrección del compilador

**Corregido: `SOL-2026-7`, `YulOptimizerKnowledgeBaseStaleBookkeeping`.** El registro oficial incluye Solidity 0.8.37 entre las versiones afectadas y sitúa la corrección en 0.8.38, publicada el 22 de octubre de 2026. El fallo puede hacer que el optimizador reutilice valores obsoletos o elimine escrituras necesarias. [Lista oficial de errores](https://docs.soliditylang.org/en/latest/bugs.html), [errores por versión](https://raw.githubusercontent.com/ethereum/solidity/develop/docs/bugs_by_version.json).

RoadProof compila con optimización habilitada. No se demostró una explotación ni una compilación incorrecta específica de estos contratos; se eliminó la exposición a ese fallo fijando `solc_version = "0.8.38"` en [foundry.toml](../../foundry.toml). Se conservaron EVM y parámetros de optimización. Este problema se encontró al contrastar el compilador con el registro oficial; **no forma parte de los cuatro resultados emitidos por Slither**.

## Clasificación de los hallazgos restantes

Los identificadores abreviados corresponden al campo `id` de `after.json`; cada detector produjo un único resultado.

| Detector e identificador | Severidad / confianza | Ubicación | Resolución |
| --- | --- | --- | --- |
| `unused-return` · `9ef209ac2e6b` | Media / media | Constructor de `RoadProofRegistry`, líneas 100–118 | Aceptado: consulta deliberada de compatibilidad. |
| `missing-zero-check` · `268f1a421508` | Baja / media | OpenZeppelin `Ownable2Step.transferOwnership`, líneas 43–44 | Falso positivo de seguridad en una dependencia: cero cancela la transferencia pendiente. |
| `pragma` · `86fbbfb685a8` | Informativa / alta | Pragmas de los 3 archivos de `src/` y los 3 archivos importados de OpenZeppelin | Aceptado: restricciones compatibles con un único compilador fijado. |
| `solc-version` · `3475c73a0288` | Informativa / alta | Pragmas `^0.8.20` de OpenZeppelin | Falso positivo para la compilación evaluada: los errores enumerados están corregidos en el compilador utilizado. |

### Retorno ignorado en el constructor

La llamada a `isAuthorized(bytes32(uint256(1)), address(this))` comprueba que el contrato configurado responde a la consulta. El registro todavía no necesita autorización como director técnico: un resultado `false` es válido y no debe impedir el despliegue. Exigir `true` alteraría el propósito de esa comprobación y rechazaría el despliegue normal con un contrato de autorizaciones vacío.

La autorización efectiva sí se comprueba en `registerInspection`: se consulta el taller solicitado y `msg.sender`, y un resultado `false` revierte antes de escribir el registro. La dirección del contrato de autorización es `immutable`. Se acepta únicamente este retorno ignorado del constructor; no se desactiva el detector para otras llamadas. La comprobación de interfaz no certifica la confiabilidad de cualquier contrato elegido al desplegar.

Evidencia: `setUp` de `RoadProofRegistryTest` despliega el registro con autorizaciones vacías; pasan `testUnauthorizedDirectorCannotRegisterInspection`, `testRevokedDirectorCannotRegisterInspection`, `testRegistryQueriesExternalAuthorization` y `testConstructorRejectsIncompatibleContract`. [Pruebas del registro](../../test/RoadProofRegistry.t.sol), [descripción del detector](https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return).

### Dirección cero en la transferencia de propiedad

`Ownable2Step.transferOwnership(address(0))` cambia el propietario pendiente a cero, sin cambiar el propietario actual. Es el mecanismo documentado para cancelar una transferencia. La aceptación comprueba al propietario pendiente y RoadProof deshabilita `renounceOwnership`, por lo que esta operación no abandona la administración. Se revisó la dependencia y no se considera fuera de alcance únicamente por su procedencia. [Documentación de OpenZeppelin](https://docs.openzeppelin.com/contracts/5.x/api/access#Ownable2Step-transferOwnership-address-).

Evidencia: pasan `testOwnerCanCancelPendingTransferWithoutRenouncingOwnership`, `testOnlyPendingOwnerCanAcceptOwnership` y `testOwnerCannotRenounceOwnershipAndCanStillManageDirectors`. [Pruebas de autorización](../../test/RoadProofAuthorization.t.sol).

### Diferencias entre pragmas

Los contratos propios declaran `^0.8.24` y OpenZeppelin declara `^0.8.20`. Ambas restricciones admiten 0.8.38. Foundry compila el conjunto con la versión exacta fijada en `foundry.toml`, confirmada en los artefactos; no se mezclan compiladores en esta ejecución. Se acepta la diferencia de restricciones para conservar los archivos originales de la dependencia. Esta justificación requiere mantener el compilador fijado y repetir la revisión al cambiarlo.

### Aviso de versión en OpenZeppelin

Slither enumera `VerbatimInvalidDeduplication`, `FullInlinerNonExpressionSplitArgumentEvaluationOrder` y `MissingSideEffectsOnSelectorAccess` por el rango `^0.8.20`. Los tres fueron corregidos, respectivamente, en 0.8.23, 0.8.21 y 0.8.21; la compilación real usa 0.8.38. El aviso permanece en la evidencia sin modificar los pragmas de OpenZeppelin. [Registro oficial de correcciones](https://docs.soliditylang.org/en/latest/bugs.html).

La clasificación se limita a esos errores y a la configuración registrada. El problema adicional `SOL-2026-7` recibió la corrección descrita arriba.

## Reproducción

Desde la raíz del repositorio, con Foundry, los submódulos inicializados, Python 3.14 y `uv` disponibles:

```bash
uv venv --python 3.14 --cache-dir .tools/uv-cache .tools/slither-venv
uv pip install --python .tools/slither-venv/bin/python --cache-dir .tools/uv-cache -r security/slither/requirements.txt
forge build --build-info --force
.tools/slither-venv/bin/slither . --json - > .tools/slither-current.json
forge test
forge fmt --check
```

Detenerse si `forge build` falla. El comando con `--json -` conserva una salida nueva en `.tools/`, sin reemplazar la evidencia de esta revisión. Slither devuelve **255** mientras existan los avisos documentados: ese código no es una ejecución sin hallazgos ni basta por sí solo para distinguir hallazgos de errores. Revisar la salida de compilación y los campos `success`, `error` y `results.detectors` del JSON, junto con la versión efectiva del compilador.

En la validación final, `forge test` terminó con código 0 y **38 aprobadas, 0 fallidas, 0 omitidas**; `forge fmt --check` terminó con código 0. La compilación puede emitir una advertencia de escritura de caché de firmas por los permisos del entorno local; no es un diagnóstico del compilador Solidity.

Las aceptaciones corresponden a estos resultados y fuentes concretas. Si cambian los contratos, las dependencias o la configuración de compilación, se debe ejecutar nuevamente el análisis y revisar cada resultado nuevo.
