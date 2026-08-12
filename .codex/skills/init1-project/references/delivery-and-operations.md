# Entrega y operaciones

## Índice

1. Estrategia de entornos
2. Desarrollo local
3. GitHub y CI
4. Hosting
5. CD
6. Configuración y secretos
7. Seguridad
8. Observabilidad y continuidad

## 1. Estrategia de entornos

Usar tres entornos:

| Entorno | Cliente | API | Base de datos |
|---|---|---|---|
| local | Vite local | Flask local | PostgreSQL en Docker |
| staging | Vercel Preview/Staging | Render staging | Render PostgreSQL staging |
| production | Vercel Production | Render production | Render PostgreSQL production |

No compartir base de datos, secretos ni cookies entre staging y producción. Usar datos sintéticos
en staging.

## 2. Desarrollo local

- Levantar PostgreSQL mediante `compose.yaml`.
- Ejecutar Vite y Flask como procesos locales con recarga.
- Proporcionar `.env.example` sin secretos en `client/` y `server/`.
- Ofrecer comandos raíz estables, preferentemente mediante `Makefile`:
  `make setup`, `make dev`, `make test`, `make lint`, `make migrate`.
- Sembrar únicamente datos ficticios mediante comando explícito.

Variables mínimas:

Cliente:

```dotenv
VITE_API_BASE_URL=http://localhost:5000/api/v1
```

Servidor:

```dotenv
FLASK_ENV=development
DATABASE_URL=postgresql+psycopg://...
SECRET_KEY=...
JWT_SECRET_KEY=...
FRONTEND_ORIGINS=http://localhost:5173
ACCESS_TOKEN_MINUTES=15
REFRESH_TOKEN_DAYS=30
```

Añadir proveedor de correo y DSN de errores solo al implementar esas funciones.

## 3. GitHub y CI

Usar ramas de vida corta y pull requests hacia `main`. Proteger `main`:

- Prohibir push directo.
- Exigir al menos una aprobación cuando haya equipo.
- Exigir conversaciones resueltas.
- Exigir checks de CI.
- Exigir rama actualizada o merge queue cuando aumente la concurrencia.

### `ci.yml`

Activar en pull requests y pushes a `main`. Usar filtros de paths sin omitir controles raíz.
Cancelar ejecuciones antiguas del mismo PR.

Trabajos:

1. `client-quality`
   - Instalar Node desde `.nvmrc`/`package.json`.
   - Usar `npm ci`.
   - Ejecutar lint, chequeo TypeScript, pruebas con cobertura y build.
2. `server-quality`
   - Instalar Python según `.python-version`.
   - Instalar dependencias bloqueadas.
   - Ejecutar Ruff, mypy y pytest con cobertura.
   - Levantar PostgreSQL como service container para pruebas de integración.
3. `contract`
   - Validar `docs/openapi.yaml`.
   - Detectar tipos generados desactualizados cuando existan.
4. `security`
   - Ejecutar análisis de dependencias y análisis estático apropiado.
5. `e2e`
   - Ejecutar Cypress para login, iniciar/finalizar toma y registrar producto.
   - Puede quedar para `main` al inicio si el costo de PR es excesivo.

Fijar acciones de terceros a SHA de commit. Configurar Dependabot para npm, pip y GitHub Actions.
No subir reportes que contengan datos reales.

## 4. Hosting

### Cliente: Vercel

Crear un proyecto apuntando al repositorio:

- Root Directory: `client`.
- Framework preset: Vite.
- Build command: `npm run build`.
- Output directory: `dist`.
- Install command: `npm ci`.
- Definir `VITE_API_BASE_URL` por entorno.
- Configurar fallback SPA hacia `index.html`.
- Asignar dominio de producción, por ejemplo `app.<dominio>`.
- Mantener previews por PR para validar interfaz.

Vercel es adecuado para assets estáticos, CDN, previews y rollback rápido del frontend.

### API: Render Web Service

Desplegar `server/` como servicio Docker:

- Root Directory: `server`.
- Health check: `/api/v1/health/ready`.
- Ejecutar Gunicorn enlazado a `$PORT`, con timeout y workers configurados según memoria.
- Política de reinicio automática.
- Dominio de producción, por ejemplo `api.<dominio>`.
- Instancia sin suspensión para producción si el producto necesita registro inmediato.

El `Dockerfile` debe usar imagen slim fijada, usuario no root, instalación reproducible, capas
pequeñas y un comando de arranque explícito.

### Base de datos: Render PostgreSQL

- Crear una instancia independiente por entorno en la misma región que la API.
- Usar la URL interna desde la API.
- Habilitar backups automáticos con retención acorde al plan.
- Activar alta disponibilidad cuando el uso/criticidad lo justifique.
- Restringir conexiones externas.
- Mantener pool pequeño y definir `pool_pre_ping`.

Render reduce complejidad al alojar API y base en la misma plataforma/red. Revisar precios,
retención y disponibilidad regional antes del lanzamiento; los planes cambian.

## 5. CD

GitHub Actions es la puerta de entrega.

### Staging

- Activar después de CI exitoso en `main`.
- Desplegar primero la API de staging mediante la API de Render, indicando el SHA exacto y con
  los autodeploys del servicio desactivados.
- Ejecutar migraciones con un Render pre-deploy command o job de una sola ejecución.
- Esperar health check.
- Desplegar el cliente de staging desde el checkout del mismo SHA mediante Vercel CLI.
- Ejecutar smoke tests contra URLs de staging.

### Producción

- Activar manualmente con `workflow_dispatch` sobre un commit ya validado en staging.
- Usar GitHub Environment `production` con aprobación y secretos propios.
- Ejecutar migraciones compatibles hacia atrás antes de promover código.
- Desplegar API, comprobar readiness y luego desplegar cliente.
- Ejecutar smoke tests sin escribir datos privados.
- Crear GitHub Release/tag semántico cuando corresponda.

Secretos esperados en GitHub Environments:

- `RENDER_API_KEY` con permisos acotados y el identificador no secreto `RENDER_SERVICE_ID`.
- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` si se usa CLI.
- URLs públicas de smoke tests sin secretos.

No permitir dos despliegues simultáneos al mismo entorno; usar `concurrency`.

### Migraciones y rollback

Aplicar expand/contract:

1. Añadir columnas/tablas compatibles.
2. Desplegar código capaz de convivir con ambos esquemas.
3. Migrar/backfill de manera separada.
4. Retirar campos en una entrega posterior.

Rollback de aplicación: promover el artefacto/commit anterior. No intentar revertir una migración
destructiva automáticamente. Tomar backup antes de cambios de alto riesgo y ensayar restauración.

## 6. Configuración y secretos

- GitHub almacena secretos de despliegue; Vercel y Render almacenan secretos de ejecución.
- Usar claves diferentes por entorno y rotarlas.
- Nunca colocar secretos en `VITE_*`, repositorio, imagen Docker, logs o artefactos.
- Validar configuración requerida al arrancar y fallar con mensaje sin revelar valores.
- Mantener `SECRET_KEY` y claves JWT largas, aleatorias e independientes.
- Definir dominios/cookies/CORS por lista explícita, no con `*`.

## 7. Seguridad

- Hash de contraseñas con Argon2id o bcrypt y parámetros actuales.
- Rate limiting en login, registro, refresh y recuperación.
- Rotación y detección de reutilización de refresh tokens.
- TLS obligatorio y cookies `Secure` en producción.
- Cabeceras CSP, HSTS, `X-Content-Type-Options`, `Referrer-Policy` y políticas de permisos.
- Consultas parametrizadas mediante ORM; validar tamaño y tipo de todos los campos.
- Autorización por propiedad incluso si el UUID es difícil de adivinar.
- Responder 404 cuando convenga no revelar existencia de recursos ajenos.
- Auditoría técnica mínima para login, exportación y borrado, sin contenido sensible.
- Política de privacidad, términos, consentimiento y canal de soporte antes del uso público.
- Revisar obligaciones legales con asesoría según países objetivo; no asumir cumplimiento por
  implementar medidas técnicas.

## 8. Observabilidad y continuidad

- Logs JSON con timestamp, nivel, entorno, versión, ruta, estado, latencia y `request_id`.
- Propagar `request_id` entre navegador y Flask cuando sea seguro.
- Capturar excepciones con un servicio como Sentry, aplicando redacción de datos.
- Métricas: tasa de errores, p95, salud DB, despliegues fallidos y saturación.
- Alertar sobre caída de readiness, errores sostenidos y espacio/conexiones de DB.
- No incluir correo, nombres, notas, tokens ni payloads completos.
- Probar restauración de backup periódicamente y documentar RPO/RTO antes del lanzamiento.
- Mantener runbook para incidente, rollback, credenciales comprometidas y restauración.
