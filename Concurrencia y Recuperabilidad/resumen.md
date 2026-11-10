# Resumen de gimini

> NOTA: No es completo ni exhaustivo. Omitió un montón de detalles. Usar complementando con las

---

## 1. Fundamentos de Concurrencia y Serializabilidad

### 1.1 Concepto de Serializabilidad
Un plan o historia de ejecución intercalada de transacciones concurrentes es **serializable** si su efecto sobre la base de datos es equivalente al de alguna ejecución estrictamente serial de esas mismas transacciones.

### 1.2 Conflictos en Modelos Monoversión
Dos operaciones $p_i$ y $q_j$ pertenecientes a transacciones distintas ($i \neq j$) están en **conflicto** si ambas acceden al mismo elemento de datos $X$ y al menos una de ellas es una escritura ($w$):
*   $r_i(X)$ vs $w_j(X)$ (Read-Write / Anti-dependencia).
*   $w_i(X)$ vs $r_j(X)$ (Write-Read / Dependencia de datos).
*   $w_i(X)$ vs $w_j(X)$ (Write-Write / Dependencia de salida).

Dos lecturas $r_i(X)$ y $r_j(X)$ **no** entran en conflicto (conmutan libremente).

### 1.3 Grafo de Serialización ($SG$ o Precedence Graph)
Para una historia $H$, el grafo dirigido $SG(H) = (V, E)$ se define como:
*   **Vértices ($V$):** Conjunto de transacciones confirmadas en $H$.
*   **Aristas ($E$):** Existe una arista dirigida $T_i \rightarrow T_j$ si existe una operación $p_i \in T_i$ y una operación $q_j \in T_j$ en conflicto tal que $p_i <_H q_j$.

> **Teorema de Serializabilidad por Conflictos:**  
> Una historia $H$ es **Conflict Serializable ($CSR$)** si y solo si su grafo de serialización $SG(H)$ es **acíclico** (no contiene ciclos).

---

## 2. Jerarquía de Recuperabilidad de Historias

Para evitar anomalías ante abortos o fallas del sistema, las historias se clasifican según sus restricciones de lectura y commit:

$$\text{Strict } (ST) \subset \text{Avoids Cascading Aborts } (ACA) \subset \text{Recoverable } (RC)$$

```
+-------------------------------------------------------+
| Recoverable (RC)                                      |
|  +-------------------------------------------------+  |
|  | Avoids Cascading Aborts (ACA)                   |  |
|  |  +-------------------------------------------+  |  |
|  |  | Strict (ST)                               |  |  |
|  |  |  +-------------------------------------+  |  |  |
|  |  |  | Rigorous (RG)                       |  |  |  |
|  |  |  +-------------------------------------+  |  |  |
|  |  +-------------------------------------------+  |  |
|  +-------------------------------------------------+  |
+-------------------------------------------------------+
```

1.  **Recuperable ($RC$):**
    *   **Condición:** Si una transacción $T_j$ lee un dato escrito previamente por $T_i$ ($r_j(X)$ tras $w_i(X)$), entonces el commit de $T_i$ debe preceder al commit de $T_j$ ($c_i < c_j$).
    *   **Propósito:** Evita que $T_j$ confirme cambios basados en datos de una transacción que luego aborte (lecturas sucias no comiteadas).
2.  **Evita Abortos en Cascada ($ACA$):**
    *   **Condición:** Toda transacción solo puede leer datos escritos por transacciones que **ya hayan comiteado** ($w_i(X) < c_i < r_j(X)$).
    *   **Propósito:** Si $T_i$ aborta, ninguna otra transacción activa se ve obligada a abortar por haber leído sus datos.
3.  **Estricta ($ST$):**
    *   **Condición:** Ningún dato puede ser leído **ni sobreescrito** hasta que la transacción previa que lo escribió haya hecho commit o abort ($w_i(X) < (c_i \lor a_i) < [r_j(X) \lor w_j(X)]$).
    *   **Propósito:** Simplifica la recuperación por Undo (restaurar imágenes previas sin pisar escrituras de otras transacciones activas).
4.  **Rigurosa ($RG$):**
    *   **Condición:** No se permite ninguna operación ($r$ o $w$) sobre datos leídos o escritos por $T_i$ hasta que $T_i$ confirme o aborte. Garantiza automáticamente serializabilidad estricta.

---

## 3. Protocolos de Control de Concurrencia Pesimistas

### 3.1 Familia de Bloqueos en Dos Fases (2PL)
*   **2PL Básico:**
    *   Fase de Crecimiento (*Growing Phase*): Se adquieren bloqueos; no se puede liberar ninguno.
    *   Punto de Bloqueo (*Lock Point*): Instante donde se retiene la totalidad de los bloqueos necesarios.
    *   Fase de Encogimiento (*Shrinking Phase*): Se liberan bloqueos; no se puede adquirir ninguno nuevo.
    *   *Garantía:* Asegura $CSR$, pero puede sufrir abortos en cascada y deadlocks.
*   **Strict 2PL ($S2PL$):**
    *   Los bloqueos exclusivos de escritura ($X$-locks) se retienen hasta el commit o abort.
    *   *Garantía:* Asegura que el plan sea $ST$ y libre de abortos en cascada.
*   **Strong / Rigorous 2PL ($SS2PL$ o $RG$):**
    *   **Todos** los bloqueos (tanto compartidos $S$ como exclusivos $X$) se retienen hasta el final de la transacción ($c_i$ o $a_i$).
    *   *Garantía:* Orden de serialización idéntico al orden de finalización (commit).

### 3.2 Prevención de Deadlocks basada en Marcas de Tiempo ($TS$)
Sea $TS(T)$ la marca de tiempo asignada al inicio de $T$ (menor valor implica mayor antigüedad):

*   **Wait-Die (No expulsivo / No preemptivo):**
    *   Si $T_{\text{vieja}}$ solicita recurso en manos de $T_{\text{joven}}$: $T_{\text{vieja}}$ **espera** (*Wait*).
    *   Si $T_{\text{joven}}$ solicita recurso en manos de $T_{\text{vieja}}$: $T_{\text{joven}}$ **muere** (*Die* y reinicia con el mismo $TS$).
*   **Wound-Wait (Expulsivo / Preemptivo):**
    *   Si $T_{\text{vieja}}$ solicita recurso en manos de $T_{\text{joven}}$: $T_{\text{vieja}}$ hiere a $T_{\text{joven}}$ (*Wound*), forzando su aborto inmediato para tomar el recurso.
    *   Si $T_{\text{joven}}$ solicita recurso en manos de $T_{\text{vieja}}$: $T_{\text{joven}}$ **espera** (*Wait*).

### 3.3 Regla de Escritura de Thomas (*Thomas Write Rule*)
En ordenamiento por marcas de tiempo monoversión ($TSO$), para una operación $w_i(X)$:
*   Si $TS(T_i) < RT(X)$: Aborto (*Read Too Late*).
*   Si $TS(T_i) < WT(X)$: Una transacción más joven ya escribió $X$. Si dicha transacción ya comiteó, **se ignora/descarta la escritura de $T_i$** y se permite continuar sin abortar. Genera vistas serializables que no son estrictamente equivalentes por conflictos directos, pero sí por vista.

---

## 4. Control de Concurrencia Multiversión (MV)

En esquemas multiversión, una escritura $w(X)$ no destruye el valor previo, sino que crea una versión formal $X_k$ asociada a la transacción $T_k$.

### 4.1 Criterios Teóricos de Corrección
*   **Multiversion View Serializability ($MVSR$):**
    *   Una historia multiversión $m$ es $MVSR$ si su relación de lecturas (*reads-from*) coincide exactamente con la de alguna historia monoversión puramente serial.
    *   Determinar si una historia pertenece a $MVSR$ es un problema **NP-Completo**.
*   **Multiversion Conflict Serializability ($MCSR$):**
    *   Subclase determinable en tiempo polinómico ($MCSR \subset MVSR$).
    *   **Análisis de Conflictos en $MCSR$:**
        *   $w_i(X_i)$ vs $w_j(X_j)$: **Sin conflicto**. Escriben versiones independientes.
        *   $w_k(X_k) < r_i(X_j)$: **Sin conflicto**. Si la lectura se mueve antes de la escritura, simplemente se reduce el universo de versiones elegibles sin invalidar la historia.
        *   $r_i(X_j) <_m w_k(X_k)$: **Único Conflicto**. Mover la lectura después de la escritura agrega una versión nueva que podría alterar la decisión de qué dato debió leer $T_i$.
    *   Una historia pertenece a $MCSR$ si y solo si su grafo de conflictos multiversión (basado en aristas $r\text{-}w$) es **acíclico**.

### 4.2 Protocolos de Ejecución Multiversión

#### Multiversion Timestamp Ordering (MVTO)
*   **Lectura ($r_i(X)$):** Nunca se bloquea ni aborta. Lee la versión $X_k$ con el mayor timestamp de escritura tal que $TS(T_k) \le TS(T_i)$.
*   **Escritura ($w_i(X)$):** Sea $X_k$ la versión con mayor $WT \le TS(T_i)$. Si existe alguna transacción $T_j$ que ya leyó $X_k$ con $TS(T_k) < TS(T_i) < TS(T_j)$, la nueva versión $X_i$ llega tarde (*Write Too Late*); por lo tanto, **$T_i$ aborta**.

#### Multiversion Two-Phase Locking (MV2PL)
*   Utiliza una variante de $SS2PL$.
*   Las transacciones lectoras leen de inmediato la versión confirmada actual.
*   Las escrituras sobre un elemento se serializan entre sí (a lo sumo una versión no comiteada activa por dato).
*   **Paso final (Commit):** Una transacción escritora $T_i$ debe suspender su commit hasta que hayan confirmado todas aquellas transacciones que hayan leído la versión actual que $T_i$ va a reemplazar. Esto preserva el orden serial ($T_{\text{lector}} \rightarrow T_{\text{escritor}}$).

#### Two-Version Two-Phase Locking (2V2PL)
*   Mantiene a lo sumo **dos versiones** por dato: la versión actual (comiteada) y una versión tentativa (no comiteada).
*   Introduce tres tipos de locks:
    *   $rl(X)$: Read Lock. Compatible con $wl(X)$.
    *   $wl(X)$: Write Lock. Compatible con $rl(X)$.
    *   $cl(X)$: Certify Lock. Adquirido en el commit. **Incompatible con $rl(X)$ y $wl(X)$**.
*   Para confirmar, el escritor convierte su $wl$ a $cl$. Si hay transacciones leyendo la versión vieja con $rl$, el escritor espera a que terminen para evitar destruir el dato mientras es consultado.

#### Read-Only Multiversion (ROMV)
*   Separa las transacciones en dos grupos:
    *   **Transacciones de actualización ($RW$):** Emplean $2PL$ monoversión estándar entre sí; al confirmar, sellan sus versiones con su marca de commit.
    *   **Transacciones de solo lectura ($RO$):** Toman un snapshot con su $TS$ de inicio y leen la versión comiteada más reciente a ese punto. **Jamás piden locks, jamás esperan y jamás son abortadas**.

---

## 5. Arquitectura de Almacenamiento, Logging y Recuperabilidad

### 5.1 Primitivas de Disco y Memoria
*   `INPUT(X)`: Transfiere el bloque de disco que contiene a $X$ al buffer pool en RAM.
*   `READ(X, t)`: Asigna el valor del buffer en RAM a la variable local $t$.
*   `WRITE(X, t)`: Guarda el valor local $t$ en el bloque de memoria RAM (pasa a ser *dirty buffer*).
*   `OUTPUT(X)`: Escribe el bloque sucio desde el buffer pool en RAM a disco físico.
*   `FLUSH LOG`: Fuerza la persistencia inmediata de los buffers del log a disco.

### 5.2 Estrategias de Logging

| Propiedad | UNDO Logging | REDO Logging | UNDO/REDO Logging |
| :--- | :--- | :--- | :--- |
| **Formato del registro** | $\langle T, X, v_{\text{antiguo}} \rangle$ | $\langle T, X, v_{\text{nuevo}} \rangle$ | $\langle T, X, v_{\text{antiguo}}, v_{\text{nuevo}} \rangle$ |
| **Regla de Persistencia** | Log en disco antes del `OUTPUT(X)`. Todos los `OUTPUT` **antes** del `COMMIT`. | Log y `COMMIT` en disco **antes** de cualquier `OUTPUT(X)`. | Log en disco antes de `OUTPUT(X)`. `OUTPUT` libre (antes o después del commit). |
| **Desventaja principal** | Latencia alta al commit (obliga I/O síncrono de datos). | Presión excesiva sobre el buffer pool (retiene páginas sucias). | Requiere algoritmos de recuperación en dos fases. |
| **Acción ante Crash** | Deshace transacciones no confirmadas. | Rehace transacciones confirmadas. | Rehace confirmadas y deshace incompletas. |

---

## 6. Mecanismos de Checkpoint No-Quiescentes

El checkpoint permite acotar la porción de log a inspeccionar durante una falla sin detener el procesamiento de nuevas transacciones.

### 6.1 Secuencia de un Checkpoint No-Quiescente (Undo/Redo)
1.  Se escribe en el log el registro:
    $$\langle \text{START CKPT } (T_{a1}, T_{a2}, \dots, T_{ak}) \rangle$$
    donde se listan todas las transacciones activas en ese instante, y se ejecuta `FLUSH LOG`.
2.  El buffer manager escribe en disco físico todos los bloques sucios (*dirty pages*) que estaban en RAM al inicio del checkpoint.
3.  Una vez persistidas las páginas, se escribe:
    $$\langle \text{END CKPT} \rangle$$
    y se vuelve a realizar `FLUSH LOG`.

---

## 7. Caso de Estudio Práctico: Recuperación Undo/Redo

### 7.1 Estado del Log tras la Caída

```text
 1. <Start T1>
 2. <Start T2>
 3. <T2, A, 4, 5>
 4. <T1, B, 9, 10>
 5. <Commit T2>
 6. <Start Ckpt (T1)>
 7. <T1, B, 10, 11>
 8. <Start T3>
 9. <T3, A, 5, 6>
10. <End Ckpt>
11. <T3, A, 6, 8>
12. <T1, C, 10, 11>
13. <Commit T1>
14. <Start Ckpt (T3)>
15. <Start T4>
16. <T3, A, 8, 10>
17. <Commit T3>
18. <End Ckpt>
19. <T4, A, 10, 40>
-- CRASH --
```

### 7.2 Diagnóstico y Clasificación
*   **Último Checkpoint Completado:** Registro 18 ($\langle \text{End Ckpt} \rangle$), correspondiente al inicio en registro 14 ($\langle \text{Start Ckpt } (T_3) \rangle$).
*   **Transacciones que confirmaron tras el Ckpt:** $T_3$ comiteó en el registro 17.
    *   $\text{Conjunto REDO} = \{ T_3 \}$.
*   **Transacciones sin confirmar al momento de la falla:** $T_4$ inició en el registro 15 y no posee commit.
    *   $\text{Conjunto UNDO} = \{ T_4 \}$.
*   *Nota sobre $T_1$ y $T_2$:* $T_2$ confirmó antes del primer checkpoint; $T_1$ confirmó antes del checkpoint del registro 14. Dado que el $\langle \text{End Ckpt} \rangle$ del registro 18 completó el volcado de dirty pages, todas sus escrituras están garantizadas en disco físico.

### 7.3 Proceso de Recuperación (Repeating History)

```
        Fase REDO (hacia adelante desde registro 14)
  -------------------------------------------------------->
  14 [Start Ckpt (T3)] -> 16 [T3 escribe A=10] -> 17 [Commit T3]
                                                   |
                     Disco: A = 10 <---------------+

        Fase UNDO (hacia atrás desde el final del log)
  <--------------------------------------------------------
  19 [T4 restaurar A a valor anterior: 10]
        |
        +--> Disco: A = 10
        |
        +--> Log: Registrar <Abort T4>
```

1.  **Fase REDO (Scan hacia adelante desde el registro 14):**
    *   Se procesa el registro 16: $\langle T_3, A, 8, 10 \rangle$. Se escribe en disco $A = 10$.
    *   Se procesa el commit de $T_3$.
2.  **Fase UNDO (Scan hacia atrás desde el final del log):**
    *   Se localiza la operación de $T_4$ en el registro 19: $\langle T_4, A, 10, 40 \rangle$.
    *   Se restaura en disco el valor previo: $A = 10$.
    *   Se emite y persiste el registro $\langle \text{Abort } T_4 \rangle$ en el log para finalizar el proceso.
3.  **Resultado Final:** La base de datos queda consistente en disco con $A = 10$ y el log cerrado sin transacciones pendientes.