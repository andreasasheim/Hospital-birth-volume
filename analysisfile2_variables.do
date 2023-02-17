//
// Make analysis file
//


keep lopenr* hovedinstnr faar mors_alder_kat_k8 fars_alder_kat_k11 svlen_* paritet_5 dodkat art preekl fodested_kat ksnitt* induksjon* fstart robson_10 kjonn vekt apgar* kommnr gkrets medu* pedu* IV* N_hosp* N_komm hovedinstnr* distanse* reisetid*  komplikasjoner episiotomi flerfodsel befolkning areal tang vakuum

local destringes lopenr* mors_alder_kat_k8 fars_alder_kat_k11 svlen_* paritet_5 dodkat art preekl fodested_kat ksnitt* induksjon* fstart robson_10 kjonn vekt apgar* medu* pedu* IV* N_hosp distanse* reisetid* episiotomi flerfodsel tang vakuum
foreach var of varlist `destringes'{
	destring `var', replace
}



// Ta ut svangerskapslengde missing, eller under uke 23, vekt < 300g
drop if vekt<500 //(1,098 observations deleted)

gen svlen = svlen_ul_dg/7
replace svlen = svlen_sm_dg/7 if svlen==.
replace svlen = svlen_art_dg/7 if svlen==.
drop if svlen<22 // (166 observations deleted)
drop if svlen==. & ( vekt<2000 | vekt ==.) // (292 observations deleted)


//
// Outcomes 
//
// Death

gen outcome_b_perinataldeath = 0
replace outcome_b_perinataldeath = 1 if inlist(dodkat,1,2,7,8,9)

gen outcome_b_perinataldeath_preterm = outcome_b_perinataldeath
replace outcome_b_perinataldeath_preterm = 0 if svlen>37
replace outcome_b_perinataldeath_preterm = . if svlen==.

gen outcome_b_infantmort = 0
replace outcome_b_infantmort = 1 if dodkat>0 & dodkat<4
replace outcome_b_infantmort = 1 if outcome_b_perinataldeath == 1
gen outcome_b_stillborn = 0
replace outcome_b_stillborn = 1 if inlist(dodkat,7,8,9)

gen outcome_b_preterm = 0
replace outcome_b_preterm = 1 if svlen<38
replace outcome_b_preterm = . if svlen==.

gen outcome_b_postterm = 0
replace outcome_b_postterm = 1 if svlen>42
replace outcome_b_postterm = . if outcome_b_stillborn==1

// Apgar
*gen outcome_b_apgar1_under8 = apgar1<8
*gen outcome_b_apgar1_under7 = apgar1<7
*replace outcome_b_apgar1_under7 = 0 if apgar1==.
gen outcome_b_apgar5_under7 = apgar5<7
replace outcome_b_apgar5_under7 = . if apgar5==.
replace outcome_b_apgar5_under7 = . if apgar5==.

gen outcome_b_apgar1_under4 = apgar1<4
replace outcome_b_apgar1_under4 = 0 if apgar1==.

gen outcome_b_apgar5_under7_sens = outcome_b_apgar5_under7
replace outcome_b_apgar5_under7_sens = . if outcome_b_stillborn

// Birth outside institution
gen outcome_b_utenfor_inst     =  inlist(fodested_kat,7,8,9)  // "hjemme, ikke planlagt", "under transport" eller "utenfor inst. uspesifisert"
replace outcome_b_utenfor_inst = . if fodested_kat==10
// C-section
gen outcome_b_ksnitt       = ksnitt != .
gen outcome_b_ksnitt_akutt = ksnitt == 2
*gen outcome_b_ksnitt_ikkeakutt = outcome_b_ksnitt & (!outcome_b_ksnitt_akutt)

gen outcome_b_tangvakuum = 0
replace outcome_b_tangvakuum = 1 if tang !=.
replace outcome_b_tangvakuum = 1 if vakuum !=. 

*gen outcome_b_indusert     = fstart == 2
*replace outcome_b_indusert = 0 if outcome_b_indusert==.

gen outcome_b_indusert = 0
replace outcome_b_indusert = 1 if induksjon_amniotomi==1
replace outcome_b_indusert = 1 if induksjon_oxytocin==1
replace outcome_b_indusert = 1 if induksjon_prostaglandin==1
replace outcome_b_indusert = 1 if induksjon_annet==1



// Travel time
*gen outcome_c_reisetid     = reisetid_10min
// Episiotomi
*rename episiotomi outcome_b_episiotomi
*replace outcome_b_episiotomi = 0 if outcome_b_episiotomi==.

//
// Balance tests
//
// Mother's and father's age
gen balance_mor_25minus = 0
replace balance_mor_25minus = 1 if mors_alder_kat_k8<4
gen balance_far_25minus = 0
replace balance_far_25minus = 1 if fars_alder_kat_k11<4
gen balance_mor_35plus = 0
replace balance_mor_35plus = 1 if mors_alder_kat_k8>5
gen balance_far_40plus = 0
replace balance_far_40plus = 1 if fars_alder_kat_k11>6

// Mother's and father's education at birth (higher)
*gen balance_hoyereutd_faar_mor = 0
*replace balance_hoyereutd_faar_mor = 1 if medu_birth_NUS2021 >4
*gen balance_hoyereutd_faar_far = 0
*replace balance_hoyereutd_faar_far = 1 if pedu_birth_NUS2021 >4

// Mother's and father's highest education (higher)
gen balance_hoyereutd_mor = 0
replace balance_hoyereutd_mor = 1 if medu_highest_NUS2021 >4
gen balance_hoyereutd_far = 0
replace balance_hoyereutd_far = 1 if pedu_highest_NUS2021 >4

// Fistborn or having 3 siblings
gen balance_firstborn = 0
replace balance_firstborn = 1 if paritet_5==0
gen balance_paritet3pluss = 0
replace balance_paritet3pluss = 1 if paritet_5>2

// IV-fertilization
gen balance_assistertbefruktning = 0
replace balance_assistertbefruktning = 1 if art!=.

// Flerfødsel
rename flerfodsel balance_flerfodsel
replace balance_flerfodsel=0 if balance_flerfodsel==.

// Preeklampsi
recode preekl (.=0) (1=1) (2=1) (3=1), gen(balance_preeklampsi)

//
// Adjustment variables
//
// Mother's age
recode mors_alder_kat_k8 (2=1) (8=7), ge(mors_alder_kat_k6)
tabulate mors_alder_kat_k6, ge(alderkat)
// Parity
recode paritet_5 (4=3), gen(paritet_4)
tabulate paritet_4, ge(paritetkat)
// Mother's education
recode medu_highest_NUS2021 (1=0) (2=0) (3=1) (4=1) (5=1) (6=2) (7=2) (8=2), gen(medu_3)
tabulate medu_3, ge(medukat)
// Year
tabulate faar, ge(faarkat)

//
// Misc.
//
gen N_hosp1000     = N_hosp/1000
egen kommuneaar    = group(kommnr faar)
egen kommune_int   = group(kommnr)
egen grunnkrets_id = group(kommnr gkrets)





//
//
// Definer id-variabler som skal brukes
//
//


// Add id-variables for municipality pair analyses
merge m:1 kommnr gkrets faar using "liste_grunnkrets_m_kommuneparid"
keep if _merge == 3
drop _merge


// id for within mother analyses (moving mothers only)
bysort lopenr_mor_c kommnr: gen ny_komm = _n==1
egen n_komm_mor   = sum(ny_komm), by(lopenr_mor_c)  
gen moving_mother = n_komm_mor>1 & n_komm_mor<10 // NB: missing lopenr means upper bound here
bysort lopenr_mor_c hovedinstnr_rank1: gen nytt_sykehus = _n==1
egen n_sykehus_mor   = sum(nytt_sykehus), by(lopenr_mor_c)  
gen moving_mother2 = n_sykehus_mor>1 & n_sykehus_mor<10 // NB: missing lopenr means upper bound 

gen id_innenmor     = lopenr_mor_c
replace id_innenmor = . if !moving_mother

drop ny_komm nytt_sykehus n_komm_mor n_sykehus_mor moving_mother*




gen id_alle = 1


save "analysefil_kommunepar", replace
