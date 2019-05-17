
******************************************
* P6110: Statistical Computing with SAS  *
* Spring 2019                            *
* Chapter 17. Longitudinal Data Analysis *
* Jihui Lee (Columbia University)        *
******************************************;

* Import the dataset;
proc import out=Cancer
	datafile="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 17\Cancer.xlsx"
	dbms=xlsx replace;
run;

proc format;
	value TRTFMT 0 = "Placebo"
				 1 = "Aloe juice";
run;

data Cancer;
	set Cancer;
	label TRT = "Treatment"
		  WEIGHTIN = "Initial weight"
		  TOTALCW0 = "Oral condition in week 0"
		  TOTALCW2 = "Oral condition in week 2"
		  TOTALCW4 = "Oral condition in week 4"
		  TOTALCW6 = "Oral condition in week 6";
	format trt trtfmt.;
run;

proc print data=Cancer (obs=5) label; run;


* Transpose from wide to long;
proc sort data=Cancer;
	by ID TRT AGE WEIGHTIN STAGE;
run;

* PROC TRANSPOSE;
proc transpose data=Cancer out=Cancer_long
				(drop=_LABEL_ rename=(col1=TOTALC));
	by ID TRT AGE WEIGHTIN STAGE;
	var TOTALCW0 TOTALCW2 TOTALCW4 TOTALCW6;
run;

data cancer_long;
	set cancer_long;
		drop _NAME_;
	WEEK = input(transtrn(_NAME_, "TOTALCW", ""), 4.);
run;

proc print data=cancer_long (obs = 5);
run;

/* Exploratory Steps */

* Mean and S.D. change;
proc means data=Cancer mean std;
	class trt;
	var totalcw0 totalcw2 totalcw4 totalcw6;
run;

* Is it appropriate to assume the linear relationship between time and totalcw?;

* Check variability and linearity of mean/median;
proc sgplot data=Cancer_long;
	vbox totalc / group=week;
run;

proc sgplot data=Cancer_long;
	vbox totalc / category=trt group=week;
run;

* Spaghetti plot;
proc sgplot data=Cancer_long;
	series x=week y=totalc / markers group=trt;
	xaxis label="Week";
	yaxis label="Oral Condition";
run;
* Variation increases over time;

proc sort data=Cancer_long out=long_plot;
	by id; run;

* Create a missing value for Y variable to indicate the end of each curve;
data long_plot;
  set long_plot;
  by id;
  output;
  if last.id then do;
	totalc = .;
    output;
  end;
run;

* BREAK: Create a break in the line for each missing value for the Y variable;

* Spaghetti plot;
proc sgplot data=long_plot;
	series x=week y=totalc / break markers group=trt;
	xaxis label="Week";
	yaxis label="Oral Condition";
run;

proc sgplot data=long_plot;
	series x=week y=totalc / break markers group=stage;
	xaxis label="Week";
	yaxis label="Oral Condition";
run;

* Individuals;
proc sgpanel data=Cancer_long;
	panelby ID / columns=5 rows=5;
*	scatter x=week y=totalc / group=trt;
	reg x=week y=totalc /group=trt;
*	pbspline x=week y=totalc /group=trt;
	colaxis label="Week";
	rowaxis label="Oral Condition";
run;

* Individuals;
proc sgplot data=Cancer_long;
	series x=age y=totalc / markers group=id;
	xaxis label="Age";
	yaxis label="Oral Condition";
run;
* In this example, there is no time-varying variable;


* Plot for each time point;
%macro plot(byvar);

proc sgpanel data=Cancer_long;
	panelby week;
	scatter x=&byvar y=totalc;
	reg x=&byvar y=totalc;
run;

proc sgpanel data=Cancer_long;
	panelby week;
	scatter x=&byvar y=totalc / group=trt;
	reg x=&byvar y=totalc / group=trt;
run;

proc sgplot data=Cancer_long;
	scatter x=&byvar y=totalc;
	reg x=&byvar y=totalc;
run;

proc sgplot data=Cancer_long;
	scatter x=&byvar y=totalc / group=trt;
	reg x=&byvar y=totalc / group=trt;
run;
%mend plot;

* Interaction with time;
%plot(age);
%plot(weightin);
%plot(stage);

* Ordinary linear regression;
* Independence assumption is violated;
proc glm data=cancer_long;
	class trt(ref="Placebo");
	model totalc = stage weightin age trt / solution;
run; quit;

* Only the last observation;
* Change over time is ignored;
proc glm data=cancer;
	class trt(ref="Placebo");
	model totalcw6 = stage weightin age trt / solution;
run; quit;


/* 17.4. Random Effects Model */

* PROC MIXED;
proc mixed data=cancer_long covtest;
	class trt(ref="Placebo");
	model totalc = stage weightin age trt / solution;
	random id;
run;

proc mixed data=cancer_long covtest;
	class trt(ref="Placebo");
	model totalc = stage weightin age trt / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;

* Include the time variable 'week';
proc mixed data=cancer_long covtest;
	class trt(ref="Placebo");
	model totalc = stage weightin age trt week / solution outpm=pred;
	random intercept / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;

proc mixed data=cancer_long covtest;
	class trt(ref="Placebo");
	model totalc = age trt week / solution outpm=pred;
	random intercept / subject=id type=un;
run; 

* hat(intercept) = 5.8769 with p-value = 0.0127;
* -> The intercept is an estimate of the mean totalc for placebo group for an average individual with age 0;

* hat(trt) = 0.04682 with p-value = 0.9577;
* -> Mean totalc comparing treatment to placebo at baseline for invididuals with similar propensity at age 0;

* hat(week) = 0.5806 with p-value <.0001;
* -> Change in mean totalc for placebo group for a unit (week) change in time for an average individual;

* Interaction;
proc mixed data=cancer_long covtest;
	model totalc = stage|week / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;

* Discrete time;
proc mixed data=cancer_long covtest;
	class trt(ref="Placebo") week(ref="0");
	model totalc = trt week / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

data cancer_long2;
	set cancer_long;
	week2=0; week4=0; week6=0;
	if week=2 then week2=1;
	if week=4 then week4=1;
	if week=6 then week6=1;
run;

proc mixed data=cancer_long2 covtest;
	class trt(ref="Placebo");
	model totalc = trt week2 week4 week6 / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

* Interaction: trt;
proc mixed data=cancer_long covtest;
	class trt(ref="Placebo") week(ref="0");
	model totalc = trt|week / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;

* Interaction: stage;
proc mixed data=cancer_long covtest;
	class week(ref="0");
	model totalc = stage|week / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;

* Interaction: trt, age;
proc mixed data=cancer_long covtest;
	class trt(ref="Placebo") week(ref="0");
	model totalc = age trt|week / solution notest outpm=pred;
	random intercept / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;

* Random slope;
proc mixed data=cancer_long covtest;
	class trt(ref="Placebo");
	model totalc = trt age stage week / solution notest outpm=pred;
	random age / subject=id type=un;
run;

proc sgplot data=pred;
	series x=week y=pred / markers group=id;
	xaxis label="Week";
	yaxis label="Predicted Value";
run;


/* 17.5. Generalized Estimating Equation (GEE) */

proc genmod data=cancer_long;
	class id trt(ref="Placebo");
	model totalc = age trt stage;
	repeated subject=id / type=un covb corrw;
run;

* GEE with exchangeable covariance matrix;
proc genmod data=cancer_long;
	class id trt(ref="Placebo");
	model totalc = age trt stage;
	repeated subject=id / type=exch covb corrw;
run;

proc genmod data=cancer_long;
	class id trt(ref="Placebo");
	model totalc = age trt stage;
	repeated subject=id / type=toep covb corrw;
run;

proc genmod data=cancer_long;
	class id trt(ref="Placebo");
	model totalc = age trt stage week;
	repeated subject=id / type=exch covb corrw;
run;

proc genmod data=cancer_long;
	class id trt(ref="Placebo") week(ref="0");
	model totalc = age trt stage week;
	repeated subject=id / type=exch covb corrw;
run;
