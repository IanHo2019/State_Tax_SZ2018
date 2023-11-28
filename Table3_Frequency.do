* This do file replicates Table 3 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023
* Alert: The results are different from Table 3 in the paper, because here I use 15 indicators (listed in Table 2) as rules to determine the base narrowing/broadendening. To get the same results as in the paper, we should use 13 of them (i.e., removing incr_ma & incr_fixed). I think this might be a coding error by the authors.

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

* Change "b_it_incr_fixed" in Rows 33 & 36 to "b_it_throwback", we will get the same results as the authors did. 
egen basebroadened = rowtotal(b_it_FedIncomeTaxDed-b_it_incr_fixed)
replace basebroadened = (basebroadened > 0)

egen basenarrow = rowtotal(b_it_FedIncomeTaxDed-b_it_incr_fixed)
replace basenarrow = (basenarrow < 0)

gen anybasechange = (basebroadened == 1 | basenarrow == 1)

* Create tax rate decreasing/increasing indicators
gen ch_corporate_rate = corporate_rate - L1.corporate_rate

gen tax_decrease = (ch_corporate_rate < 0)
gen tax_nochange = (ch_corporate_rate == 0)
gen tax_increase = (ch_corporate_rate > 0)	// Alert: Here the authors consider the missing values as tax increasing, too.


********************************************************************************
**# Create a Table
********************************************************************************

gen basechange = 0
replace basechange = 1 if basebroadened == 1
replace basechange = -1 if basenarrow == 1

gen ratechange = 0
replace ratechange = 1 if tax_increase == 1
replace ratechange = -1 if tax_decrease == 1

* Customize column and row labels
label var ratechange "Change in Corp. Rate"
label define ratelabel -1 "Rate Decrease" 0 "No Change" 1 "Rate Increase", replace
label values ratechange ratelabel

label var basechange "Change in Tax Base"
label define baselabel -1 "Narrowing" 0 "No Change" 1 "Broadening"
label values basechange baselabel

* Calculate the two-way frequencies
estpost tabulate basechange ratechange

* Export as a TeX file
estout using "Tables/Table3.tex", replace ///
	style(tex) cell(colpct(fmt(1)) b(fmt(1) par)) label unstack ///
	coll(, none) mlabels(, none) ///
	preh("\begin{tabular}{l*{4}{l}}" "\hline") posth("\hline") ///
	postfoot("\hline" "\end{tabular}")