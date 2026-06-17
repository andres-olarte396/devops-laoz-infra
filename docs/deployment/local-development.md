# Desarrollo Local

El archivo `docker-compose.override.yml` se carga automáticamente al ejecutar `docker compose up` (sin especificar `-f`). Expone los puertos internos de cada servicio para debugging directo.

---

## Levantar en modo desarrollo

```bash
# Usa docker-compose.yml + docker-compose.override.yml automáticamente
cd devops-laoz-infra
docker compose up -d
```

---

## Puertos disponibles en modo desarrollo

| Servicio | Puerto dev | URL |
|---|---|---|
| `api-secrets` | 3501 | `https://localhost:3501` |
| `api-insights` | 3600 | `http://localhost:3600` |
| `authentication-api` | 4000 | `http://localhost:4000` |
| `authorization-api` | 5000 | `http://localhost:5000` |
| `api-roles` | 5002 | `http://localhost:5002` |
| `user-api` | 6000 | `http://localhost:6000` |
| `api-files` | 3700 | `http://localhost:3700` |
| `api-manager` | 3800 | `http://localhost:3800` |
| `billing-api` | 3004 | `http://localhost:3004` |
| `api-gateway` | 9000 | `http://localhost:9000` |
| `auth-frontend` | 9001 | `http://localhost:9001` |
| `portal` | 80 | `http://localhost:80` |
| `docs-automator` | 7000 | `http://localhost:7000` |

---

## Swagger UI por servicio (modo dev)

| Servicio | URL Swagger |
|---|---|
| authentication-api | http://localhost:4000/api-docs |
| authorization-api | http://localhost:5000/api-docs |
| api-roles | http://localhost:5002/api-docs |
| user-api | http://localhost:6000/api-docs |
| api-secrets | https://localhost:3501/api-docs |
| api-insights | http://localhost:3600/api-docs |
| api-files | http://localhost:3700/api-docs |
| api-manager | http://localhost:3800/api-docs |
| billing-api | http://localhost:3004/api-docs |

---

## Desarrollo de un servicio individual (sin stack completo)

Para desarrollar un servicio sin levantar todo el ecosistema, usar el fallback a `process.env`:

```bash
# .env local del servicio (en su propio directorio)
MONGO_URI=mongodb://localhost:27017/laoz_dev
JWT_SECRET=dev-secret-32-chars-minimum-here
INSIGHTS_HOST=localhost
INSIGHTS_PORT=3600
RATE_LIMIT_MAX=1000

# Levantar solo mongo localmente
docker run -d -p 27017:27017 --name mongo-dev mongo:7-jammy

# Correr el servicio en modo dev (con nodemon)
cd dev-laoz-authentication-api
npm run dev
```

La variable `SECRETS_API_URL` puede dejarse vacía; `@dev-laoz/core` usará los valores de `process.env` como fallback.

---

## Hot reload

El `docker-compose.override.yml` activa `nodemon` para los servicios Node.js. Los cambios en el código se aplican automáticamente sin reconstruir la imagen.

---

## Diferencias con producción

| Aspecto | Desarrollo | Producción |
|---|---|---|
| Puertos internos | Expuestos | No expuestos |
| Hot reload | Activo | Inactivo |
| Logs | Verbose (debug) | Info / Error |
| CORS | Permisivo | Solo `CORS_ORIGIN` |
| TLS | Autofirmado (api-secrets) | Certificado válido |
