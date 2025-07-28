## **Tabla: `education_levels`**

Almacena los diferentes niveles educativos.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del nivel educativo.
- `level` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del nivel educativo.
- `description` (TEXT): Descripción opcional.


Para una tabla `education_levels`, los estados de nivel educativo comunes podrían incluir los siguientes:

1. **Sin Educación Formal**: Persona sin educación formal.
2. **Educación Primaria Incompleta**: Educación básica sin completar todos los años requeridos.
3. **Educación Primaria Completa**: Educación básica completa.
4. **Educación Secundaria Incompleta**: Educación secundaria sin completar todos los años requeridos.
5. **Educación Secundaria Completa**: Educación secundaria completa.
6. **Educación Técnica**: Formación técnica o vocacional posterior a la educación secundaria.
7. **Educación Universitaria Incompleta**: Estudios universitarios sin completar la carrera.
8. **Título Universitario**: Carrera universitaria completa con título profesional.
9. **Posgrado**: Educación de posgrado, como diplomados, especializaciones o maestrías.
10. **Doctorado**: El nivel más alto de educación académica, orientado a la investigación.

Estos niveles pueden ajustarse según el contexto cultural o las necesidades del sistema educativo de cada país.