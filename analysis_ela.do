clear
eststo clear

cd "/Users/isabelleyen/Desktop/2020-2021/14.33/Research_Project/Datasets"

use seda_processed_gcs

//keeping math scores and dropping ELA scores
keep if subject == "ela"

//dropping always-takers
drop if stateabb == "CA"
drop if stateabb == "DC"
drop if stateabb == "MA"
drop if stateabb == "IN"
drop if stateabb == "TN"
drop if stateabb == "TX"

//adding binary variable indicating treatment group (1) and control group (0)
gen treatment = 1
replace treatment = 0 if stateabb == "OK" | stateabb == "AK" | stateabb == "NE" | stateabb == "VA" | stateabb == "SC"

//adding the year each state expected the Common Core to be fully implemented
//leaves the value empty for never-takers
gen year_implemented = 2014 if treatment == 1
replace year_implemented = 2015 if stateabb == "OR" | stateabb == "SD" | stateabb == "MO" | stateabb == "GA" | stateabb == "WV" | stateabb == "WI" | stateabb == "NH" | stateabb == "WY"
replace year_implemented = 2013 if stateabb == "IA" | stateabb == "NC" | stateabb == "MI" | stateabb == "DE" | stateabb == "ME" | stateabb == "MN"
replace year_implemented = 2012 if stateabb == "KY"

encode stateabb, gen(state)

//generating post indicator variable
gen post = 1 if year >= year_implemented
replace post = 0 if post == .

//set timevar, or the number of years after implementation of Common Core
gen timevar = year - year_implemented if treatment == 1

//running event study and generating lags and leads graph for robustness check
eventdd mn_wbg i.state i.year if year_implemented >= 2014, timevar(timevar) ci(rcap) lags(5) leads(2) inrange cluster(stateabb) graph_op(ytitle("Mean white-Black gap in ELA"))
graph export wbg_ela_balanced.pdf, replace

//pooled result for all grades
eststo all: reg mn_wbg post i.state i.year i.grade, r cluster(stateabb)

//results for individual grades
eststo g3: reg mn_wbg post i.state i.year if grade == 3, r cluster(stateabb)
eststo g4: reg mn_wbg post i.state i.year if grade == 4, r cluster(stateabb)
eststo g5: reg mn_wbg post i.state i.year if grade == 5, r cluster(stateabb)
eststo g6: reg mn_wbg post i.state i.year if grade == 6, r cluster(stateabb)
eststo g7: reg mn_wbg post i.state i.year if grade == 7, r cluster(stateabb)
eststo g8: reg mn_wbg post i.state i.year if grade == 8, r cluster(stateabb)

//printing table of results
esttab using "esttab_wbg_ela.tex", se indicate("state fixed effects = *.state" "time fixed effects = *.year" "grade fixed effects = *.grade") ///
	style(tex) eqlabels(none) collabels(, none) mlabels(none) ///
	stats(N r2, labels("N" "R-squared") fmt(0 2)) starlevels( * 0.10 ** 0.05 *** 0.010) replace ///
	prehead("\begin{threeparttable} \begin{tabular}{lccccccc}" \hline) ///
	posthead("& All grades & Grade 3 & Grade 4 & Grade 5 & Grade 6 & Grade 7 & Grade 8\\ \hline") ///
	postfoot("\hline \end{tabular} \begin{tablenotes} \item Notes: Standard errors (in parentheses) are clustered at the state level and robust to heterskedasticity. Significance at the 1, 5, and 10 percent levels indicated by ***, **, and *, respectively \end{tablenotes} \end{threeparttable}") ///
	legend label nonumber
	
//generating graph to show estimated treatment effects
coefplot (all, label(All grades)) (g3, label(Grade 3)) (g4, label(Grade 4)) (g5, label(Grade 5)) (g6, label(Grade 6)) (g7, label(Grade 7)) (g8, label(Grade 8)), keep(post) xline(0) xtitle("Estimated effect of Common Core on gap in math, by grade")
graph export effects_ela.pdf, replace

collapse (mean) mn_wbg mn_wht mn_blk (rawsum) totgyb_all [aweight = totgyb_all], by (grade year treatment)
keep if grade == 5
graph twoway (line mn_blk mn_wht year if treatment == 0) (line mn_blk mn_wht year if treatment == 1), ytitle("Grade Cohort Standardized score") xtitle("Spring of tested year") ///
	legend(label(1 mean score, Black students, treatment) label(2 mean score, white students, treatment)  label(3 mean score, Black students control) label(4 mean score, white students, control))
graph export trendlines_ela.pdf, replace
