# Prompt maestro: staging y producción

Copia y pega el siguiente prompt en Codex desde la raíz de este repositorio.

```text
Quiero preparar y, cuando estén disponibles las cuentas y credenciales, desplegar
`breastfeeding-counter` con entornos separados de staging y producción.

Usa obligatoriamente la skill `init1-project` y toma como fuentes de verdad:

- `.codex/skills/init1-project/references/delivery-and-operations.md`
- `.codex/skills/init1-project/references/implementation-roadmap.md`
- `docs/adr/001-monorepo-and-hosting.md`
- `docs/adr/002-spa-authentication.md`

## Objetivo

Dejar un flujo reproducible con:

- Frontend React/Vite en Vercel.
- API Flask/Gunicorn en Render.
- PostgreSQL administrado en Render.
- Entornos `staging` y `production` totalmente aislados.
- GitHub Actions como puerta de calidad y promoción.
- Staging automático después de CI verde en `main`.
- Producción manual mediante `workflow_dispatch`, promoviendo exactamente un commit ya
  validado en staging.

## Forma de trabajo

1. Inspecciona primero el repositorio, el estado de Git y los archivos existentes. Conserva
   cambios ajenos y no sobrescribas decisiones implementadas sin explicar la diferencia.
2. Verifica en la documentación oficial vigente de Vercel, Render y GitHub las capacidades,
   comandos y restricciones que vayas a utilizar. Cita esas fuentes en el informe final.
3. Divide el trabajo en dos fases:

   - Fase A — preparación local: puedes modificar el repositorio, crear workflows,
     configuración, scripts, documentación y pruebas.
   - Fase B — aprovisionamiento y despliegue externo: antes de crear proyectos, bases de datos,
     servicios, dominios, secretos, hooks o despliegues reales, presenta el plan exacto y solicita
     autorización si todavía no existe una conexión o credencial aprobada.

4. No contrates planes, no inicies pruebas pagas y no generes cargos. Comienza con recursos
   gratuitos únicamente si el usuario autoriza su creación. Advierte que Render Free es solo
   para staging temporal y nunca para datos reales ni producción.
5. No solicites que se peguen secretos en el chat. Indica cómo guardarlos directamente en
   GitHub Environments, Vercel o Render.
6. No incluyas valores secretos en archivos, logs, artefactos, variables `VITE_*` ni salidas.
7. Si una limitación del plan gratuito impide migraciones pre-deploy, backups, disponibilidad
   o una promoción segura, no implementes una solución frágil en producción. Documenta la
   limitación y deja preparada la ruta de actualización.

## Implementación requerida

### Infraestructura y configuración

- Mantén `client/` y `server/` como aplicaciones independientes del monorepo.
- Configura Vercel con Root Directory `client`, Vite, `npm ci`, `npm run build` y salida `dist`.
- Conserva el fallback SPA.
- Define `VITE_API_BASE_URL` diferente para Preview/Staging y Production.
- Configura dos servicios Render independientes para la API, con Root Directory `server`,
  runtime Docker y health check `/api/v1/health/ready`.
- Configura dos bases PostgreSQL independientes y en la misma región que su API.
- Usa la URL interna de PostgreSQL cuando Render lo permita.
- No compartas base de datos, secretos, cookies ni tokens entre entornos.
- Usa exclusivamente datos sintéticos en staging.
- Evalúa si conviene representar la infraestructura declarativa con `render.yaml`; úsalo si
  mantiene aislamiento y no introduce secretos ni acoplamientos inseguros.

### Variables y secretos

Documenta, sin valores reales, dónde se configura cada variable:

Cliente:

- `VITE_API_BASE_URL`

Servidor:

- `FLASK_ENV=production`
- `DATABASE_URL`
- `SECRET_KEY`
- `JWT_SECRET_KEY`
- `FRONTEND_ORIGINS`
- `ACCESS_TOKEN_MINUTES`
- `REFRESH_TOKEN_DAYS`
- `LOG_LEVEL`
- una variable de versión/commit si se usa para observabilidad

Despliegue:

- credenciales o deploy hooks de Render separados por entorno
- `VERCEL_TOKEN`, `VERCEL_ORG_ID` y `VERCEL_PROJECT_ID` solo si la CLI resulta necesaria
- URLs públicas para readiness y smoke tests

Usa GitHub Environments llamados `staging` y `production`. Producción debe admitir una regla
de aprobación antes de ejecutar el despliegue.

### CI/CD

- Conserva y reutiliza `.github/workflows/ci.yml`.
- Crea `.github/workflows/deploy-staging.yml`:
  - se ejecuta únicamente después de CI exitoso para `main`;
  - despliega el commit exacto que superó CI;
  - ejecuta migraciones antes de activar la nueva API;
  - espera readiness con reintentos y timeout finito;
  - despliega o promueve el frontend de staging;
  - ejecuta smoke tests;
  - usa `concurrency` para impedir despliegues simultáneos.
- Crea `.github/workflows/deploy-production.yml`:
  - solo `workflow_dispatch`;
  - recibe o selecciona un SHA inmutable;
  - verifica que ese SHA fue desplegado y validado en staging;
  - usa el environment `production`;
  - ejecuta migraciones compatibles hacia atrás;
  - despliega API, comprueba readiness y después despliega/promueve frontend;
  - ejecuta smoke tests sin escribir datos privados;
  - impide despliegues simultáneos;
  - no usa automáticamente la punta cambiante de una rama.
- Fija las GitHub Actions de terceros a SHA de commit.
- Usa permisos mínimos en cada workflow.
- No dupliques innecesariamente las verificaciones de CI.

### Migraciones, fallos y rollback

- Las migraciones deben ejecutarse como pre-deploy command o trabajo de una sola ejecución,
  nunca al importar Flask ni de forma concurrente en cada réplica.
- Aplica la estrategia expand/contract.
- Si falla una migración, readiness o smoke test, detén la promoción.
- El rollback de aplicación debe volver al artefacto o commit anterior.
- No reviertas automáticamente una migración destructiva.
- Documenta backup previo, restauración y rollback; no afirmes que fueron ensayados si no se
  ejecutaron realmente.

### Seguridad y observabilidad

- CORS debe usar orígenes explícitos, nunca `*`.
- TLS y cookies seguras son obligatorios en entornos alojados.
- No expongas datos personales en logs o smoke tests.
- Añade un identificador de versión/commit a la operación o al health check solamente si no
  revela información sensible y está cubierto por pruebas.
- Documenta alertas mínimas para caída de readiness y errores sostenidos.

### Documentación operativa

Crea o actualiza documentación que explique:

- arquitectura y flujo de promoción;
- recursos que el usuario debe crear o autorizar;
- variables y secretos por plataforma y entorno;
- primer despliegue;
- despliegue rutinario;
- rollback;
- backup y restauración;
- costes o limitaciones pendientes de confirmar;
- checklist para habilitar una beta con usuarios reales.

Incluye una tabla clara con todos los valores que el usuario deberá proporcionar, indicando
plataforma, entorno, nombre del secreto/variable y propósito, pero nunca un valor secreto.

## Validación

Antes de dar por terminado el trabajo:

- valida la sintaxis de todos los YAML y JSON;
- ejecuta las verificaciones existentes de cliente y servidor;
- construye el frontend y la imagen Docker del servidor si el entorno lo permite;
- revisa que ningún secreto o URL privada haya quedado versionado;
- comprueba que los workflows referencien correctamente directorios, comandos, environments,
  secretos y SHA;
- informa con precisión qué fue probado localmente, qué fue desplegado realmente y qué quedó
  pendiente por falta de cuentas, planes, dominios o credenciales.

No hagas commit, push, apertura de PR, compra, creación de recursos externos ni despliegue real
sin que esas acciones estén expresamente autorizadas. Si necesitas una decisión que cambie
proveedor, autenticación, contrato API o límites principales, detente y propón un ADR.

Empieza ahora por la Fase A. Cuando termine, entrega:

1. resumen de archivos creados o modificados;
2. diagrama breve del flujo PR → CI → staging → aprobación → production;
3. verificaciones ejecutadas y resultados;
4. checklist exacto de acciones manuales que deberá realizar el usuario;
5. costes y limitaciones que todavía deban confirmarse;
6. siguiente comando o acción recomendada.
```

## Valores que conviene decidir antes de la fase externa

Reemplaza o comunica estos datos cuando llegue el momento:

- Nombre deseado de los proyectos de Vercel y Render.
- Región de Render.
- Dominio de producción, si ya existe.
- Dominios o URLs previstos para frontend y API de staging.
- Dominios o URLs previstos para frontend y API de producción.
- Si el producto seguirá siendo personal/no comercial durante la beta.
- Presupuesto mensual máximo autorizado.
- Cuenta u organización de GitHub, Vercel y Render que será propietaria de los recursos.
