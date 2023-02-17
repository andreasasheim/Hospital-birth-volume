// Import list of municipalities with coordinates of the municipality center
// Make list that can be merged with data

import delimited "..\Grunnlagsdata\kommuneliste_til_bruk.csv", delim(",") clear
drop v1 type kommunesenter

rename kommune_nr kommnr

foreach var of varlist lat lon utm* {
    rename `var' `var'_kommunesenter
}

// Make string kommunenummer
tostring kommnr, replace
replace kommnr = "0"+kommnr if strlen(kommnr)==3

save "liste_kommuner_m_koordinat", replace

//
// Population
//
import delimited "..\Grunnlagsdata\Befolkning_kommune_1999til2016.csv", delim(";") rowrange(2:1000) varnames(2) clear
gen kommnr = substr(region,1,4) 
sort kommnr region
by kommnr: keep if _n==1
drop statistikk* region
foreach i of numlist 3/20{
    local aar = 1996+`i'
    rename v`i' befolkning`aar'
}

reshape long befolkning, i(kommnr) j(aar)
drop if befolkning==0

collapse (median) befolkning, by(kommnr) 

merge 1:1 kommnr using "liste_kommuner_m_koordinat"
drop _merge
save "liste_kommuner_m_koordinat", replace



//
// Area
//
import delimited "..\Grunnlagsdata\Areal_kommuner_2007til2016.csv", delim(";") rowrange(2:1000) varnames(2) clear
keep if substr(statistikkvariabel,1,1) =="L"
gen kommnr = substr(region,1,4) 
sort kommnr region
by kommnr: keep if _n==1
drop statistikk* region
foreach i of numlist 3/12{
    local aar = 2004+`i'
    rename v`i' areal`aar'
}

reshape long areal, i(kommnr) j(aar)
drop if areal==0

collapse (median) areal, by(kommnr) 

merge 1:1 kommnr using "liste_kommuner_m_koordinat"
drop _merge

// Areal på de som SSB ikke hadde (Hentet fra Wikipedia)
replace areal = 137.97 if kommune == "Ramnes"
replace areal = 598.73 if kommune == "Vindafjord"
replace areal = 184.00 if kommune == "Ølen"
replace areal = 621.73 if kommune == "Aure"
replace areal = 87.54  if kommune == "Tustna"
replace areal = 465.00 if kommune == "Skjerstad"


save "liste_kommuner_m_koordinat", replace