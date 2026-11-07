### 1. Estructuras de Almacenamiento Físico: Heap vs. B-Tree (B+Tree)

El motor maneja la memoria y el almacenamiento secundario mediante **páginas de tamaño fijo** (típicamente de $8\text{ KB}$ en motores como SQL Server o PostgreSQL). En disco, un archivo es un arreglo contiguo de páginas identificadas lógicamente por un **`PageID`** ($Offset = \text{PageID} \times \text{PageSize}$), el cual el *Buffer Pool* mapea a marcos de memoria RAM (*frames*) mediante tablas hash de memoria.

```
Página física (8 KB) - Esquema Slotted Page:
+-----------------------------------------------------------------------+
| Page Header: LSN, prev_page_id, next_page_id, cantidad de slots       |
+-----------------------------------------------------------------------+
| Slot Array (Offsets a cada tupla):                                    |
| [Slot 0: offset 7800] [Slot 1: offset 7520] [Slot 2: offset 7100]... |
|                          ESPACIO LIBRE                                |
| ...Tupla C (7100)        ...Tupla B (7520)        ...Tupla A (7800)   |
+-----------------------------------------------------------------------+

```

| Propiedad | Heap (Montículo) | B-Tree / B+Tree |
| --- | --- | --- |
| **Organización** | Datos desordenados; las filas se insertan donde haya espacio libre según mapas de asignación (IAM / FSM). | Estructura jerárquica estrictamente balanceada y ordenada por una o más claves. |
| **Identificador de fila** | **RID (Row Identifier):** Par físico-lógico directo `(PageID, SlotIndex)`. | Clave de ordenamiento propia; en hojas se almacena la fila o un localizador. |
| **Mantenimiento en escritura** | Inserción $O(1)$ sin reorganización; no sufre divisiones de árbol. | Requiere mantener el orden; puede disparar **Page Splits** si una página se llena. |
| **Búsqueda puntual / rango** | Requiere escaneo completo ($O(N)$) salvo que exista un índice secundario. | Navegación logarítmica ($O(\log N)$) desde la raíz y barrido horizontal de hojas. |

#### Page Splits

Ocurren cuando una página de un B+Tree se llena y debe recibir una nueva clave intermedia. El motor asigna una página nueva (generalmente no contigua físicamente en disco), transfiere aproximadamente el 50% de las tuplas, actualiza los punteros `prev_page` / `next_page` y propaga la nueva clave de enrutamiento hacia los nodos padres (pudiendo incrementar la altura del árbol). Esto genera fragmentación lógica y reduce la densidad de datos por página.

---

### 2. Clustered vs. Non-Clustered Indexes

#### Clustered Index (Índice Agrupado)

* **La tabla *es* el índice:** Las páginas hoja del B+Tree no son punteros; contienen físicamente la fila completa con todas sus columnas.
* Solo puede existir **uno por tabla** porque las filas solo pueden estar ordenadas físicamente de una única manera en disco (en PostgreSQL las tablas son siempre Heaps por defecto; el comando `CLUSTER` ordena puntualmente pero no se mantiene de forma automática).



#### Non-Clustered Index (Índice Secundario)

* Estructura B+Tree independiente del archivo de datos base.
* Las páginas hoja contienen únicamente **las columnas del índice** más un **Row Locator** hacia la tabla base:
* Si la tabla base es un **Heap**, el Row Locator es un **RID** `(PageID, SlotIndex)`.
* Si la tabla base tiene un **Clustered Index**, el Row Locator es el valor de la **Clustered Key**.



#### Composite Index (Índice Compuesto) y Leftmost Prefix

Ordena lexicográficamente según el orden declarado en la definición `(Col1, Col2, Col3)`.

* Para aprovechar el árbol en un **Index Seek**, el predicado debe filtrar de forma continua desde la columna situada más a la izquierda (**Leftmost Prefix Rule**).


* Un filtro de rango (`>`, `<`, `BETWEEN`) sobre una columna corta la capacidad de hacer *seek* directo sobre las columnas subsecuentes del índice.



---

### 3. Operaciones de Acceso, Lookups y Algoritmos en el Plan de Ejecución

#### Operadores de Acceso Físico

* **Table Scan:** Recorre secuencialmente todas las páginas de un **Heap**.
* **Clustered Index Scan:** Recorre todas las páginas hoja del índice agrupado (equivale a leer toda la tabla física).
* *Ordered Scan:* Sigue la lista enlazada de punteros `next_page`; entrega los datos ordenados según la clave agrupada pero sufre degradación de I/O si hay fragmentación.
* *Unordered Scan:* Lee los extents/páginas en orden físico secuencial usando mapas de asignación (IAM), maximizando la tasa de transferencia de I/O a costa de no garantizar orden en la salida.


* **Clustered Index Seek:** Desciende por el árbol agrupado ($O(\log N)$) evaluando un predicado de búsqueda o rango sobre la clave agrupada.
* **Index Scan (Non-Clustered):** Recorre todas las páginas hoja del índice secundario. Se prefiere al Clustered Scan cuando el índice contiene todas las columnas requeridas (**Covering Index**), ya que es un árbol mucho más estrecho y requiere leer menos páginas totales de disco/RAM.
* **Index Seek (Non-Clustered):** Desciende por el árbol secundario ($O(\log N)$) delimitando las entradas que coinciden con el filtro.

#### Mecanismos de Lookup

Cuando un índice secundario localiza filas mediante un *Seek*, pero la consulta pide columnas que no están en dicho índice:

* **RID Lookup:** Toma el `(PageID, Slot)` de la hoja secundaria y lee directamente la página del Heap.
* **Key Lookup:** Toma la clave agrupada de la hoja secundaria y ejecuta un segundo *Index Seek* en el B+Tree del Clustered Index para traer la tupla completa.
* **Tipping Point (Umbral de Inversión):** Como cada lookup produce I/O aleatorio, si la consulta devuelve más de un pequeño porcentaje de la tabla (usualmente entre 1% y 5%), el costo acumulado de los lookups supera al costo de leer la tabla secuencialmente. El optimizador descarta el índice secundario y conmuta a un **Clustered Index Scan** o **Table Scan**.

```
Índice Secundario (Seek)
       │
       ├──[Tabla Heap]─────────► RID Lookup (Página, Slot) ──────► Fila completa
       │
       └──[Tabla Clustered]────► Key Lookup (Seek en Clustered) ──► Fila completa

```

#### Operadores de Procesamiento y Algoritmos Internos

* **Compute Scalar:** Evalúa expresiones a nivel de fila en memoria y CPU (cálculos matemáticos, concatenaciones, coerciones de tipo implícitas como `BIGINT` a `INT` en un `COUNT(*)`). Es de paso (*streaming*), no bloqueante y no consume I/O.
* **Filter:** Evalúa predicados booleanos en memoria fila por fila cuando la condición no pudo empujarse directamente al motor de almacenamiento (*Predicate Pushdown*), como ocurre en cláusulas `HAVING`, funciones no SARGables o condiciones `STARTUP`.
* **Sort:** Operador bloqueante (*stop-and-go*).
* *Internal Sort:* Si los datos caben en el *Memory Grant*, usa **Quicksort** o **Introsort**. Para `TOP N` / `LIMIT`, utiliza un **Min/Max-Heap** en memoria ($O(N \log K)$).
* *External Sort:* Si los datos superan la RAM disponible, derrama particiones ordenadas (*runs*) a disco temporal (**TempDB** / `pg_temp`) y luego aplica una mezcla polifásica (**Multi-way Merge Sort**).


* **Agregaciones (`GROUP BY`, `DISTINCT`):**
* **Stream Aggregate:** Requiere que la entrada venga **estrictamente preordenada** (por índice o Sort previo). Procesa en una sola pasada manteniendo acumuladores escalares en memoria ($O(1)$ RAM). No derrama a disco.
* **Hash Aggregate:** Para datos **desordenados**. Construye una tabla hash en RAM donde cada clave distinta tiene un bucket con sus acumuladores. Es bloqueante y puede provocar *Hash Spill* a TempDB si subestima la memoria.
* **Distinct Sort:** Variante que deduplica las claves repetidas en memoria mientras ejecuta el ordenamiento, evitando una fase de agregación posterior.


* **Joins Relacionales:**
* **Nested Loops Join:** Itera la tabla externa y ejecuta un *Index Seek* sobre la tabla interna por cada fila. Óptimo para pocas filas en el exterior y tabla interna indexada.
* **Merge Join:** Requiere que **ambas entradas estén ordenadas** por la clave de unión. Realiza un barrido lineal simultáneo ($O(M + N)$) en memoria constante $O(1)$.
* **Hash Match (Hash Join):** Para tablas grandes sin índices en condiciones de igualdad (`=`). Fase *Build* (crea tabla hash en RAM con la entrada más chica) y Fase *Probe* (escanea la entrada grande buscando coincidencias en la tabla hash en streaming).


* **`UNION` vs. `UNION ALL`:**
* `UNION ALL` utiliza el operador **Concatenation**: lee una entrada y luego la otra; emisión en streaming, costo $O(1)$ de memoria adicional.
* `UNION` requiere deduplicación: ejecuta `Concatenation` y luego fuerza un **Distinct Sort** o un **Hash Match (Union/Aggregate)**, deteniendo el flujo y consumiendo *Memory Grant*.



---

### 4. ¿Cómo Elige el Optimizador entre Distintas Implementaciones?

El optimizador de consultas basado en costos (**Cost-Based Optimizer - CBO**) opera evaluando árboles de operadores equivalentes y calculando una estimación de costo (I/O de páginas + ciclos de CPU) sustentada en:

1. **Metadatos y Estadísticas:**
* **Histogramas de distribución:** Indican la dispersión de valores para estimar cuántas filas devolverá un predicado (cardinalidad estimada).
* **Densidad (`All density`):** Determina la cantidad promedio de duplicados ($1 / \text{valores únicos}$).


2. **Propiedades físicas requeridas vs. provistas:**
* Si la consulta exige orden (`ORDER BY`), el optimizador calcula si conviene usar un índice que ya provea el orden de forma gratuita (evitando un operador `Sort`) o si es más barato un escaneo desordenado seguido de un `Sort` en memoria.


3. **Integridad Referencial (Foreign Keys Confiables):**
* Si un `JOIN` solo proyecta columnas de la tabla hija y la Foreign Key está validada (`WITH CHECK` / `is_trusted = 1`), el optimizador aplica **Table Elimination**: descarta el JOIN físico y elimina la lectura de la tabla padre del plan.


4. **Parameter Sniffing y `OPTIMIZE FOR`:**
* En procedimientos almacenados o consultas parametrizadas, el motor compila el plan evaluando el valor del parámetro pasado en la **primera ejecución**.
* Si los datos tienen alta asimetría (*skew*), ese plan en caché puede ser contraproducente para llamadas posteriores con volúmenes radicalmente distintos.
* Se corrige mediante directivas como `OPTION (OPTIMIZE FOR (@param = valor))` para forzar el caso típico, `OPTION (OPTIMIZE FOR UNKNOWN)` para obligarlo a basarse en la densidad media, o `OPTION (RECOMPILE)`.



---

### 5. SARGabilidad (Search-Argument-Able) con Ejemplos Prácticos

Un predicado es **SARGable** si está formulado de modo que el motor pueda aislar límites de búsqueda exactos en un B+Tree y ejecutar un **Index Seek** en lugar de evaluar una condición sobre cada fila.

#### A. Rango Continuo (`BETWEEN`) vs. Lista Discreta (`IN` / `OR`)

```sql
-- Caso IN / OR: 4 navegaciones independientes (Scan count 4, 18 logical reads)
SELECT sod.* FROM Sales.SalesOrderDetail AS sod
WHERE sod.SalesOrderID IN (51825, 51826, 51827, 51828);

-- Caso BETWEEN: 1 sola navegación por rango (Scan count 1, 6 logical reads)
SELECT sod.* FROM Sales.SalesOrderDetail AS sod
WHERE sod.SalesOrderID BETWEEN 51825 AND 51828;

```

* **Mecánica:** `IN` se descompone en múltiples búsquedas puntuales separadas por `OR`. Cada una desciende por el árbol individualmente. `BETWEEN` desciende una única vez al límite inferior (`51825`) y luego recorre las hojas horizontalmente hasta el límite superior, reduciendo el I/O a la tercera parte.



#### B. Operaciones y Funciones sobre Columnas

```sql
-- NO SARGABLE: Requiere Clustered Index Scan / Table Scan
SELECT * FROM Purchasing.PurchaseOrderHeader AS poh
WHERE poh.PurchaseOrderID * 2 = 3400;

-- SARGABLE: Permite Clustered Index Seek directo
SELECT * FROM Purchasing.PurchaseOrderHeader AS poh
WHERE poh.PurchaseOrderID = 3400 / 2;

```

* **Mecánica:** En la primera consulta, la operación aritmética aplicada sobre la columna oculta el valor de la clave; el motor se ve obligado a leer cada fila, multiplicar por 2 y comparar en CPU. En la segunda, el cálculo `3400 / 2 = 1700` se resuelve en tiempo de parseo/compilación, dejando la columna despejada para un *Seek* directo.



#### C. Índices Compuestos y Predicados sobre Cadenas

Dado un índice en `(LastName, FirstName)`:

* **SARGable:**
* `WHERE LastName = 'Clark' AND FirstName = 'Steve'` (Seek completo sobre ambas columnas).


* `WHERE LastName = 'Clark'` (Seek sobre el prefijo izquierdo).


* `WHERE LastName LIKE 'Cl%'` (Seek de rango acotado entre `'Cl'` y `'Cm'`).




* **Non-SARGable:**
* `WHERE FirstName = 'Steve'` (No incluye la primera columna; `FirstName` está desordenado globalmente en el árbol).


* `WHERE LastName LIKE '%ar%'` (Comodín inicial; impide determinar la página de inicio en el B+Tree).


* `WHERE LastName <> 'Clark'` (Desigualdad; no delimita un rango de búsqueda puntual).





#### D. Covering Index (`INCLUDE`) e Índices Filtrados

```sql
-- Consulta
SELECT a.PostalCode FROM Person.Address AS a WHERE a.StateProvinceID = 42;

-- Índice Cubridor con INCLUDE
CREATE NONCLUSTERED INDEX IX_Address_StateProvinceID
ON Person.Address (StateProvinceID ASC)
INCLUDE (PostalCode);

```

* **Mecánica:** `StateProvinceID` forma la estructura de navegación del árbol (claves ordenadas). `PostalCode` se añade solo en las páginas hoja como carga útil (*payload*). Permite resolver la consulta íntegramente desde el índice secundario (**Index-Only Seek**), eliminando los costos de *Key Lookup* a la tabla agrupada.



```sql
-- Índice Filtrado
CREATE NONCLUSTERED INDEX IX_Test
ON Sales.SalesOrderHeader (PurchaseOrderNumber, SalesPersonID)
INCLUDE (OrderDate, ShipDate)
WHERE PurchaseOrderNumber IS NOT NULL AND SalesPersonID IS NOT NULL;

```

* **Mecánica:** Al incorporar una cláusula `WHERE` en la creación del índice, el B+Tree solo almacena y mantiene las tuplas que cumplen el filtro. Ocupa menos páginas en disco/RAM y optimiza el mantenimiento frente a inserciones con valores nulos, siendo seleccionable para consultas que acoten explícitamente su búsqueda dentro de ese subconjunto.