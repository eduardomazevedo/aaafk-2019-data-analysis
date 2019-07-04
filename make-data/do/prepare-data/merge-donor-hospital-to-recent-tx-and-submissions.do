clear all

quietly do ./do/globals/load-globals.do

use $star_file
count
merge m:1 donor_hospital using $don_hosp_dic_CF
count
drop if _merge==2
drop    _merge
count

save $star_file_with_dh, replace

