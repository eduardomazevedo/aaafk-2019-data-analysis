* Which centers do pke? Which centers do nkr vs internal?

foreach suffix in "-perfect" "" {
*** Start ***
  set more off
  graph drop _all

  * Files
  local ctr_vars = "./datasets/ctr-participation-dataset`suffix'.dta"

// end fix

  * Load data
  clear
  use   `ctr_vars'

  * Create size variable
  gen n  = n_tx_per_year
  label variable n "kidney transplants per year"
  gen n2 = n^2
  

  * Labels for plotting
  gen     plot_labels = ""
  replace plot_labels = "Hopkins"          if ctr == "MDJH-TX"
  replace plot_labels = "Cornell"          if ctr == "NYNY-TX"
  replace plot_labels = "Methodist"        if ctr == "TXHS-TX"
  replace plot_labels = "Jackson Memorial" if ctr == "FLJM-TX"
  replace plot_labels = "UC Davis"         if ctr == "CASM-TX"
  replace plot_labels = "Wisconsin"        if ctr == "WIUW-TX"
  replace plot_labels = "UCLA"             if ctr == "CAUC-TX"
  replace plot_labels = "UCSF"             if ctr == "CASF-TX"

*** Summary Stats ***
  sum n_tx_per_year, d
  
  sum pke_ctr
  sum pke_share if pke_ctr == 1, d

  sum nkr_ctr
  sum nkr_share                if nkr_ctr == 1, d

  sum nkr_don_share_submission if nkr_ctr == 1, d

*** Participation in nkr: extensive margin ***
  logit nkr_ctr n 
  logit nkr_ctr n if pke_ctr

  binscatter nkr_ctr n if pke_ctr,                     ///
    xtitle("Hospital Size (# Transplants per year)")   ///
    ytitle("Fraction of Hospitals in the NKR")         ///
    graphregion(color(white)) mcolor(gs8) lcolor(navy) ///
    reportreg
  graph export "./figures/participation-nkr-extensive-margin`suffix'.eps", replace

  gen num_ch       = nkr_ctr + unos_ctr + apd_ctr 
  gen ch_ctr       = num_ch>0
  gen ch_multi_ctr = num_ch>1
  
  ** Fraction of centers that participate in the NKR
  !rm ./constants/c-percentage-participation-extensive-margin`suffix'.txt
  gen nkr_100 = nkr_ctr*100
  sum nkr_100 if pke_ctr
  
  file open  outputfile using ./constants/c-percentage-participation-extensive-margin`suffix'.txt, write binary
  file write outputfile %4s "`r(mean)'"
  file close outputfile

*** Participation in nkr: intensive margin ***
  reg nkr_share n
  reg nkr_share n n2
  reg nkr_share n    if nkr_ctr
  reg nkr_share n n2 if nkr_ctr
  
  // Trying to fix this
  twoway ///    
    (scatter nkr_share n if  nkr_ctr, mlabel(plot_labels) mcolor(navy) msize(vsmall) mlabcolor(navy) mlabposition(9)) ///
    (scatter nkr_share n if !nkr_ctr, mlabel(plot_labels) mcolor(gs8)  msize(vsmall) mlabcolor(navy) mlabposition(3)) ///
    (qfit    nkr_share n,            lcolor(gs8) )                        ///
    (qfit    nkr_share n if nkr_ctr, lcolor(navy)),                       ///
    name("intensive_nkr")                                                 ///
    xtitle("Hospital Size (# Transplants per year)")                      ///
    ytitle("Live Exchanges Facilitated through the NKR")                  ///
    xlabel(0 "0" 25 "25" 50 "50" 75 "75" 100 "100" 125 "125" 150 "150" 175 "175" 200 "200" 225 "225" 250 "250" 275 "275" 300 "300" 325 "325" 350 "350" 375 "375" 400 "400")               ///
    ylabel(0 "0%" 0.25 "25%" 0.5 "50%" 0.75 "75%" 1 "100%")               ///
    legend(order(3 4) label(3 "All hospitals") label(4 "NKR Participants")) ///
    graphregion(color(white))
  graph export "./figures/participation-nkr-intensive-margin`suffix'.eps", replace


  ** Overall intensive margin participation
  !rm ./constants/c-percentage-participation-intensive-margin`suffix'.txt
  gen nkr_share_100 = nkr_share*100
  sum nkr_share_100 if nkr_ctr

  file open  outputfile using ./constants/c-percentage-participation-intensive-margin`suffix'.txt, write binary
  file write outputfile %4s "`r(mean)'"
  file close outputfile


  twoway ///
    (scatter nkr_share n_pke_tx_per_year, mlabel(plot_labels))            ///
    (qfit    nkr_share n_pke_tx_per_year)                                 ///
    (qfit    nkr_share n_pke_tx_per_year if nkr_ctr),                     ///
    name("pkeintensive")                                                  ///
    xtitle("Number of PKE TX per year*")                                  ///
    ytitle("Live Exchanges Facilitated through the NKR")                  ///
    ylabel(0 "0%" 0.25 "25%" 0.5 "50%" 0.75 "75%" 1 "100%")               ///
    legend(order(2 3) label(2 "All hospitals") label(3 "NKR Participants")) ///
    note("* Includes deceased donor transplants")                         ///
    graphregion(color(white))
  graph export "./figures/pke-tx-participation-nkr-intensive-margin.eps", replace

}
