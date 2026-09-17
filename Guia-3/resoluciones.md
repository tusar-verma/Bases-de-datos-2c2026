# 1.1

## g

Devuelve una relación con 0 atributos y 1 tupla vacía: $\{()\}$

# 1.2

$ρ_{R1}R$
$ρ_{R2}R$

$ρ(NoMinimos, π_{R1.a}(σ_{R1.a > R2.a}(R1 \times R2)))$

$R - NoMinimos$

# 1.3

$ρ_{R1}R$
$ρ_{R2}R$

$ρ_{NoMinimos}(π_{R1.a, R1.b}(σ_{R1.b > R2.b \ ∧ \ R1.a = R2.a }(R1 \times R2)))$

$R - NoMinimos$

# 1.4

$ρ_{R1}R$
$ρ_{R2}R$

$π_{R1.a, R1.b}(σ_{R1.b \neq R2.b \ ∧ \ R1.a = R2.a }(R1 \times R2))$


# 1.5


$ρ_{R1(a_1,b_1)}R$
$ρ_{R2(a_2,b_2)}R$
$ρ_{R3(a_3,b_3)}R$

$ρ_{ConLosBRepetido}(π_{a1, b1. b2}(σ_{b1 \neq b2 \ ∧ \ a1 = a2 \ ∧ \ }(R1 \times R2)))$

$ρ_{ConMasDeDosBDistintos(a3, b3)}(π_{ConBRepetido.a1, ConBRepetido.b1}(σ_{b1 \neq b3 \ ∧ \ b2 \neq b3 \ ∧ \ a3 = a1 \ ∧ \ }(ConBRepetido \times R3)))$

$ρ_{ConAIgualesYBDistintos}(π_{a1, b1}(σ_{b1 \neq b2 \ ∧ \ a2 = a1 }(R1 \times R2)))$

Resultado = ConAIgualesYBDistintos - ConMasDeDosBDistintos

# 1.6

nombres de los clientes que tengan la factura (invoice) con el item (invoiceline) de mayor cantidad

## En AR

$ρ_{R1}invoiceline$
$ρ_{R2}invoiceline$

$ρ_{invoicelineNoMaximos}(π_{R1}(σ_{R1.quantity < R2.quantity} (R1 \times R2))) $

$ρ_{invoicelineMaximos}(invoiceline - invoicelineNoMaximos)$

$ρ_{CustomersIdConInvoiceLinesMaximos}(π_{CustomerId}(invoice \bowtie invoicelineMaximos))$ (natural join)

$ρ_{Resultado}(π_{FirstName}(CustomersIdConInvoiceLinesMaximos \bowtie customer))$ (Natural join)

## En CRT

$$
\{t / (\exists c, i, il) 
    (i \in Invoice \wedge \\
    il \in InvoiceLine \wedge \\
    c \in customer \wedge \\ 
    c.CustomerId = i.CustomerId \wedge \\
    i.InvoiceId = il.InvoiceId \wedge \\
    (\forall il')((il' \in InvoiceLine \wedge li' \neq il) \implies il'.Quantity \leq il.Quantity) \wedge\\
    t.FirstName = c.FirstName) \}
$$

otra forma


$$
\{t / (\exists c, i, il) 
    (i \in Invoice \wedge \\
    il \in InvoiceLine \wedge \\
    c \in customer \wedge \\ 
    c.CustomerId = i.CustomerId \wedge \\
    i.InvoiceId = il.InvoiceId \wedge \\
    \neg(\exists il')((il' \in InvoiceLine \wedge il'.Quantity > il.Quantity) \wedge\\
    t.FirstName = c.FirstName) \}
$$

# 2.9

## b

$ρ_{ItemsConPrecioHistoricoGuardado}(\pi_{idItem, nombre, precio actual, categor´ıaId}(Historia \bowtie Items))$

$ρ_{Resultado}(\pi_{nombre}(Items - ItemsConPrecioHistoricoGuardado))$

## c

$$
\{ t / (\exists i, h) (i \in items \wedge h \in historia \wedge \\
    \neg(\exists i'\in items \wedge i'.precio\_actual > i.precio\_actual) \wedge \\
    h.Idtem = i.idItem \wedge \\
    \neg(\exists h' \in historia \wedge h'.idItem = i.IdItem \wedge h'.precio > h.precio) \\
    t.mayor\_precio\_historico = h.precio \wedge \\
    t.precio\_actual = i.precio\_actual \wedge \\
    t.Nombre = i.Nombre
)  \}
$$

# 2.10

## a

Verdadero

## b

Falso, faltan los apellidos

## c

Falso. Da los alumnos inscriptos en bases O algoritmos

## d

Falso. Estudiante no tiene atributo curso.

## e

Falso. El natural join entre las selecciones se hacen en 2 relaciones que tienen ambos atributos con el mismo nombre. Por lo tanto emparejaría tuplas con <LU, "Algoritmos"> y <LU, "bases de datos"> comparando $LU = LU \wedge$ "algoritmos" = "bases de datos". (Devuelve conjunto vacío siempre).


# 2.11

## a

Falso. Falta $t.Nombre = e.Nombre$

## b

Verdadero.

## c

Verdadero

## d

Falso.

Pide que para todo proyecto en el que trabaja el empleado debe existir un proyecto con el PID correspondiente y que sea de ventas.
Es decir, todo proyecto del empleado debe ser del departamente de ventas.