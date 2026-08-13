# PRD — Breastfeeding Counter

## Control del documento

| Campo          | Valor                                                        |
| -------------- | ------------------------------------------------------------ |
| Producto       | Breastfeeding Counter                                        |
| Tipo           | Aplicación web responsive, mobile-first                      |
| Estado         | Definición inicial del MVP                                   |
| Versión        | 1.0                                                          |
| Fecha          | 2026-08-12                                                   |
| Idioma inicial | Español                                                      |
| Audiencia      | Producto, diseño, ingeniería, QA y agentes de implementación |

## Índice

1. Resumen ejecutivo
2. Problema y oportunidad
3. Visión, misión y principios
4. Personas y contexto de uso
5. Objetivos y no objetivos
6. Propuesta de valor
7. Alcance funcional del MVP
8. Flujos principales
9. Requisitos funcionales
10. Reglas de producto y negocio
11. Experiencia de usuario y accesibilidad
12. Privacidad, seguridad y confianza
13. Modelo conceptual de información
14. Métricas de éxito
15. Analítica de producto
16. Requisitos no funcionales
17. Roadmap y priorización
18. Criterios de aceptación del MVP
19. Riesgos y mitigaciones
20. Dependencias y decisiones pendientes
21. Glosario

## 1. Resumen ejecutivo

Breastfeeding Counter es una aplicación web diseñada para madres que amamantan y necesitan
registrar las tomas de sus bebés en momentos de cansancio, interrupciones y alta carga mental.
Permite acceder con una cuenta de Google, crear uno o más perfiles de bebé y registrar rápidamente
cómo se realizó cada alimentación:

- directamente del pecho;
- mediante un producto externo, como biberón, extractor, bolsa o recipiente;
- mediante una combinación de ambos cuando corresponda.

El producto conserva un historial privado y confiable y ofrece resúmenes descriptivos que ayudan a
recordar qué ocurrió y cuándo. No evalúa si una conducta es correcta, no diagnostica y no sustituye
el consejo de profesionales de la salud.

La prioridad del MVP es reducir al mínimo el esfuerzo necesario para registrar una toma en
condiciones caóticas. La acción principal debe poder iniciarse rápidamente, con una mano, desde un
teléfono y sin exigir información que no sea imprescindible en ese momento.

## 2. Problema y oportunidad

### 2.1 Problema principal

Durante la lactancia, especialmente en las primeras semanas o meses, una madre puede realizar muchas
tomas distribuidas a lo largo del día y la noche. El sueño interrumpido, la atención simultánea al
bebé y las tareas cotidianas hacen difícil recordar:

- cuándo fue la última toma;
- cuánto duró;
- qué pecho se utilizó;
- si se alimentó al bebé con leche mediante un producto externo;
- qué producto se usó y en qué momento;
- si una toma quedó en curso o no se registró correctamente.

Las notas genéricas o la memoria personal aumentan la carga mental y pueden producir registros
incompletos o inconsistentes. Las herramientas complejas también fallan porque requieren demasiados
pasos justo cuando la usuaria dispone de menos atención.

### 2.2 Oportunidad

Existe la oportunidad de crear una experiencia específica, privada y extremadamente rápida que:

- convierta el registro en una acción de pocos pasos;
- sobreviva a recargas, interrupciones y cambios de contexto;
- permita corregir posteriormente datos introducidos con prisa;
- reúna lactancia directa y productos externos en un mismo historial;
- presente información descriptiva sin emitir interpretaciones médicas.

### 2.3 Trabajo que la usuaria necesita resolver

> Cuando estoy amamantando o alimentando a mi bebé en medio de una situación cansadora o caótica,
> quiero registrar qué ocurrió con el menor esfuerzo posible, para poder recordarlo después sin
> depender de mi memoria.

## 3. Visión, misión y principios

### 3.1 Visión

Ser una memoria cotidiana confiable y respetuosa para las madres durante la etapa de lactancia.

### 3.2 Misión del MVP

Permitir que una madre autenticada registre y consulte todas las alimentaciones relevantes de sus
bebés, tanto al pecho como mediante productos externos, desde una interfaz móvil simple y segura.

### 3.3 Principios de producto

1. **Registrar primero, completar después.** La información mínima debe bastar para iniciar una
   toma; los detalles opcionales pueden agregarse posteriormente.
2. **Diseñar para el caos.** La experiencia debe tolerar interrupciones, recargas, errores y uso con
   una sola mano.
3. **Mantener la confianza.** El historial no debe perderse ni modificarse silenciosamente.
4. **Privacidad por defecto.** Cada cuenta accede únicamente a sus bebés, tomas y productos.
5. **Describir, no diagnosticar.** Los resúmenes informan hechos sin calificarlos ni convertirlos en
   recomendaciones médicas.
6. **Reducir decisiones innecesarias.** Valores opcionales, opciones claras y una acción primaria
   visible evitan sobrecarga cognitiva.
7. **Permitir corregir.** La usuaria puede editar registros creados con prisa sin perder claridad
   sobre su actualización.

## 4. Personas y contexto de uso

### 4.1 Persona primaria: madre lactante

Persona que amamanta y desea conservar un registro personal de las alimentaciones de uno o más
bebés.

Necesidades:

- registrar una toma en segundos;
- identificar rápidamente al bebé activo;
- saber si existe una toma en curso;
- consultar la última alimentación;
- recordar el pecho o método utilizado;
- registrar leche ofrecida mediante productos externos;
- corregir o completar datos más tarde;
- confiar en que sus datos son privados.

Condiciones frecuentes:

- uso nocturno o con poca luz;
- cansancio y atención fragmentada;
- una sola mano disponible;
- interrupciones repentinas;
- conexión móvil inestable;
- necesidad de leer y actuar rápidamente;
- uso desde pantallas pequeñas.

### 4.2 Persona secundaria futura: cuidadora autorizada

Persona invitada por la madre para colaborar con los registros. No forma parte del MVP porque
introduce permisos compartidos, atribución y revocación que deben diseñarse por separado.

### 4.3 Persona operativa: administrador técnico

Mantiene la disponibilidad del sistema sin acceso rutinario al contenido privado. Las herramientas
operativas no deben mostrar notas, nombres, correos ni detalles de tomas.

## 5. Objetivos y no objetivos

### 5.1 Objetivos del MVP

- Permitir acceso sencillo y seguro mediante una cuenta de Google.
- Permitir crear, seleccionar y archivar perfiles de bebé.
- Registrar lactancia directa con inicio, finalización y duración confiable.
- Registrar alimentaciones pasadas manualmente.
- Registrar el uso de productos externos relacionados con la alimentación.
- Consultar y corregir un historial cronológico.
- Mostrar la última toma y resúmenes diarios descriptivos.
- Funcionar correctamente tras una recarga durante una toma activa.
- Proporcionar una experiencia móvil accesible y de baja carga cognitiva.
- Permitir a la usuaria exportar y eliminar sus datos antes del lanzamiento público.

### 5.2 No objetivos del MVP

- Diagnosticar problemas de lactancia o salud.
- Recomendar frecuencias, cantidades, productos o tratamientos.
- Calificar una rutina como buena, mala, suficiente o insuficiente.
- Sustituir a pediatras, matronas, consultoras de lactancia u otros profesionales.
- Integrarse con historias clínicas o dispositivos médicos.
- Ofrecer una red social, chat, marketplace o publicidad personalizada.
- Gestionar múltiples cuidadoras o permisos compartidos.
- Proporcionar sincronización offline completa.
- Enviar recordatorios o alertas clínicas automáticas.
- Facturar suscripciones en la primera versión.

## 6. Propuesta de valor

### 6.1 Promesa principal

Registrar una alimentación debe ser más fácil que intentar recordarla.

### 6.2 Beneficios para la usuaria

- **Rapidez:** iniciar una toma desde la pantalla principal con pocos toques.
- **Continuidad:** recuperar una toma activa después de recargar o volver a abrir la web.
- **Claridad:** visualizar de inmediato la última toma y el método utilizado.
- **Flexibilidad:** registrar pecho, producto externo o una alimentación mixta.
- **Corrección:** editar registros incompletos o creados apresuradamente.
- **Privacidad:** conservar un historial accesible solo desde su cuenta.
- **Neutralidad:** recibir información descriptiva sin presión ni juicios médicos.

### 6.3 Diferenciador

El producto se optimiza para el momento real de uso —cansancio, bebé en brazos y atención
interrumpida— en lugar de priorizar formularios exhaustivos o métricas complejas.

## 7. Alcance funcional del MVP

### 7.1 Cuenta e identidad

- Acceso y creación automática de cuenta mediante Google.
- Cierre y recuperación segura de sesión.
- Perfil con nombre visible, zona horaria y preferencias básicas.
- Exportación de datos personales.
- Eliminación de cuenta y datos.

El MVP no utiliza contraseñas locales ni recuperación de contraseña propia. Google valida la
identidad; Breastfeeding Counter crea una cuenta interna y gestiona su propia sesión de aplicación.

### 7.2 Perfiles de bebés

- Crear uno o más perfiles.
- Guardar nombre o alias.
- Guardar fecha de nacimiento opcional.
- Seleccionar un bebé activo.
- Editar el perfil.
- Archivar un perfil sin borrar su historial.

### 7.3 Alimentación directa al pecho

- Iniciar una toma para el bebé activo.
- Indicar pecho izquierdo, derecho, ambos o no especificado.
- Mantener visible el estado de toma activa.
- Finalizar la toma.
- Calcular la duración usando los tiempos persistidos.
- Recuperar la toma activa después de una recarga.
- Crear una toma pasada manualmente.
- Editar o eliminar una toma.
- Añadir una nota opcional.

### 7.4 Alimentación mediante productos externos

- Crear un catálogo personal de productos.
- Categorías iniciales: biberón, extractor, bolsa o recipiente, protector, crema y otro.
- Registrar el uso de un producto en una fecha y hora.
- Asociar opcionalmente el uso a una toma.
- Registrar cantidad y unidad cuando tenga sentido.
- Añadir marca y notas opcionales.
- Editar y archivar productos.
- Conservar los usos históricos de productos archivados.

En el lenguaje de producto, una alimentación puede ser:

- **Pecho:** el bebé se alimentó directamente del pecho.
- **Producto externo:** la alimentación o su preparación se registró mediante un producto del
  catálogo personal.
- **Mixta:** una toma y uno o más usos de producto están vinculados al mismo evento o periodo.

### 7.5 Historial

- Lista cronológica por bebé.
- Identificación visual del método: pecho, producto externo o mixto.
- Fecha, hora, duración cuando corresponda y resumen de producto.
- Paginación estable.
- Filtros por bebé y rango de fechas.
- Acceso a detalle, edición y eliminación.
- Estados de carga, vacío y error claramente diferenciados.

### 7.6 Inicio y resúmenes

- Bebé activo.
- Acción primaria para iniciar toma.
- Toma activa y tiempo transcurrido.
- Última alimentación registrada.
- Cantidad de tomas del día.
- Duración total diaria de lactancia directa.
- Distribución descriptiva por pecho.
- Productos utilizados recientemente.

Los resúmenes deben usar la zona horaria de la usuaria y nunca presentarse como metas o umbrales
médicos.

## 8. Flujos principales

### 8.1 Primer acceso

1. La visitante elige “Continuar con Google”.
2. Google solicita autenticación y consentimiento mínimo.
3. La aplicación valida la respuesta de Google en el servidor.
4. Si es la primera vez, se crea la cuenta interna.
5. La usuaria confirma su zona horaria y crea el primer perfil de bebé.
6. La aplicación muestra el inicio con “Iniciar toma” como acción principal.

Resultado esperado: una nueva usuaria puede estar lista para registrar su primera toma sin crear ni
recordar otra contraseña.

### 8.2 Inicio y finalización de una toma al pecho

1. La usuaria confirma el bebé activo.
2. Pulsa “Iniciar toma”.
3. Selecciona izquierdo, derecho, ambos o no especificado.
4. La aplicación persiste inmediatamente el inicio.
5. La interfaz muestra claramente que la toma está activa.
6. La usuaria puede abandonar o recargar la página.
7. Al regresar, la aplicación reconstruye el tiempo transcurrido desde el inicio persistido.
8. La usuaria pulsa “Finalizar toma”.
9. El servidor confirma la hora final y calcula la duración.

Resultado esperado: ninguna recarga normal provoca la pérdida de la toma activa.

### 8.3 Registro rápido de producto externo

1. La usuaria selecciona “Registrar producto”.
2. Elige un producto usado recientemente o busca en su catálogo.
3. Confirma la hora, inicialmente “ahora”.
4. Añade cantidad y unidad solo si dispone de esa información.
5. Vincula opcionalmente el uso con una toma.
6. Guarda el registro.

Resultado esperado: registrar un producto frecuente requiere pocos pasos y no obliga a introducir
cantidad, marca o notas.

### 8.4 Registro manual posterior

1. La usuaria abre el historial y selecciona “Añadir registro”.
2. Elige el bebé y el método.
3. Introduce inicio y final o producto utilizado.
4. La aplicación valida datos imposibles o inconsistentes.
5. Guarda y muestra el registro en su posición cronológica correcta.

### 8.5 Corrección de un registro

1. La usuaria abre un elemento del historial.
2. Selecciona editar.
3. Corrige únicamente los campos permitidos.
4. Guarda los cambios.
5. El historial refleja el resultado y conserva `updated_at` como referencia técnica.

### 8.6 Cambio entre bebés

1. La usuaria abre el selector de bebé.
2. Elige otro perfil activo.
3. Inicio, historial y resúmenes cambian al perfil seleccionado.
4. Si existe una toma activa para algún bebé, la interfaz no debe ocultarla de forma engañosa.

## 9. Requisitos funcionales

### 9.1 Identidad y cuenta

- **RF-AUTH-001:** La visitante debe poder acceder mediante Google OpenID Connect.
- **RF-AUTH-002:** En el primer acceso se debe crear una cuenta interna vinculada al identificador
  estable de Google, no únicamente al correo.
- **RF-AUTH-003:** El sistema debe solicitar únicamente los alcances mínimos de identidad necesarios:
  `openid`, `email` y `profile`.
- **RF-AUTH-004:** El sistema debe rechazar tokens de Google inválidos, expirados o emitidos para
  otro cliente.
- **RF-AUTH-005:** La usuaria debe poder cerrar la sesión actual.
- **RF-AUTH-006:** La sesión debe renovarse sin conservar access tokens duraderos en almacenamiento
  accesible a JavaScript.
- **RF-AUTH-007:** La usuaria debe poder cerrar todas sus sesiones como parte de una acción de
  seguridad o eliminación de cuenta.
- **RF-AUTH-008:** El sistema no debe almacenar contraseñas de Google ni contraseñas locales.

### 9.2 Perfiles de bebés

- **RF-BABY-001:** La usuaria debe poder crear múltiples perfiles de bebé.
- **RF-BABY-002:** Cada perfil debe tener un nombre o alias y puede tener fecha de nacimiento.
- **RF-BABY-003:** La fecha de nacimiento no puede estar en el futuro.
- **RF-BABY-004:** La usuaria debe poder seleccionar un bebé activo.
- **RF-BABY-005:** La usuaria debe poder editar y archivar un perfil.
- **RF-BABY-006:** Archivar un bebé no debe borrar su historial.
- **RF-BABY-007:** No se debe archivar un bebé con una toma activa sin que la usuaria resuelva antes
  esa toma.

### 9.3 Tomas al pecho

- **RF-FEED-001:** La usuaria debe poder iniciar una toma para un bebé propio.
- **RF-FEED-002:** Debe poder indicar `left`, `right`, `both` o `unspecified`.
- **RF-FEED-003:** El inicio debe persistirse antes de mostrar la toma como confirmada.
- **RF-FEED-004:** La toma activa debe recuperarse después de recargar la aplicación.
- **RF-FEED-005:** La usuaria debe poder finalizar una toma con una operación idempotente.
- **RF-FEED-006:** La duración debe calcularse en el servidor y no persistirse como un contador
  independiente.
- **RF-FEED-007:** No puede existir más de una toma activa por usuaria y bebé.
- **RF-FEED-008:** La usuaria debe poder crear una toma manual pasada.
- **RF-FEED-009:** Debe poder editar o eliminar una toma propia.
- **RF-FEED-010:** El sistema debe impedir horas futuras fuera de una tolerancia de reloj definida.
- **RF-FEED-011:** `ended_at` no puede ser anterior a `started_at`.
- **RF-FEED-012:** Las notas son opcionales y deben tener longitud limitada.

### 9.4 Productos y usos

- **RF-PROD-001:** La usuaria debe poder crear productos en un catálogo privado.
- **RF-PROD-002:** Cada producto debe tener nombre y categoría.
- **RF-PROD-003:** Marca y notas son opcionales.
- **RF-PROD-004:** La usuaria debe poder registrar un uso de producto con fecha y hora.
- **RF-PROD-005:** Cantidad y unidad son opcionales; si existe cantidad debe ser positiva.
- **RF-PROD-006:** Un uso puede vincularse a una toma del mismo bebé y propietaria.
- **RF-PROD-007:** Producto, toma y uso vinculados deben pertenecer a la misma cuenta.
- **RF-PROD-008:** La usuaria debe poder editar y eliminar un uso propio.
- **RF-PROD-009:** La usuaria debe poder archivar un producto.
- **RF-PROD-010:** Un producto archivado conserva sus usos anteriores pero no admite nuevos usos.
- **RF-PROD-011:** El sistema debe facilitar la selección de productos usados recientemente.

### 9.5 Historial y resúmenes

- **RF-HIST-001:** La usuaria debe ver solo registros pertenecientes a su cuenta.
- **RF-HIST-002:** El historial debe poder filtrarse por bebé y rango de fechas.
- **RF-HIST-003:** El orden debe ser cronológico descendente y estable.
- **RF-HIST-004:** La paginación debe conservar su estabilidad al existir elementos con la misma
  hora.
- **RF-HIST-005:** Cada elemento debe indicar claramente su método de alimentación.
- **RF-SUM-001:** El inicio debe mostrar la última alimentación del bebé activo.
- **RF-SUM-002:** Debe mostrar una toma activa y permitir continuarla o finalizarla.
- **RF-SUM-003:** Debe mostrar cantidad y duración total del día según la zona horaria de la usuaria.
- **RF-SUM-004:** Debe mostrar distribución descriptiva por pecho y productos recientes.
- **RF-SUM-005:** Ningún resumen debe generar una recomendación o alerta médica.

### 9.6 Control de datos

- **RF-DATA-001:** La usuaria debe poder solicitar una exportación legible de sus datos.
- **RF-DATA-002:** La usuaria debe poder eliminar su cuenta y sus datos mediante confirmación
  explícita.
- **RF-DATA-003:** La eliminación debe revocar todas las sesiones.
- **RF-DATA-004:** Los datos archivados o eliminados deben respetar la política de retención
  publicada.

## 10. Reglas de producto y negocio

1. Cada recurso pertenece a una cuenta y toda lectura o escritura verifica esa propiedad.
2. El identificador público de una cuenta o recurso no concede acceso por sí mismo.
3. Una toma activa tiene `started_at` y no tiene `ended_at`.
4. La duración se deriva de las marcas de tiempo confirmadas por el servidor.
5. Repetir la finalización con la misma hora devuelve el mismo resultado; otra hora produce un
   conflicto explícito.
6. El sistema no modifica silenciosamente horas o cantidades inválidas.
7. Todas las fechas persistidas se almacenan en UTC y se muestran en la zona horaria de la usuaria.
8. El día de un resumen se calcula en la zona horaria de la usuaria y luego se consulta en UTC.
9. Eliminar una toma no debe eliminar automáticamente un uso de producto histórico; la asociación
   puede quedar vacía.
10. Un producto archivado no puede utilizarse en registros nuevos.
11. Una cuenta de Google se vincula por proveedor e identificador estable del sujeto. Los cambios de
    correo verificados por Google no deben crear accidentalmente una cuenta distinta.
12. No se fusionan cuentas automáticamente solo porque compartan un correo.
13. Toda información médica mostrada debe limitarse a una advertencia neutral sobre el alcance del
    producto.

## 11. Experiencia de usuario y accesibilidad

### 11.1 Principios de interacción

- Diseño mobile-first y utilizable con una sola mano.
- “Iniciar toma” visible como acción primaria en el inicio.
- Objetivos táctiles mínimos de 44 × 44 CSS px.
- Formularios cortos y datos opcionales marcados claramente.
- Guardado confirmado visualmente; nunca asumir éxito antes de persistir.
- Acciones destructivas diferenciadas y sujetas a confirmación.
- Navegación principal: Inicio, Historial, Productos y Perfil.
- Retorno al estado anterior sin perder entradas seguras tras errores recuperables.
- Evitar temporizadores, animaciones o colores que incrementen ansiedad.

### 11.2 Estados obligatorios

Toda vista que depende del servidor debe contemplar:

- carga;
- contenido disponible;
- resultado vacío;
- error recuperable;
- falta de conexión;
- sesión expirada;
- acción guardándose;
- éxito confirmado;
- acción no permitida.

### 11.3 Accesibilidad

- Cumplimiento objetivo WCAG 2.2 AA.
- Contraste suficiente y foco visible.
- HTML semántico y nombres accesibles.
- Etiquetas persistentes en formularios.
- Errores asociados programáticamente a sus campos.
- Navegación completa mediante teclado.
- No depender únicamente del color.
- Soportar zoom al 200% y pantallas estrechas sin pérdida de funcionalidad.
- Respetar `prefers-reduced-motion`.
- Usar mensajes claros, breves, neutrales y no culpabilizantes.

### 11.4 Contenido y tono

El idioma inicial es español. El tono debe ser:

- cálido sin infantilizar;
- directo y fácil de escanear;
- neutral frente a decisiones de alimentación;
- libre de culpa, comparación o presión;
- explícito cuando una acción no se guardó;
- prudente frente a cualquier tema médico.

## 12. Privacidad, seguridad y confianza

Los datos sobre bebés y alimentación son personales y potencialmente sensibles. La privacidad es
una condición de producto, no solo una implementación técnica.

### 12.1 Principios

- Recopilar únicamente datos necesarios para las funciones declaradas.
- Usar Google solo para identidad, no para acceder a contactos, correo, calendario u otros datos.
- Solicitar alcances mínimos de OpenID Connect.
- Mantener los datos de cada cuenta aislados.
- No vender datos ni utilizarlos para publicidad personalizada.
- No registrar notas, tokens, correos, nombres ni payloads completos en logs.
- Proporcionar exportación y eliminación antes del lanzamiento público.
- Comunicar claramente qué datos se conservan y para qué.

### 12.2 Sesión de aplicación

Después de validar Google, Breastfeeding Counter administra una sesión propia:

- access token JWT de vida corta, conservado únicamente en memoria del cliente;
- refresh token opaco y rotatorio en cookie `HttpOnly` y `Secure` en producción;
- persistencia exclusiva del hash del refresh token;
- protección CSRF en refresh y logout;
- detección de reutilización y revocación de la familia de sesión;
- CORS limitado a orígenes explícitos.

### 12.3 Consentimiento y transparencia

El primer acceso debe enlazar política de privacidad y términos aplicables. Antes del uso público se
debe determinar el mercado de lanzamiento y realizar revisión legal específica. Implementar
medidas técnicas no constituye por sí solo cumplimiento regulatorio.

## 13. Modelo conceptual de información

| Entidad           | Propósito                                 | Relaciones principales                                  |
| ----------------- | ----------------------------------------- | ------------------------------------------------------- |
| Cuenta            | Identidad interna y preferencias          | Se vincula a una identidad Google y posee bebés         |
| Identidad externa | Vínculo estable con Google                | Pertenece a una cuenta; usa proveedor + `subject` único |
| Sesión            | Renovación y revocación de acceso         | Pertenece a una cuenta y familia de tokens              |
| Bebé              | Perfil sobre el cual se registran eventos | Pertenece a una cuenta                                  |
| Toma              | Lactancia directa iniciada o manual       | Pertenece a cuenta y bebé                               |
| Producto          | Elemento personal reutilizable            | Pertenece a una cuenta                                  |
| Uso de producto   | Uso puntual de un producto                | Pertenece a cuenta; puede vincularse a una toma         |

Las especificaciones detalladas de campos, restricciones e índices viven en la referencia de datos
y en el contrato OpenAPI. El PRD define su intención de producto.

## 14. Métricas de éxito

Las métricas deben evaluarse con datos agregados y minimizados, sin capturar notas ni contenido
privado.

### 14.1 Métrica principal

**Registros de alimentación confirmados por usuaria activa semanal**, segmentados de forma agregada
por pecho, producto o mixto.

Esta métrica representa que el producto cumple su propósito sin inferir salud ni calidad de la
lactancia.

### 14.2 Activación

- Porcentaje de nuevas cuentas que crea un bebé y registra su primera alimentación.
- Tiempo mediano desde el acceso con Google hasta el primer registro confirmado.
- Porcentaje que completa el primer registro sin error o abandono.

Objetivo inicial para beta:

- al menos 70% de las nuevas cuentas crea un bebé y registra una alimentación;
- tiempo mediano hasta el primer registro inferior a 3 minutos.

### 14.3 Usabilidad y confianza

- Tiempo mediano para iniciar una toma desde el inicio: objetivo menor a 10 segundos.
- Tasa de guardado exitoso de registros iniciados: objetivo superior a 99% excluyendo cancelaciones
  explícitas.
- Porcentaje de tomas activas recuperadas correctamente tras recarga: objetivo 100% en pruebas y
  telemetría técnica elegible.
- Tasa de errores no controlados en flujos críticos: objetivo inferior a 1%.
- Solicitudes de soporte por pérdida o duplicación de registros: objetivo cercano a cero.

### 14.4 Retención exploratoria

- Retención de usuarias activadas al día 7 y día 30.
- Número de días con al menos un registro por usuaria activa.
- Uso recurrente de historial y productos recientes.

No fijar metas rígidas de retención hasta completar una beta con una muestra suficiente y consentimiento
adecuado para analítica.

## 15. Analítica de producto

La analítica es opcional hasta elegir proveedor y política de consentimiento. Si se habilita, solo
puede registrar eventos minimizados como:

- `google_sign_in_completed`;
- `baby_profile_created`;
- `feeding_started`;
- `feeding_finished`;
- `manual_feeding_created`;
- `product_usage_created`;
- `history_viewed`;
- `data_export_requested`;
- `account_deletion_requested`.

No incluir en propiedades analíticas:

- correo, nombre o identificador de Google;
- nombre o fecha de nacimiento del bebé;
- notas;
- timestamps exactos de alimentación;
- cantidades o marcas de productos;
- tokens o identificadores públicos de recursos.

Los eventos deben ser agregables, tener una finalidad documentada y poder desactivarse según la
política aplicable.

## 16. Requisitos no funcionales

- **Disponibilidad:** objetivo interno inicial de 99,5% sin prometer SLA público en el MVP.
- **Rendimiento API:** p95 menor a 500 ms para operaciones comunes bajo la carga inicial esperada.
- **Experiencia web:** carga y respuesta adecuadas en redes móviles; evitar dependencias pesadas sin
  justificación.
- **Persistencia:** PostgreSQL como única fuente de verdad; backups automáticos en producción.
- **Integridad:** migraciones versionadas, restricciones de base y transacciones explícitas.
- **Compatibilidad:** dos últimas versiones estables de Chrome, Safari, Firefox y Edge.
- **Accesibilidad:** WCAG 2.2 AA.
- **Observabilidad:** request ID, health checks y logs estructurados sin datos privados.
- **Seguridad:** TLS, cabeceras, secretos separados por entorno, rate limits y auditoría de
  dependencias.
- **Recuperación:** definir y ensayar restauración, RPO y RTO antes del lanzamiento público.
- **Despliegue:** CI obligatorio y entornos local, staging y producción aislados.

## 17. Roadmap y priorización

### Hito 0 — Fundación

- Monorepo, cliente, servidor, PostgreSQL local, migraciones, health checks y CI.
- Definiciones técnicas, ADR, OpenAPI y comandos reproducibles.

### Hito 1 — Google Identity y perfiles

- Acceso con Google y creación/vinculación de cuenta interna.
- Sesión, refresh, logout y revocación.
- Perfil, zona horaria y CRUD/archivo de bebés.
- Pruebas de aislamiento entre cuentas.

### Hito 2 — Toma al pecho completa

- Inicio, recuperación tras recarga y finalización.
- Registro manual, edición, eliminación e historial.
- Última toma y resumen diario básico.

### Hito 3 — Productos externos y alimentación mixta

- Catálogo personal y archivo.
- Registro de uso, asociación opcional a toma e historial.
- Productos recientes y representación del método mixto.

### Hito 4 — Preparación para beta

- Exportación y eliminación de cuenta.
- Accesibilidad, seguridad, rate limits y observabilidad.
- Staging, producción, backups, restauración y smoke tests.
- Política de privacidad, términos y revisión legal por mercado.

### Hito 5 — Mejoras posteriores

- PWA y soporte offline limitado.
- Invitaciones de cuidadoras y permisos.
- Segmentos y cambios de pecho dentro de una toma.
- Recordatorios voluntarios.
- Analítica agregada respetuosa de privacidad.

## 18. Criterios de aceptación del MVP

El MVP está listo para beta cuando:

1. Una persona puede acceder exclusivamente con Google y cerrar sesión de manera segura.
2. Una cuenta solo puede leer y modificar sus propios bebés, tomas, productos y usos.
3. La usuaria puede crear un bebé y seleccionarlo como activo.
4. Puede iniciar una toma al pecho, recargar la página y encontrarla todavía activa.
5. Puede finalizarla sin duplicar ni alterar incorrectamente su duración.
6. Puede registrar una alimentación pasada.
7. Puede crear un producto y registrar su uso, con cantidad opcional.
8. Puede reconocer en el historial si un registro corresponde a pecho, producto o una combinación.
9. Puede editar y eliminar registros propios según las reglas definidas.
10. Inicio e historial muestran estados de carga, vacío, error y sesión expirada.
11. Las pantallas críticas funcionan en móvil, teclado y lectores de pantalla según el alcance de
    WCAG 2.2 AA.
12. Ninguna pantalla presenta métricas como consejo médico.
13. Exportación y eliminación de cuenta funcionan de extremo a extremo.
14. CI, pruebas unitarias, integración, contrato y E2E críticos están verdes.
15. Staging y producción son reproducibles, con health checks y backups verificados.
16. Existe una política de privacidad revisada para el mercado de lanzamiento.

## 19. Riesgos y mitigaciones

| Riesgo                             | Impacto                              | Mitigación                                                        |
| ---------------------------------- | ------------------------------------ | ----------------------------------------------------------------- |
| Registro demasiado lento           | Abandono durante una toma            | Acción primaria visible, mínimos obligatorios y recientes         |
| Pérdida de una toma activa         | Ruptura de confianza                 | Persistencia inmediata y recuperación por timestamp               |
| Duplicación al finalizar           | Historial incorrecto                 | Endpoint idempotente y restricciones de base                      |
| Acceso cruzado entre cuentas       | Incidente grave de privacidad        | Autorización por propiedad y pruebas de aislamiento               |
| Dependencia exclusiva de Google    | Usuarias sin Google quedan excluidas | Declararlo como alcance MVP y evaluar otros proveedores después   |
| Cambio o pérdida de correo Google  | Duplicación de cuenta                | Vincular por issuer + subject estable, no solo por correo         |
| Interpretación médica de resúmenes | Daño o falsa seguridad               | Lenguaje neutral, límites visibles y sin alertas clínicas         |
| Datos sensibles en logs/analítica  | Exposición de privacidad             | Redacción, eventos mínimos y revisión de artefactos               |
| Mala conexión móvil                | Registros inciertos                  | Estados claros, reintentos seguros e idempotencia                 |
| Uso nocturno y fatiga              | Errores de interacción               | Diseño simple, objetivos táctiles grandes y confirmaciones claras |
| Cuenta Google comprometida         | Acceso no autorizado                 | Sesiones revocables, corta duración, avisos y cierre global       |

## 20. Dependencias y decisiones pendientes

Resolver antes de la beta pública:

- nombre comercial y dominio definitivo;
- países y mercado inicial;
- política exacta de retención y borrado;
- procedimiento de exportación y formato entregado;
- configuración del proyecto Google Cloud, pantalla de consentimiento y dominios autorizados;
- comportamiento cuando Google deja de entregar un correo o una identidad cambia;
- posibilidad futura de vincular más de un proveedor de identidad;
- proveedor de errores y analítica, junto con consentimiento y redacción;
- región, plan, backups, RPO y RTO definitivos de hosting;
- soporte al cliente y proceso ante cuenta comprometida;
- necesidad y momento de incorporar cuidadoras autorizadas;
- definición de “alimentación mixta” en interfaz cuando existen múltiples usos vinculados;
- unidades y categorías definitivas de productos tras investigación con usuarias.

Toda decisión que cambie autenticación, contrato HTTP, modelo central, privacidad o proveedores de
hosting debe registrarse mediante ADR.

## 21. Glosario

- **Alimentación:** evento registrado relacionado con la forma en que el bebé recibió leche o con
  los elementos usados para ofrecerla o prepararla.
- **Toma:** sesión de lactancia directa al pecho con inicio y final.
- **Producto externo:** elemento del catálogo personal usado en la alimentación o preparación, por
  ejemplo biberón, extractor, bolsa o recipiente.
- **Uso de producto:** evento puntual que registra cuándo se utilizó un producto.
- **Alimentación mixta:** representación de una toma vinculada con uno o más usos de producto.
- **Toma activa:** toma iniciada que todavía no tiene una hora final.
- **Bebé activo:** perfil seleccionado actualmente para inicio, historial y resúmenes.
- **Cuenta interna:** identidad propia de Breastfeeding Counter vinculada a Google y propietaria de
  todos los datos de la usuaria.
- **Google Identity:** proveedor externo que autentica a la persona mediante OpenID Connect.
- **Resumen descriptivo:** agrupación de hechos registrados que no contiene evaluación clínica.
