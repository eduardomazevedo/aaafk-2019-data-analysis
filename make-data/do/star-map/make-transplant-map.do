
* Initialize
set more off
clear

adopath + "./do"
timer clear
timer on 1

* Filenames are kept as globals in one do file
quietly do ./do/globals/load-globals.do

* Input

args a1
tokenize "`a1'", parse("=")
if ("`1'"!="clearinghouse") | !inlist("`3'","nkr","apd","unos","all_ch") {
  di as error "Argument not of form clearinghouse=nkr/apd/unos/all_ch."
  exit 111  
}
local ch     = "`3'"


//local ch_file = "${`ch'_file}"

* Output
local  match                        = "${`ch'_tx_match}"
local  ch_temp                      = "${`ch'_temp}"
local  leftovers                    = "${`ch'_leftovers}"
local  match_with_merge             = "${`ch'_tx_match_with_merge}"
local  universe_minus_exact_matches = "${`ch'_univ_minus_exact_matches}"

/*di  "Clearinghouse name   = `ch_temp'"
di  "Clearinghouse data   = `ch_file'"
di  "Match                = `match'"
di  "Leftovers            = `leftovers'"
di  "Match with merge     = `match_with_merge'"
di  "Universe minus exact = `universe_minus_exact_matches'"*/

**************************************************************************************************	
* Part 1: Get all transplants since 2008 from the STAR data and save as a tempfile  *
**************************************************************************************************

* First, we load all kidpan data and rename variables to match up better with the NKR data.
quietly do do/load-kidpan-data.do
* Then, we focus on living donor transplants from 2008 on.
keep if !mi(trr_id_code)
drop if year(tx_date)<2008
keep if don_ty=="L"
* We put the kidpan data in a file reference by a global variable so that it is passed to subsidiary 
* do file
save  $star_temp, replace

* Check to see what is missing in the data.  If too many observations have missing match variables, 
* we might be in trouble.
count
/*mvpatterns abo_coarse  abo_coarse_don  tx_ctr_id  gender     gender_don  tx_date   
mvpatterns hlaa1_don   hlaa2_don       hlab1_don  hlab2_don  hladr1_don  hladr2_don
mvpatterns hlaa1       hlaa2           hlab1      hlab2      hladr1      hladr2
mvpatterns age          age_don
mvpatterns hgt_cm_calc  hgt_cm_don_calc*/

*************************************************	
* Part 2: Load CH transplants                  *
*************************************************

* Same story as previous section, except for NKR data this time.
  
quietly do do/load-ch-transplant-data.do "clearinghouse=`ch'"
save    `ch_temp', replace
count
/*mvpatterns nkr_abo_coarse  nkr_abo_coarse_don  nkr_tx_ctr_id  nkr_gender  nkr_gender_don               ///
           nkr_a1          nkr_a2              nkr_b1         nkr_b2      nkr_dr1         nkr_dr2      ///
           nkr_a1_don      nkr_a2_don          nkr_b1_don     nkr_b2_don  nkr_dr1_don     nkr_dr2_don
                        
mvpatterns nkr_age          nkr_age_don
mvpatterns nkr_hgt_cm_calc  nkr_hgt_cm_don_calc*/

*************************************************	
* Part 3: Find exact matches                    *
*************************************************

* Delete any existing map file.
capture confirm file `match'
if (_rc==0){  // if the file already exists
  erase `match'
}

* Look for all combinations of observations that match on the tx_ctr_id.
ren    ch_tx_ctr_id ///
            tx_ctr_id
drop if mi(tx_ctr_id)

joinby     tx_ctr_id using $star_temp
gen    ch_tx_ctr_id = tx_ctr_id

quietly do do/calc-match-quality-vars.do  type=tx

* Now, we look for "perfect" matches -- those that we would accept on sight with no other evidence.
* The condition is set in the globals file.

count if ${`ch'_perf_tx_cond}
/*tab abog_matches, missing
tab abog_matches_don, missing
tab  hla_matches, missing
tab  hla_matches_don, missing
tab  age_difference, missing
tab  age_difference_don, missing
tab date_difference_tx if date_difference<=100*/

* Ensure that there isn't more than one "perfect" match per nkr_id pair
duplicates tag  ch_id*      if ${`ch'_perf_tx_cond},                   gen(num_dups_ch)

* Ensure that two nkr_id pairs don't share the same "perfect" match
duplicates tag  trr_id_code  if ${`ch'_perf_tx_cond} & num_dups_ch==0, gen(num_dups_kidpan)

* Only those in the (0,0) corner will be considered as genuine matched.  Other "matches" have the
* problems just described with the duplicates commands.
tab num_dups_kidpan num_dups_ch, missing

* Do any patched transplants involve the same patient?
duplicates report pt_code if ${`ch'_perf_tx_cond}

*
*global match_type = "transplant"
quietly do do/remove-matches-from-ch-star-temps.do    clearinghouse=`ch'    type=tx

*************************************************************************************************
* Part 4: Find other matchesby leveraging the fact that _all_ transplants should be in KIDPAN   *
*************************************************************************************************

* We start by limiting ourselves to matches where at least two hla alleles match exactly (two 
* "missing"'s does not count as a match here)

* Since all nkr transplants must be in kidpan, we will start with a loose criterion.  If only one 
* kidpan observation fits that criterion, we call it a match.  We then progressively tighten our 
* criterion.

tempfile joinby_rec
* spaces must be removed so that the entire boolean condition can be passed as an argument 
* to a do file
local trim_condition = ///
              subinstr("abs(tx_date - ch_tx_date) <= 31 & " + ///
                       "abs(age     - ch_age)     <= 10 & " + ///
                       "abs(age_don - ch_age_don) <= 10 & " + ///
                       "((abo_coarse     == ch_abo_coarse    ) | (gender     == ch_gender    )) & " + ///
                       "((abo_coarse_don == ch_abo_coarse_don) | (gender_don == ch_gender_don)) & " + ///
                       "ch_tx_date<=$star_end_date", ///
                       " ","",.)

local first_time = 1
forvalues num_matches = 2(1)5 {
    * Since we are dealing with transplants, we combine the set of potential matches where two recip 
    * loci match, and the set where two donor loci match
    quietly do do/joinby-geq-2-hla-matches.do  clearinghouse=`ch'  matchon=rec  trim=`trim_condition'
    save `joinby_rec', replace
    quietly do do/joinby-geq-2-hla-matches.do  clearinghouse=`ch'  matchon=don  trim=`trim_condition'
    append using `joinby_rec'
    duplicates drop
    * Compute the match quality variables upon which we will decide matches.
    quietly do do/calc-match-quality-vars.do  type=tx
    count

    * Save the universe of matches aside from exact matches so that we can compute distributions of 
    * the match quality variables later.
    * These will help us match:
    * 1) donors in the NKR data who are marked as never participating in a transplant in the NKR 
    *    data, but who do participate in a transplant outside of NKR (and hence are in a transplant 
    *    in the kidpan dataset).  And donors who are in an NKR transplant, but are not matched along 
    *    with their transplant partner.
    * 2) recips in the NKR data who are marked as never participating in a transplant, but are in 
    *    kidpan, either as part of a non-nkr transplant or as a waiting list entry.  Also, recipts 
    *    who are in an NKR transplant, but are not matched along with their transplant partner.

    if (`first_time' == 1){
        save `universe_minus_exact_matches', replace
        local first_time = 0
    }
    
    local condition =  "(abog_matches     >= 1 )            & " +  ///
                       "(abog_matches_don >= 1 )            & " +  ///
                       "(hla_matches_don  >= `num_matches') & " +  ///
                       "(hla_matches      >= `num_matches') & " +  ///
                       "(date_difference_tx<=31 & age_difference<=10 & age_difference_don<=10)"

    count if `condition'

    * This condition prevents the do file from prematurely ending, as running duplicates on an empty 
    * dataset throws an error.
    if (r(N)>0) {

        keep if `condition'

        duplicates tag  ch_id*  if  `condition',                   gen(num_dups_ch)
        duplicates tag   trr_id*  if  `condition'& num_dups_ch==0, gen(num_dups_kidpan)

        tab num_dups_kidpan num_dups_ch, missing

        quietly do do/remove-matches-from-ch-star-temps.do    clearinghouse=`ch'    type=tx
    }

}

***************************
* Part 5: Export results  *
***************************
* First note that the "remove-matches-from-nkr-kidpan" do file has already saved the transplant 
* matching to $nkr_to_star_map.

* Now, we generate the "left-overs" file -- the joinby's containing transplants that were not matches.  
* In case we want to think about other salvageable matches.
quietly do do/joinby-geq-2-hla-matches.do  clearinghouse=`ch'  matchon=rec  trim=`trim_condition'
save `joinby_rec', replace
quietly do do/joinby-geq-2-hla-matches.do  clearinghouse=`ch'  matchon=don  trim=`trim_condition'
append using `joinby_rec'
duplicates drop

quietly do do/calc-match-quality-vars.do  type=tx
local order  = "ch_id*          trr_id_code         tx_ctr_match                          " +  ///
               "abog_matches    hla_matches         hla_matches_don                       " +  ///
               "age_difference  age_difference_don  date_difference_tx                    " +  ///
               "gender          ch_gender           gender_don          ch_gender_don     " +  ///
               "abo_coarse      ch_abo_coarse       abo_coarse_don      ch_abo_coarse_don " +  ///
               "hlaa1           ch_a1               hlaa2               ch_a2             " +  ///
               "hlab1           ch_b1               hlab2               ch_b2             " +  ///
               "hladr1          ch_dr1              hladr2              ch_dr2            " +  ///
               "hlaa1_don       ch_a1_don           hlaa2_don           ch_a2_don         " +  ///
               "hlab1_don       ch_b1_don           hlab2_don           ch_b2_don         " +  ///
               "hladr1_don      ch_dr1_don          hladr2_don          ch_dr2_don        "
order `order'
count
save `leftovers',                 replace

* Now, we reload the full nkr and kidpan datasets (i.e. including the matches we have made thus far).  
* Once that is done, we can make a file of matches with the match quality variables merged in, so that 
* we can decide if our matches are of sufficient quality.
quietly do do/load-kidpan-data.do
keep if !mi(trr_id_code)
drop if year(tx_date)<2008
save $star_temp, replace
count

quietly do do/load-ch-transplant-data.do  "clearinghouse=`ch'"
save `ch_temp', replace
count

use  `match', clear

merge 1:1 trr_id_code  using $star_temp,   nogen keep(match)
merge 1:1 ch_id*       using `ch_temp', nogen keep(match)

quietly do do/calc-match-quality-vars.do  type=tx
order `order'
save `match_with_merge',          replace

gen age_5yr  = age_difference<=5 & age_difference_don<=5
gen date_1dy = date_difference_tx<=1
gen hla_5    = hla_matches_net>=5 & hla_matches_net_don>=5
gen abog2    = abog_matches==2 & abog_matches_don==2
//gen perfect5 = date_1dy & age_5yr & tx_ctr_match & abog2 & hla_5

keep if age_5yr==1 & date_1dy==1 & tx_ctr_match==1
keep ch_id_don ch_id_rec ch_index_rec ch_index_don pt_code wl_id_code trr_id_code

save $all_ch_tx_match_perfect,          replace


* Done!
timer off 1
timer list 1
di r(t1)/60

