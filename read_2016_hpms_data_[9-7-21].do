/***
** 9/8/21: This file is deprecated because I found 2018 data! Check read_2018_hpms_data.do. 

** This file reads in the 2016 HPMS data from 
** https://data-usdot.opendata.arcgis.com/datasets/highway-performance-monitoring-system-nhs/explore?location=44.086450%2C-112.548100%2C3.68
** Currently trying to make a scatterplot with roughness and maintenance for the presentation.


Some weirdness here because if I download different parts separately (see list in https://data-usdot.opendata.arcgis.com/search?collection=Dataset&tags=national%20transportation%20atlas%20database, where they have different datasets for each type of road), there are more results than if I download the supposed whole thing in the first link.
I was going to download all of them separately, but FSYS 5 (major collectors) refuses to download! So for now, I'm just going to use the dataset with supposedly all the data.

** Author: Audrey C 

*/

/* Commented out because it takes too long to run every time, don't want to import every time. */
*insheet using "~/Dropbox (YLS)/Procurement Survey/Data/Raw/Highway_Performance_Monitoring_System_NHS.csv", clear
*save "~/Dropbox (YLS)/Procurement Survey/Data/Raw/HPMS_2018_All_Raw"


use "~/Dropbox (YLS)/Procurement Survey/Data/Raw/HPMS_2018_All_Raw", clear 

drop begin_point end_point iri_year route_* urban_code truck toll* speed_limit psr year_record strahnet_type shape 
drop OBJECTID 
drop nhs
drop access_control_

label define facilityv 1 "One-Way Roadway" 2 "Two-Way Roadway" 4 "Ramp" 5 "Non-Mainline" 6 "Non-Inventory Direction" 7 "Planned/Unbuilt"
label values facility_type facilityv

label define structurev 0 "None" 1 "Bridge" 2 "Tunnel" 3 "Causeway"
replace structure_type = 0 if structure_type == .
label values structure_type structurev

rename shapestlength section_length 
notes section_length: Decimal value in thousandths of a mile. This length must be consistent with the difference between End_Point and Begin_Point.
label var section_length "Length in miles"

notes iri: IRI is the road roughness index most commonly used worldwide for evaluating and managing road systems. Road roughness is the primary indicator of the utility of a highway network to road users. IRI is defined as a statistic used to estimate the amount of roughness in a measured longitudinal profile.

label define ownv 1 "State Hwy Agency" 2 "County Hwy Agency" 3 "Town Hwy Agency" 4 "City Hwy Agency" 11 "State Park/Forest/Reservation Agency" 12 "Local Park/Forest/Reservation Agency" 21 "Other State Agency" 25 "Other Local Agency" 26 "Private (not railroad)" 27 "Railroad" 31 "State Toll Authority" 32 "Local Toll Authority" 40 "Other Public Instrumentality (Airport, School, University)" 50 "Indian Tribe Nation" 60 "Other Fed. Agency" 62 "Bureau of Indian Affairs" 63 "Bureau of Fish & Wildlife" 64 "US Forest Service" 66 "National Park Service" 67 "Tennessee Vally Authority" 68 "Bureau of Land Mgmt" 69 "Bureau of Reclamation" 70 "Corps of Engineers" 72 "Air Force" 73 "Navy/marines" 74 "Army" 80 "Other"

label values ownership ownv

label define fv 1 "Interstate" 2 "Principal Arterial - Other Freeways/Expressways" 3 "Principal Arterial - Other" 4 "Minor Arterial" 5 "Major Collector" 6 "Minor Collector" 7 "Local"

label values f_system fv 
label var f_system "Type of Road"

label var iri "International Roughness Index (smaller is more smooth)"
rename state_code state_fips 

*** DROPPING SEGMENTS THAT ARE BRIDGES/CAUSEWAYS/TUNNELS
drop if structure_type != 0

*** DROPPING IF SEGMENT LENGTH IS 0
drop if section_length == 0 | section_length == .

*** DROPPING IF F-SYSTEM IS MISSING
drop if f_system == 0 | f_system == .
stop
* save segment-level before collapsing
save "~/Dropbox (YLS)/Procurement Survey/Data/Clean/HPMS_2018_Segments_Cleaned", replace

preserve
    collapse (mean) iri [aweight = section_length], by(state_fips f_system)
    tempfile iri
    save `iri'
restore 
collapse (sum) section_length, by(state_fips f_system)
merge 1:1 state_fips f_system using `iri'
assert _merge == 3
drop _merge

merge m:1 using "~/Dropbox (YLS)/Procurement Survey/Data/Utility/state_ids.dta"

save "~/Dropbox (YLS)/Procurement Survey/Data/Clean/HPMS_2018_State-RoadType_Cleaned", replace



