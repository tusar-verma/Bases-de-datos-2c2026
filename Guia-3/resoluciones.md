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


$ρ_{R1}invoiceline$
$ρ_{R2}invoiceline$

$ρ_{invoicelineNoMaximos}(π_{R1}(σ_{R1.quantity < R2.quantity} (R1 \times R2))) $

$ρ_{invoicelineMaximos}(invoiceline - invoicelineNoMaximos)$

$ρ_{CustomersIdConInvoiceLinesMaximos}(π_{CustomerId}(invoice \bowtie invoicelineMaximos))$ (natural join)

$ρ_{Resultado}(π_{FirstName}(CustomersIdConInvoiceLinesMaximos \bowtie customer))$ (Natural join)
