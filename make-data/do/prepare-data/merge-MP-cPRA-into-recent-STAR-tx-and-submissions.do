do ./do/globals/load-globals.do

* First load up file of PRAs and MPs produced by compute-pra-mp.py

import delimited $star_pra_mp, clear
tempfile  pras_file
save     `pras_file'

* Now load STAR-recent-tx-and-submissions data and merge in PRA and MP

use $star_file_sans_all, clear

count

merge m:1 wl_id_code using `pras_file', keep(match master) nogen

count

save $star_file, replace

