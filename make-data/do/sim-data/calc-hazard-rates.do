* Initialize
set more off
clear

adopath + "./do"

* Filenames are kept as globals in one do file
quietly do ./do/globals/load-globals.do

*insheet using `NKRdata'
use $nkr_file

/* Reformat dates to STATA style
foreach x of varlist arr_date_min arr_date_max dep_date_min dep_date_max {
  gen `x'_temp = date(`x',"MDY")
  drop `x'
  rename `x'_temp `x'
}*/

* Generate a registered year (based on min)
gen regyear = yofd(arr_date_min)

* Calculate minumum and maximum duration
gen duration_min = dep_date_min - arr_date_max
gen duration_max = dep_date_max - arr_date_min if dep_date_max!=date("12/04/2014","MDY")
replace duration_max = . if transplanted == 1

* Weight missing dummy
gen weight_miss= (weight==0 | missing(weight))
replace weight = 0 if weight_miss == 1

* Gen dummies for bloodtype
gen AB = abo=="AB"
gen A  = abo=="A"
gen B  = abo=="B"
gen O  = abo=="O"
*rename bloodtype abo

* Deal with recips who have multiple donors
* NOTE WELL: This tie-breaking procedure should match the one in calc-hazard-rates!!!
  * Otherwise, we pick a "best" donor based on a tie-breaker.

gsort + index + isdonor - transplanted - abo + age + ch_id
* Keep the highest rec and don in the sort order
by index isdonor: ///
  gen   keep_this = _n==1
keep if keep_this ==1
drop    keep_this

* Only keep certain variables
keep id           index         arr_date_min arr_date_max isdonor   dep_date_min    ///
     dep_date_max transplanted* age          weight*      mp_strict mp_strict_noabo ///
     duration*    alt           unpaired     regyear      AB        A               ///
     B            O             abo          cpra         center    tx_ctr_id       ///
     tx_chain     tx_cycle      tx_date      transplant_index
ren tx_date transplanteddate
tempfile  nkr_file
save     `nkr_file', replace

* Split into donor and recipient file and merge back
use `nkr_file', clear
keep if isdonor==1
drop    isdonor
*foreach x of varlist id age - O {
foreach x of varlist * {
  rename `x' d_`x'
}
ren d_index index
tempfile  nkr_donor_file
save     `nkr_donor_file', replace
  
use `nkr_file', clear
keep if isdonor!=1
drop    isdonor
*foreach x of varlist id age - O {
foreach x of varlist * {
  rename `x' r_`x'
}
ren r_index index

** Check consistency of the merge
merge 1:1 index using `nkr_donor_file'
assert (_merge==1)==(r_unpaired == 1)
assert (_merge==2)==(d_alt == 1)
drop _merge

*** Gen category
gen     category = "p"
replace category = "c" if r_unpaired == 1
replace category = "a" if d_alt == 1

**********************************
*** Generate a registered year ***
gen     regyear = r_regyear
replace regyear = d_regyear if r_regyear == .
  
gen year2007= r_regyear==2007
gen year2008= r_regyear==2008
gen year2009= r_regyear==2009
gen year2010= r_regyear==2010
gen year2011= r_regyear==2011
gen year2012= r_regyear==2012
gen year2013= r_regyear==2013
gen year2014= r_regyear==2014

************************
*** Label Variables ****

label variable r_duration_min    "Min Duration (recipients)" 
label variable r_duration_max    "Max Duration (recipients)" 
label variable d_duration_min    "Min Duration (donors)" 
label variable d_duration_max    "Max Duration (donors)" 
label variable r_mp_strict_noabo "Patient Matching Power"
label variable d_mp_strict_noabo "Donor Matching Power"
label variable r_age             "Patient Age"
label variable r_weight          "Patient's Weight"
label variable r_weight_miss     "Patient's Weight Missing"
label variable r_cpra            "Patient's cPRA"
label variable d_age             "Donor Age"
label variable d_weight          "Donor's Weight"

label variable d_AB "AB Blood-type Donor"
label variable d_B  "B  Blood-type Donor"
label variable d_A  "A  Blood-type Donor"
label variable d_O  "O  Blood-type Donor"
label variable r_AB "AB Blood-type Patient"
label variable r_B  "B  Blood-type Patient"
label variable r_A  "A  Blood-type Patient"
label variable r_O  "O  Blood-type Patient"

label variable year2007 "Year 2007"
label variable year2008 "Year 2008"
label variable year2009 "Year 2009"
label variable year2010 "Year 2010"
label variable year2011 "Year 2011"
label variable year2012 "Year 2012"
label variable year2013 "Year 2013"
label variable year2014 "Year 2014"

****************************
**** Hazard Regressions ****

* Init hazard to missing
gen hazard = . 
gen hazard_cpra = .
gen hazard_base = .

* Get a dummy for post snapshots registration, prioritizing Patient arrival date
gen     post_snapshots = r_arr_date_min>=date("04/02/2012","MDY") if r_arr_date_min~=.
replace post_snapshots = d_arr_date_min>=date("04/02/2012","MDY") if r_arr_date_min == .

* Modify one by hand
replace r_duration_min = 0 if r_id == "3404-nkr"
replace r_duration_max = 0 if r_id == "3404-nkr"

* Asserts
assert r_duration_min<= r_duration_max
assert d_duration_min<= d_duration_max
assert d_duration_min>=0 if post_snapshots == 1
assert r_duration_min>=0 if post_snapshots == 1

*****************************
** Pair-level Hazard Rates **
gen esample = post_snapshots==1 & category=="p"

* 
intcens r_duration_min r_duration_max r_mp_strict_noabo d_mp_strict_noabo r_age d_age r_AB r_A r_B d_AB d_A d_B if esample == 1, d(exp) 
outreg2 using $outfile,              replace label nodepvar eform ctitle("Pair Exponential") noobs
outreg2 using $paper_table_int_file, replace tex label nodepvar eform ctitle("Patient-Donor Pairs") 

predict hr
replace hazard = exp(hr) if category == "p"
drop hr

intcens r_duration_min r_duration_max r_cpra r_AB r_A r_B d_AB d_A d_B if esample == 1, d(exp) 
predict hr
replace hazard_cpra = exp(hr) if category == "p"
drop hr

intcens r_duration_min r_duration_max if esample == 1, d(exp) 
predict hr
replace hazard_base = exp(hr) if category == "p"
drop hr

intcens r_duration_min r_duration_max r_mp_strict_noabo d_mp_strict_noabo r_age d_age    r_AB r_A r_B d_AB d_A d_B if esample == 1, d(gom) 
outreg2 using $outfile, label nodepvar eform ctitle("Pair Gompertz") noobs

intcens r_duration_min r_duration_max r_mp_strict_noabo d_mp_strict_noabo r_age d_age    r_AB r_A r_B d_AB d_A d_B if esample == 1, d(weibull) 
outreg2 using $outfile, label nodepvar eform ctitle("Pair Weibull") noobs

*****************************
** Hazard Rates for CHIPs **

replace esample = post_snapshots==1 & category=="c"

intcens r_duration_min r_duration_max r_mp_strict_noabo r_age r_AB r_A r_B if esample == 1, d(exp) 
outreg2 using $outfile,              label nodepvar eform ctitle("Chip Exponential") noobs
outreg2 using $paper_table_int_file, label nodepvar eform ctitle("Unpaired Patients") tex

predict hr
replace hazard = exp(hr) if category == "c"
drop hr

intcens r_duration_min r_duration_max r_cpra r_AB r_A r_B if esample == 1, d(exp) 
predict hr
replace hazard_cpra = exp(hr) if category == "c"
drop hr

intcens r_duration_min r_duration_max if esample == 1, d(exp) 
predict hr
replace hazard_base = exp(hr) if category == "c"
drop hr

intcens r_duration_min r_duration_max r_mp_strict_noabo r_age r_AB r_A r_B if esample == 1, d(gom) 
outreg2 using $outfile,  label nodepvar eform ctitle("Chip Gompertz") noobs

intcens r_duration_min r_duration_max r_mp_strict_noabo r_age  r_AB r_A r_B if esample == 1, d(weibull) 
outreg2 using $outfile,  label nodepvar eform ctitle("Chip Weibull") noobs

****************************************
** Hazard Rates for Altruistic Donors **

replace esample = post_snapshots==1 & category=="a"

intcens d_duration_min d_duration_max d_mp_strict_noabo d_age d_AB d_A d_B if esample ==1, d(exp) 
outreg2 using $outfile,              label nodepvar eform ctitle("Altruistic Exponential") noobs
outreg2 using $paper_table_int_file, label nodepvar eform ctitle("Altruistic Donors") tex

predict hr
replace hazard = exp(hr) if category == "a"
drop hr

intcens d_duration_min d_duration_max d_AB d_A d_B if esample == 1, d(exp) 
predict hr
replace hazard_cpra = exp(hr) if category == "a"
drop hr

intcens d_duration_min d_duration_max if esample == 1, d(exp) 
predict hr
replace hazard_base = exp(hr) if category == "a"
drop hr

intcens d_duration_min d_duration_max d_mp_strict_noabo d_age d_AB d_A d_B if  esample ==1, d(exp) 
outreg2 using $outfile,  label nodepvar eform ctitle("Altruistic Gompertz") noobs
intcens d_duration_min d_duration_max d_mp_strict_noabo d_age d_AB d_A d_B if  esample ==1, d(exp) 
outreg2 using $outfile,  label nodepvar eform ctitle("Altruistic Weibull") noobs

****************************************************
** Assert that we have a hazard rate for everyone **

assert hazard ~=. if post_snapshots == 1
sort index

save $nkr_subs_w_hazard, replace

********* Modify the Tex File and copy it to ../tables
** Remove extraneous fields added by outreg2 and add \hline above observations
!sed '/p$<$0.01/d;/pdf/d;/document/d;/seEform/d;s/VARIABLES//g;s/Observations/\\hline Observations/g' $paper_table_int_file > $paper_table_outfile

** Add the Note
!sed -i '$ a \\\flushleft{Note: Interval censored exponential hazard model. Patient (Donor) Match Power is the fraction of donors (patient) in the NKR pool over the course of a sample a given patient (donor) is compatible with. Sample restricted to patients and donors that registered after April 2012.}' $paper_table_outfile
