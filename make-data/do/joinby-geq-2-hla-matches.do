* Stata only offers two ways of doing a join: either joinby, which requires a perfect match on some 
* variable, or cross, which is indiscriminate. What we really want is to join on some condition 
* strong enough to limit the number of observations in memroy, but weak enough to avoid excluding 
* any genuine matches.  We accomplish this by combining all joins on which two hla loci match 
* perfectly.  6 choose 2 is 15, so that is how many joinby's will have to be run.

* This file takes 1) the global $suffix (either "" or "_don") 2) $nkr_temp and $kidpan_temp and 
* 2) the $trim_condition.  The $trim_condition is a way of further reducing the number of 
* observations after each joinby.

local ch             = subinstr("`1'","clearinghouse=","",1)
local matchon        = subinstr("`2'","matchon=",      "",1)
local trim_condition = subinstr("`3'","trim=",         "",1)

if !regexm("`1'","clearinghouse=") | ///
   !inlist("`ch'","nkr","apd","unos","all_ch")  {
  di as error "Argument not of form 'clearinghouse=apd/nkr/unos/all_ch'"
  error 111
}
if !regexm("`2'","matchon=")  | ///
   !inlist("`matchon'","rec","don")  {
  di as error "Argument not of form 'matchon=rec/don'"
  error 111
}
if !regexm("`3'","trim=") {
  di as error "Argument not of form 'trim=boolean_exp'"
  error 111
}

local suffix = cond("`matchon'"=="rec","","_don")

tempfile joinby_union

local locus1 a1
local locus2 a2
local locus3 b1
local locus4 b2
local locus5 dr1
local locus6 dr2

* For each i, we cycle from i+1 through 6.  This covers all 15 possibilities (5+4+3+2+1 = 15)

forvalues i = 1(1)5 {
  forvalues j = `=`i'+1'(1)6 {
    di "`locus`i'', `locus`j''"
    use ${`ch'_temp}, clear
    di "1"
    ren  ch_`locus`i''`suffix'    hla`locus`i''`suffix'
    ren  ch_`locus`j''`suffix'    hla`locus`j''`suffix'
    drop if  mi(hla`locus`i''`suffix', hla`locus`j''`suffix' )
    joinby      hla`locus`i''`suffix'  hla`locus`j''`suffix' using $star_temp
    di "2"
    count    
    keep if `trim_condition'
    count
    gen ch_`locus`i''`suffix' = hla`locus`i''`suffix'
    gen ch_`locus`j''`suffix' = hla`locus`j''`suffix'
    capture confirm file `joinby_union'
    if (_rc==0){  * if the file already exists
      append using `joinby_union'
    }
    save `joinby_union', replace
  }
}
duplicates drop
count
