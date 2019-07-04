program define normalize_names
    syntax varname
    local name `varlist'
    *** CAUTION: Changing these replace statements means you might need to go back through
    *** the do file that makes the donor hospital dictionary to adjust the spurious matches 
    *** that are dropped
    quietly {
        replace `name' = subinstr(`name',`"'s"',      " ",.)
        replace `name' = subinstr(`name',`"'"',       " ",.)
        replace `name' = subinstr(`name',".",         " ",.)
        replace `name' = subinstr(`name',",",         " ",.)
        replace `name' = subinstr(`name',"-",         " ",.)
        replace `name' = subinstr(`name',"/",         " ",.)
        replace `name' = subinstr(`name',"&",         " and ",.)
        replace `name' = subinstr(`name',"(",         " ",.)
        replace `name' = subinstr(`name',")",         " ",.)
        replace `name' =  itrim(`name')
        replace `name' = regexr(`name',  " ft ",      " fort ")
        replace `name' = regexr(`name',  "^ft ",      "fort ")
        replace `name' = regexr(`name',  " hosp ",    " hospital ")
        replace `name' = regexr(`name',  "^hosp ",    "hospital ")
        replace `name' = regexr(`name',  " hosp$",    " hospital")
        replace `name' = regexr(`name',  " hos ",     " hospital ")
        replace `name' = regexr(`name',  "^hos ",     "hospital ")
        replace `name' = regexr(`name',  " hos$",     " hospital")
        replace `name' = regexr(`name',  " ctr ",     " center ")
        replace `name' = regexr(`name',  " ctr$",     " center")
        replace `name' = regexr(`name',  " cntr ",    " center ")
        replace `name' = regexr(`name',  " cntr$",    " center")
        replace `name' = regexr(`name',  " cen ",     " center ")
        replace `name' = regexr(`name',  " cen$",     " center")
        replace `name' = regexr(`name',  " med ",     " medical ")
        replace `name' = regexr(`name',  "^med ",     "medical ")
        replace `name' = regexr(`name',  " med$",     " medical")
        replace `name' = regexr(`name',  " mc$",      " medical center")
        replace `name' = regexr(`name',  "^mc ",      "medical center ")
        replace `name' = regexr(`name',  " mc ",      " medical center ")
        replace `name' = regexr(`name',  " univ ",    " university ")
        replace `name' = regexr(`name',  "^univ ",    "university ")
        replace `name' = regexr(`name',  "childr$",   "childrens")
        replace `name' = regexr(`name',  "childr ",   "childrens ")
        replace `name' = regexr(`name',  "children ", "childrens ")
        replace `name' = regexr(`name',  "children$", "childrens")
        replace `name' = regexr(`name',  " st ",      " saint ")
        replace `name' = regexr(`name',  "^st ",      "saint ")
        replace `name' = regexr(`name',  "newyork",   "new york")
        replace `name' = subinstr(`name'," the ",     " ", .)
        replace `name' = regexr(`name',  "^the ",     " ")
        replace `name' = regexr(`name',  " dept ",     " department ")
        replace `name' = regexr(`name',  "^dept ",     "department ")
        replace `name' =  itrim(`name')
        replace `name' =   trim(`name')
    }
end
