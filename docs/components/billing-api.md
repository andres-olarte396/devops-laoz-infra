# Componente: billing-api

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-billing-api` |
| **Puerto interno** | `3004` |
| **ORM** | Sequelize (SQL) — diferente al resto del ecosistema (MongoDB) |

---

## Responsabilidades

Gestión de **pagos y suscripciones**. Es el único servicio del ecosistema que usa una base de datos SQL (Sequelize), mantenida separada de MongoDB.

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `GET` | `/api/billing/payments/cliente/:id` | Sí | Historial de pagos por cliente |
| `POST` | `/api/billing/payments` | Sí | Registra un nuevo pago |
| `GET` | `/api/billing/payments/estado/:id` | Sí | Estado de cuenta de un cliente |
| `POST` | `/api/billing/payments/suscripcion` | Sí | Crea o actualiza una suscripción |

---

## Consideraciones

- Al usar SQL en lugar de MongoDB, el esquema de datos es estricto y migraciones deben aplicarse antes de actualizar el servicio.
- Los pagos son operaciones sensibles: todas deben auditarse con `logger.audit`.
- Los errores de pago nunca deben exponer detalles internos al cliente.

---

## Dependencias

```
api-secrets    (healthy)   — credenciales de la BD SQL
api-insights   (started)   — auditoría de operaciones de pago
```
