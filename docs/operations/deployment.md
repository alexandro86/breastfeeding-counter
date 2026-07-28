# Operación de staging y producción

## Alcance

Este documento describe la automatización preparada para desplegar:

| Entorno    | Frontend                         | API                | Base de datos     |
| ---------- | -------------------------------- | ------------------ | ----------------- |
| staging    | Vercel Preview con alias estable | Render Web Service | Render PostgreSQL |
| production | Vercel Production                | Render Web Service | Render PostgreSQL |

Los entornos no comparten bases, secretos, cookies ni tokens. Staging usa exclusivamente datos
sintéticos.

La Fase A solo prepara el repositorio. Crear cuentas, recursos, dominios, secretos o despliegues
reales requiere autorización separada.

## Flujo de promoción

```text
PR
 │
 ├─ CI: formato, lint, tipos, pruebas, contrato, build y auditorías
 │
 └─ merge a main
       │
       └─ CI verde
            │
            └─ staging automático con SHA inmutable
                 ├─ Render: build → migración → health check
                 ├─ Vercel: build → preview → smoke → alias
                 └─ smoke tests de solo lectura
                      │
                      └─ aprobación manual en GitHub
                           │
                           └─ production con el mismo SHA
                                ├─ Render: build → migración → health check
                                ├─ Vercel: build → candidato → smoke → promoción
                                └─ smoke tests de solo lectura
```

Los autodeploys de Render deben quedar desactivados. `client/vercel.json` desactiva el
autodeploy de `main`, pero conserva previews automáticas para otras ramas. De este modo, ningún
proveedor sustituye silenciosamente el commit promovido por la punta de una rama.

## Decisión sobre `render.yaml`

No se incluye un Blueprint por ahora. Todavía faltan decisiones sobre nombres, región y planes,
y sincronizar un Blueprint puede crear recursos con coste. Los dos servicios se configuran una
vez desde el Dashboard y luego GitHub Actions despliega SHA inmutables mediante la API de Render.

Se puede reconsiderar `render.yaml` cuando exista un presupuesto aprobado. Antes de sincronizarlo
se debe usar la validación de Blueprint de Render y revisar el plan de recursos resultante.

## Aprovisionamiento inicial

### 1. GitHub

1. Proteger `main`: exigir pull request, checks de CI y conversaciones resueltas.
2. Crear los environments `staging` y `production`.
3. En `production`, añadir required reviewers si el plan y la visibilidad del repositorio lo
   permiten.
4. Crear la variable de repositorio `STAGING_DEPLOYMENT_ENABLED=false`. Cambiarla a `true` solo
   después de completar toda la configuración de staging.
5. Configurar en cada environment las variables y secretos de la tabla inferior.

### 2. Vercel

1. Importar el repositorio y seleccionar `client` como Root Directory.
2. Confirmar Vite, `npm ci`, `npm run build` y `dist`.
3. Configurar `VITE_API_BASE_URL` con la URL de la API correspondiente:
   - Preview: API de staging.
   - Production: API de producción.
4. Crear un alias o dominio estable para staging y anotarlo en `VERCEL_STAGING_ALIAS`.
5. Configurar el dominio de producción.
6. Crear un token acotado para GitHub Actions y obtener los IDs de organización y proyecto.
7. Verificar que el push a `main` no produce un deployment automático. Producción solo debe
   cambiar mediante `.github/workflows/deploy-production.yml`.

### 3. Render staging

1. Crear un proyecto/environment de staging.
2. Crear PostgreSQL de staging en la región elegida.
3. Crear un Web Service Docker enlazado al repositorio:
   - Root Directory: `server`.
   - Dockerfile: `server/Dockerfile` relativo al repositorio, o `Dockerfile` desde el root
     configurado.
   - Health Check Path: `/api/v1/health/ready`.
   - Auto-Deploy: `Off`.
   - Pre-Deploy Command: `flask --app wsgi db upgrade`.
4. Configurar `DATABASE_URL` con la URL interna de PostgreSQL.
5. Configurar las demás variables del servidor con valores exclusivos de staging.
6. Crear una API key acotada y guardar su valor en el environment `staging` de GitHub.

### 4. Render production

Repetir el proceso con recursos completamente independientes:

- Environment protegido de producción en Render cuando el plan lo permita.
- PostgreSQL de producción pago y con recuperación habilitada.
- Web Service que no se suspenda.
- Auto-Deploy `Off`.
- Pre-Deploy Command `flask --app wsgi db upgrade`.
- Secretos nuevos, no copias de los de staging.
- CORS limitado al origen exacto del frontend de producción.

No habilitar usuarios reales antes de probar una restauración.

## Inventario de configuración

Los valores secretos se introducen directamente en la plataforma indicada, nunca en el chat ni
en archivos del repositorio.

| Plataforma         | Alcance     | Nombre                       | Tipo     | Propósito                                      |
| ------------------ | ----------- | ---------------------------- | -------- | ---------------------------------------------- |
| GitHub             | repositorio | `STAGING_DEPLOYMENT_ENABLED` | variable | Habilita staging automático cuando vale `true` |
| GitHub Environment | ambos       | `API_BASE_URL`               | variable | URL pública HTTPS terminada en `/api/v1`       |
| GitHub Environment | ambos       | `FRONTEND_URL`               | variable | URL pública estable del frontend               |
| GitHub Environment | staging     | `VERCEL_STAGING_ALIAS`       | variable | Dominio sin `https://` asignado al preview     |
| GitHub Environment | ambos       | `RENDER_SERVICE_ID`          | variable | Servicio Render objetivo (`srv-...`)           |
| GitHub Environment | ambos       | `RENDER_API_KEY`             | secreto  | Despliega y consulta el estado en Render       |
| GitHub Environment | ambos       | `VERCEL_TOKEN`               | secreto  | Construye y despliega mediante Vercel CLI      |
| GitHub Environment | ambos       | `VERCEL_ORG_ID`              | secreto  | Organización propietaria en Vercel             |
| GitHub Environment | ambos       | `VERCEL_PROJECT_ID`          | secreto  | Proyecto frontend en Vercel                    |
| Vercel             | Preview     | `VITE_API_BASE_URL`          | pública  | API de staging                                 |
| Vercel             | Production  | `VITE_API_BASE_URL`          | pública  | API de producción                              |
| Render Web Service | ambos       | `FLASK_ENV`                  | variable | Debe valer `production` en hosting             |
| Render Web Service | ambos       | `DATABASE_URL`               | secreto  | Conexión interna a su propia base              |
| Render Web Service | ambos       | `SECRET_KEY`                 | secreto  | Firma y seguridad de Flask                     |
| Render Web Service | ambos       | `JWT_SECRET_KEY`             | secreto  | Firma de access tokens                         |
| Render Web Service | ambos       | `FRONTEND_ORIGINS`           | variable | Orígenes HTTPS exactos, separados por coma     |
| Render Web Service | ambos       | `ACCESS_TOKEN_MINUTES`       | variable | Vida del access token                          |
| Render Web Service | ambos       | `REFRESH_TOKEN_DAYS`         | variable | Vida máxima de refresh                         |
| Render Web Service | ambos       | `LOG_LEVEL`                  | variable | Nivel de logs, inicialmente `INFO`             |

No hace falta configurar una variable de versión en Render: la plataforma proporciona
`RENDER_GIT_COMMIT` y la API la expone como `version` en liveness.

## Primer despliegue

1. Confirmar que staging contiene únicamente datos sintéticos.
2. Confirmar que todas las variables y secretos están configurados.
3. Confirmar `Auto-Deploy: Off` en ambos servicios Render.
4. Confirmar que el pre-deploy command está disponible y configurado.
5. Ejecutar CI en `main`.
6. Cambiar `STAGING_DEPLOYMENT_ENABLED` a `true`.
7. Volver a ejecutar CI o fusionar un cambio seguro para iniciar staging.
8. Verificar que el workflow informa el mismo SHA en Render, Vercel y liveness.
9. Revisar manualmente staging.
10. Ejecutar `Deploy production` desde Actions e introducir el SHA completo validado.

El workflow de producción rechaza SHA que no pertenezcan a `main` o que no tengan un workflow de
staging exitoso.

## Despliegue rutinario

1. Abrir un pull request.
2. Esperar todos los checks.
3. Revisar la preview de la rama.
4. Fusionar a `main`.
5. Esperar staging y sus smoke tests.
6. Validar el flujo funcional en staging.
7. Ejecutar manualmente producción con el SHA mostrado por staging.
8. Confirmar los smoke tests y observar errores/latencia.

## Fallos y rollback

Si falla build, migración, health check o smoke test, no promover.

Rollback de aplicación:

1. Identificar el último deploy estable.
2. Confirmar que su código es compatible con el esquema actual.
3. Restaurar ese deploy desde Render y Vercel o volver a ejecutar producción con su SHA, siempre
   que también conste como validado en staging.
4. Ejecutar smoke tests.

No revertir automáticamente migraciones destructivas. Los cambios de esquema siguen
expand/contract:

1. Expandir con tablas o columnas compatibles.
2. Desplegar código compatible con ambos esquemas.
3. Ejecutar backfill separado.
4. Retirar campos en una entrega posterior.

## Backup y restauración

Antes de una migración de riesgo:

1. Confirmar la ventana de recuperación disponible.
2. Crear una exportación lógica adicional si corresponde.
3. Registrar hora, responsable, SHA y punto de recuperación sin incluir credenciales.

Ensayo de restauración:

1. Restaurar a una base nueva y aislada.
2. Conectar una API temporal o local con acceso restringido.
3. Verificar migraciones, integridad y flujos de solo lectura.
4. Documentar duración real para definir RPO/RTO.
5. Eliminar el recurso temporal solo después de confirmar el resultado y con autorización.

Este procedimiento está documentado, pero no se considera ensayado hasta ejecutarlo realmente.

## Alertas mínimas

- Readiness inaccesible o con HTTP 503.
- Tasa sostenida de respuestas 5xx.
- Despliegue o migración fallidos.
- Saturación de conexiones o espacio de PostgreSQL.
- Aproximación a límites de uso o gasto.

Los logs y alertas no deben incluir correos, nombres, notas, tokens ni payloads completos.

## Limitaciones y costes por confirmar

- Render Free suspende el servicio tras inactividad y su PostgreSQL gratuito expira; no debe
  almacenar datos reales.
- El pre-deploy command de Render está disponible para servicios web pagos, no Free.
- Las bases Render pagas incluyen recuperación; la retención exacta depende del plan.
- Vercel Hobby está limitado a uso personal/no comercial.
- Región, dominio, planes definitivos y presupuesto requieren decisión antes de aprovisionar.
- Las tarifas deben volver a verificarse en las páginas oficiales antes de contratar.

Fuentes oficiales:

- [Despliegues y pre-deploy de Render](https://render.com/docs/deploys)
- [Health checks de Render](https://render.com/docs/health-checks)
- [Limitaciones de Render Free](https://render.com/docs/free)
- [Backups de PostgreSQL en Render](https://render.com/docs/postgresql-backups)
- [API de despliegues de Render](https://api-docs.render.com/reference/create-deploy)
- [Despliegues prebuilt de Vercel](https://vercel.com/docs/cli/deploy)
- [Configuración Git de Vercel](https://vercel.com/docs/project-configuration/git-configuration)
- [Entornos de Vercel](https://vercel.com/docs/deployments/environments)
- [GitHub Actions environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
- [GitHub Actions concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency)

## Checklist de beta con usuarios reales

- [ ] API y PostgreSQL de producción no se suspenden.
- [ ] PostgreSQL de producción tiene backups/recuperación.
- [ ] Restauración ensayada y RPO/RTO documentados.
- [ ] Secretos exclusivos por entorno y rotación definida.
- [ ] CORS y cookies verificados con dominios definitivos.
- [ ] Autenticación, CSRF, rate limits y aislamiento de cuentas probados.
- [ ] E2E de registro, login, toma y producto en verde.
- [ ] Observabilidad redacta datos personales.
- [ ] Alertas y runbooks operativos.
- [ ] Exportación y eliminación de cuenta verificadas.
- [ ] Política de privacidad, términos, soporte y revisión legal completos.
- [ ] Presupuesto, límites y alertas de gasto configurados.
