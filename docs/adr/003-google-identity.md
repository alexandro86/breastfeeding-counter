# ADR-003: Google como proveedor de identidad del MVP

- Estado: aceptada para el Hito 1
- Fecha: 2026-08-12

## Contexto

El producto está destinado a madres que necesitan registrar alimentaciones bajo cansancio y carga
mental elevada. Crear, recordar y recuperar una contraseña adicional introduce fricción antes del
primer registro. El alcance de producto actualizado solicita que las personas se registren mediante
su cuenta de Google.

ADR-002 ya establece cómo Breastfeeding Counter mantiene su sesión de aplicación: access token JWT
de vida corta en memoria y refresh token opaco rotatorio en cookie segura. Faltaba definir cómo se
verifica inicialmente la identidad.

## Decisión

Usar Google OpenID Connect como único proveedor de identidad del MVP:

- Solicitar únicamente los alcances `openid`, `email` y `profile`.
- Validar en el servidor emisor, audiencia, firma, expiración, nonce y demás propiedades aplicables.
- Vincular la cuenta interna mediante la combinación estable de emisor (`iss`) y sujeto (`sub`), no
  únicamente mediante correo electrónico.
- Crear la cuenta interna en el primer acceso válido y actualizar solo atributos de perfil
  permitidos en accesos posteriores.
- No almacenar contraseñas locales ni credenciales de Google.
- Mantener el esquema de sesión definido en ADR-002 después de completar el intercambio con Google.
- No solicitar acceso a Gmail, contactos, calendario, Drive u otros servicios de Google.
- No fusionar automáticamente cuentas basándose solo en un correo coincidente.

El frontend debe utilizar el flujo recomendado por Google Identity Services para aplicaciones web.
La API es la única responsable de aceptar y validar la prueba de identidad y emitir la sesión
interna.

## Consecuencias

- El MVP requiere una cuenta de Google y no admite registro con contraseña local.
- Recuperación y seguridad de la cuenta primaria dependen de Google; la aplicación conserva la
  responsabilidad de revocar sus sesiones internas.
- Se necesita configurar un proyecto OAuth, pantalla de consentimiento, orígenes y redirect URIs por
  entorno.
- Las pruebas no deben llamar a Google: usarán identidades sintéticas y una frontera de validación
  sustituible en entornos de prueba.
- Incorporar otro proveedor o autenticación local requerirá un nuevo ADR y un modelo explícito para
  vincular identidades.
