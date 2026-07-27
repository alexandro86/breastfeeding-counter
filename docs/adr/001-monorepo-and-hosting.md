# ADR-001: monorepo y estrategia de hosting

- Estado: aceptada
- Fecha: 2026-07-27

## Contexto

El cliente y la API cambian juntos durante el MVP, pero tienen runtimes, ciclos de build y
necesidades de escalado diferentes. El equipo necesita una entrega simple y previews del cliente
sin operar infraestructura propia.

## Decisión

Mantener un monorepo con aplicaciones independientes:

- `client/`: React, TypeScript y Vite; despliegue en Vercel.
- `server/`: Flask y Gunicorn en un Web Service de Render.
- PostgreSQL administrado en Render, en la misma región que la API.
- GitHub Actions como puerta de calidad y promoción.
- Tres entornos aislados: local, staging y producción.

La comunicación se realiza mediante una API JSON versionada en `/api/v1` y documentada con
OpenAPI. No se comparten módulos ejecutables entre TypeScript y Python.

## Consecuencias

- Un pull request puede revisar cambios de interfaz y contrato en conjunto.
- Cliente y servidor se despliegan y escalan de forma independiente.
- CORS, cookies y URLs deben configurarse por entorno.
- Vercel y Render introducen dependencia de proveedor, mitigada con una SPA estática, un
  contenedor OCI y PostgreSQL estándar.
- Cambiar proveedores o separar repositorios requiere un ADR nuevo.

## Nota de implementación

En el Hito 0 se usa navegación nativa con fallback SPA. React Router se retiró porque las
versiones disponibles el 2026-07-27 no permitían una auditoría npm limpia. Se reintroducirá
cuando haya una versión corregida y la complejidad de rutas lo justifique.
