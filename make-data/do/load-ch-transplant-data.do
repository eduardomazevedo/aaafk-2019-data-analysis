* Takes an argument (either nkr or apd) and loads the data from that clearinghouse into memory.

quietly do do/globals/load-globals.do

args a1
tokenize "`a1'", parse("=")
if ("`1'"!="clearinghouse") | !inlist("`3'","nkr","apd","unos","all_ch") {
  di as error "Argument not of form clearinghouse=nkr/apd/unos/all_ch."
  exit 111  
}
local ch     = "`3'"

* Get ch data file, created by the pertinent py/parse-snapshots.py script.
use $all_ch_file, clear

if inlist("`ch'","nkr","apd","unos") {
  keep if ch=="`ch'"
}

* the ch data files contain info about matched and unmatched participants.  Drop the unmatched ones.
drop if mi(tx_id)
count

* Rename variables to be more in line with KIDPAN


* Each row is a participant in the ch data files In order to make a file where each row is a 
* transplant, we will merge the ch data fie with itself.  Hence the tempfile.
tempfile  ch_file_twin
save     `ch_file_twin'

* In the ch data file, each transplant is represented by two rows: one for the donor and one for 
* the recipient.  We will keep only the donor rows and merge in the pertinent data from the previous 
* tempfile.
keep if isdonor==1
keep ch_id       tx_id         // tx_date
ren (ch_id       tx_id      ) ///
    (ch_id_don   ch_id_rec  )
*ren tx_date tx_date_don

* Count number of transplants
count
local n_tx_to_match_all = `r(N)'

* Merge in the info that is pertinent to the match for both the donor and the recipient

* Variables to get
local ch_tx_vars          = "tx_ctr_id   tx_date ch"
local ch_rec_and_don_vars = "abo_coarse  gender    age   a1-dr2  alt "

local ch_rec_and_don_vars = "`ch_rec_and_don_vars' index unpaired "


* Import recipient data from list of ch transplanted recipients and donors 
gen ch_id = ch_id_rec
merge 1:1 ch_id using `ch_file_twin', ///
                         keepusing(`ch_tx_vars' `ch_rec_and_don_vars')
keep if _merge==3
drop _merge

foreach var of varlist `ch_tx_vars' `ch_rec_and_don_vars' {
  rename  `var'  ch_`var'
}

ren ch_ch ch

* Import donor data from list of ch transplanted recipients and donors 
replace ch_id = ch_id_don
merge 1:1 	 ch_id using `ch_file_twin', ///
                    keep(matched) nogenerate       ///
                    keepusing(`ch_rec_and_don_vars')
drop ch_id

foreach var of varlist `ch_rec_and_don_vars' {
  rename  `var'  ch_`var'_don
}
ren  ch_index ch_index_rec
drop ch_unpaired_don 
drop ch_alt

count                     
