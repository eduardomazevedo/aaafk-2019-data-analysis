program define recode_hla
    ** Recode HLA antigens
    * Input: a list of hla variable names without the 1 and 2 sufix.
    * No output
    * For each input myvar it standardizes myvar1 and myvar2 for the locuses 1 
    * and 2. This sorts the hla variables, so gotta be careful that we really 
    * want that! This seems reasonable for the merge, but we do not want to sort
    * if we do some chromosome based analysis.
    * Loop over inputs

    foreach var in `*' {

        * 98 appears to code homozygous in kidpan
        * -1 appears to code homozygous in nkr
        * Replace 98s and -1 by the other antigen

            replace `var'1 = `var'2 if (`var'1 == 98) | (`var'1 == -1)
            replace `var'2 = `var'1 if (`var'2 == 98) | (`var'2 == -1)
            
        * Replace 0s, 98s, and -1s by missing

            replace `var'1 = . if (`var'1 == 0) | (`var'1 == 98) | (`var'1 == -1)
            replace `var'2 = . if (`var'2 == 0) | (`var'2 == 98) | (`var'2 == -1)
        
        * Sort variables 1 and 2 (comment this if we do not want to resort)

            tempvar min_var max_var
            gen `min_var' = min(`var'1, `var'2)
            gen `max_var' = max(`var'1, `var'2)
            replace `max_var' = . if mi(`var'1) | mi(`var'2)
            
            replace `var'1 = `min_var'
            replace `var'2 = `max_var'
        
        * Validate

            assert(`var'1 > 0 | mi(`var'1))
            assert(`var'2 > 0 | mi(`var'2))
        
    }
end
