* Based on the preceding dates, we construct import conditions such that we exclude rows that are 
* clearly not relevant for us, like people transplanted in the early 90s who never show up again.  
* We also try to ensure that APD and NKR can actually be matched with STAR.
global star_import_cond     = subinstr(" (init_date>=$nkr_apd_start_date & !mi(init_date)) | " + /// 
                                       " (tx_date  >=$nkr_apd_start_date & !mi(tx_date)  ) | " + ///
                                       " (end_date >=$nkr_apd_start_date & !mi(end_date) )   ",  ///
                                       " ","",.)
* STAR restrictions are all we need to keep NKR matches with STAR sensible.  Note that these globals 
* are not currently used by any do files.
global  nkr_import_cond      = subinstr("1==1"," ","",.)
global  apd_import_cond      = subinstr("  apd_tx_date<=$star_end_date | mi( apd_tx_date)"," ","",.)
global unos_import_cond      = subinstr(" unos_tx_date<=$star_end_date | mi(unos_tx_date)"," ","",.)

* These are the conditions for a "perfect" tx match.  "Perfection" varies in degree across the two 
* datasets. 
global nkr_tx_date_diff_tol = 7
global nkr_age_diff_tol     = 10
global nkr_perf_tx_cond     = subinstr("(  abog_matches     == 2 ) & " +  ///
                                       "(  abog_matches_don == 2 ) & " +  ///
                                       "(   hla_matches_don == 6 ) & " +  ///
                                       "(   hla_matches     == 6 ) & " +  ///
                                       "(date_difference_tx <= $nkr_tx_date_diff_tol & " + ///
                                       "  age_difference    <= $nkr_age_diff_tol     & " + ///
                                       "  age_difference_don<= $nkr_age_diff_tol)    ",  ///
                                       " ","",.)
global nkr_perf_rec_cond    = subinstr("(abog_matches   == 2 ) &  "  +  ///
                                       "(hla_matches    == 6 ) &  "  +  ///
                                       "(age_difference         <= 2  |  mi(age_difference) )  &  "  +  ///
                                       "(abs(init_age-nkr_age) <= 10 | !mi(age_difference) )  &  "  +  ///
                                       "(end_date       >= nkr_arr_date_min)", ///
                                       " ","",.)
global nkr_rec_trim_cond     = ///
              subinstr("( abs(nkr_age - age)      <= 10   |  mi(     age) | mi(nkr_age) ) & " + ///
                       "( abs(nkr_age - init_age) <= 10   | !mi(init_age) | mi(nkr_age) ) & " + ///
                       "(( abo_coarse == nkr_abo_coarse ) |              " + ///
                       " ( gender     == nkr_gender     ))               ", ///
                       " ","",.)
global nkr_perf_don_cond =  ///
              subinstr("(abog_matches_don   == 2 )         &  "  +  ///
                       "(hla_matches_don    == 6 )         &  "  +  ///
                       "(age_difference_don <= 2 )  &  "  +  ///
                       "(end_date       >= nkr_arr_date_min)            ", ///
                       " ","",.)
global nkr_don_trim_cond = ///
              subinstr("( abs(nkr_age_don - age_don)      <= 10   |  mi(age_don) | mi(nkr_age_don) ) & " + ///
                       "(( abo_coarse_don == nkr_abo_coarse_don ) |              " + ///
                       " ( gender_don     == nkr_gender_don     ))               ", ///
                       " ","",.)



global apd_tx_date_diff_tol = 7
global apd_age_diff_tol     = 10
global apd_perf_tx_cond     = subinstr("(  abog_matches     == 2 )  & " +  ///
                                       "(  abog_matches_don == 2 )  & " +  ///
                                       "(   hla_matches_don == 6 )  & " +  ///
                                       "(   hla_matches     == 6 )  & " +  ///
                                       "(date_difference_tx <= $apd_tx_date_diff_tol & " + ///
                                       "  age_difference    <= $apd_age_diff_tol     & " + ///
                                       "  age_difference_don<= $apd_age_diff_tol)    ",  ///
                                       " ","",.)
global apd_perf_rec_cond    = subinstr("(abog_matches   == 2 ) &  "  +  ///
                                       "(hla_matches    == 6 ) &  "  +  ///
                                       "(age_difference         <= 2  |  mi(age_difference) )  &  "  +  ///
                                       "(abs(init_age-apd_age) <= 10 | !mi(age_difference) )  &  "  +  ///
                                       "(end_date       >= apd_arr_date_min)", ///
                                       " ","",.)
global apd_rec_trim_cond     = ///
              subinstr("( abs(apd_age - age)      <= 10   |  mi(     age) | mi(apd_age) ) & " + ///
                       "( abs(apd_age - init_age) <= 10   | !mi(init_age) | mi(apd_age) ) & " + ///
                       "(( abo_coarse == apd_abo_coarse ) |              " + ///
                       " ( gender     == apd_gender     ))               ", ///
                       " ","",.)
global apd_perf_don_cond = ///
              subinstr("(abog_matches_don   == 2 )         &  "  +  ///
                       "(hla_matches_don    == 6 )         &  "  +  ///
                       "(age_difference_don <= 2 )  &  "  +  ///
                       "(end_date       >= apd_arr_date_min)            ", ///
                       " ","",.)
global apd_don_trim_cond = ///
              subinstr("( abs(apd_age_don - age_don)      <= 10   |  mi(age_don) | mi(apd_age_don) ) & " + ///
                       "(( abo_coarse_don == apd_abo_coarse_don ) |              " + ///
                       " ( gender_don     == apd_gender_don     ))               ", ///
                       " ","",.)




global unos_tx_date_diff_tol = 7
global unos_age_diff_tol     = 10
global unos_perf_tx_cond     = subinstr("(  abog_matches     == 1 )  & " +  ///
                                        "(  abog_matches_don == 1 )  & " +  ///
                                        "(   hla_matches_don == 6 )  & " +  ///
                                        "(   hla_matches     == 6 )  & " +  ///
                                        "(date_difference_tx <= $unos_tx_date_diff_tol & " + ///
                                        "  age_difference    <= $unos_age_diff_tol     & " + ///
                                        "  age_difference_don<= $unos_age_diff_tol)    ",  ///
                                        " ","",.)
global unos_perf_rec_cond    = subinstr("(abog_matches   == 1 ) &  "  +  ///
                                        "(hla_matches    == 6 ) &  "  +  ///
                                        "(age_difference         <= 2  |  mi(age_difference) )  &  "  +  ///
                                        "(abs(init_age-unos_age) <= 10 | !mi(age_difference) )  &  "  +  ///
                                        "(end_date       >= unos_arr_date_min)", ///
                                        " ","",.)
global unos_rec_trim_cond     = ///
              subinstr("( abs(unos_age - age)      <= 10   |  mi(     age) | mi(unos_age) ) & " + ///
                       "( abs(unos_age - init_age) <= 10   | !mi(init_age) | mi(unos_age) ) & " + ///
                       "( abo_coarse == unos_abo_coarse ) ", ///
                       " ","",.)
global unos_perf_don_cond = ///
              subinstr("(abog_matches_don   == 1 )         &  "  +  ///
                       "(hla_matches_don    == 6 )         &  "  +  ///
                       "(age_difference_don <= 2 )  &  "  +  ///
                       "(end_date       >= unos_arr_date_min)            ", ///
                       " ","",.)
global unos_don_trim_cond = ///
              subinstr("( abs(unos_age_don - age_don)      <= 10   |  mi(age_don) | mi(unos_age_don) ) & " + ///
                       "( abo_coarse_don == unos_abo_coarse_don ) ", ///
                       " ","",.)


global sa_tx_date_diff_tol = 7
global sa_age_diff_tol     = 10
global sa_perf_tx_cond     = subinstr("(  abog_matches     == 1 )  & " +  ///
                                      "(  abog_matches_don == 1 )  & " +  ///
                                      "(   hla_matches_don == 6 )  & " +  ///
                                      "(   hla_matches     == 6 )  & " +  ///
                                      "(date_difference_tx <= $sa_tx_date_diff_tol & " + ///
                                      "  age_difference    <= $sa_age_diff_tol     & " + ///
                                      "  age_difference_don<= $sa_age_diff_tol)    & " + ///
                                      "          sa_tx_date<= $star_end_date ", ///
                                      " ","",.)

global all_ch_tx_date_diff_tol = 7
global all_ch_age_diff_tol     = 10
global all_ch_perf_tx_cond     = subinstr(`"(((abog_matches     == 2) & (ch!="unos")) | ((abog_matches     == 1) & (ch=="unos"))) & "' +  ///
                                          `"(((abog_matches_don == 2) & (ch!="unos")) | ((abog_matches_don == 1) & (ch=="unos"))) & "' +  ///
                                          "(   hla_matches_don == 6 ) & " +  ///
                                          "(   hla_matches     == 6 ) & " +  ///
                                          "(date_difference_tx <= $all_ch_tx_date_diff_tol & " + ///
                                          "  age_difference    <= $all_ch_age_diff_tol     & " + ///
                                          "  age_difference_don<= $all_ch_age_diff_tol)    ",  ///
                                          " ","",.)

