* This do file replicates Table 4 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear


* Keep only 50 states in 1980-2010
drop if fips_state == 11 | fips_state == 0 | fips_state > 56
keep if inrange(year, 1980, 2010)

* Create base narrowing/broadening indicators
xtset fips_state year

local baserules = "FedIncomeTaxDeductible FranchiseTax investment_credit rec_val Losscarryforward Losscarryback AllowFedAccDep ACRSDepreciation FederalBonusDepreciation sales_wgt"
foreach rule in `baserules' {
	gen b_it_`rule' = sign(-(`rule' - L1.`rule'))
}

local baserules = "FederalIncomeasStateTaxBase combined throwback incr_ma incr_fixed"
foreach rule in `baserules' {
	gen b_it_`rule' = sign((`rule' - L1.`rule'))
}

egen basebroadened = rowtotal(b_it_FedIncomeTaxDed-b_it_incr_fixed)
replace basebroadened = (basebroadened > 0)

egen basenarrow = rowtotal(b_it_FedIncomeTaxDed-b_it_incr_fixed)
replace basenarrow = (basenarrow < 0)

gen anybasechange = (basebroadened == 1 | basenarrow == 1)

gen basechange = 0
replace basechange = 1 if basebroadened == 1
replace basechange = -1 if basenarrow == 1


* Create tax rate decreasing/increasing indicators
gen ch_corporate_rate = (corporate_rate - L1.corporate_rate)

gen tax_decrease = (ch_corporate_rate < 0)
gen tax_nochange = (ch_corporate_rate == 0)
gen tax_increase = (ch_corporate_rate > 0)	// Alert: Here the authors consider the missing values as tax increasing, too.

gen ratechange = 0
replace ratechange = 1 if tax_increase == 1
replace ratechange = -1 if tax_decrease == 1


********************************************************************************
**# Probit Estimations
********************************************************************************

* Panel A
eststo prob1: probit anybasechange tax_decrease tax_nochange i.year, vce(cluster state)
eststo prob2: probit basebroadened tax_decrease tax_nochange i.year, vce(cluster state)
eststo prob3: probit basenarrow tax_decrease tax_nochange i.year, vce(cluster state)

label var tax_decrease "Rate decrease"
label var tax_nochange "No rate change"

estout prob1 prob2 prob3 using "Tables/Table4a.tex", replace ///
	keep(tax_decrease tax_nochange) label ///
	style(tex) cells(b(star fmt(4)) se(par fmt(4))) ///
	mlabels(, none) coll(, none) ///
	preh("\hline" ///
		"\multicolumn{4}{l}{\textit{Panel A: Base change}} \\" ///
		" & Any base change & Base broadening & Base narrowing \\ \hline")


* Panel B
gen anytaxchange = 1 - tax_nochange

label var basenarrow "Base narrowed"
label var basebroadened "Base broadened"

eststo prob4: probit anytaxchange basenarrow basebroadened i.year, vce(cluster state)
eststo prob5: probit tax_increase basenarrow basebroadened i.year, vce(cluster state)
eststo prob6: probit tax_decrease basenarrow basebroadened i.year, vce(cluster state)

estout prob4 prob5 prob6 using  "Tables/Table4b.tex", replace ///
	keep(basenarrow basebroadened) label ///
	style(tex) cells(b(star fmt(4)) se(par fmt(4))) ///
	mlabels(, none) coll(, none) ///
	preh("\addlinespace[1em]" ///
		"\multicolumn{4}{l}{\textit{Panel B: Tax rate change}} \\" ///
		" & Any tax change & Tax increase & Base decrease \\ \hline") ///
	postfoot("\hline")