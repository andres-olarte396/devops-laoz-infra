# Pruebas de Integración — Estrategia

Las pruebas de integración validan flujos completos contra el stack real o partes de él. Son más lentas que las unitarias pero detectan problemas que los mocks no revelan (contratos de API, esquemas de BD, orden de operaciones).

---

## Herramientas

- **Supertest** — llamadas HTTP a los servicios sin levantar un servidor externo
- **MongoDB Memory Server** (`mongodb-memory-server`) — MongoDB en memoria para tests de integración de BD
- **Docker Compose** — para pruebas de integración completas del ecosistema

---

## Niveles de integración

### Nivel 1 — Servicio + BD (recomendado para CI)

Usa MongoDB Memory Server. No requiere Docker.

```javascript
// setup.js
const { MongoMemoryServer } = require('mongodb-memory-server');
let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});
```

### Nivel 2 — Stack completo (smoke tests)

Requiere el stack corriendo (`docker compose up -d`). Valida flujos de extremo a extremo.

---

## Casos de integración prioritarios

### Flujo de autenticación completo

```javascript
describe('Flujo de autenticación completo', () => {

  it('debería poder: registrar → login → acceder a recurso protegido → logout', async () => {
    // 1. Registrar usuario
    const registerRes = await request(app)
      .post('/api/user')
      .send({ username: 'test-user', password: 'password123' });
    expect(registerRes.status).toBe(201);

    // 2. Login
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ username: 'test-user', password: 'password123' });
    expect(loginRes.status).toBe(200);
    const { accessToken } = loginRes.body;

    // 3. Acceder a recurso protegido
    const protectedRes = await request(app)
      .get('/api/user')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(protectedRes.status).toBe(200);

    // 4. Logout
    const logoutRes = await request(app)
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(logoutRes.status).toBe(200);

    // 5. Token ya no debe ser válido
    const afterLogout = await request(app)
      .get('/api/user')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(afterLogout.status).toBe(401);
  });
});
```

### Flujo RBAC

```javascript
describe('Flujo RBAC', () => {

  it('debería denegar acceso cuando el rol no tiene el permiso requerido', async () => {
    // Usuario con rol viewer (solo files:read)
    const { accessToken } = await loginAs('viewer-user');

    const res = await request(app)
      .post('/api/files')
      .set('Authorization', `Bearer ${accessToken}`)
      .attach('file', Buffer.from('contenido'), 'test.txt');

    expect(res.status).toBe(403);
  });

  it('debería permitir acceso cuando el rol tiene el permiso requerido', async () => {
    const { accessToken } = await loginAs('editor-user');

    const res = await request(app)
      .post('/api/files')
      .set('Authorization', `Bearer ${accessToken}`)
      .attach('file', Buffer.from('contenido'), 'test.txt');

    expect(res.status).toBe(201);
  });
});
```

---

## Ejecución en CI

```yaml
# .github/workflows/test.yml (referencia)
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - run: docker compose -f docker-compose.yml up -d
      - run: npm run test:integration
      - run: docker compose down
```

---

## Datos de prueba (fixtures)

Los fixtures de usuarios y roles del sistema se crean con un seed script:

```bash
# Crear datos iniciales de prueba
docker compose exec authentication-api node scripts/seed-test-data.js
```

> El seed script está pendiente de implementar en cada servicio.
