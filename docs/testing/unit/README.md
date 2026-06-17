# Pruebas Unitarias — Guía

---

## Principios

1. **Una sola razón para fallar**: cada test verifica un único comportamiento.
2. **Sin estado compartido**: cada test es independiente (`beforeEach` limpia el estado).
3. **Nombres descriptivos**: el nombre del test describe el comportamiento esperado, no la implementación.
4. **Arrange / Act / Assert**: estructura interna clara.
5. **Mocks explícitos**: mockear solo las dependencias externas (BD, APIs), no la lógica bajo prueba.

---

## Plantilla de test

```javascript
const { funcionBajoTest } = require('../modulo');
const depExterna = require('../dep-externa');

jest.mock('../dep-externa');

describe('moduloBajoTest', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('escenario principal', () => {
    it('debería <comportamiento esperado> cuando <condición>', async () => {
      // Arrange
      const input = { username: 'test', password: '12345678' };
      depExterna.buscar.mockResolvedValue({ _id: '1', password: 'hash' });

      // Act
      const resultado = await funcionBajoTest(input);

      // Assert
      expect(resultado).toEqual({ token: expect.any(String) });
      expect(depExterna.buscar).toHaveBeenCalledWith({ username: 'test' });
    });
  });

  describe('manejo de errores', () => {
    it('debería lanzar error cuando <condición de error>', async () => {
      depExterna.buscar.mockResolvedValue(null);

      await expect(funcionBajoTest({ username: 'noexiste' }))
        .rejects.toThrow('Usuario no encontrado');
    });
  });
});
```

---

## Cobertura por servicio (objetivos)

| Servicio | Cobertura objetivo | Prioridad |
|---|---|---|
| `authentication-api` | ≥ 85% | Alta |
| `authorization-api` | ≥ 85% | Alta |
| `api-roles` | ≥ 80% | Alta |
| `@dev-laoz/core` (authMiddleware, logger) | ≥ 80% | Alta |
| `user-api` | ≥ 75% | Media |
| `api-files` | ≥ 70% | Media |
| `billing-api` | ≥ 75% | Media |
| `api-manager` | ≥ 60% | Baja |

---

## Especificaciones por servicio

- [authentication.md](authentication.md) — casos de prueba de authentication-api
- [authorization.md](authorization.md) — casos de prueba de authorization-api
- [core-library.md](core-library.md) — casos de prueba de `@dev-laoz/core`
