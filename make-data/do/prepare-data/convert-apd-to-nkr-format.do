clear all 
set more off

quietly do ./do/globals/load-globals.do

import delimited $apd_file_pre_conv
duplicates drop

* Index is called famid in the APD data.  It is missing for alts, so we conform to NKR usage and set 
* index equal to the alt's id
ren famid index
replace   index = id if !mi(alt)
* Different names
ren center center_star
* In NKR, unpaired is missing for alts, 0 for paired don/recs, and 1 for UPRs.  APD has no UPRs, so 
* the following code should suffice.
gen     unpaired = 0
replace unpaired=. if alt==1

* Some antigens are not ordered correctly, which leads to bad matches.
foreach locus in a b dr {
  gen          switch = (`locus'1 > `locus'2) & (`locus'2!=-1)
  gen     `locus'1new =  `locus'2    if switch==1
  replace `locus'2    =  `locus'1    if switch==1
  replace `locus'1    =  `locus'1new if switch==1
  drop    `locus'1new switch
}

export delimited $apd_file_with_dups, replace
