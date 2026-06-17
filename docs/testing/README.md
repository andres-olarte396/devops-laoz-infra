# Estrategia de Testing

---

## Pirámide de pruebas

```
         ╔══════════════╗
         ║   E2E (pocos)║  Cypress / Playwright
        ╔╩══════════════╩╗
        ║  Integración   ║  Supertest + stack real
       ╔╩════════════════╩╗
       ║   Unitarias      ║  Jest (la mayoría)
      ╚══════════════════╝
```

El foco está en **pruebas unitarias**: rápidas, sin dependencias externas, ejecutables en CI sin Docker.

Las pruebas de integración validan los flujos completos (login → request → auth) contra el stack real en Docker.

---

## Framework y convenciones

| Aspecto | Elección |
|---|---|
| Framework | **Jest** |
| Estilo de assertions | `expect(actual).toBe(expected)` |
| Nomenclatura de casos | `describe('módulo') > it('debería <comportamiento>')` |
| Estructura de casos | **Given / When / Then** en comentarios o nombres |
| Mocks | `jest.fn()`, `jest.mock()` para dependencias externas |
| Cobertura mínima objetivo | 80% en lógica de negocio de servicios core (auth, authz, roles) |

---

## Qué probar (y qué no)

### Probar:
- Lógica de negocio pura (validaciones, transformaciones, reglas)
- Casos límite y condiciones de error
- Integraciones con BD (tests de integración con MongoDB in-memory)
- Middleware (authMiddleware, rateLimitMiddleware)

### No probar:
- Frameworks (Express, Mongoose): ya están probados por sus autores
- Configuración de Docker o variables de entorno
- Código que solo llama a otra función sin lógica propia

---

## Estructura de archivos de prueba

Los tests viven junto al código fuente de cada servicio:

```
dev-laoz-authentication-api/
├── src/
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   └── auth.controller.test.js   ← junto al código
│   ├── services/
│   │   ├── auth.service.js
│   │   └── auth.service.test.js
│   └── middleware/
│       ├── auth.middleware.js
│       └── auth.middleware.test.js
└── jest.config.js
```

---

## Comandos

```bash
# Ejecutar pruebas de un servicio
cd dev-laoz-authentication-api
npm test

# Con cobertura
npm test -- --coverage

# En modo watch (desarrollo)
npm test -- --watch

# Un archivo específico
npm test -- auth.service.test.js
```

---

## Documentos de especificaciones

| Documento | Descripción |
|---|---|
| [unit/README.md](unit/README.md) | Guía de pruebas unitarias |
| [unit/authentication.md](unit/authentication.md) | Casos: authentication-api |
| [unit/authorization.md](unit/authorization.md) | Casos: authorization-api + RBAC |
| [unit/core-library.md](unit/core-library.md) | Casos: `@dev-laoz/core` |
| [integration/README.md](integration/README.md) | Estrategia de pruebas de integración |
