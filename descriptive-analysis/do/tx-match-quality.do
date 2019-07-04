clear all

set linesize 150

foreach suffix in "-perfect" "" {

use ./datasets/transplant-level-data-full`suffix'.dta, clear
global star_begin_year = 2008
sum    _s_tx_date if is_nkr
global nkr_end_date = `r(max)'

* Keep only pkes after 2008 and up to the end of nkr data
  keep if (year(_s_tx_date) >= $star_begin_year) &  ///
          (     _s_tx_date  <= $nkr_end_date)    & is_pke == 1

*replace ch="pke-no-ch" if mi(ch) & is_pke==1 & _s_tx_date <= $star_end_date

tab ch, missing

count 
file open  outputfile using ./constants/c-num-pke-optn.txt,   write text replace
file write outputfile "`r(N)'% This pct sign makes a LaTeX comment"
file close outputfile

// new stuff here
gen correct = trr_id_code==_nd_trr_id_code

collapse (count) is_ch  (sum) correct, by(ch) //(sum) perfect

drop if mi(ch)
replace correct = . if correct==0
tempfile  tx
save     `tx'
*l

use ./datasets/pair-level-data-full`suffix'.dta, clear

gen            num_tx =          ( !mi(_nr_tx_id) & (year(_nr_tx_date) >= $star_begin_year) & (_nr_tx_date  <= $nkr_end_date) )
replace        num_tx = num_tx + ( !mi(_nd_tx_id) & (year(_nd_tx_date) >= $star_begin_year) & (_nd_tx_date  <= $nkr_end_date) )

collapse (sum) num_tx, by(ch)
replace        num_tx = num_tx/2

*l
merge 1:1 ch using `tx'
ren ( is_ch            correct ) ///
    ( num_matched  num_correct )
drop _merge
order ch num_matched num_tx

gen  match_rate     = 100*num_matched/num_tx
gen  corr_rate      = 100*num_correct/num_matched
l

quietly {
foreach ch in nkr apd unos {
    sum match_rate if ch=="`ch'"
    file open  outputfile using ./constants/c-tx-merge-`ch'-match-rate`suffix'.txt, write text replace
    file write outputfile %2.0f (`r(mean)') "% This pct sign makes a LaTeX comment"
    file close outputfile

    sum  num_tx if ch=="`ch'"
    local ntx_`ch' = r(mean)
    file open  outputfile using ./constants/c-num-tx-`ch'.txt,   write text replace
    file write outputfile "`r(mean)'% This pct sign makes a LaTeX comment"
    file close outputfile
}
    sum corr_rate if ch=="unos"
    file open  outputfile using ./constants/c-tx-merge-unos-corr-rate`'suffix.txt, write text replace
    file write outputfile %2.0f (`r(mean)') "% This pct sign makes a LaTeX comment"
    file close outputfile
    
    file open  outputfile using ./constants/c-num-tx-all-ch.txt, write text replace
    file write outputfile "`=`ntx_apd'+`ntx_unos'+`ntx_nkr''% This pct sign makes a LaTeX comment"
    file close outputfile
}

collapse (sum) num_tx num_matched
gen  all_match_rate = 100*num_matched/num_tx
l

quietly {
  sum all_match_rate
  file open  outputfile using ./constants/c-tx-merge-all-match-rate`suffix'.txt, write text replace
  file write outputfile %2.0f  (`r(mean)') "% Not percentage, but LaTeX comment" 
  file close outputfile
}

use ./datasets/transplant-level-data-full`suffix'.dta, clear

keep if (year(_s_tx_date) >= $star_begin_year) & (_s_tx_date  <= $nkr_end_date) & is_pke == 1

drop if mi(ch)
noisily di "Quality of transplanted match"
noisily di "-----------------------------"

gen         age_5yr  = abs(_s_age      - _nr_age     ) <= 5 & ///
                       abs(_s_age_don  - _nd_age     ) <= 5
gen         date_1dy = abs(_s_tx_date  - _nr_tx_date ) <= 1
gen hla_matches     = 0 
gen hla_matches_don = 0
foreach l in a b dr {
  foreach a in 1 2 {
    di "`l'`a'"
    count if ( _s_r`l'`a' == _nr_`l'`a' )
    count if ( _s_d`l'`a' == _nd_`l'`a' )
    replace hla_matches     = hla_matches     + ( _s_r`l'`a' == _nr_`l'`a' )
    replace hla_matches_don = hla_matches_don + ( _s_d`l'`a' == _nd_`l'`a' )
  }
}

//gen            hla_5 =   hla_matches>=5  &  hla_matches_don>=5
//gen            hla_6 =   hla_matches>=6  &  hla_matches_don>=6

gen hla_5 = hla_matches_net>=5 & hla_matches_net_don>=5
gen hla_6 = hla_matches_net>=6 & hla_matches_net_don>=6

foreach var in _s_abo _s_abo_don {
  replace `var' = subinstr(`var', "1", "",.)
  replace `var' = subinstr(`var', "2", "",.)
}
gen           abog_2 =  ( _s_abo        == _nr_abo    ) & ///
                        ( _s_abo_don    == _nd_abo    ) & ///
                        ( _s_gender     == _nr_gender ) & ///
                        ( _s_gender_don == _nd_gender )
gen     tx_ctr_match =  ( _s_tx_ctr_id  == _nr_tx_ctr_id )
gen        intersect =  (              date_1dy==1 & hla_5==1 & abog_2==1 & tx_ctr_match==1 ) | ///
                        ( age_5yr==1 &               hla_5==1 & abog_2==1 & tx_ctr_match==1 ) | ///
                        ( age_5yr==1 & date_1dy==1            & abog_2==1 & tx_ctr_match==1 ) | ///
                        ( age_5yr==1 & date_1dy==1 & hla_5==1             & tx_ctr_match==1 ) | ///
                        ( age_5yr==1 & date_1dy==1 & hla_5==1 & abog_2==1                   ) 
gen        perfect5  =  ( age_5yr==1 & date_1dy==1 & hla_5==1 & abog_2==1 & tx_ctr_match==1 )
gen        perfect6  =  ( age_5yr==1 & date_1dy==1 & hla_6==1 & abog_2==1 & tx_ctr_match==1 )

gen vec = 100000+age_5yr*10000 + date_1dy*1000 + hla_5*100 + abog_2*10 + tx_ctr_match
tab vec, mi

count if ch=="nkr" & age_5yr==1 & date_1dy==1 & tx_ctr_match==1
local matched  = r(N)
count if ch=="nkr" & age_5yr==1 & date_1dy==1 & tx_ctr_match==1 & perfect5==1
local pmatched = r(N)
di "Percentage matched: `: di %2.1f `=100*`matched'/1193''%"
di "Of matched, percent perfect5: `: di %2.1f `=100*`pmatched'/`matched'''%"


label   var age_5yr      "Ages within 5 years"
label   var date_1dy     "Tx Date within 1 day"
label   var hla_5        "5 or 6 HLA matches"
label   var abog_2       "Both ABO and gender matched"
label   var tx_ctr_match "Transplant center match"
label   var intersect    "At most one of the above fail"
label   var perfect5     "All of the above hold"
label   var perfect6     "All of the above hold and all 6 HLA alleles match"

local vs      = "age_5yr date_1dy hla_5 abog_2 tx_ctr_match intersect perfect5 perfect6"
local count_vs  = ""
local sum_vs    = ""
local mean_vs   = ""

foreach v in `vs' {
    ren  `v'        `v'_count
    gen  `v'_sum  = `v'_count
    gen  `v'_mean = `v'_count
    local count_vs  = "`count_vs'  `v'_count"
    local sum_vs    = "`sum_vs'    `v'_sum"
    local mean_vs   = "`mean_vs'   `v'_mean"
}
collapse (sum)  `sum_vs' (count) `count_vs' (mean) `mean_vs', by(ch)
*foreach v in `mean_vs' {
*  replace `v' = 100 * `v'
*}
di  "`v'"
preserve
  keep ch `mean_vs'
  tempfile  by_ch
  save     `by_ch'
restore

collapse (sum)  `sum_vs' (sum)   `count_vs'
foreach v in `vs' {
  gen `v'_mean = `v'_sum / `v'_count
}
gen   ch = "all-ch"
order ch
keep  ch `mean_vs'

tempfile  all_ch
save     `all_ch'

use `by_ch', clear
append using `all_ch'
l
export excel using "./intermediate-tables/tx-match-quality`suffix'.xls", sheet("raw") firstrow(varlabels) sheetreplace

replace perfect5_mean = 100*perfect5_mean
sum perfect5_mean if ch=="all-ch"
file open  outputfile using ./constants/c-tx-merge-perf5-rate`suffix'.txt, write text replace
file write outputfile %2.0f (`r(mean)') "% This pct sign makes a LaTeX comment"
file close outputfile 
}
