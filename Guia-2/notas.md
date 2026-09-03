## Consideraciones de diseño

- Evitar la información redundante en tuplas
- Evitar los valores nulos en las tuplas
- No permitir la generación de tuplas ilegítimas (Si ciertas tuplas no deber´ıan existir, no se deben permitir)
- Pérdida de información (aparición de tuplas espureas)
- Pérdida de dependencias funcionales, es decir, ciertas restricciones de integridad que dan lugar a interdependencias entre los datos
- Aparición en la BD de estados no válidos, es decir, anomalías de inserción, borrado y modificación

Para evitar anomalias:
- Descomposición de Relaciones
- Dependencias Funcionales
- Normalización

## Dependencia funcional

Decimos que X determina funcionalmente a Y (o que Y es determinado funcionalmente por X ) en R, y lo notamos $$X → Y$$ , si para todo conjunto de tuplas r(R) se verifica que si $t1(X) = t2(X)$ entonces necesariamente $t1(Y) = t2(Y)$.

> $X \rightarrow Y$ Si dos tuplas estan de acuerdo en X entonces también estan de acuerdo en Y.

r, conjunto de tuplas, es legal si cumple todas las DF

#### Axiomas de Armstrong

Sean $X$ e $Y$ conjuntos de atributos.
1. Reflexividad: Si $Y ⊆ X$ entonces $X → Y$
2. Aumento: Para cualquier $W$ , si $X → Y$ entonces $XW → YW$
3. Transitividad: Si $X → Y$ e $Y → Z$ entonces $X → Z$

Reglas adicionales (se demuestran a partir de las anteriores):

1. Unión: Si $X → Y$ y $X → Z$ entonces $X → Y$Z
2. Pseudotransitividad: Para cualquier $W$ , si $X → Y$ e $YW → Z$ entonces $XW → Z$
1. Descomposición: Si $X → YZ$ entonces $X → Y$ y $X → Z$

#### Inferencia

Decimos que F (conj de dep func) infiere f (dep func) $F ⊨ f$ , si toda $r$ tupla que satisface $F$ debe necesariamente satisfacer también $f$.

#### Clausura de DF

Se denomina clausura de un conjunto de dependencias funcionales al conjunto de todas las DF que pueden inferirse del conjunto aplicando los axiomas. $$F^+ = \{ X  → Y | \ F ⊨ X → Y \}$$

Decimos que dos conjuntos de dependencias funcionales $F$ y $G$ sobre $R$, relación, son equivalentes $$(F ≡ G) \iff F^+ = G^+$$

#### Clausura de atributos

La clausura de un conjunto de atributos $X$ respecto de $F$, es el conjunto de todos los atributos $A$ tal que $X → A$. Es decir, todos los atributos que X determina funcionalmente
$$X^+ = \{A ∈ R | \ F ⊨ X → A \}$$

## Claves

### Superclave
Dado un conjunto de atributos $X$ , un esquema $R$ y un conjunto de DF $F$ decimos que $X$ es superclave de $R$ si y solo si $X → R ∈ F^+$. 
Es decir, X determina funcionalmente a todos los atributos de la relación

### Clave (clave candidata)

Una superclave minimal. Sea $X$ superclave, no existe  $Z ⊂ X$ tal que $Z → R ∈ F^+$.

### Algoritmo clausura de atributo

Computamos una secuencia $X_0, X_1, . . .$ aplicando:
1. $X_0$ es $X$
2. $X_{i+1}$ es $X_i$ unión el conjunto de atributos $A$ tal que hay $Y → Z$ en $F$ , con $A ∈ Z$ e $Y ⊆ X_i$
3. Repetimos (2) hasta que $X_i = X_{i+1}$

### Cubrimiento minimal

Un recubrimiento minimal de un conjunto de dependencias funcionales $F$ es un conjunto de dependencias $Fm$ tal que $Fm ≡ F$ y además $Fm$ cumple:
1. Todo lado derecho tiene un unico atributo (regla de descomposición)
2. Todo lado izquierdo es reducido, es decir, no tiene atributos redundantes ($B ⊂ X$ es redundante para $X → A$ si puedo determinar funconalmente a $A$ sin $B$: $A ∈ (X − {B})^+$)
3. No contiene dependencias funcionales redundantes (en general, las que se obtienen por transitividad) ($X → A$ es redundante si $F − \{X → A \} ≡ F$ )

Quitar dependencias funcionales redundantes: $X → A$ es redundante si $A ∈ X^+$ respecto de $F − {X → A}$. Es decir, calculo $X^+$ con respecto a las DF $F − {X → A}$ y si $A ∈ X^+$ entonces la DF $X → A$ es redundante

## Descompocisión

Descomponer un esquema R es reemplazarlo por varios subesquemas $R_1, . . . , R_k$ (cada uno con un subconjunto propio de los atributos de R) de manera que la unión de los atributos de todos los $R_i$ sea exactamente $R$: todo tributo de $R$ aparece en al menos un subesquema. Se pueden repetir atributos en distintos subesquemas.

Una buena descomposición es sin perdida de información ni perdida de dependencias funcionales. 

Sea $R = (A_1, . . . , A_n)$, $F$ un conjunto de $DF$ y $ρ$ una descomposición de $R$, $$ρ = \{R_1, . . . , R_k\}$ tal que $\cup^k_{i=1} R_i = R$. Decimos que ρ es una descomposición sin pérdida de información (SPI) si para cada instancia $r$ de $R$ que satisface $F$ se verifica: $r = \cup \bowtie_{i=1}^k π_{R_i}(r)$
Donde $\pi$ proyecta la tupla $r$ de $R$ en las columnas de $R_i$.


### Proyección de dependencias funcionales

La proyección de $F$ sobre $Z$ , $π_Z(F)$, es el conjunto de $DF$ $X → Y ∈ F^+$ tal que $XY ⊆ Z$. 
Es decir, las dependencias funcionales que participan atributos de la relación Z de la descomposición R.

### Preservación de dependencias funcionales (SPDF)

Dados $R, ρ = (R_1, . . . , R_k)$ y $F$, $ρ$ preserva $F$ si la unión de las $DF$ en $π_{Ri} (F)$ implica lógicamente a F: $$F^+ = (\cup_{i_1}^k \pi_{R_i}(F))^+$$
Es decir, uno las dependencias funcionales proyectadas y la clausura de DF de la unión debe ser igual a la clausura original F.

### Descomposición binaria SPI (loseless join)

$ρ = (R1, R2)$ es lossless join respecto de $F \iff(R1 ∩ R2) → (R1 − R2) ∈ F^+$ o $(R1 ∩ R2) → (R2 − R1) ∈ F^+$.

Es decir, la intersección de los atributos es superclave de alguno de los dos esquemas. Por ejemplo, en $R1$ los atributos $(R1 ∩ R2)$ se determinan funcionalmente a si mismo y a los demás atributos, si vale $(R1 ∩ R2) → (R1 − R2)$, entonces se determina funcionalmente a los atributos de $R1$ que no están en $R2$. Y como $R = R1 + R2$ por construcción, queda determinada funcionalmente toda $R1$

### Atributo primo

Si es miembro de alguna clave (superclave minimal). Caso contrario es No primo.

### Dependencia parcial

$X → Y$ es dependencia funcional PARCIAL (o $Y$ depende parcialmente de $X$) si $Y$ solo depende de un subconjunto de $X$: para algún $Z ⊂ X$ se verifica $Z → Y$. En caso contrario es TOTAL.

## Formas normales

### 1FN

Todos los atributos son atómicos

### 2FN

Todo atributo no primo no depende parcialmente de alguna clave de R. 

Es decir, todo atributo que no pertenece a alguna clave, no depende parcialmente a alguna clave. Para que una relación este en 2FN, todo atributo no clave debe depender totalemente (de todos los atributos de) una clave.

Si se tiene una dependencia funcional $X → Y$ donde $Y$ depende parcialmente de una de las claves entonces se viola 2FN.
Luego se separa en 2 relaciones: una que contenga a la dependencia parcial (atributos no primos con dependencia parcial $Y$ y la parte de la clave a la que dependen) y otra con el resto de atributos (copiando los atributos de la clave que dependen parcialmente $Y$).

### 3FN

$R$ está en $3FN$ si para toda $DF$ no trivial $X → A$ sobre $R$, se cumple que 
1. $X$ es superclave de $R$ o 
2. $A$ es primo. 

Equivalente: $R$ está en $3FN$ si para toda $DF$ no trivial $X → Y$ , o bien $X$ es superclave de $R$ o $Y$ es subconjunto de alguna clave de $R$.

DF Trivial: $X → X$

Descomposición en 2 relaciones, una con los atributos de la DF que viola la 3FN y otra con el resto de atributos.

### FNBC

$R$ está en FNBC si para toda $DF$ no trivial $X → A$ sobre $R$, $X$ es superclave de $R$

Descomposición en 2 relaciones, una con los atributos de la DF $X → A$ que no cumple el requisito, y otro con el resto de atributos (X se copia en ambas relaciones).


### Propiedades

- Todo esquema se puede descomponer en 3FN de forma SPI y SPDF
- Hay esquemas que no se pueden descomponer en FNBC siendo SPDF
- Todo esquema de 2 atributos está en FNBC

## Algoritmo descomposición FNBC SPI

Parte de R aplicando la propiedad de descomposici´on binaria: el
resultado siempre es SPI, pero a veces no es SPDF.
1. Si hay $X → Y$ que viola FNBC en $R_i ∈ ρ$, reemplazar $R_i$ por $R′_i = XY$ y $R′′i = R_i − Y$
2. Repetir sobre cada $R_i$ que no esté en FNBC, hasta que todos lo estén

## Algoritmo descomposición 3FN SPI y SPDF

Se obtiene una descomposición $ρ$ de $R$ por síntesis, a partir de una cobertura minimal $FM$ de $F$:
1. Crear un subesquema $(X , A)$ para cada dependencia $X → A$ en $FM$
2. Unificar los que provienen de $DF$ con igual lado izquierdo: $(X , A_1, . . . , A_n)$
3. Si ningún esquema contiene una clave, agregar uno con los atributos de alguna clave
4. Eliminar esquemas redundantes (contenidos en otro)