# Motor de Base de Datos y Optimización en SQL Server

---

## 1. Almacenamiento Físico y Estructuras de Datos

### Páginas y Extents
* **Página (8 KB):** Es la unidad mínima de entrada/salida (I/O) en disco. Los datos siempre se leen y escriben en páginas enteras.
* **Extent (64 KB):** Bloque de 8 páginas contiguas usado para gestionar el espacio eficientemente.

### Heap (Montículo) vs. B+Tree
* **Heap:**
  * Tabla sin un orden físico predefinido. Las filas se insertan donde haya espacio libre disponible.
  * *Ventaja:* Inserciones masivas (*bulk insert*) a máxima velocidad, ideal para tablas de paso (*staging*).
  * *Desventaja:* Búsquedas puntuales requieren recorrer toda la tabla (**Table Scan**). Las modificaciones de longitud pueden generar **Forwarding Pointers**, incrementando lecturas.
* **B+Tree (Índice Agrupado / Clustered Index):**
  * La tabla completa se organiza como un árbol B+.
  * **Nivel Raíz e Intermedios:** Contienen únicamente valores clave y punteros hacia páginas de niveles inferiores.
  * **Nivel Hoja:** Contiene las filas reales con **todas las columnas de la tabla**, ordenadas físicamente por la clave del índice.
  * Permite búsquedas en tiempo logarítmico: $O(\log N)$.

---

## 2. Índices: Clustered vs. Non-Clustered y Covering Indexes

### Clustered Index vs. Primary Key
* **Primary Key:** Restricción lógica (unicidad y no nulidad).
* **Clustered Index:** Estructura física del almacenamiento. Por defecto, SQL Server asocia la Primary Key a un Clustered Index, pero son conceptos independientes.

### Non-Clustered Index (Índice Secundario)
* Es un árbol B+ completamente independiente del principal.
* **Nivel Hoja:** Contiene exclusivamente las columnas clave del índice secundario más un **puntero** a la fila del Clustered Index (la clave agrupada).
* **Key Lookup (Salto Costoso):**
  * Ocurre cuando la consulta solicita columnas que no están presentes en el índice secundario.
  * El motor localiza la fila en el índice secundario mediante un **Index Seek**, pero debe saltar al Clustered Index para leer las columnas restantes.
  * Si la consulta devuelve muchas filas, miles de *Key Lookups* degradan gravemente el rendimiento; el optimizador suele preferir un Scan completo en su lugar.

### Covering Index y la cláusula `INCLUDE`
* **Solución al Key Lookup:** Agregar las columnas consultadas al índice secundario.
* **¿Por qué `INCLUDE` y no clave compuesta?**
  * Las columnas en `INCLUDE` se almacenan **únicamente en el nivel hoja** del índice no agrupado.
  * No forman parte de las claves de búsqueda en los niveles raíz e intermedios.
  * Ahorra espacio en las páginas de navegación, evita alterar el orden del árbol y reduce la sobrecarga de mantenimiento en escrituras.

---

## 3. Ciclo de Vida y Compilación de Consultas

El camino que recorre una consulta se divide en 4 fases sucesivas:

1. **Parse:** Valida la sintaxis SQL. Genera el Árbol de Sintaxis Abstracta (**AST**). No valida existencia de tablas ni columnas.
2. **Bind (Algebrizador):** Consulta el catálogo de metadatos, valida la existencia de tablas, columnas, tipos de datos y permisos. Convierte el AST en un **árbol de operadores lógicos** (álgebra relacional).
3. **Optimize (Cost-Based Optimizer):** Transforma los operadores lógicos en **operadores físicos concretos**.
   * Aplica reglas de reescritura como **Predicate Pushdown** (aplicar filtros antes de los Joins para reducir el volumen de filas tempranamente).
   * Evalúa planes por fases (Fase 0: Trivial, Fase 1: Transaccional rápida, Fase 2: Completa).
   * Emplea un criterio de parada temprana (**Good Enough Plan**): elige un plan suficientemente bueno sin consumir tiempo excesivo de CPU en compilar.
4. **Execute:** El motor de ejecución procesa el plan físico mediante llamadas iterativas: `Open()`, `GetRow()` y `Close()`.

---

## 4. Operadores del Plan de Ejecución

### Operadores de Acceso
* **Table Scan:** Recorrido completo de una tabla tipo Heap.
* **Index Scan:** Recorrido secuencial de todas las páginas hoja de un índice.
* **Index Seek:** Navegación jerárquica logarítmica desde la raíz hasta un valor o rango de valores puntuales.

### Operadores de Transformación y Flujo
* **Sort (Operador Bloqueante / Stop-and-Go):**
  * Debe absorber y almacenar todas las filas de entrada antes de poder emitir la primera fila ordenada.
  * Si la memoria RAM asignada (*memory grant*) no alcanza, sufre un **Sort Spill to tempdb**, escribiendo en disco y degradando el tiempo de respuesta.
* **Distinct Sort:** Ordena los datos y descarta duplicados en el mismo paso.
* **Compute Scalar:** Operador no bloqueante (*streaming*) que calcula expresiones escalares fila a fila en memoria (por ejemplo, funciones matemáticas o de texto).
* **Filter:** Evalúa condiciones booleanas fila por fila cuando no pudieron resolverse en el operador de acceso inicial.

### Algoritmos Físicos de Join
| Algoritmo | Requisitos / Características | Cuándo se usa |
| :--- | :--- | :--- |
| **Nested Loops** | La entrada externa itera y busca en la interna fila a fila. | Conjunto exterior pequeño y conjunto interior con índice. |
| **Merge Join** | Lee ambas entradas en paralelo una sola vez. | Ambas entradas vienen previamente ordenadas por la clave del join. |
| **Hash Join** | Construye una tabla hash en memoria con la tabla menor y luego la compara con la mayor. | Tablas grandes, no ordenadas y sin índices adecuados. |

### Operadores de Agregación (`GROUP BY`, `DISTINCT`)
* **Stream Aggregate:** Procesa las filas en flujo (*streaming*). Muy rápido y bajo consumo de memoria. **Exige datos previamente ordenados**.
* **Hash Aggregate:** Construye una tabla hash en memoria con las claves distintas. Ideal para grandes volúmenes no ordenados.

### Operaciones de Conjuntos
* **`UNION ALL` (Operador Concat):** Une los flujos fila a fila sin verificar duplicados (*streaming* puro, óptimo en recursos).
* **`UNION`:** Requiere deduplicación. Inserta internamente un **Distinct Sort** o un **Hash Aggregate**, requiriendo retener filas en memoria.

---

## 5. Estadísticas, Tuning y Control del Motor

### Estadísticas e Histogramas
* Guían la **estimación de cardinalidad** (cuántas filas se esperan).
* El histograma divide los datos en hasta 200 intervalos (*steps*).
* Si las estadísticas quedan obsoletas tras muchas modificaciones, el optimizador subestima o sobrestima costos, eligiendo operadores inadecuados (ej. Loops en vez de Hash) o asignando memoria insuficiente.

### SARGability (*Search Argument Able*)
* Capacidad de un predicado en el `WHERE` de ser resuelto con un **Index Seek**.
* **No SARGable:** `WHERE YEAR(Fecha) = 2024` (aplica una función sobre la columna; obliga a un Scan completo).
* **SARGable:** `WHERE Fecha >= '2024-01-01' AND Fecha < '2025-01-01'` (compara la columna aislada contra constantes; permite Seek de rango).

### Parameter Sniffing y Control de Planes
* **Parameter Sniffing:** El motor compila y almacena en el *Plan Cache* un plan optimizado para el valor del parámetro de la primera ejecución. Si los datos están sesgados, ejecuciones posteriores con otros parámetros pueden sufrir un rendimiento deficiente.
* **Soluciones:**
  * `OPTION (RECOMPILE)`: Fuerza la compilación de un plan nuevo y a medida en cada ejecución. Ideal para procesos esporádicos o reportes complejos con alta varianza.
  * `OPTION (OPTIMIZE FOR (@var = valor))`: Instruye al optimizador a calcular el plan asumiendo un valor fijo representativo.
* **Query Hints (Último recurso):**
  * Directivas manuales como `WITH (INDEX(...))`, `WITH (FORCESEEK)` o `OPTION (MERGE JOIN)`.
  * Riesgo: Si el esquema cambia o los datos crecen, pueden congelar planes ineficientes o provocar errores en tiempo de ejecución.


  Aquí tienes la sección complementaria para añadir al final de tus notas, con ejemplos representativos de cómo las estadísticas y los índices determinan el plan físico final.


## 6. Casos Prácticos: Del SQL al Plan Físico

Para todos los ejemplos siguientes, asumimos este esquema:
* Tabla `Ventas` con **1.000.000 de filas**.
* Clustered Index (PK) en `VentaID`.
* Non-Clustered Index `IX_Cliente` en `(ClienteID)`.
* Histograma de `ClienteID`: el valor `10` tiene solo **2 filas** asociadas (`EQ_ROWS = 2`), mientras que el valor `500` tiene **350.000 filas** asociadas (`EQ_ROWS = 350000`).

---

### Caso 1: Búsqueda altamente selectiva con columnas adicionales
```sql
SELECT VentaID, Fecha, Total 
FROM Ventas 
WHERE ClienteID = 10;
```

* **Operadores físicos resultantes:**
1. `Index Seek` sobre `IX_Cliente`.
2. `Key Lookup` hacia el Clustered Index por `VentaID`.
3. `Nested Loops` que une el seek con cada lookup.


* **Justificación en estadísticas:**
* El histograma indica una cardinalidad estimada de apenas **2 filas**.
* El costo de realizar 2 saltos por árbol B+ (**Key Lookups**) es insignificante frente al costo de leer secuencialmente las miles de páginas de toda la tabla en un scan.



---

### Caso 2: Búsqueda poco selectiva (Tipping Point)

```sql
SELECT VentaID, Fecha, Total 
FROM Ventas 
WHERE ClienteID = 500;

```

* **Operadores físicos resultantes:**
* `Clustered Index Scan` (o `Table Scan`) directo sobre toda la tabla, evaluando el predicado `WHERE` en cada fila.


* **Justificación en estadísticas:**
* El histograma estima **350.000 filas** (35% de la tabla).
* Realizar 350.000 `Key Lookups` generaría una cantidad inmensa de I/O aleatorio (muchas veces leyendo la misma página repetidamente).
* El optimizador determina que una lectura secuencial continua de todas las páginas de la tabla tiene un costo computacional y de I/O mucho menor.



---

### Caso 3: Consulta cubierta (*Covering Index*)

Asumiendo que existe el índice:
`CREATE INDEX IX_Cliente_Cubridor ON Ventas(ClienteID) INCLUDE (Fecha, Total);`

```sql
SELECT Fecha, Total 
FROM Ventas 
WHERE ClienteID = 500;
```

* **Operadores físicos resultantes:**
* `Index Seek` sobre `IX_Cliente_Cubridor`.


* **Justificación en estadísticas e índices:**
* Aunque se devuelven 350.000 filas, **todas** las columnas requeridas (`Fecha`, `Total`) residen en el nivel hoja de este índice no agrupado.
* El optimizador navega hacia el inicio del rango `ClienteID = 500` y lee secuencialmente sólo las páginas hoja del índice secundario correspondientes a ese cliente, **eliminando el 100% de los Key Lookups**.



---

### Caso 4: Agregación sin orden previo vs. con orden previo

```sql
-- Consulta A: Sin índice en Estado
SELECT Estado, COUNT(*) 
FROM Ventas 
GROUP BY Estado;

-- Consulta B: Con índice en ClienteID
SELECT ClienteID, COUNT(*) 
FROM Ventas 
GROUP BY ClienteID;
```

* **Operadores físicos resultantes:**
* **Consulta A:** `Table Scan` / `Clustered Index Scan` ➔ `Hash Match (Aggregate)`.
* **Consulta B:** `Index Scan` sobre `IX_Cliente` ➔ `Stream Aggregate`.


* **Justificación en estadísticas e índices:**
* En la **Consulta A**, no hay orden físico por `Estado`. El optimizador estima la cantidad de estados distintos por la densidad de la columna y prefiere construir una tabla hash en memoria antes que pagar el costo de un operador `Sort` explícito.
* En la **Consulta B**, el índice `IX_Cliente` ya entrega los datos ordenados por `ClienteID`. El optimizador aprovecha este orden natural para aplicar un `Stream Aggregate`, procesando las filas en flujo continuo con mínimo uso de CPU y memoria.

Exacto 🎯. Al alcanzar la fila **10.001**, el operador `Top` envía una señal de detención hacia abajo y no pide ni una fila más. Realiza exactamente 10.001 lookups en lugar de 350.000 🛑.


### Caso 5: Optimización de conteos con Top y evaluación de Lookups
```sql
SELECT TOP (10001) 1 
FROM Ventas 
WHERE ClienteID = @ClienteID;

```

* **Operadores físicos resultantes:**
* `Index Seek` sobre `IX_Cliente` ➔ `Top (10001)` ➔ `Stream Aggregate` (para el `COUNT`).


* **Comportamiento de I/O y Lookups:**
* **Cero Key Lookups:** Como solo se proyecta un literal (`1`), el índice secundario cubre toda la consulta. No se accede al Clustered Index.
* **Corte temprano:** Para clientes masivos (e.g., 350.000 ventas), la consulta frena inmediatamente al alcanzar la fila 10.001, protegiendo memoria y lecturas en disco.
* *Nota sobre columnas no cubiertas:* Si se proyectara una columna ausente en el índice (como `Fecha`), el motor ejecutaría **únicamente 10.001 Key Lookups** antes de frenar, evitando los 350.000 potenciales.


