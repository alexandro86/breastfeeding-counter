---
name: init1-project
description: Base de producto y arquitectura para crear, inicializar o evolucionar breastfeeding-counter como monorepo con React y Vite en client, Python y Flask en server, PostgreSQL, GitHub Actions y despliegue en Vercel y Render. Usar al diseñar el MVP, generar el esqueleto del repositorio, modelar datos o API, implementar funcionalidades, preparar pruebas, CI/CD, seguridad, observabilidad o hosting de este proyecto.
---

# Init1 Project

Usar esta skill como fuente de verdad inicial de `breastfeeding-counter`. Mantener las
decisiones existentes salvo que el usuario solicite cambiarlas o una restricción técnica
demuestre que deben revisarse.

## Flujo de trabajo

1. Leer [product-and-architecture.md](references/product-and-architecture.md) para cualquier
   tarea de producto, estructura del monorepo o frontend/backend.
2. Leer [data-and-api.md](references/data-and-api.md) antes de crear migraciones, modelos,
   endpoints, validaciones o clientes HTTP.
3. Leer [delivery-and-operations.md](references/delivery-and-operations.md) antes de configurar
   entornos, Docker, GitHub Actions, hosting, secretos, seguridad u observabilidad.
4. Leer [implementation-roadmap.md](references/implementation-roadmap.md) para iniciar el
   repositorio, seleccionar el siguiente hito o evaluar si una entrega está terminada.
5. Inspeccionar el estado real del repositorio antes de modificarlo. No sobrescribir decisiones
   ya implementadas sin identificar la diferencia y su impacto.
6. Implementar incrementos verticales pequeños: migración/modelo, servicio, endpoint, interfaz
   y pruebas del mismo caso de uso.
7. Ejecutar las verificaciones aplicables de cliente y servidor. Informar qué se verificó y qué
   quedó pendiente.
8. Actualizar estas referencias cuando una decisión arquitectónica aceptada cambie.

## Reglas no negociables

- Conservar `client/` y `server/` como aplicaciones independientes dentro de un monorepo.
- Mantener reglas de negocio en servicios del servidor, no en rutas Flask ni en componentes.
- Tratar fechas persistidas como UTC y convertirlas a la zona horaria del usuario al presentar.
- Aplicar autorización por propiedad en toda lectura o escritura de datos de una madre.
- No registrar tokens, contraseñas, notas de lactancia ni otros datos sensibles en logs.
- Versionar el contrato HTTP bajo `/api/v1`.
- Crear cambios de esquema solo mediante migraciones.
- Añadir pruebas a toda corrección de bug y a toda regla de negocio relevante.
- No presentar métricas como consejo médico ni inferir diagnósticos.
- Cumplir la estrategia de ramas, controles y despliegues definida en operaciones.

## Criterio para resolver ambigüedades

Priorizar, en orden: privacidad y seguridad, integridad del historial, accesibilidad móvil,
simplicidad operativa, velocidad de entrega y optimización. Registrar como ADR cualquier cambio
que afecte proveedor de hosting, autenticación, contrato API, esquema central o límites entre
cliente y servidor.
