* Initialize
set more off
clear

adopath + "./do"

* Filenames are kept as globals in one do file
quietly do ./do/globals/load-globals.do

** Create a long format compatility matrix file
*insheet using $compat_matrix, delimit(" ")
import delimited $compat_matrix, delimit(" ")
* Last index happens to be missing all the time
* Rows are recipient indices
gen r_index = _n
reshape long v, i(r_index)
rename _j d_index
rename v compatible
save $compat_matrix_dta, replace 

/*
** Create a long format hard-block file
* blockFileReal is Itai's file -- need to substitute this with python script
clear
*insheet using $block_file_real
import delimited $block_file_real
* Format v1: recipient id, v2: number of blocks, v3 -- blocked donor id
drop v2
rename v1 rid
reshape long v, i(rid)
drop _j
* Output rows comprise each donor and recipient
drop if v==.
rename v did
* Drop duplicates
duplicates drop
isid rid did
tempfile  blockFileReal
save     `blockFileReal', replace
*/

//global initial_hard_block_file = "./intermediate-data/sim/initial-hard-blocks.txt"
clear
* insheet using $initial_hard_block_file
import delimited $initial_hard_block_file, delimit(" ")
gen r_index = _n
reshape long v, i(r_index)
rename _j d_index
rename v hard_block
tempfile initial_hard_block
save `initial_hard_block', replace
  
*** Pull data from the NKR
* Donor File
clear
*insheet using ./intermediate-data/NKRHistoricalDataAll.csv
import delimited $nkr_file_csv
keep id isdonor index arr_date* dep_date* famid center age cpra bloodtype weight height
keep if isdonor == 1
drop isdonor

* Rename Variables
rename id did
rename index d_index
rename famid d_famid
rename center d_center
rename age d_age
rename bloodtype d_bloodtype
rename weight d_weight
rename height d_height
rename arr_date_min d_arr_date_min
rename arr_date_max d_arr_date_max
rename dep_date_min d_dep_date_min
rename dep_date_max d_dep_date_max

* Generate an index for merging purposes
gen merge_index = _n

* Count the number of donors
count
local  donor_count `r(N)'
di    `donor_count'

tempfile  d_file
save     `d_file', replace

* Recipient File
clear
*insheet using ./intermediate-data/NKRHistoricalDataAll.csv
import delimited $nkr_file_csv
keep id isdonor index arr_date* dep_date* famid center age cpra bloodtype weight height unpaired
keep if isdonor == 0
drop isdonor

* Rename variables
rename id rid
rename index r_index
rename famid r_famid
rename center r_center
rename age r_age
rename weight r_weight
rename height r_height
rename cpra r_cpra
rename bloodtype r_bloodtype
rename unpaired r_unpaired
rename arr_date_min r_arr_date_min
rename arr_date_max r_arr_date_max
rename dep_date_min r_dep_date_min
rename dep_date_max r_dep_date_max

* Duplicate the rows and generate a merge index, one for each donor
expand `donor_count'
bysort rid: gen merge_index = _n
tempfile  r_file
save     `r_file', replace


* Merge datasets
use `d_file', clear
merge 1:m merge_index using `r_file', assert(match) nogenerate
drop merge_index

* Pull in blood/tissue compatibility information
merge m:1 r_index d_index using $compat_matrix_dta,  nogenerate keep(match)
*assert(match using)

* Pull in information on hard blocks
* merge 1:1 rid did using `blockFileReal'
* gen hard_block = _merge == 3
* drop if _merge == 2
* drop    _merge 
merge m:1 r_index d_index using `initial_hard_block', assert(match using) nogenerate keep(match)

** Generate an esample
gen esample = 1

** Drop if the donor is related to the recipient
replace esample = 0 if r_famid == d_famid & r_famid~=.
    
** Do not include pre 4/1/2012 departures in estimateion sample 
replace esample = 0 if date(r_dep_date_max,"MDY")<date("04/01/2012","MDY")
replace esample = 0 if date(d_dep_date_max,"MDY")<date("04/01/2012","MDY")

** Drop if donor and recipient were not overlapping in the pool (this is the most conservative version)
gen overlap = (min(date(r_dep_date_max,"MDY"),date(d_dep_date_max,"MDY")) - max(date(r_arr_date_min,"MDY"),date(d_arr_date_min,"MDY")))>=0

**
replace esample = 0 if overlap == 0

** Drop if not compatibile
replace esample = 0 if compatible == 0

*** Hard Blocks
gen rz_weight = r_weight == 0 | r_weight == .
replace r_weight = 0 if r_weight ==.

gen rz_height = r_height == 0 | r_height == .
replace r_height = 0 if r_height ==.


gen rz_age = 1 if r_age==.
replace r_age = 0 if r_age==.

* Regression model we picked
reg   hard_block r_cpra d_age r_age *height *weight r_unpaired if esample == 1, cluster(rid)
logit hard_block r_cpra d_age r_age *height *weight r_unpaired if esample == 1
predict p_hard_block

* Take the minimum hard-block probability for recipients with multiple donors
collapse (min) p_hard_block, by(r_index d_index)

* Temporary File
tempfile p_hard_block
save `p_hard_block', replace

**** Output a Matrix with p_hard_block

* Generate a dataset with n_index x n_index rows
local n_index = 2925
clear
set obs `n_index'
gen r_index = _n
expand `n_index'
bysort r_index: gen d_index = _n

* Merge with hard-block matrix
merge 1:1 r_index d_index using `p_hard_block', assert(match master) nogenerate
replace p_hard_block = 0 if p_hard_block == .
reshape wide p_hard_block, i(r_index) j(d_index)

* Output the file
export delimited p_hard_block* using $p_hard_block, delimit("|") replace novarnames
