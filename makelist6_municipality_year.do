//
// This script makes a list with one line per municipality-year with the top three hospitals,
// number of births per hospital and total for the municipality. 
// Some filtering is done based on number of births and distances to remove extraneous cases
// The list also contains IVs, expected volume of hospital, and expected travel distance and time, which is constant per hospital-year
//

use "../Grunnlagsdata/analysefil_regforsk", clear

gen kommnr = substr(grunnkrets,1,4)
gen gkrets = substr(grunnkrets,5,8)

// Drop home births
drop if hovedinstnr == 10001

// Make list of number of births per hospital, from each municipality, per year (gjennomsnitt over tre år)
collapse (count) N_inst_aar=versjon_record, by(kommnr faar hovedinstnr)
sort kommnr hovedinstnr faar
by kommnr hovedinstnr: gen N_inst     = (N_inst_aar[_n-1] + N_inst_aar[_n+1])/2
by kommnr hovedinstnr: replace N_inst = (N_inst_aar[_n+1]) if _n==1
by kommnr hovedinstnr: replace N_inst = (N_inst_aar[_n-1]) if _n==_N
drop N_inst_aar

merge m:1 hovedinstnr using "liste_MFR_institusjoner"
keep if _merge==3
drop _merge

merge m:1 kommnr using "liste_kommuner_m_koordinat"
drop if _merge == 1 // NB: En fødsel i Hønefoss kommune, som ble avviklet for lenge siden!
drop _merge

// Straight line distance between hospital and municipality
gen dist = sqrt((utme_kommunesenter-utme_inst)^2+(utmn_kommunesenter-utmn_inst)^2)/1000
drop utm* lat* lon* 

// Rank hospitals according to distance and number of births
sort faar kommnr dist 
by faar kommnr: gen rank_dist = _n
gsort faar kommnr -N_inst 
by faar kommnr: gen rank_ant = _n

// Ratio of births at different hospitals
egen N_komm = sum(N_inst), by(kommnr faar)
gen ratio = N_inst/N_komm

// Addtional distance to secondary hospitals
gsort faar kommnr -N_inst 
by faar kommnr: gen add_dist = dist - dist[1]

drop befolkning areal
save "temp_kommune_sykehusbruk_full", replace





// May run different combinations to test sensitivity
foreach max_rank of numlist 3{
	foreach ratio of numlist .1{
		use "temp_kommune_sykehusbruk_full", clear
		// Rule for eliminating extraneous births:
		drop if rank_ant>`max_rank' // Select 3 hospitals per municipality
		drop if ratio<`ratio' // Remove if less than 10% of births from that municiaplity is at that hospital

		drop rank* N_komm add_dist sykehus dist ratio

		// Recompute ratio of births at different hospitals and rank
		gsort faar kommnr -N_inst 
		egen N_komm = sum(N_inst), by(kommnr faar)
		gen ratio = N_inst/N_komm
		by faar kommnr: gen rank = _n

		// Add data on hospital characteristics to make exposure variable (IV)
		merge m:1 hovedinstnr faar using "liste_MFR_hovedinstnr_fodsler_per_aar"
		keep if _merge==3
		drop _merge

		// Reshape to one line per municipality-year
		reshape wide hovedinstnr N_inst N_hosp ratio nivaa, i(faar kommnr) j(rank)
		
		
		capture replace N_inst2 = 0 if N_inst2 == . 
		capture replace N_inst3 = 0 if N_inst3 == . 
		capture replace N_hosp2 = 0 if N_hosp2 == . 
		capture replace N_hosp3 = 0 if N_hosp3 == . 
		capture replace ratio2  = 0 if N_hosp2 == 0 
		capture replace ratio3  = 0 if N_hosp3 == 0 

		gen IV_kommunepar_per1000             = N_hosp1*ratio1/1000
		capture replace IV_kommunepar_per1000 = IV_kommunepar_per1000 + N_hosp2*ratio2/1000
		capture replace IV_kommunepar_per1000 = IV_kommunepar_per1000 + N_hosp3*ratio3/1000
		

		local rr = `ratio'*100
		save "liste_kommune_og_institusjoner_rank`max_rank'_ratio`rr'", replace

	}
}





