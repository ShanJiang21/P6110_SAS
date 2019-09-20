
*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Practice 1 (Due: Feb 07, 2019)        *
* Jihui Lee (Columbia University)       *
*****************************************;

libname practice "C:\Users\Jihui\Desktop\P6110\SAS\Dataset";

/* 1. Pima Indians */

* a) Import datasets in 3 different ways;

* xlsx;
proc import out=Practice.Pima
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 1\Pima.xlsx"
	dbms=xlsx replace;
	sheet="Pima";
	getnames=yes;
run;

* csv;
proc import out=Practice.Pima2
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 1\Pima.csv"
	dbms=csv;
run;

* txt;
proc import out=Practice.Pima3
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 1\Pima.txt"
	dbms=tab;
run;

* b) Labels;
data practice.pima;
	set practice.pima;
	label pregnant = "Number of times pregnant"
		  glucose = "Plasma glucose concentration"
		  blood = "Diastolic blood pressure (mmHg)"
		  triceps = "Triceps skin fold thickness (mm)"
		  insulin = "2-hour serum insulin (mu U/ml)"
		  bmi = "Body mass index"
		  pedigree = "Diabetes pedigree function"
		  age = "Age (years)"
		  test = "Sign of diabetes";
run;

proc print data=practice.pima (obs=5) label; run;

* c) Formats;

proc format; 
	value posneg 1 = "Positive"
				 0 = "Negative";
	value bmilevel low - <18.5 = "Underweight"
		  		   18.5 - <25 = "Healthy"
				   25 - <30 = "Overweight"
				   30 - high = "Obese";
run;

proc print data=practice.pima (obs=5) label;
	format test posneg. bmi bmilevel.;
run;

* d) Subset;
data practice.young;
	set practice.pima;
	if age < 27;
	where test = 0;
	keep glucose triceps bmi age test;
	format test posneg. bmi bmilevel.;
run;

* e) Subset2;
data bplow bphigh;
	set practice.pima (keep = bmi glucose blood insulin);
	if blood < 60 then output bplow;
	else if blood > 80 then output bphigh;
run;

proc print data=bplow (obs=5); run;
proc print data=bphigh (obs=5); run;



/* 2. Athletic Shoes */

data Regular0;
	input Style $ ExerciseType $ RegularPrice; * Variable length by default is 8;
	cards;
MaxFlight Running 142.99
LightStep Walking 73.99
ZoomAirborne Running 112.99
ZipSneak C-Train 92.99
;
run;

data Regular;
	input Style $12. ExerciseType $ RegularPrice;
	cards;
MaxFlight    Running 142.99
LightStep    Walking 73.99
ZoomAirborne Running 112.99
ZipSneak     C-Train 92.99
;
run;

data Discount;
	input ExerciseType $ DiscountRate;
	cards;
	Running 0.30
	Walking 0.20
	C-Train 0.25
;
run;


* a) Merge;

proc sort data = Regular;
	by ExerciseType;
run;

proc sort data = Discount;
	by ExerciseType;
run;

data Shoes;
	merge Regular Discount;
	by ExerciseType;
run;

* b) Create a new variable;

data Shoes;
	set Shoes;
	NewPrice= RegularPrice*(1-DiscountRate);
run;

proc print data=Shoes;
	var Style NewPrice;
	format NewPrice dollar7.2;
run;


*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Practice 2 (Due: Feb 14, 2019)        *
* Jihui Lee (Columbia University)       *
*****************************************;

/* Wine Quality */

* a) Import datasets and combine them;

* White;
proc import out=white
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 2\wine.xlsx"
	dbms=xlsx replace;
	sheet="white";
	getnames=yes;
run;

* Red;
proc import out=red
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 2\wine.xlsx"
	dbms=xlsx replace;
	sheet="red";
	getnames=yes;
run;

* Wine color;
data white;
	set white;
	color = "white";
run;

data red;
	set red;
	color = "red";
run;

* Combine the two datasets;
data wine;
	set white red;
run;

* b) Labels;
data wine;
	set wine;
	label facid = "Fixed acidity"
		  vacid = "Volatile acidity"
		  cacid = "Citric acid"
		  rsugar = "Residual sugar"
		  freesd = "Free sulfur dioxide"
		  totalsd = "Total sulfur dioxide";
run;

proc print data=wine (obs=5) label; run;

* c) New variable;
data wine;
	set wine;
	length qgroup $6.;
	if quality < 5 then qgroup = "poor";
	else if quality < 7 then qgroup = "normal";
	else if quality <= 10 then qgroup = "great";
run;

* d) Descriptive statistics;

* d1) Free sulfur dioxide; 

* Summary statistics;
proc means data=wine min max mean median maxdec=2;
	class color;
	var freesd;
run;

* Histogram;
proc sgpanel data=wine;
	panelby color / novarname;
	histogram freesd / scale=count;
	density freesd / type=kernel;
run;

* New variable;
data wine;
	set wine;
	if freesd < 5 then fsd = "Less";
	else fsd = "More";
run;

* Frequency table;
proc freq data=wine;
	table fsd * qgroup / norow nopercent;
run;

* d2) Quality of wine;

* Summary statistics;
proc means data=wine min mean std median max maxdec = 2;
	var quality;
run;

* Frequency table;
proc freq data=wine;
	table qgroup;
run;

* Bar chart;
proc sgplot data=wine;
	vbar qgroup / datalabel;
run;

* Boxplot;
proc sgplot data=wine;
	vbox quality / group = color;
run;

proc sgplot data=wine;
	vbox quality / category = color;
run;

* Scatterplot;
proc sgplot data=wine;
	scatter x=freesd y=quality / group=color;
run;


* d3) Alcohol;

* Histogram;
proc sgplot data=wine;
	histogram alcohol;
run;

* Frequency table;
proc freq data=wine;
	table alcohol;
run;

* Summary statistics;
proc means data=wine min max mean std median maxdec=1;
	var alcohol;
run;

* Normality check;
proc univariate data=wine normal plots;
	class color;
	var alcohol;
	histogram alcohol/normal;
run;

* For both red and white, 
  the distribution of alcohol is not normal;

*******************************************
* P6110: Statistical Computing with SAS   *
* Spring 2019                             *
* In-Class Practice 3 (Due: Feb 21, 2019) *
* Jihui Lee (Columbia University)         *
*******************************************;


* a) Import;
proc import out=respiratory
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 3\respiratory.xlsx"
	dbms=xlsx replace;
	sheet="respiratory";
run;

ods pdf file="C:\Users\Jihui\Desktop\P6110\Practice\Practice 3\Descriptive.pdf"
		startpage=yes;
ods noproctitle;


* b) Subset;
data res;
	set respiratory;
	if month = 0;
	drop month;
run;

proc print data=res (obs = 5);
run;


* c) Format;
proc format;
	value centerfmt 1 = "Center A"
					2 = "Center B";
run;

data res;
	set res;
	format center centerfmt.;
run;

proc print data=res (obs = 5);
run;


* d) Descriptive statistics;

* d-1) Distribution of age at each study center;

* Summary statistics;

* CLASS;
proc means data=res n mean median std min max maxdec=2;
	class center;
	var age;
run;

* BY;
proc sort data=res out=res2;
	by center;
run;

proc means data=res2 n mean median std min max maxdec=2;
	by center;
	var age;
run;

* Histogram;
proc sgpanel data=res;
	panelby center;
	histogram age / scale=count;
run;


* d-2) Cross-tabular frequency table of treatment (columns) and respiratory status (rows).

* PROC FREQ (nocol norow nopercent);
proc freq data=res;
	table status*treatment / nocol norow nopercent;
run;

* PROC TABULATE (Add total counts for both columns and rows);
proc tabulate data=res;
	class status treatment;
	table status all , treatment all;
	keylabel N = "Freq"
			 All = "Total";
run;

* e) Report;
proc report data=res nowindows;
	column center N treatment, sex, (age),(mean std);
	define center / group;
	define treatment / across;
	define sex / across;
	define age / format = 5.2;
run;

* f) Table;
proc tabulate data=res;
	class center treatment status;
	var age;
	table (treatment="" All) * (status="" All), age*(center="" All)*(n mean*f=4.1 std*f=5.2)
			/ box = "Treatment and Respiratory status";
	keylabel N = "Freq"
			 All = "Total"
		     mean = "Average"
			 std = "SD";
run;

ods pdf close;


*******************************************
* P6110: Statistical Computing with SAS   *
* Spring 2019                             *
* In-Class Practice 4 (Due: Feb 28, 2019) *
* Jihui Lee (Columbia University)         *
*******************************************;

* 1. Number of tests a student passed;

data passing;
	array pass_score{5}_temporary_(65 70 60 62 65);
	array Score{5};
	input ID Score1-Score5;

	NumberPassed = 0;
	do Test = 1 to 5;
	NumberPassed = NumberPassed + (Score{Test} ge pass_score{Test});
	end;

	drop Test;

	datalines;
	101	90	88	92	95	90
	102	64	62	77	72	71
	103	62	69	80	75	70
	104	88	77	66	77	60
	;
run;

proc print data=passing;
	id ID;
run;


* 2. Refugee;

ods rtf file="C:\Users\Jihui\Desktop\P6110\Practice\Practice 4\Refugee.rtf"
		startpage=yes;
ods noproctitle;

* a) Import;
proc import out=refugee
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 4\Refugee.xlsx"
	dbms=xlsx replace;
run;

* b) Format;
proc format;
	value yesno 0 = "No"
				1 = "Yes";
run;

data refugee;
	set refugee;
	format rater yesno. decision yesno.;
run;

proc print data=refugee (obs=5) label; run;

* c) Missing character variables: "Unknown" -> ".";
data refugee;
	set refugee;
	array char{*} _character_;
	do i=1 to dim(char);
		if char{i}= "Unknown" then char{i}="";
	end;
	drop i;
run;

proc print data=refugee (obs=5) label; run;


* c) Descriptive statistics;

* c-1) Frequency table and bar chart of the nation of origin of claimant ;
proc freq data=refugee;
	table nation;
run;

proc sgplot data=refugee;
	vbar nation;
run;

* c-2) Cross-tabular frequency table of location of original refugee claim (columns) and judge’s decision (rows);
proc freq data=refugee;
	table decision * location;
run;

proc tabulate data=refugee;
	class decision location;
	table decision ALL, location ALL;
run;

* c-3) Boxplots of logit of success rate depending on the language of case;
proc sgplot data=refugee;
	vbox success / category = language;
	xaxis label="Language of case";
	yaxis label="Logit of success rate";
run;

* d) Macro;
%macro descriptive(datain, var1, var2);
proc sgpanel data=&datain;
	panelby &var1;
	vbar &var2;
run;

proc freq data=&datain;
	table &var1 * &var2 / nocol norow nopercent;
run;

%mend desriptive;

%descriptive(refugee, decision, location);

ods rtf close;

*******************************************
* P6110: Statistical Computing with SAS   *
* Spring 2019                             *
* In-Class Practice 5 (Due: Mar 07, 2019) *
* Jihui Lee (Columbia University)         *
*******************************************;

* a) Import, Labels and Formats;

proc import out=Cancer
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 5\Cancer.xlsx"
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
		  TOTALCW8 = "Oral condition in week 8";
	format trt trtfmt.;
run;

proc print data=Cancer (obs=5) label; run;

* b) Transpose from wide to long;

proc sort data=Cancer;
	by ID TRT AGE WEIGHTIN STAGE;
run;

* PROC TRANSPOSE;
proc transpose data=Cancer out=Cancer_long1 
				(drop=_NAME_ _LABEL_ rename=(col1=TOTALC));
	by ID TRT AGE WEIGHTIN STAGE;
	var TOTALCW0 TOTALCW2 TOTALCW4 TOTALCW8;
run;

proc print data=Cancer_long1 (obs = 10) label; run;


* FYI (PROC TRANSPOSE) Include the variable WEEK;
proc transpose data=Cancer out=Cancer_long1_1
				(drop=_LABEL_ rename=(col1=TOTALC));
	by ID TRT AGE WEIGHTIN STAGE;
	var TOTALCW0 TOTALCW2 TOTALCW4 TOTALCW8;
run;

data cancer_long1_1;
	retain ID TRT AGE WEIGHTIN STAGE WEEK TOTALC;
	set cancer_long1_1;
	WEEK = input(transtrn(_NAME_, "TOTALCW", ""), 2.);
	drop _NAME_;
run;

proc print data=cancer_long1_1 (obs = 10) label; run;

* ARRAY;
data Cancer_long2;
	retain id week;
	set Cancer;
	array cond{4} TOTALCW0 TOTALCW2 TOTALCW4 TOTALCW8;
	array weekn{4} _temporary_ (0,2,4,8);
	do measure=1 to 4;
		if missing(cond{measure}) then leave;
		WEEK = weekn{measure};
		TOTALC = cond{measure};
		output;
	end;
	keep ID WEEK TRT AGE WEIGHTIN STAGE TOTALC;
run;

proc print data=Cancer_long2 (obs = 10) label; run;

* c) PROC EXPORT;
proc export data=Cancer_long2 
			outfile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 5\Cancer2.xlsx"
			dbms=xlsx replace;
			sheet="Cancer2";
run;


* d) GrandTotal;
proc sort data=Cancer_long2 out = long; 
	by id week; 
run;

data Cancer_sum;
	set long;
	by id;
	retain GrandTotal;
	if first.id then GrandTotal = totalc;
	else GrandTotal = GrandTotal + totalc;
	if last.id;
	drop Totalc;
run;

proc print data=Cancer_sum (obs = 10) label; run;

* e) Plots;

ods graphics / height=5IN;
ods rtf file="C:\Users\Jihui\Desktop\P6110\Practice\Practice 5\plot.rtf";


proc sort data=Cancer_long2 out=Cancer_long3;
	by id; run;

* Create a missing value for Y variable to indicate the end of each curve;
data Cancer_long3;
  set Cancer_long3;
  by id;
  output;
  if last.id then do;
	totalc = .;
    output;
  end;
run;

proc sgplot data=Cancer_long3;
	series x=week y=totalc / break markers group=trt;
	xaxis label="Week";
	yaxis label="Oral Condition";
run;

proc sgpanel data=Cancer_long3;
	panelby ID / columns=5 rows=5;
	pbspline x=week y=totalc /group=trt;
	colaxis label="Week";
	rowaxis label="Oral Condition";
run;

ods rtf close;
ods graphics off;


*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* In-Class Practice 6                   *
* Jihui Lee (Columbia University)       *
*****************************************;

/* 1. Teaching Module */

* Import the dataset;

data school;
	input ID PRE POST @@; **For entering two obs in one line;
	cards;
1	18	22	2	21	25
3	16	17	4	22	24
5	19	16	6	24	29
7	17	20	8	21	23
9	23	19	10	18	20
11	14	15	12	16	15
13	16	18	14	19	26
15	18	18	16	20	24
17	12	18	18	22	25
19	15	19	20	17	16
;
run;

* Check the normality assumption;
proc univariate data=school normal;
	var pre post;
	histogram pre post;
	qqplot pre post;
run;
* Shapiro-Wilk test p-value
* (pre) 0.9569 (post) 0.2654: Fail to reject H0 
* -> Normality assumption is appropriate;

* However, the sample size is small (n=20);
* You may want to try both parametric and nonparametric tests;

* (Parametric) Paired two-sample t-test;
proc ttest data=school;
	paired post*pre;
run;
* p-value = 0.0044: Reject H0;
* -> Strong evidence to support significant difference in means 
*    between pre- and post- teaching modules.;

* -> p-value presented in SAS output is two-sided (i.e. H1: mu_pre not eqaul to mu_post).
*    p-value for one-sided test (i.e. improvement H1: Mu_pre < Mu_post) is 0.0044/2 = 0.0022;
*    : Strong evidence to reject H0;
proc ttest data=school sides=U;
	paired post*pre;
run;

* (Nonparametric) Wilcoxon signed rank test;
data school;
	set school;
	diff = post - pre; * Define a new variable 'diff';
run;

proc univariate data=school normal;
	var diff;
	histogram diff;
	qqplot diff;
run;
* p-value = 0.0058: Reject H0;
* -> Significant difference between pre- and post- teaching modules.

* FYI, another way to conduct paired two-sample t-test by using difference;
proc ttest data=school sides=U;
	var diff;
run;

/* 2. Potato cooking quality */
	
* a) Import and format;
proc import out=Potato
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 6\Potato.xlsx"
	dbms=xlsx replace;
run;

* Proc Format;
proc format;
	value areafmt 1 = "Southern"
				  2 = "Central";
	value sizefmt 1 = "Large"
				  2 = "Medium";
	value tempfmt 1 = "75F"
				  2 = "40F";
	value storagefmt 1 = "0 month"
					 2 = "2 months"
					 3 = "4 months"
					 4 = "6 months";
	value cookingfmt 1 = "Boil"
					 2 = "Steam"
					 3 = "Mash"
					 4 = "Bake at 350F"
					 5 = "Bake at 450F";
run;
* Data format.;
data potato;
	set potato;
	format area areafmt. size sizefmt. temp tempfmt.
		   storage storagefmt. cooking cookingfmt.;
run;

proc print data=potato (obs=5); run;

* b) Macro: Histogram;
%macro hist(byvar);
proc sgplot data=potato;
	histogram &byvar / scale=count;
run;
%mend hist;

%hist(texture);
%hist(flavor);
%hist(moistness);

* c) Hypothesis testing;


* c)-1 Is the mean flavor score significantly different from 3?;
* H0: mu = 3 vs H1: mu not equal to 3;
* -> One-sample t-test;

* Check normality;
proc univariate data=potato normal mu0=3;
	var flavor;
	histogram flavor;
	qqplot flavor;
run;
* Shapiro-Wilk p-value = 0.0095: Reject H0;
* -> Assuming normality is not appropriate;

* (Nonparametric) Wilcoxon signed rank test;
* p-value = 0.0003: Reject H0;
* <<Median>> flavor score is significantly different from 3;
* Note: Nonparametric test is about 'median', not 'mean';

* FYI one-sample t-test;
proc ttest data=potato h0=3;
	var flavor;
run;
* p-value = 0.0001: Reject H0;


* c)-2. Is there a difference in mean texture score between large and medium potatoes?;
* H0: mu_large = mu_medium vs H1: mu_large not equal to mu_medium;
* -> Independent Two-sample t-test;

* Check normality;
proc univariate data=potato normal;
	class size;
	var texture;
	histogram texture;
	qqplot texture;
run;

* Shapiro-Wilk p-value;
* (large) 0.5278 (medium) 0.1759: Fail to reject H0;
* -> Assuming normality is appropriate;

* Two-sample t-test;
proc ttest data=potato;
	class size;
	var texture;
run;

* Equality of variances : p-value = 0.6922;
* Fail to reject H0 -> Use pooled variance;

* t-test p-value <.0001: Reject H0;
* Strong evidence to conclude that the two means are significantly different;

* c)-3. Is the mean moistness score different depending on cooking method?;
* H0: mu_boil = mu_steam = mu_mash = mu_bake@350F = mu_bake@450F
* vs H1: Not H0 (At least one pair has different means.);
* -> ANOVA;

* Check the normality;
proc univariate data=potato normal;
	class cooking;
	var moistness;
	histogram moistness;
	qqplot moistness;
run;

* Shapiro-Wilk p-value;
* (Boil) 0.1703 (Steam) 0.0638 (Mash) 0.1647 (Bake at 350F) 0.0938 (Bake at 450F) 0.8958;
* -> Normality assumption is appropriate;

* PROC ANOVA;
proc glm data=potato;
	class cooking;
	model moistness = cooking;
	means cooking / hovtest=bf dunnett("Boil"); 
	* Equality of variances (hovtest = BF);
	* Pairwise comparison("Boil" as reference);
run; quit;

* PROC GLM;
proc anova data=potato;
	class cooking;
	model moistness = cooking;
	means cooking / hovtest=bf dunnett("Boil");
	* Equality of variances (hovtest = BF);
	* Pairwise comparison("Boil" as reference);
run; quit;

* Equality of variances (BF test) p-value = 0.4106: Fail to reject H0;
* -> Assumption of equal variance is satisfied;

* ANOVA p-value = 0.0028: Reject H0;
* Depending on cooking method, the mean moistness score is significantly different;
* i.e. There exists at least one pair of methods with different mean moistness scores;

* Multiple comparison (Dunnett with "Boil" as reference);
* -> 'Mash' and 'Bake at 350F' were significant;




