# Hoja de ruta de implementación

## Índice

1. Definición de terminado
2. Hitos
3. Orden del primer incremento
4. Decisiones pendientes

## 1. Definición de terminado

Una historia está terminada cuando:

- Cumple criterios funcionales y estados de interfaz.
- Valida datos en servidor y aplica autorización por propiedad.
- Incluye migración si cambia el esquema.
- Incluye pruebas unitarias/integración y actualiza E2E si afecta un flujo crítico.
- Actualiza OpenAPI si cambia HTTP.
- Supera lint, tipos, pruebas y build.
- No introduce secretos, datos reales ni logs sensibles.
- Considera accesibilidad móvil y mensajes de error.

## 2. Hitos

### Hito 0 — Fundación

- Crear estructura `client/`, `server/`, `.github/` y `docs/`.
- Inicializar React + TypeScript + Vite.
- Inicializar Flask factory, configuración, health checks y pytest.
- Añadir PostgreSQL local, SQLAlchemy y migraciones.
- Crear `.env.example`, `.editorconfig`, `.gitignore`, comandos raíz y README operativo.
- Configurar CI de cliente y servidor.
- Escribir ADR-001 sobre monorepo/hosting y ADR-002 sobre autenticación.

Criterio: clon limpio puede instalar, levantar, probar y construir ambas aplicaciones.

### Hito 1 — Identidad y perfiles

- Acceso con Google, creación de cuenta interna, refresh, logout y sesión.
- Perfil y zona horaria.
- CRUD/archivo de bebés.
- Pruebas de aislamiento entre usuarios.

Criterio: una cuenta puede autenticarse y administrar solo sus bebés.

### Hito 2 — Toma completa

- Iniciar, recuperar visualmente y finalizar cronómetro.
- Alta manual, edición, eliminación e historial paginado.
- Restricción de sesión activa e idempotencia al finalizar.
- Dashboard con última toma y totales diarios.

Criterio: el flujo funciona tras recarga del navegador y conserva tiempos correctos.

### Hito 3 — Productos

- Catálogo personal y archivo.
- Registro de uso asociado opcionalmente a una toma.
- Historial y productos recientes.

Criterio: no existen referencias cruzadas entre cuentas y el historial sobrevive al archivo.

### Hito 4 — Preparación para beta

- Exportación y eliminación de cuenta.
- Accesibilidad, seguridad, rate limits y cabeceras.
- Observabilidad con redacción.
- Staging/producción, backups, smoke tests y runbooks.
- Política de privacidad y revisión legal según mercado.

Criterio: despliegue reproducible, restauración ensayada y flujos críticos E2E verdes.

### Hito 5 — Mejoras posteriores

- PWA y soporte offline limitado.
- Invitación de cuidadoras y permisos.
- Segmentos/cambios de lado en una toma.
- Recordatorios opt-in.
- Analítica agregada respetuosa de privacidad.

No comenzar estas mejoras antes de validar el MVP.

## 3. Orden del primer incremento

1. Crear esqueleto y comandos reproducibles.
2. Añadir health checks y conexión PostgreSQL.
3. Crear modelo/migración de usuario y bebé.
4. Implementar acceso con Google y autorización.
5. Crear pantalla de sesión y selector de bebé.
6. Añadir pruebas de integración y primer E2E.
7. Desplegar staging.

Usar commits pequeños y coherentes. No construir todas las tablas antes de tener un flujo vertical.

## 4. Decisiones pendientes

Resolver mediante ADR cuando llegue el momento:

- Dominio y países de lanzamiento.
- Proveedor transaccional de correo.
- Cookies de sesión en mismo sitio frente a access/refresh JWT entre sitios.
- Política exacta de retención y exportación.
- Servicio de errores/monitorización y presupuesto.
- Planes definitivos de Vercel/Render y región, tras revisar oferta vigente.
- Necesidad real de roles para cuidadoras.

Estas decisiones no bloquean la fundación local, salvo autenticación, que debe decidirse antes del
Hito 1.
