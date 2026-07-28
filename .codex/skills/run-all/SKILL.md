---
name: run-all
description: "Levanta y gestiona el entorno local completo de breastfeeding-counter en Windows: PostgreSQL con Docker Compose, migraciones Flask, API y cliente Vite. Usar cuando el usuario pida iniciar, ejecutar, levantar o detener todo el proyecto, preparar sus dependencias locales, consultar URLs/logs de desarrollo o recuperar una ejecución parcial."
---

# Run All

Arrancar el stack local en el orden correcto y dejar procesos verificables, logs y una forma
segura de detenerlos. Usar los scripts incluidos en Windows; no reescribir la secuencia a mano.

## Comprobar el plan

Ejecutar primero el modo sin cambios cuando sea útil confirmar rutas y herramientas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  .codex/skills/run-all/scripts/run_all.ps1 -Plan
```

El plan debe localizar el repositorio, Node compatible y el entorno Python. Si Docker figura como
no disponible, informar al usuario que debe instalar o iniciar Docker Desktop antes de levantar
el stack.

## Levantar todo

1. Ejecutar:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File `
     .codex/skills/run-all/scripts/run_all.ps1
   ```

2. Permitir que el script:
   - resolver Node 22 desde `.nvmrc` o NVM sin ejecutar `nvm use`;
   - crear `.env` locales desde los ejemplos cuando falten;
   - ejecutar `npm ci` y preparar `server/.venv` cuando cambien los archivos de dependencias;
   - levantar `db` mediante Docker Compose y esperar `pg_isready`;
   - aplicar `flask db upgrade`;
   - iniciar Flask y Vite en procesos ocultos separados;
   - verificar ambos servicios por HTTP antes de declarar éxito.
3. Reportar las URLs y ubicación de logs que entregue el script.
4. No afirmar que el entorno está listo si el script no confirmó ambos endpoints.

Usar `-SkipInstall` solo cuando las dependencias ya existan y se quiera omitir su comprobación.
Los metadatos, fingerprints y logs se guardan en `.run/`, que está ignorado por Git.

## Diagnosticar fallos

Leer primero:

- `.run/server.err.log`
- `.run/server.out.log`
- `.run/client.err.log`
- `.run/client.out.log`

Después comprobar `docker compose ps` y
`docker compose logs db`. No imprimir valores de `.env`. Si un puerto está ocupado por un proceso
no gestionado, no detenerlo sin identificarlo y obtener autorización.

## Detener todo

Ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  .codex/skills/run-all/scripts/stop_all.ps1
```

El script valida ejecutable y hora de inicio antes de detener cada PID. Detiene PostgreSQL sin
eliminar su volumen. Usar `-KeepDatabase` para dejar PostgreSQL activo.

## Entornos no Windows

No ejecutar los scripts PowerShell si la plataforma no soporta `Start-Process -WindowStyle`.
Reproducir el mismo orden con procesos gestionados por la herramienta disponible:

1. `docker compose up -d db` y esperar `pg_isready`.
2. Instalar dependencias desde `client/package-lock.json` y `server/requirements-dev.lock`.
3. Ejecutar migraciones desde `server/`.
4. Mantener Flask y Vite en sesiones separadas.
5. Verificar `/api/v1/health/live` y el puerto 5173.

Nunca usar `docker compose down -v`: conservar los datos locales salvo solicitud explícita.
