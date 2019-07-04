* Initialize
set more off
clear

adopath + "./do"

* Filenames are kept as globals in one do file
quietly do ./do/globals/load-globals.do

foreach suffix in "" "_perfect" {
di "suffix: `suffix'"

// Generate a list of all centers, along with whether they ever participated in a clearinghouse
use ${tx_dataset`suffix'}, clear

keep if _s_tx_date>=date("04/02/2012","MDY") & _s_tx_date<$nkr_end_date //date("12/04/2014","MDY")

gen  nkr_ctr =  is_nkr  == 1 & !mi(is_nkr)
gen  apd_ctr =  is_apd  == 1 & !mi(is_apd)
gen unos_ctr =  is_unos == 1 & !mi(is_unos)
gen   ch_ctr = (is_unos == 1) | (is_apd == 1) | (is_nkr == 1) 
ren _s_tx_ctr_id   ctr
drop if mi(ctr)

collapse (max) nkr_ctr apd_ctr unos_ctr, by(ctr)
tempfile  ctr_list
save     `ctr_list', replace

// At this point, 240 centers, of which 113 ever did a ch transplant (68 NKR, 47 UNOS, 24 APD)

// Count Transplants by Center, within the NKR sample period -- This is the number of donors
use ${tx_dataset`suffix'}, clear
drop if mi(_s_tx_ctr_id)
keep if _s_tx_date>=date("04/02/2012","MDY") & _s_tx_date<$nkr_end_date //date("12/04/2014","MDY")

* Summarize the dates
sum      _s_tx_date
local    years_of_data   = (`r(max)' - `r(min)' ) / 365
di     "`years_of_data'"

* Use the tx_ctr_id as given by the STAR dataset
ren _s_tx_ctr_id   ctr
gen is_tx = 1

** Addressing refs: efficiency vs. n_internal
gen is_ineff_internal_pke = is_internal_pke==1 & _s_abo!="O" & _s_abo_don=="O"
gen is_o_don_internal_pke = is_internal_pke==1               & _s_abo_don=="O"


gen is_internal_non_nkr_pke  = is_internal_pke==1 & is_nkr ==0
gen is_external_non_nkr_pke  = is_external_pke==1 & is_nkr ==0
gen is_internal_non_apd_pke  = is_internal_pke==1 & is_apd ==0
gen is_external_non_apd_pke  = is_external_pke==1 & is_apd ==0
gen is_internal_non_unos_pke = is_internal_pke==1 & is_unos==0
gen is_external_non_unos_pke = is_external_pke==1 & is_unos==0
gen is_internal_non_ch_pke   = is_internal_pke==1 & is_nkr ==0 & is_apd==0 & is_unos==0
gen is_external_non_ch_pke   = is_external_pke==1 & is_nkr ==0 & is_apd==0 & is_unos==0

collapse (sum)                                           ///
  n_tx                       = is_tx                     ///
  n_nkr_tx                   = is_nkr                    ///
  n_apd_tx                   = is_apd                    ///
  n_unos_tx                  = is_unos                   ///
  n_ch_tx                    = is_ch                     ///
  n_pke_tx                   = is_pke                    ///
  n_live_tx                  = is_live                   ///
  n_internal_pke_tx          = is_internal_pke           ///
  n_external_pke_tx          = is_external_pke           ///
  n_internal_non_nkr_pke_tx  = is_internal_non_nkr_pke   ///
  n_external_non_nkr_pke_tx  = is_external_non_nkr_pke   ///
  n_internal_non_apd_pke_tx  = is_internal_non_apd_pke   ///
  n_external_non_apd_pke_tx  = is_external_non_apd_pke   ///
  n_internal_non_unos_pke_tx = is_internal_non_unos_pke  ///
  n_external_non_unos_pke_tx = is_external_non_unos_pke  ///
  n_internal_non_ch_pke_tx   = is_internal_non_ch_pke    ///
  n_external_non_ch_pke_tx   = is_external_non_ch_pke    ///
  n_ineff_internal_pke       = is_ineff_internal_pke     ///
  n_o_don_internal_pke       = is_o_don_internal_pke,    ///
by(ctr)

* Merge with ctr_list
merge 1:1 ctr using `ctr_list', assert(match using) nogenerate

foreach x of varlist n_* {
  replace `x' = 0 if mi(`x')
}

tempfile  tx_sums_by_ctr
save     `tx_sums_by_ctr'
// At this point, 240 centers, etc just as above

// Generate a list of centers ever in a CH (outside of the study period included)
use ${pair_dataset`suffix'}
gen     ctr = _nr_tx_ctr_id
replace ctr = _nd_tx_ctr_id if is_alt
keep ctr
duplicates drop
drop if mi(ctr)
tempfile nkr_ctrs
save `nkr_ctrs', replace
// 172 ctrs that ever did CH transplants

// Count TX and Non-TX Pairs by Center, within the NKR period
use ${pair_dataset`suffix'}

* Drop pairs that were registered outside the window
gen     drop_this =  0
replace drop_this =  1 if _nr_arr_date_min<date("04/02/2012","MDY") & ~mi(_nr_arr_date_min)
replace drop_this =  1 if _nd_arr_date_min<date("04/02/2012","MDY") & ~mi(_nd_arr_date_min)
replace drop_this =  1 if _nr_arr_date_min>$nkr_end_date            & ~mi(_nr_arr_date_min)
replace drop_this =  1 if _nd_arr_date_min>$nkr_end_date            & ~mi(_nd_arr_date_min)
drop if drop_this == 1

* Figure out the number of double counted donors
gen double_counted_donor = matched_donors>1

* Generate counts
gen     ctr = _nr_tx_ctr_id
replace ctr = _nd_tx_ctr_id if is_alt
collapse (sum)                         ///
 n_nkr_pair   = is_pair                ///
 n_nkr_chip   = is_chip                ///
 n_nkr_alt    = is_alt                 ///
 n_nkr_dc_don = double_counted_donor   ///
, by(ctr)
// n_nkr_tx     = _nr_transplanted       ///

// Compute participation rates
drop if mi(ctr)
count
// 146 NKR pairs during the period

merge 1:1 ctr using `nkr_ctrs', generate(nkr_merge) assert(match using)
// Add the 26 NKR centers who did no NKR tx during the study period
merge 1:1 ctr using `tx_sums_by_ctr'
// Add the 73 other centers that never partic in NKR, for a total of 245.
// The extra 5 must be from NKR pairs that were never matched, who were at centers that never 
// matched anyone else.

replace n_tx                =0 if mi(n_tx)
replace n_pke_tx            =0 if mi(n_pke_tx)
replace n_live_tx           =0 if mi(n_live_tx)
replace n_internal_pke_tx   =0 if mi(n_internal_pke_tx)
replace n_ineff_internal_pke=0 if mi(n_ineff_internal_pke)
replace n_o_don_internal_pke=0 if mi(n_o_don_internal_pke)
replace n_external_pke_tx   =0 if mi(n_external_pke_tx)

drop _merge

gen n_tx_per_year                   = n_tx                      / `years_of_data'
gen n_nkr_tx_per_year               = n_nkr_tx                  / `years_of_data'
gen n_apd_tx_per_year               = n_apd_tx                  / `years_of_data'
gen n_unos_tx_per_year              = n_unos_tx                 / `years_of_data'
gen n_pke_tx_per_year               = n_pke_tx                  / `years_of_data'
gen n_live_tx_per_year              = n_live_tx                 / `years_of_data'
gen n_internal_pke_per_year         = n_internal_pke_tx         / `years_of_data'
gen n_ineff_internal_pke_per_year   = n_ineff_internal_pke      / `years_of_data'
gen n_o_don_internal_pke_per_year   = n_o_don_internal_pke      / `years_of_data'
gen n_external_pke_per_year         = n_external_pke_tx         / `years_of_data'
gen n_internal_non_nkr_pke_per_year = n_internal_non_nkr_pke_tx / `years_of_data'
gen n_external_non_nkr_pke_per_year = n_external_non_nkr_pke_tx / `years_of_data'

gen ctr_size                = log(n_tx_per_year)
gen nkr_share               = n_nkr_tx          / n_pke_tx
gen apd_share               = n_apd_tx          / n_pke_tx
gen unos_share              = n_unos_tx         / n_pke_tx
gen ch_share                = n_ch_tx           / n_pke_tx
gen pke_share               = n_pke_tx          / n_live_tx
gen internal_share          = n_internal_pke_tx / n_pke_tx
gen nkr_ctr_2012            = n_nkr_tx > 0 & !mi(n_nkr_tx)
gen pke_ctr                 = n_pke_tx > 0 & !mi(n_pke_tx)

gen n_nkr_submission        = n_nkr_pair       + n_nkr_chip + n_nkr_alt
gen n_nkr_and_non_nkr_pke   = n_nkr_submission + n_pke_tx   - n_nkr_tx
gen nkr_share_submission    = n_nkr_submission / n_nkr_and_non_nkr_pke

gen n_nkr_don_submission      = n_nkr_pair + n_nkr_alt
gen n_nkr_and_non_nkr_pke_don = n_nkr_pair + n_nkr_alt + n_pke_tx - n_nkr_dc_don
gen nkr_don_share_submission  = n_nkr_don_submission / n_nkr_and_non_nkr_pke_don

// Over-writing some data, make assertions
* A couple centers have a share greater than 1, because of timing of txs and releases
* Most of these differences are very small
assert !(nkr_don_share_submission>1 & ~mi(nkr_don_share_submission) )
//count if nkr_don_share_submission>1 & ~mi(nkr_don_share_submission) 
//assert `r(N)'==10
//assert nkr_don_share_submission<=2 | mi(nkr_don_share_submission)                                        
//replace nkr_don_share_submission = 1 if nkr_don_share_submission>1 & ~mi(nkr_don_share_submission)

* One center has a missing share because of a zero denominator
assert !(mi(nkr_don_share_submission) & ~mi(n_nkr_pair))
//count if mi(nkr_don_share_submission) & ~mi(n_nkr_pair)
//assert `r(N)'==2
//replace nkr_don_share_submission = 1 if mi(nkr_don_share_submission) & ~mi(n_nkr_pair)

* Assert that nkr centers without nkr_don_share_submission did not participate during this period
assert n_nkr_don_submission == . if nkr_merge == 2

sort ctr
save ${ctr_partic_dataset`suffix'}, replace
}





