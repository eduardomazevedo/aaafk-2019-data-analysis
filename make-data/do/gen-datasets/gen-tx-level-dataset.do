set more off
clear all
adopath + "./do"

// This do file makes a dataset where each line is a STAR transplant.  When the transplant is 
// matched to a clearinghouse transplant, extra clearinhouse data is appended.  Note that
// this means that we are omitting clearinghouse transplants that don't match with a STAR
// transplant.  This is by design: if STAR includes all transplants, then it must include even
// those that we can't match to a clearinghouse.  Hence, to include both the STAR and 
// clearinghouse record would double count.  The important catch here is that looking at the 
// clearinhouse variable will only summarize clearinghouse transplants that were matche to STAR.

* Filenames are kept as globals in one do file
quietly do do/globals/load-globals.do

//foreach ch in nkr apd unos {
//  di "Clearinghouse: `ch'"
*local ch = "nkr"
  use $all_ch_file, clear
  /*if "`ch'"=="nkr" {
    foreach v in antidrw antidpa antidqa {
        di "Textifying: `v'"
        gen `v'_txt = string(`v')
        drop `v'
        ren  `v'_txt `v'
    }
  }
  if "`ch'"=="apd" {
    foreach v in alias race antibw anticw {
        di "Textifying: `v'"
        gen `v'_txt = string(`v')
        drop `v'
        ren  `v'_txt `v'
    }
  }
  if "`ch'"=="unos" {
    drop insnapshots
    gen  insnapshots=.
    foreach v in sex race alias center antibw antidrw antidpa relateddonors dialysisstartdate ///
                 unoslistdate hard_blocked_donors{
        di "Textifying: `v'"
        gen `v'_txt = string(`v')
        drop `v'
        ren  `v'_txt `v'
    }
  }*/
  *egen   num_tx_nkr = sum(!mi(tx_id)), by(index)
  keep if !mi(tx_id) // We only want clearinghouse patients and donors who were 
                     // ultimately transplanted.
  // Save the transplanted donors
  preserve
    keep if isdonor==1
    quietly ds
    foreach var in `r(varlist)' {
      ren `var' _nd_`var'
    }
    * rename the donor's tx_id so it can be merged with the recipient
    ren _nd_tx_id       _nr_ch_id
    * use the extended_id (with D prefix) as the main reference for the donor
    ren _nd_ch_id ch_id_don
    tempfile  tx_dons
    save     `tx_dons' 
    count
  restore

  // Save the transplanted recipients
  preserve
    keep if isdonor==0
    quietly ds
    foreach var in `r(varlist)' {
      ren `var' _nr_`var'
    }
    tempfile  tx_recs
    save     `tx_recs'
    count
  restore

  // Using the renames from before, merge the transplanted partner dons to the transplanted 
  // recs. Note that this can be done with identifiers internal to the clearinghouse.  We 
  // aren't linking to the STAR data yet.
  use `tx_recs', clear
  merge 1:m _nr_ch_id using `tx_dons'
  ren       _nr_ch_id ch_id_rec

  order ch_id*
  drop _merge

// This file includes all transplants in the all_ch data, regardless of whether they matchs 
// with STAR
  tempfile before_tx_merge
  save `before_tx_merge', replace

foreach suffix in "" "_perfect" { 
  use `before_tx_merge', clear
  di "suffix: `suffix'"
  // Now, we add the STAR identifiers found in the tx match, so that we can import data 
  // from the STAR data.
  merge 1:1 ch_id_don ch_id_rec using ${all_ch_tx_match`suffix'}
  drop ch_index_rec ch_index_don pt_code _merge

  assert _nd_ch==_nr_ch
  drop _nr_ch
  ren  _nd_ch ch

// We still include transplants from the clearinghouse match that didn't match to STAR
save ${tx_dataset`suffix'}, replace

use $star_file_with_dh
recode_hla ra rb rdr da dr ddr 
// Only STAR transplants (disregard waitinglist only guys)
keep if !mi(trr_id_code)    
ren max_kdpi_import_non_zero_abdr ///
    max_kdpi_impt_nonzero_abdr
quietly ds
foreach var in `r(varlist)' {
    ren `var' _s_`var'
}
ren _s_wl_id_code   wl_id_code
ren _s_trr_id_code  trr_id_code

merge 1:m wl_id_code trr_id_code using ${tx_dataset`suffix'}
ren _s_pt_code pt_code
// _merge==2 is "using only": this is the point where we drop all transplants from the 
// clearinghouse data that didn't match with STAR
drop if _merge==2
drop _merge
    
*** Additional Variables ***
* Now we add tags that classify transplants
* NOTE that a transplant can be internal AND nkr/apd/unos by these definitions!

gen     is_ch           = !mi(ch_id_don, ch_id_rec)
gen     is_nkr          = is_ch & ch=="nkr"
gen     is_apd          = is_ch & ch=="apd"
gen     is_unos         = is_ch & ch=="unos"
gen     is_pke          = is_ch | inlist(_s_liv_don_ty_reclassified,9,10)
gen     is_live         = is_ch | _s_don_ty != "C"
gen     is_internal_pke = is_pke & (_s_tx_ctr == _s_tx_ctr_don)
gen     is_external_pke = is_pke & !is_internal_pke

/*gen     tx_category     = "ch-internal pke"     if  is_ch & is_internal_pke
replace tx_category     = "ch-external pke"     if  is_ch & is_external_pke
replace tx_category     = "non-ch-internal pke" if !is_ch & is_internal_pke
replace tx_category     = "non-ch-external pke" if !is_ch & is_external_pke*/
gen     tx_category     = "nkr"              if  is_nkr
replace tx_category     = "internal pke"     if  is_internal_pke
replace tx_category     = "external pke"     if  is_external_pke


label variable is_ch           "ch transplant"
label variable is_internal_pke "PKE inside a center"
label variable is_external_pke "PKE across different centers"
label variable tx_category     "Transplant Category"

*save `tx_and_subm_level_output_file', replace

drop if mi(trr_id_code)
drop if year(_s_tx_date)<2008

merge 1:1 trr_id_code using $all_ch_tx_match_with_merge, ///
          keepusing(hla_matches_net hla_matches_net_don) nogen

save             ${tx_dataset`suffix'},     replace
export delimited ${tx_dataset`suffix'_csv}, replace

}
