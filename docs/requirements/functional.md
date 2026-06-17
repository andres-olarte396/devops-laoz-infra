# Requerimientos Funcionales

Requerimientos funcionales del ecosistema Dev Laoz, organizados por módulo.

**Estado:** `[I]` Implementado · `[P]` Parcial · `[X]` Pendiente

---

## RF-01 Autenticación

| ID | Requerimiento | Estado |
|---|---|---|
| RF-01.1 | El sistema debe permitir a un usuario autenticarse con `username` y `password` | [I] |
| RF-01.2 | Una autenticación exitosa debe devolver un `accessToken` (1h) y un `refreshToken` (7d) | [I] |
| RF-01.3 | El sistema debe permitir renovar el `accessToken` usando un `refreshToken` válido | [I] |
| RF-01.4 | El sistema debe invalidar la sesión inmediatamente al hacer logout | [I] |
| RF-01.5 | El sistema debe rechazar tokens de sesiones invalidadas aunque el JWT no haya expirado | [I] |
| RF-01.6 | El portal debe redirigir automáticamente al login si no hay sesión activa | [I] |
| RF-01.7 | El portal debe retornar al origen después de completar el login | [I] |
| RF-01.8 | El sistema debe soportar múltiples sesiones simultáneas por usuario | [I] |

---

## RF-02 Autorización (RBAC)

| ID | Requerimiento | Estado |
|---|---|---|
| RF-02.1 | El sistema debe controlar el acceso a recursos mediante roles | [I] |
| RF-02.2 | Los permisos deben seguir el formato `resource:action` | [I] |
| RF-02.3 | Un usuario puede tener múltiples roles simultáneamente | [I] |
| RF-02.4 | Debe existir un rol `admin` con acceso total al sistema | [I] |
| RF-02.5 | Debe ser posible crear roles personalizados con permisos específicos | [I] |
| RF-02.6 | Un administrador debe poder asignar/revocar roles a usuarios | [I] |
| RF-02.7 | Los cambios de rol deben surtir efecto en un máximo de 5 minutos | [I] |

---

## RF-03 Gestión de Usuarios

| ID | Requerimiento | Estado |
|---|---|---|
| RF-03.1 | Cualquier visitante debe poder registrarse con `username` y `password` | [I] |
| RF-03.2 | Las contraseñas deben almacenarse hasheadas (bcrypt) | [I] |
| RF-03.3 | Un administrador debe poder listar, ver, editar y eliminar usuarios | [I] |
| RF-03.4 | La contraseña nunca debe ser devuelta en respuestas de API | [I] |
| RF-03.5 | El sistema debe poder desactivar un usuario sin eliminarlo | [P] |
| RF-03.6 | El sistema debe poder listar las sesiones activas de un usuario | [X] |

---

## RF-04 Gestión de Archivos

| ID | Requerimiento | Estado |
|---|---|---|
| RF-04.1 | El sistema debe permitir subir archivos (multipart/form-data) | [I] |
| RF-04.2 | El sistema debe mantener historial de versiones por archivo | [I] |
| RF-04.3 | Debe ser posible descargar una versión específica de un archivo | [I] |
| RF-04.4 | El sistema debe soportar múltiples tipos de almacenamiento (local, network, cloud) | [I] |
| RF-04.5 | El borrado de archivos debe ser lógico (soft delete) | [I] |
| RF-04.6 | El sistema debe permitir etiquetar archivos con `tags` | [I] |
| RF-04.7 | Debe ser posible mover archivos entre tipos de almacenamiento | [I] |

---

## RF-05 Observabilidad

| ID | Requerimiento | Estado |
|---|---|---|
| RF-05.1 | Todos los servicios deben emitir logs de sistema a `api-insights` | [I] |
| RF-05.2 | Las operaciones sensibles deben generar eventos de auditoría | [I] |
| RF-05.3 | Cada request HTTP debe registrar método, path, status y duración | [I] |
| RF-05.4 | Los logs deben ser consultables por servicio, nivel y rango de fechas | [I] |
| RF-05.5 | Debe existir un stream en tiempo real de eventos (SSE) | [I] |
| RF-05.6 | Los datos de logs deben expirar automáticamente (TTL) | [I] |

---

## RF-06 Gestión de Secretos

| ID | Requerimiento | Estado |
|---|---|---|
| RF-06.1 | Los secretos deben almacenarse cifrados con AES-256-CBC | [I] |
| RF-06.2 | Los servicios deben cargar sus secretos al arrancar | [I] |
| RF-06.3 | El sistema debe funcionar con fallback a variables de entorno si `api-secrets` no está disponible | [I] |
| RF-06.4 | `api-secrets` debe ser accesible solo desde la red interna | [I] |

---

## RF-07 Control de Infraestructura

| ID | Requerimiento | Estado |
|---|---|---|
| RF-07.1 | Un administrador debe poder listar los contenedores Docker en ejecución | [I] |
| RF-07.2 | Un administrador debe poder iniciar y detener contenedores | [I] |
| RF-07.3 | Un administrador debe poder ver los logs de un contenedor | [I] |
| RF-07.4 | El sistema debe permitir clonar repositorios Git y hacer pull | [I] |

---

## RF-08 Facturación

| ID | Requerimiento | Estado |
|---|---|---|
| RF-08.1 | El sistema debe registrar pagos de clientes | [I] |
| RF-08.2 | El sistema debe permitir crear y gestionar suscripciones | [I] |
| RF-08.3 | El sistema debe permitir consultar el historial de pagos por cliente | [I] |
| RF-08.4 | El sistema debe mostrar el estado de cuenta de un cliente | [I] |
