program define lcs
    syntax varlist(min=2 max=2 string), GENerate(name) [Noisily]
    tokenize `varlist'
    local str1 `1'
    local str2 `2'
    local lcs  `generate'
    capture confirm new var `lcs', exact
    *di "`str1'"
    *di "`str2'"
    *di "`lcs'"

    if _rc!=0 {
        di as error "Variable `lcs' already exists."
        exit 111
    }

    tempvar big little little_len found


    quietly{
        gen        `big' = `str1' if length(`str2')<=length(`str1')
        gen     `little' = `str2' if length(`str2')<=length(`str1')
        replace    `big' = `str2' if length(`str2') >length(`str1')
        replace `little' = `str1' if length(`str2') >length(`str1')
    
        gen `little_len' = length(`little')
        sum `little_len'
        local maxmin = r(max)
        `noisily' di "Length of longest smaller string: `maxmin'"

        gen `found' = 0
        gen `lcs'   = ""
        count
        local tot = `r(N)'

        forvalues l = `maxmin' (-1) 1 {
            forvalues st = 1 (1) `=`maxmin'-`l'+1' {
                replace `lcs' = substr(`little',`st',`l') if `l'<=length(`little') & `found'==0
                replace `found'=1 if strpos(`big',`lcs')>0 & !mi(`lcs')
                replace `lcs' = ""  if `found'==0
            }
            count if `found'==1
            local pct: di %5.2f `=100*`r(N)'/`tot''
            local fnd: di %5.0f       `r(N)'
            local sl:  di %2.0f       `l'
            noisily di "LCS length `sl' search complete: `fnd'/`tot' (`pct'%) found thus far."
            count if `found'==0
            if (`r(N)'==0) {
                noisily di "Search terminated: all LCSs found."
                continue, break
            }
        }
        replace `lcs'="" if `found'==0
        replace `lcs'=trim(`lcs')
    }
end
