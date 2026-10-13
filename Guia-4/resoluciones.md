# 1

## 1.1

1. escalado horizontal rígido: como las RDB deben garantizar ACID, al particionar se incrementan los costos de consultas.
2. rigidez en los esquemas: cambiar un esquema de una tabla que contiene millones de registros requiere bloquear las nuevas escrituras, dejando inoperable la aplicación hasta finalizada la migración
3. Velocidad de respuestas ante consulta masiva de datos: en general, son más lentas con grandes volumenes de datos por los joins que deben resolver. 

Las bases de datos NoSQL atacan estos 3 problemas (de manera diferente según el tipo de NoSQL), permitiendo esquemas flexibles, consultas rápidas sin joins (diseño de esquema hecho en función de la consulta), consistencia eventual para garantizar disponibilidad.

## 1.2

key-value: administra los datos en una sola tabla en memoria que accede a datos por clave. La clave se estructura de tal forma que no tenga colisiones entre entidades como entidad:id:atributo. Opcionalmente se puede usar namespace para evitar colisiones entre entidades con el mismo nombre. 

Documental: también se accede a los datos por clave pero el valor son documentos. Pueden ser JSON, XML y otros. Se permite también hacer consultas por atributos dentro del documento, a diferencia de las key-value que traen el objeto entero y luego la aplicación debe procesar el filtro. Los documentos pueden ser refernciados o incrustados, y se diseñaran según el caso de uso (las consultas que se tengan que procesar).

Column family: se modela los datos en base a las consultas. Una sola tabla por consulta y se tienen varios valores nulos (fisicamente no se guardan los nulos, se usan filas dispersas) entre las columnas. Esto para evitar joins y hacer consultas de lectura más rápidas. Las consultas se hacen en un lenguaje parecido a SQL: CQL. Se diseñan los esquemas con primary keys compuestas, donde una parte corresponde a la partition key y la otra a la clave de ordenamiento. Con la partition key se establece a cual nodo del sistema distribuido irá el dato. 

Grafos: no lo vemos en la materia pero está pensado para optimizar sobre consultas que en RDB usan muchos joins.



> CAP:
>- **Redis / Key-Value:** Tradicionalmente configurado como **CP** (o nodo único), aunque con replicación asíncrona prioriza rendimiento local.
>- **MongoDB / Documental:** Por defecto tiende a **CP** (un nodo primario acepta escrituras para consistencia fuerte).
>- **Cassandra / Wide Column:** Nace con enfoque **AP** (alta disponibilidad y consistencia eventual), aunque permite ajustar el nivel de consistencia (*tunable consistency*).

## 1.3

El namespace es un mecanismo para aislar/agrupar claves en la base de datos key-value. De esta forma se evita colisiones de clave de distintas entidades: namespace:id:atributo. Por ejemplo User:123:name y Product:123:name

## 1.4

Ejemplos de datos que deberían tener TTL en una base de datos key-value:
- tokens de acceso
- token de verificación enviados por SMS o mail, que tienen una validez de cierto tiempo para autenticar el registro o login de usuario
- Carritos de compra, en general no deberían de persistir mas de un par de dias.
- Rate limiting de una feature: se puede contar la cantidad de "llamadas" que hace un usuario y ponerle cierto limite por tiempo: Ej, 100 llamadas por minuto a una API.

## 1.5

key-value:
- ventajas: Máxima velocidad de lectura: buscar clave por hash. facil escalado horizontal.
- desventaja: no saben nada del valor interno, por lo que no se puede indexar o filtrar por atributos especificos que tenga el valor. Queda en responsabilidad de la aplicación

Documentales:
- ventajas: permiten indexar y filtrar por atributos internos del valor.
- desventajas: en consecuencia son más lentas que las clave-valor al tener este costo de procesamiento adicional.

## 1.6

Permite que se puedan agregar más features a futuro facilmente. La desventaja es que genera heterogeneidad de los datos y costo adicional del lado aplicación para mantenerlo. 

Permite evolucionar el modelo ágilmente agregando o modificando campos sin migraciones costosas (como un `ALTER TABLE` que bloquee escrituras). Pero la responsabilidad de validar la coherencia y tipos de datos se traslada por completo al código de la aplicación; si no se controla bien, pueden convivir documentos con formatos viejos o inconsistentes.

## 1.7

La normalización consiste en particionar relaciones para eliminar anomalías producidas por redundancia de datos. Esto obliga a tener que hacer joins para resolver consultas.  Y si se tiene un gran volumen de datos, las consultas terminan siendo lentas. 
Des-normalizar vuelve a agrupar relaciones pagando redundancia por consultas más rápidas (al eliminar joins).

Otros casos:
- Lecturas atómicas y conjuntas: Cuando dos entidades se leen casi siempre al mismo tiempo y la tasa de escritura o modificación de los datos duplicados es baja.
- Congelamiento de datos (Data freeze): Cuando se requiere preservar el estado histórico de una entidad en un instante dado (por ejemplo, el precio unitario y la dirección de envío dentro de una factura o reserva, que no deben cambiar aunque el producto o el cliente se actualicen más adelante).

## 1.8

Estan pensadas para datos distribuidos en red. Se diseña la primary key de una entidad con 2 partes: partition key que indico sobre qué columnas se va a hashear para eligir a cual cluster guardar el dato, y clustering key que indica como agrupar/ordenar los datos dentro del cluster.
Además las tablas se diseñan en base a las consultas: se guarda todo en una sola tabla para no requerir joins. Los registros que no tengan datos para ciertas columnas no tienen esas entradas (filas dispersas).
El lenguaje de consulta es CQL, parecido a SQL. Se requiere que el orden de filtrado sea igual al de la primary key: primero el partition key y luego cada columna del clustering key en orden (esta restricción por la estructura de representación que se usa para indexar).

- Frente a Key-Value: Key-Value trata el valor como un bloque opaco accesible solo por su clave; Column Family ofrece una estructura interna tabular y multidimensional ordenada por clustering keys dentro de cada partición
- frente a Documental: Las bases documentales permiten consultas más flexibles y filtros sobre atributos arbitrarios mediante índices secundarios; Column Family es mucho más estricta y exige respetar siempre el prefijo de la clave primaria para poder consultar.

## 1.9

Intuitivamente: En bases de datos distribuidas físicamente, no se puede garantizar consistencia inmediata y disponibilidad (availability), ya que requeriría pausar las operaciones de todos los nodos hasta completar una escritura en toda la red. Por eso se relaja la primera restricción a consistencia eventual: luego de cierto tiempo todos los nodos tendrán una copia del objeto con el mismo valor.

Mas formalmente: la consistencia eventual garantiza que, si no se realizan nuevas actualizaciones sobre un dato, eventualmente todas las réplicas convergerán y cualquier lectura devolverá el último valor escrito. Mientras tanto, durante la ventana de inconsistencia, el sistema puede devolver datos obsoletos (stale data).

## 1.10

CAP: Consistency, Availability, Partition Tolerance. Un sistema distribuido no puede garantizar las 3 propiedades al mismo tiempo. A lo sumo 2 de ellas.

- **Consistencia ($C$):** Cada lectura recibe la escritura más reciente o un error (linealizabilidad).
- **Disponibilidad ($A$):** Cada nodo no averiado responde a las solicitudes con éxito, sin garantizar que sea el dato más reciente.
- **Tolerancia a Particiones ($P$):** El sistema sigue funcionando a pesar de que la red pierda o demore mensajes entre nodos.

En el mundo real, las fallas de red son inevitables, por lo que **$P$ no es negociable** en un sistema distribuido. Por eso, el teorema realmente plantea una elección forzada **ante una partición de red**:
- **Elegir $CP$:** Si se aísla un nodo, se bloquean las lecturas/escrituras para evitar inconsistencias (sacrificando disponibilidad).
- **Elegir $AP$:** Los nodos aislados siguen respondiendo aunque tengan datos viejos (sacrificando consistencia fuerte).

# 2

## 2.1

La relación es N, M y no nos dicen si la cantidad de ambos es acotada o no, voy a asumir que no. En este caso, podemos hacer 2 conjuntos de documentos: uno para usuario y otro para grupo. Ambos guardan una lista con referencias a los otros documentos.
Alternativas: 
- incrustar dentro de un documento usuario una lista con los documentos a los grupos que pertenece
- Idem pero incrustando usuarios en los documentos de los grupos

La alternativa que se elija va depender de las consultas que se hagan:

- Si se leen y actualizan por separado conviene hacer ambas referencias
- Si se debe leer rápidamente los grupos de un usuario, se debe incrustar los grupos al usuario
- Si se debe leer rápidamente los usuarios de un grupo, se debe incrustar los usuarios al grupo.
- Si se deben leer ambas rápidamente , se podría hacer ambas incrustaciones pero se agrega el costo de mantenimiento de mantener la consistencia.
- Si se debe actualizar rápidamente los usuarios de un grupo particular, conviene que ambos estén separados y el grupo guarde las referencias. O al revés si se necesita actualizar los grupos de un usuario.

```json

"Alternativa 1"
Usuario: {"Password": ... ,"IdUsuario": ... , "Nombre": ... , "Grupos": [idGrupo1, ... idGrupoN] }
Grupo: {"IdGrupo": ... , "Nombre": ... , "usuarios": [IdUsuario1, ... , IdUsuarioM] }


"Alternativa 2"
Usuario: {
    "Password": ... ,
    "IdUsuario": ... , 
    "Nombre": ... , 
    "Grupos": [
        {"IdGrupo1": ... , "NombreGrupo1": ... }, ... 
        {"IdGrupoM": ... , "NombreGrupoM": ... }
    ] 
}

"Alternativa 3"
Grupo: {
    "IdGrupo": ... , 
    "Nombre": ... , 
    "usuarios": [
        {"Password1": ... ,"IdUsuario1": ... , "NombreUsuario1": ... }, ... ,
        {"PasswordM": ... ,"IdUsuarioM": ... , "NombreUsuarioM": ... }
    ] 
}

```


## 2.2

```json

{
    "idEditorial": "idEditorial1",
    "nombre": "O’Reilly Media",
    "fundada": 1980,
    "ubicacion": "CA"
}

{
    "titulo": "MongoDB: The Definitive Guide",
    "autor": [ "Kristina Chodorow", "Mike Dirolf" ],
    "fecha_pub": ISODate("2010-09-24"),
    "paginas": 216,
    "idioma": "English",
    "editorial": "idEditorial1"
}
{
    "titulo": "50 Tips and Tricks for MongoDB Developer",
    "autor": "Kristina Chodorow",
    "fecha_pub": ISODate("2011-05-06"),
    "paginas": 68,
    "idioma": "English",
    "editorial": "idEditorial1"
}
```

## 2.3

### a

```SQL
CREATE TABLE IF NOT EXISTES articulos_con_cita (
  titulo text,
  fecha text,
  cita text
PRIMARY KEY ((cita), titulo)
);

SELECT titulo , fecha FROM articulos_con_cita WHERE cita = <titulo dado>

```

### b

```SQL
CREATE TABLE IF NOT EXISTES autores_por_fecha(
  nombre text,
  apellido text,
  titulo text,
  fecha text,
PRIMARY KEY ((fecha), nombre, apellido, titulo)
);

SELECT nombre, apellido FROM autores_por_fecha WHERE fecha = <fecha dada>
```

## 2.4

```xml
<!--clave-->
usuario:<id>:<fecha>:<hora>
```

y el valor corresponde a un objeto con todos los datos que se requiere guardar.

Luego para poder consultar las fechas y horas que tiene disponible un usuario se debe guardar una lista con ellas: 

```xml
<!--clave-->
usuario:<id>:partidas
```

con valor lista de fecha y horas ```[ "2026-10-12_21:00", "2026-10-12_22:30", ... ]```

## 2.5

Criterios para diseñar bases de datos key value:
- Agrupar atributos que siempre se leen o escriben juntos
- Separar aquellos atributos grandes que se actualizan o leen de manera independiente, para no transferir datos pesados innecesariamente.

Con esto en cuenta las claves son:

```xml
usuario:<email>:datos_personales
usuario:<email>:claves_publicas
usuario:<email>:imagen
usuario:<email>:audio
```

Los primeros 2 podrían guardar un JSON con los datos o un hashmap campo: valor.

## 2.6
## 2.7
## 2.8
## 2.9
## 2.10