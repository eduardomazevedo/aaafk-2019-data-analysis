do ./do/globals/load-globals.do

use $kidpan, clear

drop if mi(wl_id_code)

count

keep wl_id_code abo a1 a2 b1 b2 dr1 dr2 abo_don da1 da2 db1 db2 ddr1 ddr2

merge 1:m wl_id_code using $kidpan_unacc_ant, keepusing(locus*)

keep if _merge==3

drop _merge

duplicates drop wl_id_code locus*, force

* Remove all "1"'s and "2"'s from abo and abo_don, since these don't matter for blood type compatibility
foreach var in abo abo_don {
    replace `var' = subinstr(`var', "1", "",.)
    replace `var' = subinstr(`var', "2", "",.)
}

export delimited $star_histo_pre_union, replace


