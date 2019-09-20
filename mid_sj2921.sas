*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Midterm       					    *
* Shan Jiang (Columbia University)      *
*****************************************;

/* PBC problem */

* a) 
* Import two pbc sheets as of xlsx;
proc import out=pbc1
	datafile="C:\Users\Studentlab\Desktop\midterm\pbc.xlsx"
	dbms=xlsx replace;
	sheet="Basic";
	getnames=yes;
run;

proc import out=pbc2
	datafile="C:\Users\Studentlab\Desktop\midterm\pbc.xlsx"
	dbms=xlsx replace;
	sheet="Clinical";
	getnames=yes;
run;

 	* Merge Two datasets as PBC; 
	* Sort the datasets by ID before merging;
proc sort data=pbc1; 
	by ID; 
run;

proc sort data=pbc2; 
	by ID; 
run;

	* Create a new dataset that is a merge of the two individual datasets;
data pbc; 
	merge pbc1 pbc2; * Tell SAS which datasets to merge;
run; 
* Save to RTF;
ods rtf file = "C:\Users\Studentlab\Desktop\midterm\midterm.rtf"
		bodytitle startpage=yes;
ods noproctitle;
* b) * Label and format;

* Label;
data labelling;
	set pbc;
	label Hepato = "Hepatomegaly"
		  Bili = "Bilirubin"
		  Chol = "Cholesterol"
		  Albu = "Albumin"
		  Copp = "Copper"
		  Alka = "Alkaline"
		  Trig = "Triglycerides"; * New label in quotes;
run;

* Formatting;
proc format; * Create formats;
	value yesno     0 = "No"
					1 = "Yes";  * Add a semicolon after each format;
	value trtfmt    1 = "D-penicillamine"
					2 = "Placebo";		 
run;

data pbc;
	set labelling;
	format Ascites Hepato Spiders yesno. 
		   Treatment trtfmt.;
run; 

proc print data=pbc (obs = 5) label; 
run;


* c) * Create new variables;
data pbc_new;                                                                                                                  
	set pbc;                                                                                                                      
	array measure{3} Albu Trig Protime; * New variables: Albu2 Trig2 Pro2;
	array HB{3} _temporary_ (6, 200, 14);  * Higher bound; 
	array LB{3} _temporary_ (3.5, 0, 11); 
	array New{3} Albu2 Trig2 Pro2;
	do i = 1 to 3; 
		if measure{i} ge LB{i} and measure{i} le HB{i}  then
		New{i} = 1;
		else New{i} = 0;
	end;

	drop i; ** By dropping the i = 3 in dataset**;
run;  

proc print data= pbc_new (obs = 5) label; run;

* d). * Subset data;
data Normal Serious;
	set pbc_new;
	if Albu2  = 0 &  Trig2 = 0  & Pro2 = 0 then output Normal;
	else if Albu2 = 1 &  Trig2 = 1  & Pro2 = 1 then output Serious;
run;
proc print data=Normal (obs=5) label; run;
proc print data=Serious (obs=5) label; run;


* e). Create a macro program; 
%macro summary(datain);

proc sgplot data= pbc;
	vbox &datain / category = Treatment group = Treatment;     * I. Boxplot;
run;

proc sgpanel data=pbc;
	panelby Treatment; 
	density &datain;
	histogram &datain /transparency=0.6;     * II.Histogram;
run;

proc tabulate data = pbc;
	class Treatment Ascites;
	var Age &datain;
	table (Treatment =' ')*(Ascites  All),
		Age*(mean*f=5.1 std*f=5.2)
		&datain*(mean*f=5.1 std*f= 5.2);  *III. Table;
keylabel ALL = 'Total'
 		 mean = 'Mean'
		 std = 'Std';
run;

%mend summary;

%summary(copp);

* f). Dedscriptive statistics;

* i. Cross-table: Use Proc Freq;

proc freq data= pbc;
	table Ascites * Hepato / nocol norow nopercent;
run;

*  Use Proc Tabulate;
proc tabulate data= pbc;
	class Ascites Hepato;
	table Ascites All,  Hepato All;
run;


* ii. Distribution Alka depending on Treatment;

 * 1) Statistics; 
proc means data= pbc n mean median std min max maxdec=2;
	class Treatment; 
	var Alka;
run;

* 2) Boxplots;

proc sgplot data= pbc;
	vbox Alka / category = Treatment group = Treatment;   *Boxplot;
run;


* iii. Distribution of trig;

* 1) Statistics; 
proc means data= pbc n nmiss mean median std min max maxdec=2;
	class Treatment Ascites; 
	var Trig;
run;

* 2) Histograms;

* Treatment; 
proc sgpanel data=pbc;
	panelby Treatment/ novarname;
	histogram Trig;
	density Trig / type=kernel; /*density has different types: here I use Kernel*/
run;
* Ascites; 
proc sgpanel data=pbc;
	panelby Ascites/ novarname;
	histogram Trig;
	density Trig / type=kernel; /*density has different types: here I use Kernel*/
run;


* g). -1. Compare the Mean Copper level in Two Treatment Groups;

* H0: mu_Treatment = mu_placebo vs H1: mu_Treatment not equal to mu_placebo;
	* -> Independent Two-sample t-test;

* 1. Check normality;
proc univariate data=pbc normal;
	class Treatment;
	var Copp;
	histogram Copp;
	qqplot Copp;
run;

* 2. Shapiro-Wilk p-value;
* Treatment - D-penicillamine =  0.752587, Placebogroup = 0.825063: We should reject H0;
* -> Assuming normality is NOT appropriate;

* 3. We should try to do some transformations for Copp before Test;
Data pbc_test;
 set pbc;
 Copp_test = log(Copp);
run; 
* Check normality for Response variable again;
proc univariate data=pbc_test normal;
	class Treatment;
	var Copp_test;
	histogram Copp_test;
	qqplot Copp_test;
run;

* Based on The transformation Normality Test result, we find that 
* Shapiro-Wilk p-value;
* Treatment - D-penicillamine =  0.995, Placebogroup = 0.98514: should not reject H0;
* -> Assuming normality is appropriate for log(Copp); 


*4. Two-sample t-test For log(Copp), Measure the variance first, equal or unequal; 
proc ttest data= pbc_test;
	class Treatment;
	var Copp_test;
run;

* Equality of variances : p-value = 0.8792;
* Fail to reject H0 -> Use pooled variance;

* t-test : 0.8331; * p-value > 0.05: Reject H0;
* Conclusion: 
* At 5% sig. level we cannot reject the null hypothesis, 
* thus conclude that the means of log-transformed Copper level 
* in two treatment groups are not significantly different;


* g-2. More than 2 categories: ANOVA. Is there platelet count different depending on Histolical Stage?;

	* H0: mu_1 = mu_2 = mu_3 = mu_4 
	* vs H1: Not H0 (At least one pair has different means.);	
	* -> ANOVA;

* Check the normality;
proc univariate data=pbc normal;
	class Stage;
	var Platelet;
	histogram Platelet;
	qqplot Platelet;
run;

* Shapiro-Wilk p-value;
* (Stage 1) 0.96299 
* (Stage 2) 0.985595
* (Stage 3) 0.978338
* (Stage 4) 0.975549;
* -> Normality assumption is appropriate;


* PROC ANOVA;
proc anova data=pbc;
	class Stage;
	model Platelet = Stage;
	means Stage / hovtest=bf dunnett("4");
	* Equality of variances (hovtest = BF);
	* Pairwise comparison("Stagel" as reference);
run; quit;

* Equality of variances (BF test) p-value = 0.5642: Fail to reject H0;
* -> Assumption of equal variance is satisfied;

* ANOVA p-value <.0001: Reject H0;
* Conclusion: At the sig. level of 5%,
* Depending on Histologic stage, the mean platelet is significantly different;



* Multiple comparison (Dunnett with "Stage 1" as reference);
* No output of all other results, only show significant above;
* -> 'Stage 2' and 'Stage 4' were significant;
* -> 'Stage 3' and 'Stage 4' were significant;
ods rtf close; 
