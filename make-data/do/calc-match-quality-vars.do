* Computes match quality variables.  We treat the "_don" and "" suffixed variables differently so 
* that this do file can be used for all matches (transplant, recip, and donor)

* Note that throughout, we do not count .==. as a match.

*local ch       = regexr("`1'","clearinghouse=","")
local type     = regexr("`1'","type=","")

*if !regexm("`1'","clearinghouse=")  | ///
*   !inlist("`ch'","nkr","apd","unos","all_ch")  {
*     di as error "Argument 1 not of form 'clearinghouse=apd/nkr/unos/all_ch'"
*     error 111
*}
if !regexm("`1'","type=")  | ///
   !inlist("`type'","tx","don","rec") {
    di as error "Argument 2 not of form 'type=tx/don/rec'"
    error 111
}

if ("`type'"=="tx") | ("`type'"=="rec") {
  confirm variable abo_coarse, exact
  * Calculate the number of perfect hla allele matches for the recipient and donor, respectively
  gen  hla_matches     = 0
  gen  missing_alleles = 0
  foreach antigen in a1 a2 b1 b2 dr1 dr2 {
    replace hla_matches         = hla_matches     + 1 if    (hla`antigen'    == ch_`antigen') & ///
                                                         !mi(hla`antigen')
    replace missing_alleles     = missing_alleles + 1 if  mi(hla`antigen') | mi(ch_`antigen')
  }
  gen hla_matches_net  = hla_matches  + missing_alleles
  gen age_difference   = abs(ch_age - age)
  
//  if ("`ch'"=="nkr") {
    gen     abog_matches = 0
    gen     abog_missing = 0
    replace abog_matches = abog_matches + 1 if    (gender    == ch_gender)         & ///
                                               !mi(gender)
    replace abog_missing = abog_missing + 1 if  mi(gender) | mi(ch_gender)
    replace abog_matches = abog_matches + 1 if    (abo_coarse ==    ch_abo_coarse) & ///
                                               !mi(abo_coarse)
    replace abog_missing = abog_missing + 1 if  mi(abo_coarse) | mi(ch_abo_coarse)
//  }
/*  if ("`ch'"=="apd"){
    gen abo_match   = (abo_coarse==apd_abo_coarse)
    gen abo_missing = mi(abo_coarse) | mi(apd_abo_coarse) 
  }*/
}

if ("`type'"=="tx") | ("`type'"=="don") {
  confirm variable abo_coarse_don, exact
  gen hla_matches_don      = 0
  gen missing_alleles_don  = 0

  foreach antigen in a1 a2 b1 b2 dr1 dr2 {
    replace hla_matches_don     = hla_matches_don     + 1 if    (hla`antigen'_don == ch_`antigen'_don) & ///
                                                             !mi(hla`antigen'_don)
    replace missing_alleles_don = missing_alleles_don + 1 if  mi(hla`antigen'_don) | mi(ch_`antigen'_don)
  }
  gen hla_matches_net_don = hla_matches_don + missing_alleles_don
  gen age_difference_don            = abs(ch_age_don - age_don)
  
  //if ("`ch'"=="nkr"){
    gen     abog_matches_don = 0
    gen     abog_missing_don = 0

    replace abog_matches_don = abog_matches_don + 1 if     (gender_don     ==    ch_gender_don)     & ///
                                                        !mi(gender_don)
    replace abog_missing_don = abog_missing_don + 1 if   mi(gender_don)     | mi(ch_gender_don)
  
    replace abog_matches_don = abog_matches_don + 1 if     (abo_coarse_don ==    ch_abo_coarse_don) & ///
                                                        !mi(abo_coarse_don)      
    replace abog_missing_don = abog_missing_don + 1 if   mi(abo_coarse_don) | mi(ch_abo_coarse_don)
  //}
}

* Calculate date differences	
gen date_difference_tx            = abs(tx_date - ch_tx_date)

gen     tx_ctr_match = 0
replace tx_ctr_match = 1 if ( tx_ctr_id == ch_tx_ctr_id ) & !mi(tx_ctr_id)

