# Pruebas Unitarias — @dev-laoz/core

---

## authMiddleware

```javascript
describe('authMiddleware', () => {
  let req, res, next;

  beforeEach(() => {
    req  = { headers: {} };
    res  = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    next = jest.fn();
  });

  it('debería llamar next() cuando el token es válido y la sesión está activa', async () => {
    req.headers.authorization = 'Bearer valid-token';
    authorizationApi.validate.mockResolvedValue({ authorized: true, userId: 'u1' });

    await authMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(req.user).toEqual({ authorized: true, userId: 'u1' });
  });

  it('debería responder 401 cuando no hay header Authorization', async () => {
    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: expect.stringContaining('Token') });
    expect(next).not.toHaveBeenCalled();
  });

  it('debería responder 401 cuando el header tiene formato incorrecto (sin "Bearer ")', async () => {
    req.headers.authorization = 'invalid-format';

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('debería responder 401 cuando authorization-api rechaza el token', async () => {
    req.headers.authorization = 'Bearer expired-token';
    authorizationApi.validate.mockRejectedValue(
      Object.assign(new Error('Token expirado'), { status: 401 })
    );

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('debería responder 403 cuando authorization-api devuelve 403', async () => {
    req.headers.authorization = 'Bearer valid-token';
    authorizationApi.validate.mockRejectedValue(
      Object.assign(new Error('Sin permiso'), { status: 403 })
    );

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });
});
```

---

## logger

```javascript
describe('logger', () => {

  describe('logger.info', () => {
    it('debería enviar POST a /api/insights/log con level: "info"', async () => {
      await logger.info('mensaje de prueba', { key: 'value' });

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/insights/log'),
        expect.objectContaining({
          method: 'POST',
          body: expect.stringContaining('"level":"info"'),
        })
      );
    });

    it('debería incluir SERVICE_NAME en el cuerpo del log', async () => {
      process.env.SERVICE_NAME = 'test-service';
      await logger.info('test');

      expect(fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          body: expect.stringContaining('"service":"test-service"'),
        })
      );
    });

    it('no debería lanzar error si api-insights no está disponible (fire-and-forget)', async () => {
      fetch.mockRejectedValue(new Error('ECONNREFUSED'));

      await expect(logger.info('test')).resolves.not.toThrow();
    });
  });

  describe('logger.audit', () => {
    it('debería enviar POST a /api/insights/audit con todos los campos', async () => {
      await logger.audit('user-123', 'FILE_DELETED', 'file-456', 'SUCCESS', { size: 100 });

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/insights/audit'),
        expect.objectContaining({
          body: expect.stringContaining('"actor":"user-123"'),
        })
      );
    });
  });

  describe('logger.transaction', () => {
    it('debería enviar POST a /api/insights/transaction con método, path, status y duración', async () => {
      await logger.transaction('/api/files', 'POST', 201, 45);

      const call = fetch.mock.calls[0];
      const body = JSON.parse(call[1].body);

      expect(body).toMatchObject({
        path: '/api/files',
        method: 'POST',
        statusCode: 201,
        duration: 45,
      });
    });
  });
});
```

---

## config.loadRemoteSecrets

```javascript
describe('config.loadRemoteSecrets', () => {

  it('debería cargar secretos en process.env desde api-secrets', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: () => ({ value: 'mongodb://mongo:27017/laoz' }),
    });

    await config.loadRemoteSecrets('user-api', ['MONGO_URI']);

    expect(process.env.MONGO_URI).toBe('mongodb://mongo:27017/laoz');
  });

  it('debería usar el valor de process.env existente si api-secrets falla', async () => {
    process.env.MONGO_URI = 'mongodb://fallback:27017/test';
    fetch.mockRejectedValue(new Error('ECONNREFUSED'));

    await config.loadRemoteSecrets('user-api', ['MONGO_URI']);

    expect(process.env.MONGO_URI).toBe('mongodb://fallback:27017/test');
  });

  it('debería cargar múltiples secretos en una llamada', async () => {
    fetch
      .mockResolvedValueOnce({ ok: true, json: () => ({ value: 'uri' }) })
      .mockResolvedValueOnce({ ok: true, json: () => ({ value: 'secret-jwt' }) });

    await config.loadRemoteSecrets('auth-api', ['MONGO_URI', 'JWT_SECRET']);

    expect(fetch).toHaveBeenCalledTimes(2);
    expect(process.env.MONGO_URI).toBe('uri');
    expect(process.env.JWT_SECRET).toBe('secret-jwt');
  });
});
```

---

## rateLimitMiddleware

```javascript
describe('rateLimitMiddleware', () => {

  it('debería permitir pasar cuando el límite no se ha excedido', () => {
    const middleware = createRateLimitMiddleware({ max: 5 });
    const { next } = callMiddleware(middleware, { ip: '127.0.0.1' });
    expect(next).toHaveBeenCalled();
  });

  it('debería responder 429 cuando se supera el límite de requests', () => {
    const middleware = createRateLimitMiddleware({ max: 2 });
    callMiddleware(middleware, { ip: '1.2.3.4' });
    callMiddleware(middleware, { ip: '1.2.3.4' });
    const { res } = callMiddleware(middleware, { ip: '1.2.3.4' });

    expect(res.status).toHaveBeenCalledWith(429);
  });

  it('debería contar requests por IP de forma independiente', () => {
    const middleware = createRateLimitMiddleware({ max: 1 });
    const { next: next1 } = callMiddleware(middleware, { ip: '1.1.1.1' });
    const { next: next2 } = callMiddleware(middleware, { ip: '2.2.2.2' });

    expect(next1).toHaveBeenCalled();
    expect(next2).toHaveBeenCalled();
  });
});
```
