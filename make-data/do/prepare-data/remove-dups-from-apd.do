clear all
set more off

quietly do ./do/globals/load-globals.do

import delimited $apd_file_with_dups

******************
* Initial cleanup
******************

* Convert tx_date from string to Stata dates
gen    listingdate_stata  = date(listingdate, "MDY")
gen    dep_date_max_stata = date(dep_date_max, "DMY")
format listingdate_stata  %td
format dep_date_max_stata %td

* Put the 1/1/2000 dates to the end of any sorts, so the earliest record must be one with a "real" date.
replace listingdate_stata = date("01/01/3000","MDY") if listingdate_stata == date("01/01/2000","MDY")

* Start by dropping a few weird tx ctrs that are APD's way of coding foreign patients.  They won't 
* be in STAR so we drop them.
count
drop  if inlist(center_star,"APD-TX","APDUS-TX","RENEW-TX","NKR-TX","INNSZ-TX") & mi(tx_id)
count if !mi(tx_id)
count

* Show that we start off with all non-alts matching to someone on famidx.
tempfile  dons_temp
tempfile  recs_temp
preserve
  keep if isdonor==1
  save     `dons_temp'
restore
preserve
  keep if isdonor==0
  save     `recs_temp'
  merge 1:m famidx using `dons_temp'
  tab _merge alt, missing
  assert (_merge==2 & alt==1) | (_merge==3 & mi(alt))
restore

***************
* Remove one-sided translants
***************

* A one-sided transplant is a record with a tx_id that doesn't reference an idx that is found 
* anywhere else.

* Find donors whose tx_id doesn't match with any rec
preserve
  use `dons_temp', clear
  drop if mi(tx_id)
  ren idx    temp_idx
  ren tx_id  idx
  merge 1:m idx using `recs_temp'
  keep temp_idx  idx  _merge
  ren  idx       tx_id
  ren  temp_idx  idx
  keep if _merge==1 // only in master
  keep idx tx_id
  l
  keep idx
  tempfile  one_sided_tx
  save     `one_sided_tx'
restore

* Find recs whose tx_id doesn't match with any donor
preserve
  use `recs_temp', clear
  drop if mi(tx_id)
  ren idx    temp_idx
  ren tx_id  idx
  merge 1:m idx using `dons_temp'
  keep temp_idx  idx _merge
  ren  idx       tx_id
  ren  temp_idx  idx
  keep if _merge==1  // only in master
  keep idx  tx_id
  l
  keep idx
  append using `one_sided_tx'
  save         `one_sided_tx', replace
  l
restore

* For all dons and recs whose tx_id doesn't match with anyone in the data set, remove any mention 
* of transplantation -- that is, treat them as untransplanted dons and recs.
use          `dons_temp',    clear
append using `recs_temp'
merge 1:1 idx using `one_sided_tx'
replace tx_id            = "" if _merge==3
replace transplanted     = .  if _merge==3
replace transplanteddate = "" if _merge==3
drop _merge

* Make sure that we have the same number of dons and recs in transplants
count if isdonor==0 & !mi(tx_id)
local rec_tx_num = r(N)
count if isdonor==1 & !mi(tx_id)
local don_tx_num = r(N)
assert `rec_tx_num'==`don_tx_num'

* Ensure all transplants are two-sided
preserve
  tempfile don_tx
  keep if isdonor==1 & !mi(tx_id)
  keep idx tx_id
  save `don_tx'
restore
preserve
  keep if isdonor==0 & !mi(tx_id)
  keep idx tx_id
  ren tx_id idx2
  ren idx   tx_id
  merge 1:1 tx_id using `don_tx'
  assert _merge==3
  assert idx==idx2
  count
restore


* APD has a lot of duplicate donors and recs (for some reason).  Also, APD codes bridge donors as 
* altruists. The rest of this do file cleans this up.  The procedure is:
*   - Merge duplicate recs into one rec and fix the famidx on donors so that they point at the new 
*     merged rec.
*   - Find within famidx duplicates (wfds), that is, donors that match on $apd_dup_matchon AND 
*     famidx. Merge these into one record.
*   - Find cross famidx duplicates (cfds), that is, donors that match on just $apd_dup_matchon.
*   - The cfd profile groups can be classified as
*        + Loners.  Profiles with one record.  No need to do anything here.
*        + Bridge.  Profiles with two records, one of which is an alt.  Here we move the earliest 
*          dates to the non-alt and drop the alt.
*        + Non-bridge.  Profiles with two records where both are alts or non-alts.  These guys seem 
*          to be donors pledged to more than one rec.  Here, we declare them no to be duplicates, 
*          by fiat.
*

********
* Find duplicates
********
* First, we look for duplicates without considering center or age
egen dup_id     =               group(isdonor sex bloodtype a1 a2 b1 b2 dr1 dr2)
* manual_mark will be included in all duplicate searches.  So, by giving two records distinct non-negative  
* values in manual_mark, they are manually marked as not duplicates. We break up duplicate groups where 
* the records neither match on center nor have ages within 5 years of each other. 
egen cnum = group(center_star)
egen min_cnum = min(cnum), by(dup_id)
egen max_cnum = max(cnum), by(dup_id)
egen min_age  = min(age),  by(dup_id)
egen max_age  = max(age),  by(dup_id)
gen     manual_mark  = -1
gen     dup_comment = ""
replace manual_mark  = runiform() if min_cnum!=max_cnum & abs(min_age-max_age)>5
replace dup_comment = "Didn't match on center and age off by >5 years" ///
                                  if min_cnum!=max_cnum & abs(min_age-max_age)>5
egen    num_man_mark = total(!mi(idx)), by(manual_mark)

* In theory, two records could randomly get the same manual_mark.  This assert rules that out, but if 
* the assert fails, running the script again might solve the problem.
assert num_man_mark==1 | manual_mark==-1
* Now we build the dup_id we will use for the rest of the script
drop cnum min_cnum max_cnum min_age max_age num_man_mark dup_id 
egen dup_id     =               group(isdonor sex bloodtype a1 a2 b1 b2 dr1 dr2 manual_mark)
egen num_dups   = total(!mi(idx)), by(isdonor sex bloodtype a1 a2 b1 b2 dr1 dr2 manual_mark)

*********
* Merge duplicate recs
*********

* Find the max_dup_id
sum       dup_id
local max_dup_id = r(max)

* Create a file that has the idx of all duplicate recs along with the keep_id -- the idx that the 
* duplicates are being merged into.
preserve
  keep if isdonor==0 & num_dups>1
  bysort dup_id (listingdate_stata): gen keep_id = idx[1]
  keep idx keep_id
  tempfile  dup_recs
  save     `dup_recs'
  l
restore

* Make sure all transplant information is in the keep_id, then drop all records that aren't the 
* keep_id.  This will leave a lot of dons matched with non-existent recs, either as a "family" 
* member or as a transplant partner.  We will fix those dangling pointers immediately after this 
* preserve block.
preserve
  keep if isdonor==0
  * Put transplant info into all duplicates, so ensure that none is lost.
  * String missings are first in the sort order.
  bysort dup_id (tx_id)            : replace tx_id            = tx_id[_N]
  bysort dup_id (tx_id)            : replace transplanteddate = transplanteddate[_N]
  bysort dup_id (tx_id)            : replace transplanted     = transplanted[_N]
  * Remove duplicate recs where idx!=keep_id. This will leave dons who pointed at the 
  * deleted recs hanging.  We will clean that up shortly.
  merge 1:1 idx using `dup_recs'
  keep if idx==keep_id | _merge==1   // keep if the idx is only in the master (ie isn't duplicated) 
                                     // or if the idx is the keep_id of a duplicate group.
  replace dup_comment="Duplicate recs merged into this record" if idx==keep_id
  drop num_dups
  egen num_dups = total(!mi(idx)),   by(dup_id)
  assert num_dups==1
  drop keep_id _merge num_dups
  tempfile  recs
  save     `recs', replace
  count
  local start_recs = r(N)
restore

* Now, we point dons who were pointed at a deleted dup rec at the new rec id that we kept above. 
keep if isdonor==1
count
local start_dons = r(N)
* Fix dons whose famid is pointed at a duplicate rec that was just dropped
ren idx temp_idx
ren famidx idx
merge m:1 idx using `dup_recs'
ren idx famidx
ren temp_idx idx
replace famidx   = keep_id if _merge==3
drop keep_id _merge
tempfile dons
count
save `dons', replace

* Fix dons whose tx_id is pointed at a duplicate rec that was just dropped
ren idx temp_idx
ren tx_id idx
merge m:1 idx using `dup_recs'
ren idx tx_id
ren temp_idx idx
replace tx_id   = keep_id if _merge==3
* Not all dups will match on tx_id; we drop such records.
drop if _merge==2
drop keep_id _merge
save `dons', replace
count
append using `recs'

* Ensure all transplants are two-sided
preserve
  tempfile don_tx
  keep if isdonor==1 & !mi(tx_id)
  keep idx tx_id
  save `don_tx', replace
restore
preserve
  keep if isdonor==0 & !mi(tx_id)
  keep idx tx_id
  ren tx_id idx2
  ren idx   tx_id
  merge 1:1 tx_id using `don_tx'
  assert _merge==3
  assert idx==idx2
restore

****************
* Merge duplicate donors who share the same famid
**************

keep if isdonor==1
* Now, we deal with "within family duplicates" (wfd), that is, duplicates who are in the same family.
* These will all be dons, since we have already eliminated duplicate recs.
*duplicates tag dup_id famidx, gen(numwfds)
egen num_wfds = total(!mi(idx)), by(dup_id famidx)
tab  num_wfds

* Put donors with no within-famidx duplicate (wfd) aside for the moment.
preserve
  drop if num_wfds>1
  drop    num_wfds
  tempfile  dons_no_wfds
  save     `dons_no_wfds'
  tab isdonor
  count
restore
keep if num_wfds>1

* At this point, all that remains is wfds.
egen num_tx    = total(!mi(tx_id)),      by(dup_id)
egen minldate  = min(listingdate_stata), by(dup_id)
bysort dup_id: replace listingdate_stata = minldate
drop minldate
tab    num_tx
assert num_tx<=1

* This is where we tag duplicates to be dropped.  If there is a tx, we keep that one, if not, we 
* keep the one whose listing date is oldest (the _n!=1 bit does this)
* Note that it is fine to just drop the duplicates, as we necessarily keep the one that is 
* transplanted, and recs have no pointers to donors besides the tx_id.
bysort dup_id: gen tagged = 1 if (mi(tx_id) & num_tx>0) | (num_tx==0 & _n!=1)
preserve
  keep if tagged==1
  tempfile  dons_dropped_wfds
  save     `dons_dropped_wfds'
restore
drop if tagged==1
replace dup_comment="Within famidx duplicate dons merged into this record"

* Drop vars that are extraneous moving forward
drop num_wfds num_tx tagged

* Now, there are no wfds.  We add them back to the original file we set aside.
append using `dons_no_wfds'
save         `dons_no_wfds', replace

* There should be no wfds left!  Assert this.
duplicates report dup_id famidx
assert r(N)==r(unique_value)

* There should be no rec that doesn't match to a non-alt don or vice-versa.
preserve
  merge m:1 famidx using `recs'
  tab _merge alt, missing
  assert (_merge==1 & alt==1) | (_merge==3 & mi(alt))
restore
* The donor's tx_id should have a tx_id that is the original donor. Basically, tx_id should be 
* idempotent. 
preserve
  keep if !mi(tx_id)
  ren idx   idx_don
  ren tx_id idx
  merge 1:1 idx using `recs'
  ren idx idx_rec
  assert tx_id==idx_don
restore

********
* Identify cross-family duplicates and id them as bridge or non-bridge
********

* First we compute the number of duplicates
drop num_dups
egen num_dups = total(!mi(idx)), by(dup_id)
tab  num_dups
tab  num_dups alt, missing

* Set aside donors who have no duplicates
preserve
  keep if num_dups==1
  tempfile  dons_no_wfds_loners
  save     `dons_no_wfds_loners'
  count
restore
drop if num_dups==1
assert  num_dups==2

* Compute how many alts are in each dup family
egen    num_alts = total(alt==1), by(dup_id)
* Either 0 or 1 alt.  0 alt is a standard duplication, 1 is a bridge duplication.
assert num_alts<=1
preserve
  drop if num_alts==1
  tempfile  dons_no_wfds_non_bridge
  save     `dons_no_wfds_non_bridge'
restore
keep if num_alts==1
tempfile  dons_no_wfds_bridge
save     `dons_no_wfds_bridge'

****
* Merge non-bridge cross famid duplicates.
***

* These seem to be the same don offering to donate for two different recs.  We will treat them as a 
* different donor for each rec, but this shouldn't matter much, since there aren't many of them and 
* only one transplant results.
use `dons_no_wfds_non_bridge', clear
count
sort dup_id
l dup_id center_star age idx famid tx_id listingdate_stata alt num_dups
egen num_tx = total(!mi(idx)), by(dup_id)
replace dup_id = `max_dup_id' + _n
sum dup_id
local max_dup_id = r(max)
replace num_dups = 1
*replace manual_mark = _n
replace manual_mark = runiform()
replace dup_comment = "Non-bridge cross-famidx duplicate (dons acting as donors for different recs?)"
append using `dons_no_wfds_loners'
save         `dons_no_wfds_loners', replace

********
* Merge bridge cross-family duplicates
********

* Ultimately, we want to keep the dates from the record with the earliest listingdate, make the 
* record a non-alt, and preserve any tx_id or famid info.
use `dons_no_wfds_bridge', clear
count if !mi(tx_id)
local num_tx_tot = r(N)

egen num_tx     = total(!mi(tx_id)),      by(dup_id)
egen minldate   = min(listingdate_stata), by(dup_id)
assert num_tx<=1

* famid and tx_id info are always on just one record in the dup family.  Copy that info to the other 
* member of the dup family.
gen keeper=0
bysort dup_id:          replace keeper=1   if (num_tx==1 & !mi(tx_id)) | (num_tx==0 & _n==1)
bysort dup_id (tx_id):  replace tx_id            = tx_id[2]            if _n==1
bysort dup_id (tx_id):  replace transplanted     = transplanted[2]     if _n==1
bysort dup_id (tx_id):  replace transplanteddate = transplanteddate[2] if _n==1
bysort dup_id (famidx): replace famidx           = famidx[2]           if _n==1
replace alt=.
count if !mi(tx_id)
assert 2*`num_tx_tot'==r(N)

* Now, make sure both records have the dates from the record with the earlier listingdate
gen tofix = listingdate_stata!=minldate
bysort dup_id (listingdate_stata): replace arr_date_max = arr_date_max[_n-1] if tofix==1
bysort dup_id (listingdate_stata): replace arr_date_min = arr_date_max[_n-1] if tofix==1
bysort dup_id (listingdate_stata): replace dep_date_max = arr_date_max[_n-1] if tofix==1
bysort dup_id (listingdate_stata): replace dep_date_min = arr_date_max[_n-1] if tofix==1
bysort dup_id (listingdate_stata): replace listingdate  =  listingdate[_n-1] if tofix==1
                                   replace listingdate_stata = minldate
* Just keep the non-alt
keep if keeper==1
replace dup_comment = "Bridge duplication merged into this record."
count if !mi(tx_id)
count

* Now that the bridge donor duplication is fixed, put these guys with the loner dons.
append using `dons_no_wfds_loners'
save         `dons_no_wfds_loners', replace

* Now, all duplicates should be gone.
use          `recs', clear
append using `dons_no_wfds_loners'
duplicates report isdonor sex bloodtype a1 a2 b1 b2 dr1 dr2 manual_mark
duplicates report dup_id manual_mark
duplicates report isdonor sex bloodtype a1 a2 b1 b2 dr1 dr2
table dup_comment

***
* At this point, we have the original data file with all duplicates purged.  
* Ensure that the data makes sense.
***

* Make sure all recs match to a don and all non-alt dons match to a rec
preserve
  keep if isdonor==1
  save     `dons_temp', replace
restore
preserve
  drop if isdonor==1
  save     `recs_temp', replace
  merge 1:m famidx using `dons_temp'
  tab alt _merge, missing
  assert (_merge==2 & alt==1) | (_merge==3 & mi(alt))
restore

* Ensure all transplants are two-sided
preserve
  tempfile don_tx
  keep if isdonor==1 & !mi(tx_id)
  keep idx tx_id
  save `don_tx'
restore
preserve
  keep if isdonor==0 & !mi(tx_id)
  keep idx tx_id
  ren tx_id idx2
  ren idx   tx_id
  merge 1:1 tx_id using `don_tx'
  assert _merge==3
  count
  assert idx==idx2
restore

*****
* Now, we try to excise any records with bad date data, without removing any transplants.
*****

gen      bad_date = listingdate_stata == date("01/01/3000","MDY")
egen num_bad_date = total(bad_date==1), by(famidx)
egen     fam_size = total(!mi(idx)),    by(famidx)
drop       num_tx
egen       num_tx = total(!mi(tx_id)),  by(famidx)

* All families with any bad dates and no transplants are dropped
drop  if num_bad_date>=1 & num_tx==0

* Demonstrate that all bad_date altruists aren't transplanted and then drop them
assert !(alt==1 & bad_date==1 & !mi(tx_id))
drop  if alt==1 & bad_date==1

* Recompute famid-level stats and display that we have removed all bad dates
drop num_bad_date fam_size num_tx
egen num_bad_date = total(bad_date==1), by(famidx)
egen     fam_size = total(!mi(idx)),    by(famidx)
egen       num_tx = total(!mi(tx_id)),  by(famidx)
tab  num_bad_date fam_size
assert num_bad_date==0
drop fam_size num_tx

* Remove untransplanted alts
drop if mi(transplanted) & alt==1

****
* Output the final data file.
****

drop index
gen famid_str = substr(famidx, 2, .)
destring famid_str, gen(index)
drop famid_str
replace index=id if alt==1

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


export delimited $apd_file_sans_MP_cPRA, replace

l idx transplanted center_star if alt==1


