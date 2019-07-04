clear all
set more off

quietly do ./do/globals/load-globals.do

use $star_file, clear
keep trr_id_code gender gender_don
keep if !mi(trr_id_code)
//count
//egen num_genders=total(!mi(gender)), by(pt_code)
//drop if num_genders>1
//drop num_genders
count
tempfile  gender_file
save     `gender_file', replace

import delimited $unos_raw, clear

ren towl donated_to_wl
replace center_star=substr(center_star,1,7)

assert mi(sex)

*merge m:1 pt_code using `gender_file', keepusing(gender gender_don)
merge m:1 trr_id_code using `gender_file'
// keep if the record was originally in the unos data, either matched (3) or master only (1)
keep if inlist(_merge,1,3)
drop _merge

/*foreach var of varlist arr_date_min      arr_date_max ///
                       dep_date_max      dep_date_min ///
                       transplanteddate  registered  {
  di "`var'"
  gen    d = date(`var', "MDY")
  format d %td
  drop            `var'
  ren    d        `var'
}*/
format %td dialysisstartdate unoslistdate

* Some antigens are not ordered correctly, which leads to bad matches.
foreach locus in a b dr {
  replace `locus'1 = -1 if `locus'1==0 | mi(`locus'1)
  replace `locus'2 = -1 if `locus'2==0 | mi(`locus'2)
  gen          switch = (`locus'1 > `locus'2) & (`locus'2!=-1)
  gen     `locus'1new =  `locus'2    if switch==1
  replace `locus'2    =  `locus'1    if switch==1
  replace `locus'1    =  `locus'1new if switch==1
  drop    `locus'1new switch
}

*duplicates tag pt_code, gen(pt_dups)
replace index=famid if !mi(famid)
egen fam_size = sum(!mi(   id)), by(index)
replace unpaired = 0 if alt!=1 & fam_size>1
replace unpaired = . if alt==1
replace unpaired = 1 if fam_size==1 & alt!=1
drop fam_size
replace isdonor = 1
replace isdonor = 0 if regtype=="Recipient"
drop sex
gen     sex = gender_don if isdonor==1
replace sex = gender     if isdonor==0
drop gender gender_don
replace alt=. if alt==0
gen     extended_id = "D"+string(   id) if isdonor==1
replace extended_id = "R"+string(   id) if isdonor==0
preserve
  tempfile notx
  keep if mi(trr_id_code)
  save `notx'
restore
preserve
  tempfile txdons
  keep if isdonor==1 & !mi(trr_id_code)
  save `txdons'
restore
preserve
  tempfile txrecs
  keep if isdonor==0  & !mi(trr_id_code)
  save `txrecs'
restore

use `txdons', clear
ren id    temp
* With the donors, we keep records that don't match, since there are some transplants that go to the 
* WL, and the WL candidate is not in the system.  These are marked with donated_to_wl==1
merge 1:1 trr_id_code using `txrecs', keepusing(id) 
drop _merge
ren id    tx_id
ren temp  id
save `txdons', replace

use `txrecs', clear
ren id    temp
merge 1:1 trr_id_code using `txdons', keepusing(id) keep(match)
drop _merge
ren id    tx_id
ren temp  id
save `txrecs', replace

append using `txdons'
append using `notx'

gen     tx_id_str       = "D"+string(tx_id) if isdonor==0 & !mi(tx_id)
replace tx_id_str       = "R"+string(tx_id) if isdonor==1 & !mi(tx_id)
drop    tx_id
ren     tx_id_str  tx_id

foreach locus in a b dqb dr {
    replace anti`locus' = subinstr(anti`locus',"*","",.)
}

* Fix caps so that compute-mp-pra.py functions correctly
* ABO compatibility
*ren  bloodtype bloodType
* Weak tissue-type compatibility
*ren (a1 a2 b1 b2 dr1 dr2) ///
*    (A1 A2 B1 B2 DR1 DR2)
*ren (antia antib antidr) ///
*    (antiA antiB antiDR)
* Strict tissue-type compatibility
*ren (bw1 bw2 bw4 bw6 cw1 cw2 drw1 drw2 dpa1 dpa2 dqa1 dqa2 dqb1 dqb2 dr51 dr52 dr53) ///
*    (Bw1 Bw2 Bw4 Bw6 Cw1 Cw2 DRw1 DRw2 DPA1 DPA2 DQA1 DQA2 DQB1 DQB2 DR51 DR52 DR53)
*ren (antibw antibw4 antibw6 anticw antidrw antidpa antidqa antidqb antidr51 antidr52 antidr53) ///
*    (antiBw antiBw4 antiBw6 antiCw antiDRw antiDPa antiDQa antiDQb antiDR51 antiDR52 antiDR53)

export delimited $unos_file_sans_MP_cPRA, replace 
