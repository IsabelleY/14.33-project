*ssc install eventdd
*ssc install coefplot

clear
eststo clear

cd "/Users/isabelleyen/Desktop/2020-2021/14.33/Research_Project/Datasets"

//processing dataset

use seda_geodist_long_gcs_v30.dta

//keeping mean white and Black scores and white-Black gap
keep leaidC leanm fips stateabb grade year subject totgyb_all mn_wbg mn_blk mn_wht
rename leaidC leaid
destring leaid, replace
//drop if white-Black gap missing
drop if mn_wbg == .


save seda_processed_gcs.dta, replace

//running analysis for math and ELA

do analysis_math

do analysis_ela
