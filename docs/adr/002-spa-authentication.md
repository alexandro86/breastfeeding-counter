# ADR-002: autenticación de la SPA

- Estado: aceptada para el Hito 1
- Fecha: 2026-07-27

## Contexto

La SPA y la API se desplegarán inicialmente en dominios distintos. Guardar tokens duraderos en
`localStorage` aumenta el impacto de una vulnerabilidad XSS, mientras que usar cookies entre
sitios exige tratar CORS, SameSite y CSRF explícitamente.

## Decisión

Usar un esquema híbrido:

- Access token JWT de vida corta, conservado únicamente en memoria.
- Refresh token opaco, rotatorio y almacenado en cookie `HttpOnly`, `Secure` y `SameSite=None`.
- Persistir solo el hash del refresh token y permitir revocación por sesión.
- Proteger refresh y logout mediante token CSRF.
- Limitar CORS a orígenes explícitos y habilitar credenciales solo para ellos.
- Detectar reutilización de refresh tokens y revocar la familia afectada.

Las contraseñas se protegerán con Argon2id. Los endpoints de autenticación tendrán rate limiting
y respuestas que no revelen la existencia de una cuenta.

## Consecuencias

- Una recarga necesita renovar el access token antes de consultar datos privados.
- El servidor debe gestionar rotación, revocación y CSRF.
- La API no depende de almacenamiento inseguro del navegador.
- Si cliente y API pasan a compartir un mismo sitio, se evaluará una sesión íntegramente basada
  en cookies mediante un ADR que simplifique esta decisión.
