
quietly do do/globals/load-globals.do

* Load recent transplants
    use $star_file_with_dh, clear

    replace tx_ctr_id = substr(listing_ctr,1,7) if mi(tx_ctr_id) & !mi(listing_ctr)

capture confirm var tx_ctr_don, exact
if (_rc!=0) {
    gen tx_ctr_don    = ""
    gen tx_ctr_id_don = ""
}
keep     a1  a2  b1  b2  dr1  dr2    ///
         da1 da2 db1 db2 ddr1 ddr2    ///
         ra1 ra2 rb1 rb2 rdr1 rdr2    ///
         abo          abo_don         ///
         gender       gender_don      ///
         age          age_don         ///
         tx_ctr_id    tx_date         ///
         trr_id_code  wl_id_code      ///
         end_date     pt_code         ///
         init_age     death_date      ///
         init_date    activate_date   ///
         init_hgt_cm  hgt_cm_calc     ///
         ssdmf_death_date             ///
         don_ty       donor_hospital  ///
         tx_ctr_don   tx_ctr_id_don   ///
         rem_cd

* recode_hla is an .ado file that normalizes these variables

    recode_hla da db ddr ra rb rdr a b dr

* Rename unos hla variables to make looping easier
    foreach antigen in a1 a2 b1 b2 dr1 dr2 {
      rename d`antigen' hla`antigen'_don
      rename r`antigen' hla`antigen'
    }
    gen missing_all_rec_hla = mi(hlaa1) & mi(hlaa2) & mi(hlab1) & mi(hlab2) & mi(hladr1) & mi(hladr2)
    replace hlaa1  = a1   if missing_all_rec_hla == 1
    replace hlaa2  = a2   if missing_all_rec_hla == 1
    replace hlab1  = b1   if missing_all_rec_hla == 1
    replace hlab2  = b2   if missing_all_rec_hla == 1
    replace hladr1 = dr1  if missing_all_rec_hla == 1
    replace hladr2 = dr2  if missing_all_rec_hla == 1
    drop a1 a2 b1 b2 dr1 dr2
		
* Remove all "1"'s and "2"'s from abo and abo_don, since these don't matter for blood type compatibility
    foreach var in abo abo_don {
      replace `var' = subinstr(`var', "1", "",.)
      replace `var' = subinstr(`var', "2", "",.)
    }
    rename abo 		abo_coarse
    rename abo_don 	abo_coarse_don

    sort tx_ctr_id



