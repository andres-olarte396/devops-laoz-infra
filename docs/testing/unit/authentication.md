# Pruebas Unitarias — authentication-api

Especificación de casos de prueba para el servicio de autenticación.

---

## auth.service — login

```javascript
describe('AuthService.login', () => {

  describe('credenciales válidas', () => {
    it('debería devolver accessToken y refreshToken cuando las credenciales son correctas', async () => {
      // Arrange
      UserModel.findOne.mockResolvedValue({
        _id: 'user-id-123',
        username: 'andres',
        password: await bcrypt.hash('password123', 10),
        active: true,
      });
      SessionModel.create.mockResolvedValue({ sessionToken: 'session-uuid' });

      // Act
      const result = await AuthService.login('andres', 'password123');

      // Assert
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(typeof result.accessToken).toBe('string');
    });

    it('debería crear una sesión en BD al hacer login exitoso', async () => {
      await AuthService.login('andres', 'password123');
      expect(SessionModel.create).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'user-id-123', isActive: true })
      );
    });

    it('debería embeber userId y sessionToken en el JWT', async () => {
      const result = await AuthService.login('andres', 'password123');
      const payload = jwt.decode(result.accessToken);
      expect(payload).toMatchObject({
        userId: 'user-id-123',
        sessionToken: expect.any(String),
      });
    });

    it('debería emitir evento de auditoría SESSION_CREATED al login exitoso', async () => {
      await AuthService.login('andres', 'password123');
      expect(logger.audit).toHaveBeenCalledWith(
        'user-id-123', 'SESSION_CREATED', expect.any(String), 'SUCCESS', {}
      );
    });
  });

  describe('usuario no encontrado', () => {
    it('debería lanzar error 401 cuando el username no existe', async () => {
      UserModel.findOne.mockResolvedValue(null);

      await expect(AuthService.login('noexiste', 'password123'))
        .rejects.toMatchObject({ status: 401 });
    });

    it('debería emitir auditoría AUTH_FAILED cuando el username no existe', async () => {
      UserModel.findOne.mockResolvedValue(null);
      try { await AuthService.login('noexiste', 'password123'); } catch {}
      expect(logger.audit).toHaveBeenCalledWith(
        'system', 'AUTH_FAILED', 'noexiste', 'DENIED', {}
      );
    });
  });

  describe('contraseña incorrecta', () => {
    it('debería lanzar error 401 cuando la contraseña no coincide', async () => {
      UserModel.findOne.mockResolvedValue({
        _id: 'user-id-123',
        password: await bcrypt.hash('correcta', 10),
        active: true,
      });

      await expect(AuthService.login('andres', 'incorrecta'))
        .rejects.toMatchObject({ status: 401 });
    });

    it('no debería crear sesión cuando la contraseña es incorrecta', async () => {
      await expect(AuthService.login('andres', 'incorrecta')).rejects.toThrow();
      expect(SessionModel.create).not.toHaveBeenCalled();
    });
  });

  describe('usuario inactivo', () => {
    it('debería lanzar error 403 cuando el usuario está inactivo', async () => {
      UserModel.findOne.mockResolvedValue({
        _id: 'user-id-123',
        password: await bcrypt.hash('password123', 10),
        active: false,
      });

      await expect(AuthService.login('andres', 'password123'))
        .rejects.toMatchObject({ status: 403 });
    });
  });
});
```

---

## auth.service — refresh

```javascript
describe('AuthService.refreshToken', () => {

  it('debería devolver nuevo accessToken con refreshToken válido', async () => {
    SessionModel.findOne.mockResolvedValue({
      userId: 'user-id-123',
      sessionToken: 'session-uuid',
      isActive: true,
    });

    const result = await AuthService.refreshToken('valid-refresh-token');

    expect(result).toHaveProperty('accessToken');
    expect(typeof result.accessToken).toBe('string');
  });

  it('debería lanzar error 401 cuando el refreshToken no corresponde a ninguna sesión activa', async () => {
    SessionModel.findOne.mockResolvedValue(null);

    await expect(AuthService.refreshToken('invalid-token'))
      .rejects.toMatchObject({ status: 401 });
  });
});
```

---

## auth.service — logout

```javascript
describe('AuthService.logout', () => {

  it('debería marcar la sesión como isActive: false', async () => {
    const mockSession = { isActive: true, save: jest.fn() };
    SessionModel.findOne.mockResolvedValue(mockSession);

    await AuthService.logout('session-uuid');

    expect(mockSession.isActive).toBe(false);
    expect(mockSession.save).toHaveBeenCalled();
  });

  it('debería lanzar error 404 cuando la sesión no existe', async () => {
    SessionModel.findOne.mockResolvedValue(null);

    await expect(AuthService.logout('no-existe'))
      .rejects.toMatchObject({ status: 404 });
  });
});
```

---

## auth.controller — manejo de request/response

```javascript
describe('AuthController.login', () => {

  it('debería responder 200 con tokens en el body', async () => {
    AuthService.login.mockResolvedValue({
      accessToken: 'access-jwt',
      refreshToken: 'refresh-token',
    });

    const { res } = await callController(AuthController.login, {
      body: { username: 'andres', password: 'password123' },
    });

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ accessToken: 'access-jwt' })
    );
  });

  it('debería responder 400 cuando faltan username o password', async () => {
    const { res } = await callController(AuthController.login, {
      body: { username: 'andres' }, // password ausente
    });

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('debería responder 401 cuando AuthService.login lanza error de credenciales', async () => {
    AuthService.login.mockRejectedValue(Object.assign(new Error('Inválido'), { status: 401 }));

    const { res } = await callController(AuthController.login, {
      body: { username: 'x', password: 'y' },
    });

    expect(res.status).toHaveBeenCalledWith(401);
  });
});
```

---

## JWT — casos de borde

```javascript
describe('JWT generation', () => {

  it('debería generar un token que expira en 1 hora', () => {
    const token = generateAccessToken('user-id', 'session-uuid');
    const payload = jwt.decode(token);
    const diff = payload.exp - payload.iat;
    expect(diff).toBe(3600);
  });

  it('no debería incluir password ni datos sensibles en el payload', () => {
    const token = generateAccessToken('user-id', 'session-uuid');
    const payload = jwt.decode(token);
    expect(payload).not.toHaveProperty('password');
    expect(payload).not.toHaveProperty('roles');
    expect(payload).not.toHaveProperty('permissions');
  });
});
```
