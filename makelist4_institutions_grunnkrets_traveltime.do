// Import list of traveltimes between grunnkrets and hosptials
// Make list that can be merged with data

// List of changes in grunnkrets from 2019 to 2020
import excel "..\Grunnlagsdata\grunnkretsendringer2020.xlsx", firstrow clear
replace grunnkretsnummer2019 = substr(grunnkretsnummer2019,1,8)
replace grunnkretsnummer2020 = substr(grunnkretsnummer2020,1,8)
destring grunnkretsnummer2019, replace
destring grunnkretsnummer2020, replace
rename grunnkretsnummer2020 grunnkretsnummer
save "liste_grunnkretsendringer2020", replace

import excel "..\Grunnlagsdata\grunnkretsendringer2018.xlsx", firstrow clear
replace grunnkretsnummer2017 = substr(grunnkretsnummer2017,1,8)
replace grunnkretsnummer2018 = substr(grunnkretsnummer2018,1,8)
destring grunnkretsnummer2017, replace
destring grunnkretsnummer2018, replace
rename grunnkretsnummer2018 grunnkretsnummer
save "liste_grunnkretsendringer2018", replace



// Import traveltimes
import delimited "..\Grunnlagsdata\grunnkrets_inst_routing_full.csv", delim(",") clear

// Changes in grunnkkrets from 2019-2020 (traveltime is by 2020-grunnkrets)
merge m:1 grunnkretsnummer using "liste_grunnkretsendringer2020"
drop if _merge ==2
drop _merge
replace grunnkretsnummer = grunnkretsnummer2019 if grunnkretsnummer2019!=.

// Changes in grunnkkrets from 2018-2019 
merge m:1 grunnkretsnummer using "liste_grunnkretsendringer2018"
drop if _merge ==2
drop _merge
replace grunnkretsnummer = grunnkretsnummer2017 if grunnkretsnummer2017!=.


tostring grunnkretsnummer, replace
replace grunnkretsnummer = "0"+grunnkretsnummer if strlen(grunnkretsnummer)==7

gen kommnr = substr(grunnkretsnummer,1,4)
gen gkrets = substr(grunnkretsnummer,5,8)

// Siden noen grunnkretser blir slått sammen (21 stykk) blir det duplikater
// disse får kun små forskjeller i reisetid
egen distanse_km2    = mean(distanse_km), by(kommnr gkrets hovedinstnr)
egen reisetid_min2   = mean(reisetid_min), by(kommnr gkrets hovedinstnr)
replace distanse_km  = distanse_km2
replace reisetid_min = reisetid_min2
bysort kommnr gkrets hovedinstnr: keep if _n==1


// Save  list of grunnkrets-institution traveltime
preserve
keep kommnr gkrets hovedinstnr distanse_km reisetid_min
save "liste_reisetid_grkrets_inst", replace
restore


//
// Save list with closest university hospital per kommune
//
use "liste_reisetid_grkrets_inst", clear
merge m:1 hovedinstnr using "list_hospitallevels", keepusing(universitetssykehus)
keep if universitetssykehus ==1 
collapse (min) reisetid_min distanse_km, by(kommnr gkrets)
drop if kommnr ==""
collapse (mean) reisetid_unisykehus = reisetid_min distanse_unisykehus = distanse_km, by(kommnr)

save "liste_reisetid_universitetssykehus", replace






// Add actual traveldistance from each municipality
drop *
set obs 1
gen faar = .
save "temp", replace
foreach aar of numlist 1999/2016{
	use "liste_reisetid_kommune_inst_closest", clear
	keep if faar == `aar'
	merge 1:m kommnr hovedinstnr using "liste_reisetid_grkrets_inst", keepusing(reisetid_min gkrets)
	keep if _merge ==3
	drop _merge
	
	append using "temp"
	save "temp", replace
}
drop if faar==.
rename (hovedinstnr N_hosp reisetid_min) (hovedinstnr_rankdist N_hosp_rankdist reisetid_min_rankdist)
reshape wide hovedinstnr_rankdist N_hosp_rankdist reisetid_min_rankdist nivaa, i(kommnr gkrets faar) j(rank_dist)

save "liste_reisetid_grkrets_inst_closest", replace





