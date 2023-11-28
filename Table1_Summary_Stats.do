* This do file replicates Table 1 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023

clear all


********************************************************************************
**# Clean Data
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips==11 | fips==0 | fips>56
keep if inrange(year, 1980, 2010)

* Generate corporate tax revenue as share of GDP
gen r_gdp = (rev_corptax)/GDP*100


local sumlist = "r_gdp throwback combined investment_credit rec_val Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation sales_wgt incr_fixed incr_ma"


********************************************************************************
**# Summary Statistics: 1980-2010 Pooled Sample
********************************************************************************
preserve
	
foreach var in `sumlist'{
	qui{
		sum `var'
		local num_`var' = `r(N)'
		local m_`var' = `r(mean)'
		local sd_`var' = `r(sd)'
		
		if inlist("`var'", "investment_credit", "rec_val") {
			local m_`var' = 100*`r(mean)'
			local sd_`var' = 100*`r(sd)'
		}
	}
}
		
* Customize labels
g labels = ""
local row = 1

replace labels = "Corp Tax Revenue as Share of GDP (\%)" in `row'
local ++row
replace labels = "Throwback Rules" in `row'
local ++row
replace labels = "Combined Reporting" in `row'
local ++row
replace labels = "Investment Tax Credit" in `row'
local ++row
replace labels = "R\&D Tax Credit" in `row'
local ++row
replace labels = "Loss Carryback Rules" in `row'
local ++row
replace labels = "Loss Carryforward Rules" in `row'
local ++row
replace labels = "Franchise Tax" in `row'
local ++row
replace labels = "Fed Income Tax Deductible" in `row'
local ++row
replace labels = "Fed Income as State Tax Base" in `row'
local ++row
replace labels = "Fed Accelerated Depreciation" in `row'
local ++row
replace labels = "ACRS Depreciation" in `row'
local ++row
replace labels = "Federal Bonus Depreciation" in `row'
local ++row
replace labels = "Sales Apportionment Weight" in `row'
local ++row
replace labels = "Incremental R\&D Credit, Base is Fixed" in `row'
local ++row
replace labels = "Incremental R\&D Credit, Base is Moving Average" in `row'
local ++row	

* Store summary statistics in table format
foreach var in num m sd{
	qui{
		local row = 1
		if "`var'"=="num" {
			local decimal = 0
		}
		else{
			local decimal = 3
		}
		
		g `var' = ""
		
		replace `var' = string(``var'_r_gdp', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_throwback', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_combined', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_investment_credit', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_rec_val', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_Losscarryback', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_Losscarryforward', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FranchiseTax', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FedIncomeTaxDeductible', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FederalIncomeasStateTaxBase', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_AllowFedAccDep', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_ACRSDepreciation', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FederalBonusDepreciation', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_sales_wgt', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_incr_fixed', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_incr_ma', "%12.`decimal'f") in `row'
		local ++row
	}
}

* Export as a TeX file
g tab = "\begin{tabular}{l*{3}{c}}" in 1
g titlerow = " & Observations & Mean & Std. Dev." in 1
g panelA = "\multicolumn{4}{l}{\textit{Panel A. 1980-2010 Pooled Sample}}" in 1
g hline = "\hline" in 1
g end = "\end{tabular}" in 1

listtex tab if _n == 1 using "Tables/Table1.tex", replace
listtex hline if _n == 1, appendto("Tables/Table1.tex")
listtex hline if _n == 1, appendto("Tables/Table1.tex")
listtex titlerow if _n==1, appendto("Tables/Table1.tex") rstyle(tabular)
listtex hline if _n == 1, appendto("Tables/Table1.tex")
listtex panelA if _n==1, appendto("Tables/Table1.tex") rstyle(tabular)
listtex labels num m sd if _n<=16, appendto("Tables/Table1.tex") rstyle(tabular)
listtex labels num m sd if _n==18, appendto("Tables/Table1.tex") rstyle(tabular)

restore
	
	
********************************************************************************
**# Summary Statistics: 2010 Cross Section
********************************************************************************
preserve

keep if year==2010
	
foreach var in `sumlist'{
	qui{
		sum `var'
		local num_`var' = `r(N)'
		local m_`var' = `r(mean)'
		local sd_`var' = `r(sd)'
		
		if inlist("`var'", "investment_credit", "rec_val") {
			local m_`var' = 100*`r(mean)'
			local sd_`var' = 100*`r(sd)'
		}
	}
}
		
* Customize labels
g labels = ""
local row = 1

replace labels = "Corp Tax Revenue as Share of GDP (\%)" in `row'
local ++row
replace labels = "Throwback Rules" in `row'
local ++row
replace labels = "Combined Reporting" in `row'
local ++row
replace labels = "Investment Tax Credit" in `row'
local ++row
replace labels = "R\&D Tax Credit" in `row'
local ++row
replace labels = "Loss Carryback Rules" in `row'
local ++row
replace labels = "Loss Carryforward Rules" in `row'
local ++row
replace labels = "Franchise Tax" in `row'
local ++row
replace labels = "Fed Income Tax Deductible" in `row'
local ++row
replace labels = "Fed Income as State Tax Base" in `row'
local ++row
replace labels = "Fed Accelerated Depreciation" in `row'
local ++row
replace labels = "ACRS Depreciation" in `row'
local ++row
replace labels = "Federal Bonus Depreciation" in `row'
local ++row
replace labels = "Sales Apportionment Weight" in `row'
local ++row
replace labels = "Incremental R\&D Credit, Base is Fixed" in `row'
local ++row
replace labels = "Incremental R\&D Credit, Base is Moving Average" in `row'
local ++row	

* Store summary statistics in table format
foreach var in num m sd{
	qui{
		local row = 1
		if "`var'"=="num" {
			local decimal = 0
		}
		else{
			local decimal = 3
		}
		
		g `var' = ""
		
		replace `var' = string(``var'_r_gdp', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_throwback', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_combined', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_investment_credit', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_rec_val', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_Losscarryback', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_Losscarryforward', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FranchiseTax', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FedIncomeTaxDeductible', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FederalIncomeasStateTaxBase', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_AllowFedAccDep', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_ACRSDepreciation', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_FederalBonusDepreciation', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_sales_wgt', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_incr_fixed', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_incr_ma', "%12.`decimal'f") in `row'
		local ++row
	}
}

* Export as a TeX file
g tab = "\begin{tabular}{l*{3}{c}}" in 1
g titlerow = " & Observations & Mean & Std. Dev." in 1
g panelB = "\multicolumn{4}{l}{\textit{Panel B. 2010 Cross Section}}" in 1
g hline = "\hline" in 1
g end = "\end{tabular}" in 1

listtex panelB if _n==1, appendto("Tables/Table1.tex") rstyle(tabular)
listtex labels num m sd if _n<=16, appendto("Tables/Table1.tex") rstyle(tabular)
listtex hline if _n == 1, appendto("Tables/Table1.tex")
listtex hline if _n == 1, appendto("Tables/Table1.tex")
listtex end if _n == 1, appendto("Tables/Table1.tex")
		
restore