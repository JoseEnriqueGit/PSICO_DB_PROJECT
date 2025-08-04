## **Tabla: `marital_statuses`**

Almacena los diferentes estados civiles posibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del estado civil.
- `status` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del estado civil.
- `description` (TEXT): Descripción opcional.

---

Para una tabla `marital_statuses`, los estados civiles comunes pueden incluir los siguientes:

1. **Soltero/a**: Persona que no ha contraído matrimonio.
2. **Casado/a**: Persona unida en matrimonio.
3. **Divorciado/a**: Persona cuyo matrimonio ha sido disuelto legalmente.
4. **Viudo/a**: Persona cuyo cónyuge ha fallecido.
5. **Separado/a**: Persona que vive separada de su cónyuge sin haber disuelto el matrimonio oficialmente.
6. **Unión Libre**: Persona que vive en pareja sin estar casada legalmente.
7. **Comprometido/a**: Persona en una relación de compromiso formal, generalmente de cara a un futuro matrimonio.
8. **Anulado**: Matrimonio que ha sido declarado nulo legalmente.

Estos estados pueden variar según el país y las necesidades específicas del sistema, pero estos suelen ser los más utilizados.