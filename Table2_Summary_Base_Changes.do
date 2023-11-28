* This do file replicates Table 2 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
keep if inrange(year, 1980, 2010)
drop if fips_state == 11 | fips_state == 0 | fips_state > 56

xtset fips_state year

local baserules = "FedIncomeTaxDeductible FranchiseTax"
foreach rule in `baserules' {
	gen b_it_`rule' = -(`rule' - L1.`rule')
}

local baserules = "investment_credit rec_val Losscarryforward Losscarryback AllowFedAccDep ACRSDepreciation FederalBonusDepreciation sales_wgt"
foreach rule in `baserules' {
	gen b_it_`rule' = sign(-(`rule' - L1.`rule'))
}

local baserules = "FederalIncomeasStateTaxBase combined throwback incr_ma incr_fixed"
foreach rule in `baserules' {
	gen b_it_`rule' = sign((`rule' - L1.`rule'))
}


********************************************************************************
**# Create a Table
********************************************************************************

local i = 1

foreach s in sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit rec_val incr_ma incr_fixed {
	count if b_it_`s' == -1
	scalar A = `r(N)'
	
	count if b_it_`s' == 1
	scalar B = `r(N)'
	
	count if b_it_`s' == -1 | b_it_`s' == 1
	scalar C = `r(N)'
	
	count if b_it_`s' == 0
	scalar D = `r(N)'
	
	if `i' == 1 mat define tab2 = A,B,C,D
	if `i' > 1 mat define tab2 = tab2\A,B,C,D	// Backslash is used to separate rows.

	local ++i
}

*mat colnames tab2 = -1 +1 Total_Changes No_Change
mat list tab2

* Convert the matrix to dta
svmat tab2
keep tab*
drop if missing(tab21)

* Manually add appropriate variable names
g varnames = ""
replace varnames = "Sales apportionment weight" in 1
replace varnames = "Loss carryback" in 2
replace varnames = "Loss carryforward" in 3
replace varnames = "Franchise tax" in 4
replace varnames = "Federal income tax deductible" in 5
replace varnames = "Federal income tax as state tax base" in 6
replace varnames = "Federal accelerated depreciation" in 7
replace varnames = "ACRS depreciation" in 8
replace varnames = "Federal bonus depreciation" in 9
replace varnames = "Throwback" in 10
replace varnames = "Combined reporting" in 11
replace varnames = "Investment credit" in 12
replace varnames = "R\&D credit" in 13
replace varnames = "Incremental R\&D credit, base is moving average" in 14
replace varnames = "Incremental R\&D credit, base is fixed" in 15

order varnames

* Export as a TeX file
g tab = "\begin{tabular}{l*{4}{l}}" in 1
g titlerow = "Base narrowing/broadening & $-1$ & $+1$ & Total changes & No change \\" in 1
g hline = "\hline" in 1
g end = "\end{tabular}" in 1

listtex tab if _n == 1 using "Tables/Table2.tex", replace
listtex hline if _n == 1, appendto("Tables/Table2.tex")
listtex titlerow if _n == 1, appendto("Tables/Table2.tex")
listtex hline if _n == 1, appendto("Tables/Table2.tex")
listtex varnames tab2*, appendto("Tables/Table2.tex") rstyle(tabular)
listtex hline if _n == 1, appendto("Tables/Table2.tex")
listtex end if _n == 1, appendto("Tables/Table2.tex")