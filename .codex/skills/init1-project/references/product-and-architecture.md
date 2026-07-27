# Producto y arquitectura

## Índice

1. Propósito
2. Alcance del MVP
3. Experiencia de usuario
4. Arquitectura
5. Estructura del monorepo
6. Convenciones por aplicación
7. Requisitos no funcionales
8. Fuera de alcance

## 1. Propósito

`breastfeeding-counter` permite que una madre o cuidadora registre de forma rápida los momentos
de lactancia y los productos relacionados que utiliza. Debe reducir la carga mental, conservar
un historial confiable y ofrecer resúmenes descriptivos fáciles de entender.

El producto informa y organiza; no diagnostica, no reemplaza a profesionales de salud y no debe
calificar una rutina como correcta o incorrecta.

### Personas principales

- Madre lactante: registra tomas y productos, consulta historial y resúmenes.
- Cuidadora autorizada: queda como evolución posterior; el MVP tiene una cuenta propietaria.
- Administrador técnico: opera el sistema, sin acceso rutinario al contenido privado.

## 2. Alcance del MVP

### Cuenta

- Registrarse con correo y contraseña.
- Iniciar y cerrar sesión.
- Renovar sesión de manera segura.
- Solicitar y completar recuperación de contraseña.
- Configurar nombre visible, zona horaria y preferencias básicas.
- Exportar o eliminar la cuenta y sus datos.

### Perfiles de bebés

- Crear uno o más perfiles.
- Guardar nombre o alias y fecha de nacimiento opcional.
- Archivar un perfil sin borrar su historial.
- Seleccionar el perfil activo.

### Tomas

- Iniciar un cronómetro indicando lado izquierdo, derecho, ambos o no especificado.
- Pausar/cambiar de lado como mejora posterior; en MVP registrar segmentos o finalizar y editar.
- Finalizar la toma y calcular duración en el servidor.
- Añadir manualmente una toma pasada.
- Editar o eliminar una toma propia.
- Guardar notas opcionales.
- Consultar historial paginado y filtrar por bebé y rango de fechas.

### Productos

- Crear un catálogo personal: nombre, categoría, marca y notas opcionales.
- Categorías iniciales: extractor, biberón, crema, protector, bolsa/recipiente y otro.
- Registrar un uso de producto asociado opcionalmente a una toma.
- Guardar cantidad y unidad solo cuando tengan sentido; no exigirlas.
- Editar, archivar y consultar productos.

### Resúmenes

- Mostrar última toma.
- Mostrar cantidad y duración total por día.
- Mostrar distribución descriptiva por lado.
- Mostrar productos usados recientemente.
- Evitar recomendaciones clínicas o alertas médicas.

## 3. Experiencia de usuario

Diseñar primero para teléfono y uso con una mano:

- Acción primaria “Iniciar toma” visible en la pantalla inicial.
- Objetivos táctiles de al menos 44 x 44 CSS px.
- Confirmación clara de un cronómetro activo y recuperación visual al recargar.
- Formularios cortos, valores opcionales explícitos y mensajes de error accionables.
- Navegación principal: Inicio, Historial, Productos y Perfil.
- Contraste WCAG 2.2 AA, foco visible, etiquetas accesibles y soporte de teclado.
- Español como idioma inicial; preparar textos para futura internacionalización.
- Formato de fecha/hora según locale y zona horaria del perfil.

El cronómetro del cliente es solo presentación. Persistir `started_at`; calcular el tiempo
transcurrido con el reloj actual y confirmar `ended_at` en el servidor. No depender de un
contador en memoria.

## 4. Arquitectura

Usar una aplicación web desacoplada:

```text
Navegador
   |
   | HTTPS / JSON
   v
client: React + Vite (Vercel)
   |
   | /api/v1
   v
server: Flask (Render Web Service)
   |
   v
PostgreSQL administrado (Render)
```

### Principios

- SPA React responsable de presentación, accesibilidad y estado de interfaz.
- API Flask responsable de identidad, autorización, reglas, cálculo e integridad.
- PostgreSQL como única fuente de verdad.
- API REST JSON versionada; OpenAPI como contrato.
- Arquitectura de monolito modular. No introducir microservicios para el MVP.
- Trabajos asíncronos solo cuando aparezca una necesidad real; no añadir Redis inicialmente.

### Dependencias preferidas

Cliente:

- React, TypeScript y Vite.
- React Router para rutas cuando exista una versión sin vulnerabilidades conocidas; mientras la
  auditoría no esté limpia, usar navegación nativa y fallback SPA sin añadir la dependencia.
- TanStack Query para estado remoto, caché e invalidación.
- React Hook Form y Zod para formularios y validación de interfaz.
- Vitest, Testing Library y MSW para pruebas.
- Playwright para el flujo crítico extremo a extremo.
- ESLint y Prettier.

Servidor:

- Python 3.12 o versión estable compatible con el proveedor.
- Flask con factory pattern y blueprints.
- SQLAlchemy 2 y Flask-Migrate/Alembic.
- Marshmallow o Pydantic para serialización/validación; elegir uno y usarlo consistentemente.
- Flask-JWT-Extended si se adopta JWT.
- Psycopg 3 como driver PostgreSQL.
- pytest, pytest-cov, Ruff y mypy.
- Gunicorn en producción.

Fijar versiones reproducibles y habilitar actualización automatizada de dependencias.

## 5. Estructura del monorepo

```text
breastfeeding-counter/
├── .codex/skills/init1-project/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── deploy-staging.yml
│   │   └── deploy-production.yml
│   ├── CODEOWNERS
│   ├── dependabot.yml
│   └── pull_request_template.md
├── client/
│   ├── public/
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── babies/
│   │   │   ├── feedings/
│   │   │   ├── products/
│   │   │   └── dashboard/
│   │   ├── lib/
│   │   ├── routes/
│   │   ├── styles/
│   │   ├── test/
│   │   └── main.tsx
│   ├── .env.example
│   ├── package.json
│   └── vite.config.ts
├── server/
│   ├── app/
│   │   ├── api/v1/
│   │   ├── auth/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── schemas/
│   │   ├── services/
│   │   ├── extensions.py
│   │   ├── config.py
│   │   └── __init__.py
│   ├── migrations/
│   ├── tests/
│   ├── .env.example
│   ├── pyproject.toml
│   ├── Dockerfile
│   └── wsgi.py
├── docs/
│   ├── adr/
│   └── openapi.yaml
├── .editorconfig
├── .gitignore
├── Makefile
├── compose.yaml
└── README.md
```

No compartir código ejecutable entre Python y TypeScript. Compartir el contrato mediante
OpenAPI y, si resulta útil, generar tipos TypeScript desde dicho contrato.

## 6. Convenciones por aplicación

### Cliente

- Organizar por funcionalidad, no por tipo global de archivo.
- Mantener componentes de UI sin llamadas HTTP directas.
- Centralizar el cliente HTTP, errores, credenciales y URL base en `src/lib`.
- Tratar TanStack Query como fuente del estado del servidor; evitar duplicarlo en contextos.
- Reservar contexto para sesión, tema o preferencias verdaderamente globales.
- Usar variables `VITE_*` solo para valores públicos. Nunca colocar secretos en Vite.
- Ofrecer estados de carga, vacío, error y éxito en cada vista remota.

### Servidor

- Crear la app con `create_app(config_name=None)`.
- Mantener rutas delgadas: validar, invocar servicio y construir respuesta.
- Mantener transacciones y reglas en servicios.
- Encapsular consultas reutilizables en repositorios o funciones de consulta.
- Usar errores de dominio convertidos de forma central a respuestas Problem Details.
- No exponer modelos ORM directamente.
- Ejecutar migraciones como trabajo previo al despliegue, no al importar la app.

## 7. Requisitos no funcionales

- Seguridad y privacidad desde el diseño por tratarse de datos personales y potencialmente
  sensibles.
- Disponibilidad objetivo inicial: 99,5 %, sin prometer SLA público en MVP.
- Respuesta API p95 objetivo menor a 500 ms para consultas comunes bajo carga inicial.
- Páginas principales con buena experiencia móvil y presupuesto inicial de JS razonable.
- Copias de seguridad automáticas y restauración ensayada.
- Accesibilidad WCAG 2.2 AA.
- Navegadores: dos últimas versiones estables de Chrome, Safari, Firefox y Edge.
- Observabilidad sin contenido privado.

## 8. Fuera de alcance inicial

- Diagnóstico, consejo médico o puntuaciones de lactancia.
- Integración con dispositivos o historias clínicas.
- Marketplace o recomendaciones comerciales.
- Chat, red social o intercambio entre familias.
- Sincronización offline completa. Una PWA instalable puede evaluarse después del MVP.
- Facturación, suscripciones y roles administrativos complejos.
