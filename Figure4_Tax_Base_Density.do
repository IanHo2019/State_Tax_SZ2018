* This do file replicates Figure 4 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in four years
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inlist(year, 1980, 1990, 2000, 2010)

* Generate some variables
replace sales_wgt = sales_wgt/100
gen sales_corporate_rate = sales_wgt*corporate_rate

replace payroll_wgt = payroll_wgt/100
gen payroll_corporate_rate = payroll_wgt*corporate_rate


********************************************************************************
**# Density Visualization
********************************************************************************

local varlist = "rec_val Losscarryforward investment_credit Losscarryback sales_corporate_rate payroll_corporate_rate"
foreach var in `varlist' {
	quietly {
		if "`var'" == "rec_val" {
			local fignum = "A"
			local xt = "R&D Credit Rule"
			local max = 0.2
			local inc = 0.04
		}
	
		if "`var'" == "Losscarryforward" {
			local fignum = "B"
			local xt = "Loss Carryforward Rule"
			local max = 20
			local inc = 4
		}
	
		if "`var'" == "investment_credit" {
			local fignum = "C"
			local xt = "Investment Credit Rate"
			local max = 0.1
			local inc = 0.02
		}
	
		if "`var'" == "Losscarryback" {
			local fignum = "D"
			local xt = "Loss Carryback Rule"
			local max = 3
			local inc = 1
		}
		
		if "`var'" == "sales_corporate_rate" {
			local fignum = "E"
			local xt = "Sales Apportioned Corporate Tax Rate"
			local max = 12
			local inc = 3
		}
	
		if "`var'" == "payroll_corporate_rate" {
			local fignum = "F"
			local xt = "Payroll Apportioned Corporate Tax Rate"
			local max = 5
			local inc = 1
		}
	
		preserve
		
		sort year fips_state
		gen id = mod(_n - 1, 50) + 1
		replace id = id/50
		gen xaxis = id*`max'

		tempfile panel
		save `panel', replace

		* Estimate kernel density for each year
		foreach year in 1980 1990 2000 2010 {
			use `panel', clear
			keep if year == `year'
			kdensity `var', gen(x_`var' kd_`var'_`year') at(xaxis) nograph
			keep fips_state year kd*
			tempfile panel_`year'
			save `panel_`year'', replace
		}

		use `panel', clear
		foreach year in 1980 1990 2000 2010 {
			merge 1:1 fips_state year using `panel_`year'', nogen
		}

		* Plot
		twoway (line kd_`var'_1980 xaxis, c(l) lcolor(black) lwidth(medthick)) ///
		(line kd_`var'_1990 xaxis, c(l) lcolor(black) lpattern(dash) lwidth(medthick)) ///
		(line kd_`var'_2000 xaxis, c(l) lcolor(gs9)) ///
		(line kd_`var'_2010 xaxis, c(l) lcolor(gs9) lpattern(dash)), ///
		xtitle("`xt'", size(medsmall)) ///
		ytitle("Kernel Density", size(medsmall)) ///
		xlab(0(`inc')`max', nogrid) ylab(, nogrid angle(90)) ///
		legend(label(1 "1980") label(2 "1990") label(3 "2000") label(4 "2010") size(*0.8) span position(6) row(1) region(lc(gs9))) ///
		name(`fignum', replace)
		
		restore
	}
}

grc1leg A B C D E F, ///
	legendfrom(A) cols(3) ///
	name(Fig4, replace)
graph export "Figures/Figure4.svg", replace