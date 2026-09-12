# Anomalías y Formas Normales

## 1FN — Primera Forma Normal

### Descripción y justificación

Una relación está en **1FN** si todos sus atributos tienen valores **atómicos**.

No debe haber listas, conjuntos ni grupos repetitivos dentro de una celda.

### Ejemplo de eliminación de cada tipo de anomalía

Supongamos:

| Alumno | Teléfonos |
|---|---|
| Juan | 1111, 2222 |
| Ana | 3333, 4444 |

El atributo `Teléfonos` contiene varios valores, por lo que no cumple 1FN.

Se puede transformar en:

| Alumno | Teléfono |
|---|---|
| Juan | 1111 |
| Juan | 2222 |
| Ana | 3333 |
| Ana | 4444 |

Esto permite insertar, modificar y borrar un teléfono individualmente.

### Anomalía que no resuelve

La 1FN **no resuelve las anomalías clásicas de actualización, inserción y borrado causadas por redundancia**.

Por ejemplo, si tenemos:

| Alumno | Materia | NombreAlumno |
|---|---|---|
| 1 | Matemática | Juan |
| 1 | Física | Juan |

el nombre de Juan sigue estando repetido aunque la relación esté en 1FN.

---

# 2FN — Segunda Forma Normal

### Descripción y justificación

Una relación está en **2FN** si:

1. Está en 1FN.
2. Ningún atributo no primo depende funcionalmente de una **parte propia de una clave candidata compuesta**.

La 2FN elimina las **dependencias parciales**.

### Ejemplo de eliminación de cada tipo de anomalía

Supongamos:

```text
Cursa(idAlumno, idMateria, nombreAlumno, nombreMateria, nota)
```

con clave:

```text
{idAlumno, idMateria}
```

y dependencias:

```text
idAlumno → nombreAlumno
idMateria → nombreMateria
{idAlumno, idMateria} → nota
```

Tenemos una dependencia parcial:

```text
idAlumno → nombreAlumno
```

porque `idAlumno` es solamente una parte de la clave.

La relación puede tener:

| Alumno | Materia | NombreAlumno | Nota |
|---|---|---|---|
| 1 | 10 | Juan | 8 |
| 1 | 20 | Juan | 7 |
| 1 | 30 | Juan | 9 |

### Anomalía de actualización

Si Juan cambia de nombre, debemos modificar todas sus filas.

La descomposición:

```text
Alumno(idAlumno, nombreAlumno)
Cursa(idAlumno, idMateria, nota)
```

hace que el nombre aparezca una sola vez.

### Anomalía de inserción

Antes, no podemos registrar un alumno que todavía no curse ninguna materia sin introducir información artificial.

Después podemos insertar:

```text
Alumno(2, Pedro)
```

sin necesidad de una materia.

### Anomalía de borrado

Antes, si eliminamos todas las materias cursadas por Juan, también podemos perder la información de que Juan existe.

Después, eliminar sus cursos no elimina:

```text
Alumno(1, Juan)
```

### Anomalía que no resuelve

La 2FN **no resuelve las anomalías producidas por dependencias transitivas**.

Por ejemplo:

```text
Empleado → Departamento
Departamento → NombreDepartamento
```

Puede seguir existiendo redundancia de `NombreDepartamento` aunque la relación esté en 2FN.

---

# 3FN — Tercera Forma Normal

### Descripción y justificación

Una relación está en **3FN** si para toda dependencia funcional no trivial:

\[
X\to A
\]

se cumple al menos una de las siguientes condiciones:

1. \(X\) es superclave.
2. \(A\) es atributo primo.

Intuitivamente, la 3FN elimina dependencias transitivas problemáticas de atributos no primos.

### Ejemplo de eliminación de cada tipo de anomalía

Supongamos:

```text
Empleado(idEmpleado, idDepartamento, nombreDepartamento)
```

con:

```text
idEmpleado → idDepartamento
idDepartamento → nombreDepartamento
```

Entonces:

```text
idEmpleado → idDepartamento → nombreDepartamento
```

Tenemos una dependencia transitiva.

La relación puede contener:

| Empleado | Departamento | NombreDepartamento |
|---|---|---|
| 1 | 10 | Ventas |
| 2 | 10 | Ventas |
| 3 | 10 | Ventas |
| 4 | 20 | Sistemas |

La descomponemos como:

```text
Empleado(idEmpleado, idDepartamento)
Departamento(idDepartamento, nombreDepartamento)
```

### Anomalía de actualización

Antes, si el departamento 10 cambia de "Ventas" a "Comercial", debemos actualizar todas las filas de empleados de ese departamento.

Después:

```text
Departamento(10, Comercial)
```

se modifica una sola vez.

### Anomalía de inserción

Antes, no podemos registrar:

```text
Departamento(30, Marketing)
```

si todavía no tiene empleados.

Después podemos insertar el departamento independientemente de los empleados.

### Anomalía de borrado

Antes, si eliminamos al último empleado de un departamento, podemos perder también la información del departamento.

Después, el departamento existe independientemente de sus empleados.

### Anomalía que no resuelve

La 3FN **no garantiza FNBC**.

Puede existir una dependencia:

\[
X\to A
\]

donde \(X\) **no sea superclave**, pero \(A\) sea un atributo primo.

En ese caso la relación puede estar en 3FN pero no en FNBC.

---

# FNBC — Forma Normal de Boyce-Codd

### Descripción y justificación

Una relación está en **FNBC** si para toda dependencia funcional no trivial:

\[
X\to Y
\]

se cumple:

\[
X\text{ es superclave}
\]

La FNBC es más restrictiva que la 3FN.

### Ejemplo de eliminación de cada tipo de anomalía

Supongamos:

\[
R(A,B,C)
\]

con:

\[
AB\to C
\]

\[
C\to B
\]

y claves:

\[
AB,\ AC
\]

La dependencia:

\[
C\to B
\]

viola FNBC porque \(C\) no es superclave.

Sin embargo, puede cumplir 3FN porque \(B\) es un atributo primo.

Una posible descomposición es:

\[
R_1(C,B)
\]

\[
R_2(A,C)
\]

Ahora en \(R_1\):

\[
C\to B
\]

y \(C\) es clave.

Por lo tanto, se elimina la redundancia causada por el determinante \(C\) que no era superclave en la relación original.

### Anomalía de actualización

La información determinada por \(C\) puede estar repetida en varias filas.

Separando \(C\) y \(B\), cada valor de \(C\) aparece una sola vez asociado con su \(B\).

### Anomalía de inserción

Podemos registrar la relación:

```text
C → B
```

sin necesitar los demás atributos de la relación original.

### Anomalía de borrado

Eliminar una ocurrencia de \(C\) en la relación original ya no implica necesariamente perder la información asociada:

```text
C → B
```

porque esa información está separada.

### Anomalía que no resuelve

La FNBC **no garantiza la preservación de todas las dependencias funcionales al descomponer**.

Una descomposición puede estar en FNBC pero perder **preservación de dependencias (SPDF)**.

Además, FNBC no garantiza por sí sola la preservación de dependencias; esto es independiente de que la descomposición sea sin pérdida de información (SPI).

---

# Resumen

| Forma normal | Principal problema que elimina | Problema que puede permanecer |
|---|---|---|
| **1FN** | Valores no atómicos y grupos repetitivos | Redundancia y anomalías de actualización/inserción/borrado |
| **2FN** | Dependencias parciales | Dependencias transitivas |
| **3FN** | Dependencias transitivas problemáticas | Dependencias que violan FNBC |
| **FNBC** | Determinantes que no son superclaves | Puede perderse preservación de dependencias |

### Regla mental

```text
1FN → ¿Los valores son atómicos?

2FN → ¿Hay dependencia parcial de una clave compuesta?

3FN → ¿Hay dependencia transitiva problemática?

FNBC → ¿Todo determinante es superclave?
```

Importante: **las anomalías no se asignan de forma exclusiva a una forma normal**. Actualización, inserción y borrado pueden aparecer por diferentes tipos de redundancia. Las formas normales eliminan progresivamente las **causas estructurales** de esas anomalías.