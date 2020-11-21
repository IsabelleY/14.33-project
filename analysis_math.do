*ssc install eventdd

clear
eststo clear

cd "/Users/isabelleyen/Desktop/2020-2021/14.33/Research_Project/Datasets"

use seda_geodist_long_cs_v30.dta

//keeping mean disparities and dropping mean scores
keep leaidC leanm fips stateabb grade year subject totgyb_all mn_wag mn_wbg mn_whg mn_mfg mn_neg
rename leaidC leaid
destring leaid, replace

//keeping math scores and dropping ELA scores
keep if subject == "math"

//dropping always-takers
drop if stateabb == "CA"
drop if stateabb == "DC"
drop if stateabb == "FL"
drop if stateabb == "IN"
drop if stateabb == "WA"

//collapsing disparities across grade levels using a weighted average of the number of test-takers in each grade
//keeping total number of test-takers in each county
collapse (mean) mn_wag mn_wbg mn_whg mn_mfg mn_neg (rawsum) totgyb_all [aweight = totgyb_all], by (lea* year stateabb)

//adding binary variable indicating treatment group (1) and control group (0)
gen treatment = 1
replace treatment = 0 if stateabb == "TX" | stateabb == "OK" | stateabb == "AK" | stateabb == "NE" | stateabb == "MN" | stateabb == "VA" | stateabb == "SC"

//adding the year each state expected the Common Core to be fully implemented
//leaves the value empty for never-takers
gen year_implemented = 2014 if treatment == 1
replace year_implemented = 2015 if stateabb == "OR" | stateabb == "SD" | stateabb == "MO" | stateabb == "GA" | stateabb == "WV" | stateabb == "WI" | stateabb == "NH" | stateabb == "WY"
replace year_implemented = 2013 if stateabb == "IA" | stateabb == "NC" | stateabb == "MI" | stateabb == "DE" | stateabb == "ME"
replace year_implemented = 2012 if stateabb == "KY"

//set timevar, or the number of years after implementation of Common Core
gen timevar = year - year_implemented if treatment == 1

encode stateabb, gen(state)

//running event study and generating lags and leads graph
//leaving out lead3 and lead4 from the graph because of the small sample size
eventdd mn_wbg treatment i.state i.year, timevar(timevar) ci(rcap) lags(6) leads(2) inrange cluster(stateabb) graph_op(ytitle("Mean white-Black gap in mathematics"))
graph export wbg_math.pdf, replace

esttab using "esttab_wbg_math.tex", se wide indicate("state fixed effects = *.state" "time fixed effects = *.year") ///
	style(tex) eqlabels(none) collabels(, none) mlabels(none) ///
	stats(N r2, labels("N" "R-squared") fmt(0 2)) starlevels( * 0.10 ** 0.05 *** 0.010) replace ///
	prehead("\begin{threeparttable} \begin{tabular}{lccc}" \hline) ///
	posthead("& Mean white-Black gap in mathematics & & \\ \hline") ///
	postfoot("\hline \end{tabular} \begin{tablenotes} \item Notes: Standard errors (in parentheses) are clustered at the state level and robust to heterskedasticity. Significance at the 1, 5, and 10 percent levels indicated by ***, **, and *, respectively \end{tablenotes} \end{threeparttable}") ///
	legend label nonumber
