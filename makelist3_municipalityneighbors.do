//
// Data on municipality-pair-level
// Import list of municipality pairs (neighbors) and save as Stata-datasets to be merged
// Make a unique id per pair of neighboring municipalities
//

import delimited "..\Grunnlagsdata\Kommunenaboer_til_kommuneparanalyser.txt", delim(";") clear
destring length, dpcomma replace
drop if length == 0
drop length node* objectid
rename (src_kommunenum nbr_kommunenum) (kommune_nr nabo_nr)

// Make string kommunenummer
tostring kommune_nr, generate(kommnr)
replace kommnr = "0"+kommnr if strlen(kommnr)==3

tostring nabo_nr, generate(nabonr)
replace nabonr = "0"+nabonr if strlen(nabonr)==3


// Make an id-variable for each pair of municipalities
gen     pair_1 = kommnr   if kommnr<nabonr
replace pair_1 = nabonr   if kommnr>nabonr
gen     pair_2 = nabonr   if kommnr<nabonr
replace pair_2 = kommnr   if kommnr>nabonr
egen   id_pair = group(pair_1 pair_2)
drop pair* kommune_nr nabo_nr


save "liste_kommunenaboer", replace