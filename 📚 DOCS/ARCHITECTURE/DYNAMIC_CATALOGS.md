# Documentación de Cambios Relevantes en el Esquema de Catálogos Dinámicos

A continuación se describe de forma ordenada y sintética cada uno de los cambios más importantes que se aplicaron al esquema de la base de datos para gestionar catálogos dinámicos en PostgreSQL. El objetivo de estos cambios es garantizar **integridad referencial**, **validaciones automáticas**, **rendimiento de consultas** (incluyendo búsquedas con texto completo), **vistas de consulta estandarizadas**, **seguridad de solo lectura** para la capa de aplicación y **documentación embebida** (comentarios en objetos).

---

## 1. Integridad Referencial y Validación Automática

### 1.1. Tabla `util.catalog_fk_map`

* **¿Qué es?**
  Una tabla auxiliar que mapea cada columna "\*\_item\_id" en tablas de negocio al `type_code` esperado en `catalog_types`.

* **Estructura principal:**

  ```sql
  CREATE TABLE IF NOT EXISTS util.catalog_fk_map (
    schema_name TEXT    NOT NULL,
    table_name  TEXT    NOT NULL,
    column_name TEXT    NOT NULL,
    type_code   TEXT    NOT NULL,
    PRIMARY KEY (schema_name, table_name, column_name)
  );
  ```

  * `schema_name`   → nombre del esquema (p. ej. "public").
  * `table_name`    → nombre de la tabla de negocio (p. ej. "user\_emails").
  * `column_name`   → nombre de la columna que apunta a `catalog_items.id` (p. ej. "email\_type\_id").
  * `type_code`     → identificador corto de catálogo en `catalog_types` (p. ej. "email\_type").

* **Propósito:**
  Conocer de antemano qué columnas de qué tablas deben apuntar a cada `catalog_type`, de modo que la función/triggers de validación consulte `util.catalog_fk_map` y sepa qué `type_code` validar en tiempo de INSERT/UPDATE.

* **Valores típicos insertados:**

  ```sql
  INSERT INTO util.catalog_fk_map (schema_name, table_name, column_name, type_code)
  VALUES
    ('public','user_emails', 'email_type_id',    'email_type'),
    ('public','user_phones', 'phone_type_id',    'phone_type'),
    ('public','catalog_item_translations','catalog_item_id','__ANY__') -- "__ANY__" permite traducciones libres
  ON CONFLICT (schema_name, table_name, column_name) DO NOTHING;
  ```

  * La fila con `type_code = '__ANY__'` se usa para asociaciones más genéricas (como las traducciones), cuando no queremos forzar un solo tipo.

---

### 1.2. Función de Validación: `util.validate_catalog_item_type()`

* **Definición (PL/pgSQL):**

  ```sql
  CREATE OR REPLACE FUNCTION util.validate_catalog_item_type()
  RETURNS trigger
  LANGUAGE plpgsql
  AS $$
  DECLARE
      v_expected_type_id UUID;
      v_item_id          UUID;
  BEGIN
      -- 1. Obtener el UUID del tipo de catálogo esperado (por type_code en TG_ARGV[0])
      SELECT id
        INTO v_expected_type_id
        FROM catalog_types
       WHERE type_code = TG_ARGV[0];

      IF v_expected_type_id IS NULL THEN
          RAISE EXCEPTION 'Tipo de catálogo % no existe', TG_ARGV[0];
      END IF;

      -- 2. Extraer dinámicamente el valor NEW.<columna> (nombre en TG_ARGV[1])
      EXECUTE format('SELECT ($1).%I', TG_ARGV[1])
         USING NEW
         INTO v_item_id;

      -- 3. Si no viene valor, nada que validar
      IF v_item_id IS NULL THEN
          RETURN NEW;
      END IF;

      -- 4. Verificar que exista en catalog_items con ese catalog_type_id y no esté eliminado
      PERFORM 1
        FROM catalog_items
       WHERE id              = v_item_id
         AND catalog_type_id = v_expected_type_id
         AND is_deleted      = false;

      IF NOT FOUND THEN
          RAISE EXCEPTION
            'Valor % inválido: no pertenece al tipo de catálogo %',
            v_item_id, TG_ARGV[0];
      END IF;

      RETURN NEW;
  END;
  $$;
  ```

  * **Parámetros (`TG_ARGV`):**

    * `TG_ARGV[0]` → `type_code` esperado (p. ej. 'gender', 'email\_type').
    * `TG_ARGV[1]` → el nombre de la columna que recibe el ID (p. ej. 'gender\_id', 'email\_type\_id').

* **Propósito:**
  Cada vez que se intenta insertar o actualizar una fila en alguna tabla de negocio que tenga una columna "\*\_item\_id", el trigger asociado invoca esta función, que:

  1. Busca el `catalog_type_id` en `catalog_types` según el `type_code`.
  2. Obtiene de `NEW.<columna>` el UUID del item.
  3. Verifica en `catalog_items` que ese UUID exista, pertenezca al `catalog_type_id` correcto y no esté marcado como eliminado (`is_deleted = false`).
  4. Si no coincide, arroja un error y aborta la operación.

---

### 1.3. Triggers `BEFORE INSERT OR UPDATE` en Tablas de Negocio

Por cada columna que apunta a un catálogo, se creó un `TRIGGER` que ejecuta la función de validación.

* **Ejemplo en la tabla `user_emails`:**

  ```sql
  -- 1) Trigger function ya creada: util.validate_catalog_item_type()
  -- 2) Crear el trigger apuntando a los argumentos ('email_type', 'email_type_id'):
  CREATE TRIGGER validate_user_emails_email_type
  BEFORE INSERT OR UPDATE ON public.user_emails
  FOR EACH ROW
  EXECUTE FUNCTION util.validate_catalog_item_type('email_type','email_type_id');
  ```

* **Replicar para cada columna "\*\_item\_id" mapeada en `util.catalog_fk_map`:**

  ```sql
  -- user_phones.phone_type_id → type_code = 'phone_type'
  CREATE TRIGGER validate_user_phones_phone_type
  BEFORE INSERT OR UPDATE ON public.user_phones
  FOR EACH ROW
  EXECUTE FUNCTION util.validate_catalog_item_type('phone_type','phone_type_id');

  -- si existiera table: user_addresses.address_type_id → 'address_type'
  CREATE TRIGGER validate_user_addresses_address_type
  BEFORE INSERT OR UPDATE ON public.user_addresses
  FOR EACH ROW
  EXECUTE FUNCTION util.validate_catalog_item_type('address_type','address_type_id');
  ```

  * **Nota:** No olvides que, para cada trigger, el primer argumento debe coincidir con un `type_code` válido en `catalog_types`, y el segundo con la columna exacta en la tabla.

---

## 2. Esquema de Catálogos y Traducciones

### 2.1. Tablas Principales

1. **`catalog_types`**
   Catalogo de "tipos de catálogo".

   * Columnas principales:

     * `id          UUID PRIMARY KEY`
     * `type_code   TEXT UNIQUE NOT NULL`
     * `description TEXT`

2. **`catalog_items`**
   Valores de cada catálogo.

   * Columnas principales:

     * `id              UUID PRIMARY KEY`
     * `catalog_type_id UUID REFERENCES catalog_types(id)`
     * `code            TEXT NOT NULL`
     * `description     TEXT`
     * `is_deleted      BOOLEAN NOT NULL DEFAULT false`
     * `created_at      TIMESTAMPTZ NOT NULL DEFAULT now()`
     * `updated_at      TIMESTAMPTZ`
     * `created_by      UUID`  (FK opcional a tabla de usuarios)
     * `updated_by      UUID`  (FK opcional a tabla de usuarios)

   * **Índice recomendado para búsqueda de (`catalog_type_id`, `code`):**

     ```sql
     CREATE INDEX IF NOT EXISTS idx_catalog_items_type_code
       ON catalog_items (catalog_type_id, code);
     ```

3. **`catalog_item_translations`**
   Traducciones pluralizadas de cada valor de catálogo, multi-idioma.

   * Columnas principales:

     * `id               UUID PRIMARY KEY`
     * `catalog_item_id  UUID REFERENCES catalog_items(id)`
     * `language_code    CHAR(2) NOT NULL`     -- ISO-639-1
     * `translated_name  TEXT NOT NULL`
     * `translated_desc  TEXT`
     * `created_at       TIMESTAMPTZ NOT NULL DEFAULT now()`
     * `updated_at       TIMESTAMPTZ`
     * `created_by       UUID`
     * `updated_by       UUID`
   * **Clave única por (`catalog_item_id`, `language_code`)**
     (para garantizar una sola traducción por idioma).
   * **Índice de Texto Completo (GIN) para búsquedas por `translated_name`:**

     ```sql
     CREATE INDEX IF NOT EXISTS idx_cit_tr_name
       ON catalog_item_translations
       USING gin(
         to_tsvector('simple', translated_name)
       );
     ```

---

## 3. Vistas de Consulta Estandarizadas

Para cada `type_code` en `catalog_types`, se genera dinámicamente una vista `vw_catalog_<type_code>`. Estas vistas son de **solo lectura** y traen la lista de items más sus traducciones.

### 3.1. Código genérico (PL/pgSQL) para crear/actualizar vistas

```sql
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT id, type_code FROM catalog_types LOOP
        EXECUTE format(
            $fmt$
            CREATE OR REPLACE VIEW public.vw_catalog_%1$I AS
            SELECT 
              ci.id,
              ci.code,
              ci.description,
              tr.language_code,
              tr.translated_name,
              tr.translated_desc
            FROM catalog_items ci
            LEFT JOIN catalog_item_translations tr
              ON tr.catalog_item_id = ci.id
            WHERE ci.catalog_type_id = %2$L
              AND ci.is_deleted      = false;
            $fmt$,
            rec.type_code, -- %1$I → nombre seguro para la vista
            rec.id          -- %2$L → UUID literal para filtrar
        );
    END LOOP;
END $$;
```

* Cada iteración crea o reemplaza una vista, p. ej. `vw_catalog_gender`, `vw_catalog_phone_type`, `vw_catalog_email_type`, etc.
* El filtro `ci.is_deleted = false` garantiza que solo los valores "activos" aparezcan.
* **Ejemplo resultante:**

  ```sql
  CREATE OR REPLACE VIEW public.vw_catalog_gender AS
    SELECT 
      ci.id,
      ci.code,
      ci.description,
      tr.language_code,
      tr.translated_name,
      tr.translated_desc
    FROM catalog_items ci
    LEFT JOIN catalog_item_translations tr
      ON tr.catalog_item_id = ci.id
    WHERE ci.catalog_type_id = '90a8c8d2-d844-4926-88ec-02cae06e12ce'
      AND ci.is_deleted      = false;
  ```
* **Permisos posteriores (ver sección 5)**.

---

## 4. Comentarios (`COMMENT ON`) para Documentación Embebida

Para que futuros desarrolladores vean la intención de cada objeto directamente desde la base de datos, se agregaron comentarios a tablas, columnas, funciones y vistas.

### 4.1. Tablas y Columnas Principales

```sql
-- ---------- CATÁLOGOS PRINCIPALES ----------
COMMENT ON TABLE catalog_types IS
  'Tabla de tipos de catálogo globales. Ej: gender, phone_type, email_type, etc.';

COMMENT ON COLUMN catalog_types.type_code IS
  'Identificador corto único; se usa como sufijo en las vistas vw_catalog_<type_code>.';

COMMENT ON TABLE catalog_items IS
  'Valores para cada catálogo (clave foránea a catalog_types). Incluye soft-delete.';

COMMENT ON COLUMN catalog_items.code IS
  'Código corto único dentro del tipo de catálogo. Se expone en APIs y UIs.';

COMMENT ON COLUMN catalog_items.is_deleted IS
  'Marca lógica de eliminación. Los triggers soft_del_* la gestionan.';

-- ---------- TRADUCCIONES ----------
COMMENT ON TABLE catalog_item_translations IS
  'Tabla de traducciones para catalog_items. Clave primaria compuesta: (catalog_item_id, language_code).';

COMMENT ON COLUMN catalog_item_translations.language_code IS
  'Código de idioma ISO-639-1 (dos letras).';

COMMENT ON COLUMN catalog_item_translations.translated_name IS
  'Nombre traducido del valor de catálogo en el idioma especificado.';

COMMENT ON COLUMN catalog_item_translations.translated_desc IS
  'Descripción traducida (opcional) del valor de catálogo.';

-- ---------- TABLA DE UTILIDAD ----------
COMMENT ON TABLE util.catalog_fk_map IS
  'Mapa de columnas *_item_id → type_code. Usada por triggers para validar integridad referencial.';

COMMENT ON COLUMN util.catalog_fk_map.type_code IS
  'Identificador corto en catalog_types. "__ANY__" indica que se admite cualquier tipo (caso de traducciones).';

-- ---------- FUNCIÓN DE VALIDACIÓN ----------
COMMENT ON FUNCTION util.validate_catalog_item_type() IS
  $$
  Trigger BEFORE INSERT/UPDATE.
    Valida que el valor NEW.<columna> pertenezca al catálogo con type_code esperado.
    Parámetros:
      1) type_code (p. ej. "gender", "email_type")
      2) nombre de la columna con el ID (p. ej. "gender_id", "email_type_id")
  $$;

-- ---------- VISTAS POR CATÁLOGO (dinámicas) ----------
DO $$
DECLARE rec RECORD;
BEGIN
  FOR rec IN SELECT type_code FROM catalog_types LOOP
    EXECUTE format(
      $$
      COMMENT ON VIEW public.vw_catalog_%I IS
        'Vista de solo lectura para el catálogo %1$I, incluye traducciones activas.';
      $$,
      rec.type_code
    );
  END LOOP;
END $$;
```

* Los comentarios facilitan que, al hacer `\d+ catalog_items` o `\d+ vw_catalog_gender` en `psql` o en pgAdmin, se vea la descripción de cada objeto.
* **Nota:** El bloque DO de las vistas recorre cada `type_code` existente y les pone un comentario estándar.

---

## 5. Permisos y Seguridad de Solo Lectura

Para garantizar que la capa de aplicación solo pueda **consultar** (no modificar) la información de catálogos y vistas, se definió un rol (por ejemplo, `app_user`) con permisos mínimos.

### 5.1. Creación / Verificación del Rol

* **(Solo si no existe)**

  ```sql
  CREATE ROLE app_user LOGIN PASSWORD '⟨tu_contraseña_segura⟩';
  ```
* En nuestro ejemplo, la consola de Supabase ya provee un rol "anon" o similar; basta con asignarle permisos. Pero si no existe, hay que crearlo explícitamente.

### 5.2. GRANT SELECT en Tablas de Catálogo

```sql
GRANT SELECT
  ON catalog_types,
     catalog_items,
     catalog_item_translations
TO app_user;
```

* Con esto, el rol `app_user` puede leer todas las filas de las tablas principales de catálogos.

### 5.3. GRANT SELECT en Vistas Dinámicas

* **Opción global (más sencilla):**

  ```sql
  GRANT SELECT
    ON ALL VIEWS IN SCHEMA public
  TO app_user;
  ```

  * Eso cubre todas las vistas `vw_catalog_<type_code>` y cualquier otra vista creada en `public`.

* **Opción granular (por cada vista):**

  ```sql
  GRANT SELECT
    ON public.vw_catalog_gender,
       public.vw_catalog_phone_type,
       public.vw_catalog_email_type
  TO app_user;
  ```

  * Si no queremos abrir "todas" las vistas, podemos enumerar solo las vistas de catálogo.

### 5.4. Verificación de Permisos

Para comprobar que realmente el rol no pueda insertar/actualizar pero sí seleccionar:

```sql
-- Como superusuario o rol owner:
GRANT app_user TO CURRENT_USER;     -- para simular sesión con ese rol
RESET ALL;                          -- abrir nueva sesión que reconozca la pertenencia
SET ROLE app_user;

-- Prueba de SELECT (debe funcionar):
SELECT * FROM public.vw_catalog_gender LIMIT 3;

-- Prueba de INSERT (debe fallar):
INSERT INTO public.catalog_types (id, type_code, description)
VALUES (gen_random_uuid(), 'dummy', 'Prueba'); -- debe arrojar "permission denied"

RESET ROLE;    -- volver al rol original
```

---

## 6. Índices para Rendimiento de Búsqueda

### 6.1. Índice Compuesto en `catalog_items`

Para acelerar consultas que filtran por tipo y código:

```sql
CREATE INDEX IF NOT EXISTS idx_catalog_items_type_code
  ON catalog_items (catalog_type_id, code);
```

* **¿Por qué?**
  Muchos filtros / joins harán `WHERE catalog_type_id = … AND code = …`. Un índice compuesto cubre esa ordenación sin crear varios índices individuales.

### 6.2. Índice GIN de Texto Completo en `catalog_item_translations`

Para facilitar búsquedas full-text (letras acentuadas, coincidencias parciales) en `translated_name`:

```sql
-- Se puede crear CONCURRENTLY en un cliente que no esté en transacción.
CREATE INDEX IF NOT EXISTS idx_cit_tr_name
  ON catalog_item_translations
  USING gin(
    to_tsvector('simple', translated_name)
  );
```

* **Notas de ejecución:**

  * En clientes como `psql` o pgAdmin, ejecuta la instrucción completa sin estar en un bloque `BEGIN; … COMMIT;`.
  * Si estás en una consola que abre implicítamente transacciones, debes quitar los `BEGIN; … COMMIT;` o usar `CREATE INDEX` (sin `CONCURRENTLY`).

* **Verificación de uso:**

  ```sql
  EXPLAIN ANALYZE
    SELECT *
    FROM catalog_item_translations
    WHERE to_tsvector('simple', translated_name) @@ to_tsquery('simple','masculino');
  ```

  Debe verse `Bitmap Index Scan on idx_cit_tr_name` o similar en el plan.

---

## 7. Flujo de Trabajo para Nuevos Catálogos

A partir de ahora, cuando se necesite incorporar un **nuevo catálogo dinámico**, el flujo recomendado es el siguiente:

1. **Insertar en `catalog_types`**

   ```sql
   INSERT INTO catalog_types (id, type_code, description)
   VALUES (gen_random_uuid(), 'payment_method', 'Métodos de pago disponibles');
   ```

2. **Insertar valores iniciales en `catalog_items`** (si hay valores por defecto)

   ```sql
   -- Asumiendo v_type_id = (SELECT id FROM catalog_types WHERE type_code='payment_method');
   INSERT INTO catalog_items (id, catalog_type_id, code, description, is_deleted)
   VALUES
     (gen_random_uuid(), v_type_id, 'CARD', 'Tarjeta de crédito/débito', false),
     (gen_random_uuid(), v_type_id, 'CASH', 'Pago en efectivo', false),
     (gen_random_uuid(), v_type_id, 'BANK', 'Transferencia bancaria', false);
   ```

3. **Mapear la nueva columna "\*\_item\_id"** en `util.catalog_fk_map`
   Supongamos que existe la tabla `user_payments` con columna `payment_method_id`:

   ```sql
   INSERT INTO util.catalog_fk_map (schema_name, table_name, column_name, type_code)
   VALUES ('public','user_payments','payment_method_id','payment_method')
   ON CONFLICT (schema_name, table_name, column_name) DO NOTHING;
   ```

4. **Crear el Trigger de Validación** en la tabla de negocio

   ```sql
   CREATE TRIGGER validate_user_payments_payment_method
   BEFORE INSERT OR UPDATE ON public.user_payments
   FOR EACH ROW
   EXECUTE FUNCTION util.validate_catalog_item_type('payment_method','payment_method_id');
   ```

5. **Crear / Reemplazar la Vista de Catálogo** (opcional si usamos la generación dinámica)
   Si manejamos vistas para cada catálogo, podemos invocar el bloque PL/pgSQL que recorra todos los `catalog_types`, o simplemente:

   ```sql
   DO $$
   DECLARE
     v_id UUID := (SELECT id FROM catalog_types WHERE type_code = 'payment_method');
   BEGIN
     EXECUTE format(
       $$CREATE OR REPLACE VIEW public.vw_catalog_%I AS
         SELECT 
           ci.id,
           ci.code,
           ci.description,
           tr.language_code,
           tr.translated_name,
           tr.translated_desc
         FROM catalog_items ci
         LEFT JOIN catalog_item_translations tr
           ON tr.catalog_item_id = ci.id
         WHERE ci.catalog_type_id = %L
           AND ci.is_deleted      = false;$$,
       'payment_method',
       v_id
     );
   END;
   $$;
   ```

6. **Conceder Permisos de Lectura (SELECT) a `app_user`**

   ```sql
   GRANT SELECT ON public.vw_catalog_payment_method TO app_user;
   ```

7. **(Opcional) Agregar ínidces de texto completo si se usarán traducciones**

   ```sql
   CREATE INDEX IF NOT EXISTS idx_cit_tr_payment_method_name
     ON catalog_item_translations
     USING gin(to_tsvector('simple', translated_name))
     WHERE catalog_item_id IN (
       SELECT id FROM catalog_items WHERE catalog_type_id = v_id
     );
   ```

   — Aunque el índice general `idx_cit_tr_name` ya cubre la mayoría de búsquedas.

---

## 8. Pruebas y Validaciones Automatizadas

Para asegurar que futuras migraciones o cambios no rompan la integridad:

1. **Tests con pgTAP**

   * Verificar existencia de la función:

     ```sql
     SELECT has_function('util.validate_catalog_item_type', 0) AS ok;
     ```
   * Probar que insertar un ID inválido falle:

     ```sql
     SELECT throws_ok(
       $q$
       INSERT INTO user_payments (id, user_id, payment_method_id, amount)
       VALUES (gen_random_uuid(), '<user_uuid>', '<uuid_que_no_sea_payment_method>', 100);
       $q$,
       'Valor .* inválido: no pertenece al tipo de catálogo payment_method',
       'Trigger valida mal uso de payment_method_id'
     );
     ```
   * Probar que un ID válido inserte sin errores:

     ```sql
     SELECT lives_ok(
       $q$
       INSERT INTO user_payments (id, user_id, payment_method_id, amount)
       VALUES (gen_random_uuid(), '<user_uuid>', '<uuid_valido_de_payment_method>', 100);
       $q$,
       'Inserción con payment_method_id correcto debe funcionar'
     );
     ```

2. **Chequeo SQL de Integridad General**
   Un script que detecte columnas "\*\_item\_id" que no estén mapeadas o que referencien IDs inexistentes:

   ```sql
   -- 8.1. Columnas *_item_id sin mapear en util.catalog_fk_map
   WITH fk_cols AS (
     SELECT table_schema AS schema_name,
            table_name,
            column_name
     FROM information_schema.columns
     WHERE column_name LIKE '%\_item_id'
       AND table_schema = 'public'
   )
   SELECT fk.*
   FROM fk_cols fk
   LEFT JOIN util.catalog_fk_map m
     ON m.schema_name = fk.schema_name
    AND m.table_name  = fk.table_name
    AND m.column_name = fk.column_name
   WHERE m.column_name IS NULL;
   ```

   * Debe devolver 0 filas (significa que todas las columnas "\*\_item\_id" están mapeadas).

   ```sql
   -- 8.2. Chequear valores inválidos directos (sin pasar por trigger)
   WITH fk_cols AS (
     SELECT schema_name, table_name, column_name, type_code
     FROM util.catalog_fk_map
   ),
   violations AS (
     SELECT 
       fk.schema_name,
       fk.table_name,
       fk.column_name,
       COUNT(*) AS bad_count
     FROM fk_cols fk
     JOIN (
       EXECUTE format(
         'SELECT %I AS fk_val FROM %I.%I',
         fk.column_name, fk.schema_name, fk.table_name
       )
     ) AS sub ON true
     LEFT JOIN catalog_items ci
       ON ci.id = sub.fk_val
      AND ci.catalog_type_id = (SELECT id FROM catalog_types WHERE type_code = fk.type_code)
      AND ci.is_deleted      = false
     WHERE sub.fk_val IS NOT NULL
       AND ci.id IS NULL
     GROUP BY fk.schema_name, fk.table_name, fk.column_name
   )
   SELECT * FROM violations WHERE bad_count > 0;
   ```

   * Debe devolver 0 filas (si hay filas, hay registros que apuntan a IDs de catálogo inexistentes o eliminados).

---

## 9. Resumen de Objetos y Rol de Aplicación

Al finalizar los cambios, estos son los **objetos principales** y sus finalidades:

| Objeto                                          | Función / Descripción                                                                                      |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tabla `catalog_types`**                       | Define cada tipo de catálogo (p. ej. gender, email\_type, phone\_type, etc.).                              |
| **Tabla `catalog_items`**                       | Contiene los valores de cada tipo de catálogo (vinculado a `catalog_types`).                               |
| **Tabla `catalog_item_translations`**           | Guarda traducciones multi-idioma de cada `catalog_items`.                                                  |
| **Tabla `util.catalog_fk_map`**                 | Mapea cada columna "\*\_item\_id" en tablas de negocio al `type_code` que debe validar la FK.              |
| **Función `util.validate_catalog_item_type()`** | Permite validar, en triggers, que un ID en una columna "\*\_item\_id" corresponda al `type_code` adecuado. |
| **Triggers en tablas de negocio**               | Invocan la función de validación antes de INSERT/UPDATE para cada columna "\*\_item\_id".                  |
| **Vistas `vw_catalog_<type_code>`**             | Vistas de solo lectura que exponen los valores "activos" de cada catálogo junto con sus traducciones.      |
| **Índice `idx_catalog_items_type_code`**        | Índice (catalog\_type\_id, code) para acelerar filtros basados en tipo y código.                           |
| **Índice GIN `idx_cit_tr_name`**                | Índice de texto completo sobre `catalog_item_translations.translated_name` para búsquedas rápidas.         |
| **Rol `app_user`**                              | Rol al que se le concedieron permisos de SELECT sobre tablas y vistas de catálogos para lectura segura.    |

---

## 10. Conclusión y Próximos Pasos

Con estos cambios:

1. **Integridad Referencial** → garantizada por triggers que validan el `type_code` y que los IDs existan en `catalog_items` y no estén eliminados (`is_deleted = false`).
2. **Flexibilidad Dinámica** → se pueden agregar nuevos tipos de catálogo en `catalog_types` y, en 5 pasos, montar toda la cadena: ítems, mapeo, trigger, vista, permisos.
3. **Rendimiento** → índices adecuados (compuestos y GIN) aseguran búsquedas rápidas, incluso con textos largos o búsquedas full-text.
4. **Seguridad de Solo Lectura** → el rol `app_user` sólo tiene permisos `SELECT` (ningún DML ni DDL), evitando modificaciones accidentales desde la capa de aplicación.
5. **Documentación In Situ** → comentarios (`COMMENT ON`) en cada objeto ayudan a entender rápidamente el propósito y las reglas de cada tabla, columna, función y vista.
6. **Automatización de Pruebas** → se sugiere usar pgTAP o scripts de validación SQL en el pipeline de CI/CD para detectar cualquier ruptura en las reglas de integridad o permisos.

**Próximos pasos recomendados**:

* **Revisar periódicamente** (por ejemplo, en cada despliegue) que las columnas "\*\_item\_id" nuevas se agreguen a `util.catalog_fk_map` y que se creen sus triggers correspondientes.
* **Ejecutar pruebas automáticas** (pgTAP o SQL) tras cada migración de esquema para validar que no hay filas huérfanas ni permisos rotos.
* **Mantener un registro** (changelog) de todos los `type_code` nuevos y de los triggers asociados para facilitar auditorías y futuras modificaciones.
* **Documentar en el repositorio** los cinco pasos para agregar un nuevo catálogo (sección 7 de este documento), de modo que cualquier miembro del equipo sepa exactamente qué scripts ejecutar.

Con esta documentación, el equipo de desarrollo y operaciones dispone de una guía clara para entender, mantener y extender el sistema de catálogos dinámicos con seguridad, integridad y rendimiento garantizados.