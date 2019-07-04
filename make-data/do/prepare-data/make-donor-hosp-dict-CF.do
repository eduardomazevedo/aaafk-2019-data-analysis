set more off
clear all
adopath + ./do
timer on 1

* Build up a list of all donor hospitals used by living donors and a list of all 
* transplant centers used by living donors.  Normalize the text and match zipcodes to 
* states and counties

do ./do/globals/load-globals.do

* First, we get a list of all living donor oriented transplants, as these are the ones 
* where we will care about matching the donor_hospital.
use $star_file
keep if don_ty=="L"
replace donor_hospital_zip = substr(donor_hospital_zip,1,5) if length(donor_hospital_zip)>5
replace         tx_ctr_zip = substr(        tx_ctr_zip,1,5) if length(        tx_ctr_zip)>5
ren     donor_hospital_zip hosp_zip
destring   hosp_zip, replace
destring tx_ctr_zip, replace

ren hosp_zip zip
merge m:1 zip using $zip_to_state, keep(match master) keepusing(state county) nogen
replace county = subinstr(county, " County","",1)
replace county = subinstr(county, " Parish","",1)
replace county =    lower(county)
ren state  hosp_state
ren county hosp_county
ren zip    hosp_zip

ren tx_ctr_zip zip
merge m:1 zip using $zip_to_state, keep(match master) keepusing(state county) nogen
replace county = subinstr(county, " County","",1)
replace county = subinstr(county, " Parish","",1)
replace county =    lower(county)
ren state  tx_ctr_state
ren county tx_ctr_county
ren zip    tx_ctr_zip
* Walter Reed is in Bethesda, but UNOS lists them as in DC for historical reasons
replace tx_ctr_state = "DC" if regexm(lower(tx_ctr), "walter reed")

tempfile liv_don_data
save    `liv_don_data'

* Now, we build a list of the donor hospitals that we will need to match.
drop if mi(donor_hospital)
keep       donor_hospital  hosp_zip hosp_county hosp_state
duplicates drop
gen ccn_code  = substr(donor_hospital,1, 6)
gen hosp_type = substr(donor_hospital,10,3)
gen hosp_name = lower(substr(donor_hospital,14,.))
normalize_names hosp_name
duplicates list   hosp_name
* Try to make hosp_name a unique identifier.
* Some hospitals have multiple ccn codes (I think they get a new one if they shut down and re-open)
replace hosp_name = "driscoll childrens hospital old code"   if ccn_code=="452380"
replace hosp_name = "north austin medical center old code"   if ccn_code=="452364"
replace hosp_name = "hahnemann university hospital old code" if ccn_code=="390051"
* Trying to keep the three university medical centers separate.
replace hosp_name = "university medical center az"           if ccn_code=="030064"
replace hosp_name = "university medical center la"           if ccn_code=="190006"
replace hosp_name = "university medical center tx"           if ccn_code=="450686"
duplicates list   hosp_name
count
noisily di "Number of donor hospitals attached to living donors: `r(N)'"
local num_don_hosp = r(N)
tempfile hospital_list
save    `hospital_list'
tempfile all_hospitals
save    `all_hospitals'

* And finally we build a list of transplant centers that are attached to living donors.
use `liv_don_data'
drop if mi(tx_ctr)
keep       tx_ctr tx_ctr_zip tx_ctr_county tx_ctr_state
duplicates drop
gen unos_code   = substr(tx_ctr,1, 8)
gen tx_ctr_type = substr(tx_ctr,6, 3)
gen tx_ctr_name = lower(substr(tx_ctr,10,.))
normalize_names tx_ctr_name
duplicates list   tx_ctr_name
* Change tx_ctr names when they are they same, but it is clear they represent different 
* tx_ctrs (ie state is different)
replace tx_ctr_name = "university medical center la" if tx_ctr_name=="university medical center" & unos_code=="LAMC-TX1"
replace tx_ctr_name = "university medical center tx" if tx_ctr_name=="university medical center" & unos_code=="TXLG-TX1"
replace tx_ctr_name = "university hospital tx"       if tx_ctr_name=="university hospital"       & unos_code=="TXBC-TX1"
replace tx_ctr_name = "university hospital nm"       if tx_ctr_name=="university hospital"       & unos_code=="NMAQ-TX1"

duplicates list tx_ctr_name
count
noisily di "Number of transplant centers attached to living donors: `r(N)'"
tempfile tx_ctr_list
save    `tx_ctr_list'

* In all that follows, we will only consider potential matches where the tx_ctr state is the same as the 
* donor_hospital state.

*** FIRST PASS: 
*** Look for matches based on the longest common substring between the tx_ctr name and donor hospital name

ren    tx_ctr_state   hosp_state
joinby                hosp_state using `hospital_list'
gen    tx_ctr_state = hosp_state

* Remove spurious matches
*                         hosp_name                                          tx_ctr_name
local spurious  = `" "sutter medical center sacramento"                  "uc davis medical center"        "' ///
                + `" "mayo clinic jacksonville"                          "shands jacksonville"            "' ///
                + `" "childrens memorial hospital chicago"               "northwestern memorial hospital" "' ///
                + `" "lankenau medical center"                           "albert einstein medical center" "' ///
                + `" "veterans administration medical center nashville"  "centennial medical center"      "' ///
                + `" "lankenau medical center"                           "crozer chester medical center"  "'
tokenize `"`spurious'"'
local numspur : list sizeof spurious
assert mod(`numspur',2)==0
forvalues pairnum=1/`=`numspur'/2' {
    local hosp   = "``=`pairnum'*2-1''"
    local tx_ctr = "``=`pairnum'*2''"
    drop if (hosp_name=="`hosp'") & (tx_ctr_name=="`tx_ctr'")
}

* Compute the longest common substring of tx_ctr_name and hops_name.  Longer suggests a genuine match.
quietly lcs hosp_name tx_ctr_name, gen(lcs) noisily
gen     lcs_len = length(lcs)

*Keep only the "best" match by the metric of lcs length
egen    max_ll = max(lcs_len), by(hosp_name)
keep if max_ll ==    lcs_len
drop    max_ll

* A short lcs suggests a spurious match
tab lcs if lcs_len<=10
drop    if lcs_len<=10

* For those with multiple matches, break ties with zip code differences
gen zip_diff = abs(hosp_zip-tx_ctr_zip)

egen    min_zd =  min(zip_diff), by(hosp_name)
keep if min_zd ==     zip_diff
drop    min_zd

* Use zip_diff to rule out spurious matches
drop if zip_diff>100

* Insist that the donor_hospital matches to a unique tx_ctr.
duplicates tag    hosp_name, gen(numdups)
drop if numdups>0
drop    numdups

* Save the matches from the first pass
keep ccn_code unos_code
tempfile best_matches
save  `best_matches'
count

* Clear matched donor_hospitals from the list of hospitals
use `hospital_list', clear
merge 1:1 ccn_code using `best_matches'
keep if _merge==1
drop _merge unos_code
save `hospital_list', replace

*** SECOND PASS:
*** Look for matches with by the Levenshtein edit distance, that is, the minimum number of 
*** deletions, insertions and substitutions needed to convert one string into the other.
use `tx_ctr_list', clear
ren tx_ctr_state   hosp_state
joinby             hosp_state using `hospital_list'
gen tx_ctr_state = hosp_state

*                        hosp_name                                          tx_ctr_name
local spurious     =                                                                   ///
   `"`spurious'"'  + `" "uab hospital uab highlands"                 "childrens of alabama"                   "' ///
                   + `" "arua uams university hospital of arkansas"  "arkansas childrens hospital"            "' ///
                   + `" "childrens hospital colorado"                "centura porter adventist hospital"      "' ///
                   + `" "childrens hospital colorado"                "presbyterian saint luke medical center" "' ///
                   + `" "university of colorado hospital"            "centura porter adventist hospital"      "' ///
                   + `" "university of colorado hospital"            "presbyterian saint luke medical center" "' ///
                   + `" "georgia regents health system"              "georgia health sciences medical center" "' ///
                   + `" "childrens memorial hospital chicago"        "rush university medical center"         "' ///
                   + `" "nhlo norton hospital"                       "jewish hospital"                        "' ///
                   + `" "mayo clinic hospital rochester"             "saint marys hospital mayo clinic"       "' ///
                   + `" "ummc fairview university"                   "abbott northwestern hospital"           "' ///
                   + `" "ummc fairview university"                   "hennepin county medical center"         "' ///
                   + `" "mount sinai roosevelt"                      "mount sinai medical center"             "' ///
                   + `" "nyu langone medical center"                 "mount sinai medical center"             "' ///
                   + `" "upmc health system presbyterian"            "allegheny general hospital"             "' ///
                   + `" "upmc health system presbyterian"            "va pittsburgh healthcare system"        "' ///
                   + `" "clements university hospital"               "medical city dallas hospital"           "' ///
                   + `" "clements university hospital"               "baylor university medical center"       "' 
tokenize `"`spurious'"'
local numspur : list sizeof spurious
assert mod(`numspur',2)==0
forvalues pairnum=1/`=`numspur'/2' {
    local hosp   = "``=`pairnum'*2-1''"
    local tx_ctr = "``=`pairnum'*2''"
    drop if (hosp_name=="`hosp'") & (tx_ctr_name=="`tx_ctr'")
}

gen     zip_diff = abs(hosp_zip-tx_ctr_zip)
drop if zip_diff>=100

* Compute the Levenshtein distance
ssc install strdist
strdist hosp_name tx_ctr_name, gen(edit_dist)

* Keep only each hospital's best Levenshtein match
egen    min_ed = min(edit_dist), by(hosp_name)
keep if min_ed ==    edit_dist
duplicates tag    hosp_name, gen(numdups)
drop if numdups>0
drop    numdups

* Append the matches from the second pass
keep ccn_code unos_code
append using `best_matches'
save         `best_matches', replace
count

* Clear matched donor_hospitals from the list of hospitals
use `hospital_list', clear
merge 1:1 ccn_code using `best_matches'
keep if _merge==1
drop _merge unos_code
save `hospital_list', replace

*** THIRD PASS: Manual matching
use `tx_ctr_list', clear
ren tx_ctr_state   hosp_state
joinby             hosp_state using `hospital_list'
gen tx_ctr_state = hosp_state

gen zip_diff=abs(tx_ctr_zip-hosp_zip)

drop if hosp_name=="childrens hospital colorado"         & tx_ctr_name!="childrens hospital colorado"
drop if hosp_name=="university of colorado hospital"     & tx_ctr_name!="university of colorado hospital hsc"
drop if hosp_name=="walter reed army medical center"     & tx_ctr_name!="walter reed national military"
drop if hosp_name=="georgia regents health system"       & tx_ctr_name!="georgia health sciences medical center"
drop if hosp_name=="childrens memorial hospital chicago" & tx_ctr_name!="ann and robert h lurie childrens hospital"
drop if hosp_name=="upmc health system presbyterian"     & tx_ctr_name!="hospital of university of pa"
drop if hosp_name=="clements university hospital"        & tx_ctr_name!="ut southwestern medical center"

* Append the matches from the second pass
keep ccn_code unos_code
append using `best_matches'
save         `best_matches', replace

* Assert that all hospitals are matched
count
assert `r(N)'== `num_don_hosp'
assert !mi(unos_code, ccn_code)
duplicates report ccn_code
assert `r(unique_value)'==`r(N)'
 
merge 1:1 ccn_code using `all_hospitals'
drop _merge
merge m:1 unos_code using `tx_ctr_list'
keep if _merge==3
keep donor_hospital tx_ctr unos_code
ren tx_ctr    tx_ctr_don 
ren unos_code tx_ctr_id_don
replace tx_ctr_id_don = substr(tx_ctr_id_don,1,7)

save $don_hosp_dic_CF, replace

timer off  1
timer list 1

/*use `all_hospitals'
* donor_hospital hosp_zip hosp_state hosp_county ccn_code hosp_type hosp_name
* donor_hospital tx_ctr_id_don tx_ctr_don
merge 1:1 donor_hospital using $don_hosp_dic_EA
keep if _merge==3
drop _merge
merge 1:1 ccn_code       using $don_hosp_dic_CF
replace unos_code=substr(unos_code,1,7)
count if unos_code==tx_ctr_id_don
*/

