*** by Tal Rotemberg, edited by Nikhil Agarwal, re-edited by CRF
*** Edited again by edu to make it work on the server.

** Generates a "better" version of liv_don_ty

** As currently written, this document keeps known unrelated donors as 999
** (e.g. co-workers and church members) because 999 is defined as
** "Non-Biological, Other Unrelated."  
** I am reserving 10 for anonymous non-directed donors;
** if we know who the donor is, I am calling it 999.

** Fix classification

** This one requires you to be using a document
** with variable called liv_don_ty and  liv_don_ty_ostxt

**  Note that the "inlist" commands below are split up to ensure that there 
**  aren't more than 10 arguments per instance.  This is a restriction of the command (see the Stata help file).

set more off

* rec is for reclassified(!!) not recipient
gen     liv_don_ty_rec  =   liv_don_ty

*Parents:
replace liv_don_ty_rec=1 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "MOTHER",   "FATHER",   "PARENT")

*Children
replace liv_don_ty_rec=2 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "CHILD",    "SON",      "DAUGHTER")

*Identical Twins:
replace liv_don_ty_rec=3 if liv_don_ty==999 & liv_don_ty_ostxt=="IDENTICAL TWIN"

*Full Siblings
replace liv_don_ty_rec=4 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "BROTHER",  "SISTER",   "TWIN NOT IDENTICAL",   "SIBLING")

*Half-Siblings
replace liv_don_ty_rec=5 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "HALF BROTHER",         "HALF SISTER")

*Other relative--Cousins:
replace liv_don_ty_rec=6 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,   ///
    "COUSIN",   "COUZIN",   "1ST COUSIN",   "FIRST COUSIN ONCE REMOVED", ///
    "MATERNAL COUSIN",      "PATERNAL COUSIN",                           ///
    "FATHER'S COUSIN",      "CAUSION")

*Other relative--Grandparents and Grandchildren:
replace liv_don_ty_rec=6 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "GRANDPARENT",  "GRANDDAUGHTER",    "GRANDAUGHTER" )

*Spouses:
replace liv_don_ty_rec=7 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "SPOUSE",   "SPOUCE",   "HUSBAND",  "WIFE", "SPOUCE/WIFE" )

*Life Partners:
replace liv_don_ty_rec=8 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,  ///
    "PARTNER",      "DOMESTIC PARTNER", "LIFE PARTNER", "GIRLSRIEND",   ///
    "GIRLFREIND",   "GIRLFRIEND",       "GIRLFREND",    "GIRLFRIEN") |  ///
                                              inlist(liv_don_ty_ostxt,  ///
    "BOYFRIEND",    "BOYFREIND",        "COHABITATING", "SIGN OTHER",   ///
    "WIFE TO HUSBAND",                  "FIANC'E",      "HUSBAND TO BE")

*Paired donation:
replace liv_don_ty_rec=9 if liv_don_ty==999 & inlist(liv_don_ty_ostxt,   ///
    "UONS EXCHANGE#1",  "SWAP PAIRED EXCHANGE", "PAIR EXCHANGE",         ///
    "DONOR PKD PROGRAM","SWAP PAIRED EXCHANGE", "NEPKE, CHAIN",          ///
    "NEPKE EXCHANGE",   "NEPKE",                "PAIRED EXCHANGED") |    ///
                                              inlist(liv_don_ty_ostxt,   ///
    "PKE",              "REGISTRY CHAIN",       "NKR DONOR",             ///
    "NKR",              "NKR CHAIN",            "PAIRED PROGRAM",           ///
    "DONOR EXCHANGE",   "KIDNEY SWAP",          "PAIRED KIDNEY EXCHANGE") | ///
                                              inlist(liv_don_ty_ostxt,   ///
    "KIDNEY EXCHANGE",  "PAIRED DONOR EXCHANGE","PAIRED EXCHANGE",       ///
    "SWAP DONOR",       "PAIRED DONOR",         "PAIRED DONATION DONOR", ///
    "DONOR SWAP",       "3-WAY PAIRED EXCHANGE","PAIRED")   |            ///
                                              inlist(liv_don_ty_ostxt,   ///
    "BENEVOLENT SWAP",  "PDN",                  "3 WAY PAIRED EXCHANGE", ///
    "EXCHANGE",         "3 WAY SWAP",                                    ///
    "NKR CHAIN DONOR FROM NEW YORK",            "PAIRED DONATION")  |    ///
                                              inlist(liv_don_ty_ostxt,   ///
    "3 WAY EXCHANGE",   "DONOR SWAP EXCHANGE",  "SWAP, PAIRED EXCHANGE", ///
    "SPOUSE, DONOR SWAP")
    
foreach text_field in  ///
    "KPD" "NEPKE SWAP" ///
    {
	replace liv_don_ty_rec = 9 if liv_don_ty == 999 ///
			& liv_don_ty_ostxt == "`text_field"
    }
			
*Anonymous donation:
replace liv_don_ty_rec=10 if liv_don_ty==999 & inlist(liv_don_ty_ostxt, ///
    "ANONYMOUS",    "DOES NOT KNOW RECIP")

* Altruistic / good samaritan    
foreach text_field in ///
		"ANSWERED NEWSPAPER ARTICLE"   "MATCHED ON DONATION WEBSITE."     ///
		 "SAW NEWS PAPER AD"            "INTERNET WEBSITE"                ///
		 "RESPONDER TO PLEA"            "INTERNET"                        ///
		 "INTERNET DONOR"               "CHURCH BULLETIN/ NEVER MET"      ///
		 "FOUND RECIPIENT'S NAME IN CHURCH NEWSLETTER"                    ///
		 "DONORMATCH.COM"               "MATCHINGDONORS.COM WEBSITE"      ///
		 "MET THROUGH WEBSITE"          "MATCH.COM"                       ///
		 "MATCH DONORS.COM"                                               ///
		 "FOUND RECIPIENT THROUGH DONOR MATCH DOT COM"                    ///
		 "CONNECTED VIA INTERNET"       "LEARNED OF PT'S NEED VIA MSNBC"  ///
		 "FACEBOOK ACQUAINTANCE"        "DIRECTED HUMANITARIAN"           ///
		 "LOCAL NEWSPAPER STORY"        "RESPONDED THROUGH E-MAIL"        ///
		 "MET ON THE INTERNET"                                            ///
		 "BECAME AWARE OF PARTICULAR PERSON'S NEED VIA MEDIA"             ///
		 "ALTRUSTIC DONOR"              "RESPONDER"                       ///
		 "MATCHING DONOR.COM"           "MATCHINGDONORS.COM"              ///
		 "MATCHING DORORS WEBSITE"      "NEWSPAPER STORY"                 ///
		 "DONATING DUE TO POST ON FACEBOOK"                               ///
		 "ANSWERED ADVERTISEMENT"       "AD RESPONSE"                     ///
		 "WEBSITE KIDNEY CONNECTION"    "NON-DIRECTED LIVING DONOR"       ///
		 "NON-DIRECTED"                 "ALTRUIST"                        ///
		 "HUMANITARIAN"                 "ALTRUISTRIC DONOR"               ///
		 "ALTRUISITIC"                  "ALTRUISITC"                      ///
		 "ALTRUISTIC"                   "ALTRUSTIC"                       ///
		 "SAMARITAN"                    "GOOD SAMARITAN"                  ///
		 "SAMATARIN"                    "GOOOD SAMIRITAN"                 ///
		 "BENEVOLENT DONOR"             "HUMANITARIAN-DIRECTED"           ///
		 "ALTRUISTIC DONOR"             "GOOD WILL"                       ///
		 "ALTERISTIC"                   "ALTRUISITC DONOR"                ///
		 "GOOD SAMATARIN"               "ALRIUSTIC"                       ///
		 "GOOD SAMARATIN"               "ALTRUSITIC"                      ///
		 "ALTRRUISTIC"                  "GOOD SAMIRITAN"                  ///
		 "DIRECTED DONATION/ALTRUITIC"  "ALTRURTIC DONOR"                 ///
		 "NDD"                          "ALTURISTIC"                      ///
		 "GOOD SAMARATON"               "ALTURSTIC"                       ///
		 "ALTRUSTIC"                    "ULTRUISTIC DONATION"             ///
		 "ALTRISTIC"                    "NON-DIRECTED DONOR"              ///
		 "ALTURISIC"                                                      ///
	{
		replace liv_don_ty_rec=10 if liv_don_ty==999 ///
			& liv_don_ty_ostxt == "`text_field"
	}                                                      

*Living/deceased donor donation (wait list?)
replace liv_don_ty_rec=11 if liv_don_ty==999 & inlist(liv_don_ty_ostxt, ///
    "UNRELATED, UNKNOWN TO FAMILY",     "DIRECTED",                     ///
    "DIRECTED DONATION TO WAIT LIST",   "DONATE TO LIST",               ///
    "DONATION",                         "EXCHANGE TO WAIT LIST")

ren liv_don_ty_rec liv_don_ty_reclassified
**END
