* Checks for inefficient use of o donors in internal vs nkr transplants.

*** Load the ado library
prog drop _allado
sysdir set PERSONAL ./ado/

*** Start ***
  set more off
  graph drop _all

foreach suffix in "-perfect" "" {
  * Files
  local dataset    "./datasets/transplant-level-data-full`suffix'.dta"
  local ctr_vars = "./datasets/ctr-participation-dataset`suffix'.dta"

*** Open data ***
  * Load data
  clear
  use `dataset'

  * Keep only pkes after 2008 and up to the end of nkr data
  keep if year(_s_tx_date) >= 2008 & is_pke == 1
  sum          _s_tx_date if is_nkr
  keep if      _s_tx_date  <= `r(max)'

  drop if missing(_s_tx_ctr)

// Merge with participation data. Note we are insisting that all ctrs match to the center
// participation dataset.
  gen ctr = _s_tx_ctr_id
  merge m:1 ctr using `ctr_vars', generate(_merge_ctr) keep(match master) //assert(match using)
  
  // Dropped that last assert to make the script run.  Only drops HISF-TX, which never 
  // participates in a clearinghouse transplant, and also does not run transplants after 
  // 2011.

*** Analysis ***
  * abo_dum generates dummies from abo
  * First arugment is abo field and second argument is output abo
  abo_dum _s_abo     r_abo
  abo_dum _s_abo_don d_abo

  ** Select variables

  * PRA
  rename _s_end_cpra pra
  gen pra_90 = pra>90 if pra!=.

  * Age, weigh, height bmi
  rename _s_age_don          age
  rename _s_bmi_don_calc     bmi
  rename _s_hgt_cm_don_calc  height
  rename _s_wgt_kg_don_calc  weight
  rename _s_hlamis           hlamis
  rename _s_drmis            drmis

  * Match Power
  rename _s_mp_weak        mp_weak
  rename _s_mp_weak_noabo  mp_weak_noabo
  *rename _s_mp_weak_don mp_weak_don
  *rename _s_mp_weak_noabo_don mp_weak_noabo_don

  * Efficiency
  gen O_to_non_O                = r_abo_O == 0 & d_abo_O == 1
  gen O_to_non_O_non_sensitized = r_abo_O == 0 & d_abo_O == 1 & (pra<90 | pra == .)

  * Time on Dialysis
  gen     dialysis_days = _s_tx_date - _s_dial_date
  replace dialysis_days = 0 if dialysis_days<0

  * Interactions of participation rate with is_nkr
  gen nkr_share_int_is_nkr = nkr_don_share_submission * is_nkr

  * tx_category is internal vs external i.e. same center or not. Replace
  *replace tx_category = "nkr" if is_nkr
  replace tx_category = ch         if !mi(ch)
  replace tx_category = "apd-unos" if inlist(tx_category,"apd","unos")
  tab     tx_category
  
  * Generate a histogram of dialysis days
  gen     tx_name = "NKR"             if tx_category == "nkr"
  // The line below was gen instead of replace before.
  replace tx_name = "Within Hospital" if tx_category == "internal pke"

  hist dialysis_days if dialysis_days>0, by(tx_name)
  // This was png before.  But the linux server only doesn't have Graph2png
  graph export ./figures/dialysis_hist.eps, replace
  !convert ./figures/dialysis_hist.eps ./figures/dialysis_hist.png

    *** Generates a summary table with count, mean, sd
* Stores the output in outdir/filestub.dta and outdir/filestub.xls
*  Arguments, in this order
  * vars      = variables to summarize
  * by_vars   = categories
  * outdir    = output directory
  * filestub  = stub of the filenames to use
  * sheetname = sheet for the excel file

summary_tab "r_abo* d_abo* mp* pra pra_90 O_to_non_O* age bmi height weight hlamis dialysis_days drmis" ///
            "tx_category"                                                                               ///
            "./intermediate-tables"                                                                     ///
            "pke-tx-summary`suffix'"                                                                            ///
            "summ_raw"


}
