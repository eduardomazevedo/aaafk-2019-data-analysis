* Generates dummies from abo
* First arugment is abo field and second argument is output abo

program define abo_dum
  args abo out_abo

  * generate dummies
  gen `out_abo'_A  = `abo'== "A" | `abo'=="A1"  | `abo'=="A2"  if `abo'!=""
  gen `out_abo'_B  = `abo'== "B"                               if `abo'!=""
  gen `out_abo'_AB = `abo'=="AB" | `abo'=="A1B" | `abo'=="A2B" if `abo'!=""
  gen `out_abo'_O  = `abo'== "O"                               if `abo'!=""

end
