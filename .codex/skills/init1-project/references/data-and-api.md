# Datos y API

## Índice

1. Reglas generales
2. Modelo de datos
3. Contrato HTTP
4. Endpoints del MVP
5. Reglas de negocio
6. Errores y paginación
7. Evolución del contrato

## 1. Reglas generales

- Usar UUID como identificador público.
- Guardar timestamps como `timestamptz` en UTC.
- Incluir `created_at` y `updated_at` donde exista edición.
- Usar borrado real solo cuando el usuario elimina una toma o solicita eliminar su cuenta;
  archivar catálogos mediante `archived_at`.
- Definir claves foráneas, restricciones `CHECK`, unicidad e índices en PostgreSQL.
- No confiar únicamente en validación del cliente.
- No retornar hashes, tokens internos ni datos de otras cuentas.

## 2. Modelo de datos

### users

| Campo | Tipo | Regla |
|---|---|---|
| id | uuid | PK |
| email | citext/varchar | único, normalizado, requerido |
| display_name | varchar(120) | requerido |
| timezone | varchar(64) | IANA, por defecto `UTC` |
| is_active | boolean | por defecto true |
| created_at | timestamptz | requerido |
| updated_at | timestamptz | requerido |

Usar extensión `citext` si el proveedor la permite; si no, índice único sobre `lower(email)`.
El correo es un atributo de contacto verificado, no la clave canónica de identidad.

### external_identities

| Campo | Tipo | Regla |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users, requerido |
| provider | varchar(32) | `google` en el MVP |
| issuer | varchar(255) | emisor OpenID Connect, requerido |
| subject | varchar(255) | sujeto estable del proveedor, requerido |
| email_at_link | varchar | correo verificado al vincular, informativo |
| created_at | timestamptz | requerido |
| updated_at | timestamptz | requerido |

Crear unicidad sobre `(issuer, subject)` y sobre `(user_id, provider)`. No vincular ni fusionar
cuentas automáticamente usando únicamente el correo.

### babies

| Campo | Tipo | Regla |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users, requerido |
| name | varchar(120) | requerido |
| birth_date | date | opcional, no futura |
| archived_at | timestamptz | opcional |
| created_at | timestamptz | requerido |
| updated_at | timestamptz | requerido |

Índice `(user_id, archived_at)`.

### feeding_sessions

| Campo | Tipo | Regla |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users, requerido |
| baby_id | uuid | FK babies, requerido |
| started_at | timestamptz | requerido |
| ended_at | timestamptz | opcional mientras está activa |
| side | enum/text | `left`, `right`, `both`, `unspecified` |
| notes | text | opcional, longitud limitada |
| created_at | timestamptz | requerido |
| updated_at | timestamptz | requerido |

Restricciones: `ended_at >= started_at`; una sesión activa tiene `ended_at IS NULL`.
Crear índice `(user_id, baby_id, started_at DESC)`. Impedir más de una sesión activa por bebé
y usuario con índice único parcial sobre `(user_id, baby_id) WHERE ended_at IS NULL`.

No persistir `duration_seconds`: derivarla de `ended_at - started_at` para evitar divergencias.

### products

| Campo | Tipo | Regla |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users, requerido |
| name | varchar(160) | requerido |
| category | enum/text | catálogo controlado |
| brand | varchar(160) | opcional |
| notes | text | opcional |
| archived_at | timestamptz | opcional |
| created_at | timestamptz | requerido |
| updated_at | timestamptz | requerido |

Índice `(user_id, archived_at, name)`.

### product_usages

| Campo | Tipo | Regla |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users, requerido |
| product_id | uuid | FK products, requerido |
| feeding_session_id | uuid | FK feeding_sessions, opcional |
| used_at | timestamptz | requerido |
| quantity | numeric(10,2) | opcional, mayor que 0 |
| unit | varchar(32) | opcional si no hay cantidad |
| notes | text | opcional |
| created_at | timestamptz | requerido |
| updated_at | timestamptz | requerido |

Índice `(user_id, used_at DESC)`. Verificar que producto, toma y uso pertenezcan al mismo usuario.

### Sesiones

Guardar para las sesiones de autenticación una representación hasheada del refresh token,
usuario, familia, expiración, rotación y revocación. El MVP no almacena contraseñas locales ni
tokens de recuperación de contraseña.

## 3. Contrato HTTP

Base: `/api/v1`. JSON en UTF-8. Usar nombres `snake_case` para coincidir con Python y documentar
la elección en OpenAPI.

Autenticación preferida para SPA en dominios distintos:

- Access token de vida corta enviado en `Authorization: Bearer`.
- Refresh token rotatorio en cookie `HttpOnly`, `Secure`, `SameSite=None` en producción.
- Protección CSRF en operaciones de refresh/logout basadas en cookie.
- Access token solo en memoria, no en `localStorage`.
- CORS limitado exactamente a los orígenes permitidos y credenciales habilitadas.

Si se puede servir API y web bajo un mismo sitio, preferir cookies seguras de sesión para reducir
complejidad. Documentar cualquier cambio mediante ADR.

Formato de timestamps: ISO 8601 con offset, normalizado a `Z` al responder.

## 4. Endpoints del MVP

### Sistema

- `GET /health/live`: proceso vivo, sin consultar dependencias.
- `GET /health/ready`: comprueba conexión a PostgreSQL.

### Autenticación

- `POST /auth/google` para validar la identidad Google y crear o recuperar la cuenta interna
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /me`
- `PATCH /me`
- `DELETE /me`
- `GET /me/export`

Google OpenID Connect es el único proveedor del MVP. Validar la prueba de identidad en el servidor
y vincular por `(issuer, subject)`, no solo por correo. Solicitar únicamente `openid`, `email` y
`profile`.

### Bebés

- `GET /babies`
- `POST /babies`
- `GET /babies/{baby_id}`
- `PATCH /babies/{baby_id}`
- `DELETE /babies/{baby_id}` para archivar

### Tomas

- `GET /feedings?baby_id=&from=&to=&cursor=&limit=`
- `POST /feedings` para alta manual o inicio con `ended_at=null`
- `GET /feedings/{feeding_id}`
- `PATCH /feedings/{feeding_id}` para corregir campos permitidos
- `POST /feedings/{feeding_id}/finish` con `ended_at`
- `DELETE /feedings/{feeding_id}`

Hacer idempotente `finish`: repetir con el mismo final retorna el recurso; un final incompatible
devuelve conflicto.

### Productos

- `GET /products?include_archived=false`
- `POST /products`
- `GET /products/{product_id}`
- `PATCH /products/{product_id}`
- `DELETE /products/{product_id}` para archivar
- `GET /product-usages?from=&to=&cursor=&limit=`
- `POST /product-usages`
- `PATCH /product-usages/{usage_id}`
- `DELETE /product-usages/{usage_id}`

### Resumen

- `GET /dashboard/summary?baby_id=&date=`

Responder última toma, sesión activa, totales del día, distribución por lado y productos
recientes. Calcular límites del día con la zona horaria del usuario y consultar en UTC.

## 5. Reglas de negocio

- Comprobar que todo `baby_id`, `product_id` y `feeding_session_id` pertenece al usuario autenticado.
- No permitir inicio futuro más allá de una tolerancia pequeña de reloj; los registros manuales
  futuros son inválidos.
- Limitar una toma a una duración razonable configurable; devolver validación, no corregirla en
  silencio.
- Permitir editar historial, dejando `updated_at` como indicio de corrección.
- Rechazar el archivo de un bebé con sesión activa hasta finalizarla o cancelarla.
- Impedir asociar usos a productos archivados en nuevas operaciones; conservar asociaciones
  históricas existentes.
- Eliminar una toma sin eliminar necesariamente el uso: usar `ON DELETE SET NULL`.
- Eliminar cuenta en una transacción o mediante proceso verificable, revocando sesiones.

## 6. Errores y paginación

Usar `application/problem+json`, inspirado en RFC 9457:

```json
{
  "type": "https://breastfeeding-counter.example/problems/validation-error",
  "title": "Datos inválidos",
  "status": 422,
  "detail": "Revisa los campos indicados.",
  "errors": {
    "started_at": ["No puede estar en el futuro."]
  },
  "request_id": "..."
}
```

Estados principales: 400 sintaxis, 401 sin autenticación, 403 sin autorización, 404 recurso no
visible, 409 conflicto de estado, 422 validación y 429 límite.

Preferir paginación por cursor estable con orden `(started_at DESC, id DESC)` o
`(used_at DESC, id DESC)`. Limitar `limit` a 100 y usar 20 por defecto.

## 7. Evolución del contrato

- Mantener `docs/openapi.yaml` actualizado en el mismo cambio que modifica endpoints.
- Validar OpenAPI en CI.
- Generar tipos del cliente cuando el contrato se estabilice.
- Hacer cambios aditivos dentro de `v1`; crear nueva versión para rupturas inevitables.
- Añadir pruebas de contrato para serialización, autorización, errores y paginación.
