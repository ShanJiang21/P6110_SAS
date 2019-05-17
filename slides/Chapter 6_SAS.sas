
*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Chapter 6: SAS Reporting              *
* Jihui Lee (Columbia University)       *
*****************************************;

/* 6.1. PROC TABULATE */

* Import the dataset;
data blood;
	infile "C:\Users\Jihui\Desktop\P6110\SAS\Chapter 6\blood.txt";
	input obs Gender $ Type $ Agegroup $ wbc rbc chol;
	label wbc = "White blood cell"
		  rbc = "Red blood cell"
		  chol = "Cholesterol";
run;

proc print data=blood (obs=5) label;run;

* Categorical variable: Default statistics is N;

* 1-dimensional table;
proc tabulate data=blood;
	class Gender;
	table Gender;
run;

proc freq data=blood;
	table Gender / nopercent nocum;
run;

* 2-dimensional table;
proc tabulate data=blood;
	class Gender Type;
	table Gender, Type;
run;

proc freq data=blood;
	table Gender * Type / nocol norow nopercent;
run;

* 3-dimensional table;
proc tabulate data=blood;
	class Agegroup Gender Type;
	table Gender, Agegroup, Type;
run;

proc freq data=blood;
	tables Gender * Agegroup * Type / nocol norow nopercent;
run;

*Keyword ALL (Total);
proc tabulate data=blood;
	class Gender Type;
	table Gender, Type ALL;
run;

proc tabulate data=blood;
	class Gender Type;
	table Gender ALL, Type ALL;
run;

* Continuous variable: Default statistics is SUM;
proc tabulate data=blood;
	var wbc rbc;
	table wbc rbc;
run;

* Compute the mean;
proc tabulate data=blood;
   var wbc rbc;
   table mean*wbc rbc*mean;
run;

proc tabulate data=blood;
   var wbc rbc;
   table (mean stddev)*(wbc rbc);
run;

proc tabulate data=blood;
   var wbc rbc;
   table (wbc rbc)*(mean stddev);
run;

* Concatenating;
proc tabulate data=blood;
	class Gender Type;
	table Gender Type All;
run;

* Crossing;
proc tabulate data=blood;
	class Gender Type;
	var wbc;
	table Gender All, mean*wbc*(Type All)*f=7.1;
run;

* Crossing, grouping, and concatenating;


* Compute mean, min, max;
proc tabulate data=blood format=comma9.2;
	var rbc wbc;
	table rbc*(mean min max) wbc*min;
run;

proc tabulate data=blood format=comma9.2;
	class Gender;
	var rbc wbc;
	table Gender All, rbc*(mean min max) wbc*min;
run;

* Combine categorical and continuous variables in a table;
proc tabulate data=blood format=comma11.2;
	class Gender AgeGroup;
	var rbc wbc chol; 
	table (Gender='abc' ALL)*(AgeGroup = "" All), mean*(rbc wbc chol); 
   * Display the mean (rbc, wbc, chol) for gender by agegroup;
run;

* Formats and labels;
proc tabulate data=blood;
	class Gender;
	var rbc wbc;
	table Gender="" ALL, rbc*(mean*f=9.3 std*f=9.4) wbc*(mean*f=comma9. std*f=comma9.1);
	keylabel ALL  = "Total"
			 mean = "Average"
			 std  = "Standard Deviation";
run;

* Picture format: Print values as a format of xxx.xx%;
proc format;
   picture pctfmt low-high="000.00%";
run;

proc tabulate data=blood;
	class Type;
	table (Type ALL)*(n*f=5. pctn*f=pctfmt.);
	keylabel n = "Count"
			 pctn = "Percentage";	
run;

* Column Percentage;
proc tabulate data=blood;
	class Gender Type;
	table (Type="" ALL="All Blood Types"),
		  (Gender ALL)*(n*f=5. colpctn*f=pctfmt.) 
		  / box="Blood type by gender";
	keylabel All = "Both Genders"
			 n = "Count"
			 colpctn = "Col Percent";
run;

* Customizing your table;
proc tabulate data=blood format=comma9.2;
	class Gender AgeGroup;
	var rbc wbc Chol;
	table (Gender=' ' ALL)*(AgeGroup=' ' All),
		  rbc*(n mean*f=5.1)
		  wbc*(n*f=3. mean*f=comma7.)
		  chol*(n*f=4. mean*f=7.1);
   keylabel ALL = 'Total';
run;

/* 6.2. PROC REPORT */

* Dataset: National parks and monuments in the USA;
data park;
	input Name $21. Type $ Region $ Museums Campings;
	datalines;
Dinosaur              NM West 2 6
Ellis Island          NM East 1 0
Everglades            NP East 5 2
Grand Canyon          NP West 5 3
Great Smoky Mountains NP East 3 10
Hawaii Volcanoes      NP West 2 2
Lava Beds             NM West 1 1
Statue of Liberty     NM East 1 0
Theodore Roosevelt    NP .    2 2
Yellowstone           NP West 2 11
Yosemite              NP West 2 13
;
run;

proc print data=park;run;

* Define a format;
proc format;
	value $typefmt NM = "National monument"
				   NP = "National park";
run;

data park;
	set park;
	format type $typefmt.;
run;

proc print data=park;run;

* PROC REPORT without specifying COLUMN (windows);
proc report data=park windows headline split='' ;
run;

* PROC REPORT without specifying COLUMN (nowindows);
proc report data=park nowindows;
run;

* PROC REPORT with character variable;
proc report data=park nowindows;
	column Type Region; 
run;

* PROC REPORT with only numeric variables;
proc report data=park nowindows;
	column Museums Campings;
run;

* WHERE;
proc report data=park nowindows;
	column Museums Campings;
	where Type = "NM";
run;

proc print data=park;
	where Type = "NM"; 
run;

* If?;
proc report data=park nowindows;
	column Museums Campings;
	if Type = "NM";
run;

* ORDER;
proc report data=park nowindows;
	column Region Name Museums Campings;
	define Region / order;
run;

* ACROSS & GROUP;
proc report data=park nowindows;
	column Region Type Museums Campings;
	define Region / group;
	define Type / across;
	* ACROSS: Produce sum/frequency of each value for the variable (column);
	* GROUP: Create one row for each unique value of the variable (row);
run;

* Across;
proc report data=park nowindows;
	column Region Type Museums Campings;
	define Region / across;
	define Type / across;
run;

* FYI;
proc tabulate data=park format=2.;
	class Type Region;
	var Museums Campings;
	table Region Type Museums Campings;
run;

* Group;
proc report data=park nowindows;
	column Region Type Museums Campings;
	define Type / group;
	define Region / group;
run;

* FYI;
proc tabulate data=park format=2.;
	class Type Region;
	var Museums Campings;
	table Region*Type, Museums Campings;
run;

* Use of ', ()';
proc report data=park nowindows;
	column Region Type , (Museums Campings);
	define Region / group;
	define Type / across;
run;

* FYI;
proc tabulate data=park;
	class Type Region;
	var Museums Campings;
	table Region, Type * (Museums Campings);
run;

* MISSING;
proc report data=park nowindows missing;
	column Region Type Museums Campings;
	define Region / group;
	define Type / across;
run;

* FYI;
proc tabulate data=park missing;
	class Type Region;
	var Museums Campings;
	table Region, Type Museums Campings;
run;


* DEFINE options;
proc report data=park nowindows;
	column Type museums=m_sum museums=m_sum2 
			museums=m_mean museums=m_min museums=m_max;
	define Type / group 'Type: park or monument'; 
	define m_sum / analysis 'Total number of museums' right;
	define m_sum2 / 'Total number of museums2' left;
	define m_mean / mean 'Mean number of museums';
	define m_min / min 'Minimum number of museums';
	define m_max / max 'Maximum number of museums';
run;

* (R)BREAK options;
proc report data=park nowindows;
	column Name Region Museums=museums_mean Campings;
	define Region / order;
	define museums_mean / mean 'Mean number of museums' format=4.2;

* BREAK: Produce summary stats each time value of group/order variable changes;
	break after Region / summarize;
	rbreak after / summarize;
run;

* Windows;
proc report data=park windows;
	column Name Region Museums=museums_mean Campings;
	define Region / order;
	define museums_mean / mean 'Mean number of museums' format=4.2;

	break after Region / ol summarize skip;
	rbreak after / summarize;
run;

* OL/DOL : Single/Double line;
* SKIP: Print a blank line after the summary;


* Adding statistics;

* Produce N for each Region x Type category and MEAN;
proc report data=park nowindows;
	column Region Type N (Museums Campings),mean;
	define Region / group;
	define Type / group;
run;

* FYI1;
proc report data=park nowindows;
	column Region Type N Museums Campings;
	define Region / group;
	define Type / group;
	define Museums / mean;
	define Campings / mean;
run;

* FYI2;
proc tabulate data=park format = 5.2;
	class Region Type;
	var Museums Campings;
	table Region * Type, (museums campings)* mean;
run;

* Produce N for each Region and MEAN for each Region x Type category;
proc report data=park nowindows;
	column Region N Type,(Museums Campings),mean;
	define Region / group;
	define Type / across;
run;

* Produce N for each Region and MEAN and STD for each Region x Type category;
proc report data=park nowindows;
	column Region N Type, (Museums Campings),mean Type, (Museums Campings),std;
	define Region / group;
	define Type / across;
run;

* Produce N for each Region and MEAN and STD for each Region x Type category;
proc report data=park nowindows;
	column Region N Type, (Museums Campings),(mean std);
	define Region / group;
	define Type / across;
run;

* Compute variables;
proc report data=park nowindows;
	column Name Region Museums Campings Facilities Note;
*	define Museums / analysis sum noprint;
*	define Campings / analysis sum noprint;
	define Facilities / computed "Campings/and/Museums";
	define Note / computed;

	compute Facilities;
		Facilities = Museums.sum + Campings.sum;
	endcomp;

	compute Note / char length=10; * Length: 1-200 (Default is 8.);
		if campings.sum=0 then Note ="No Camping";
	endcomp;
run;


/* 6.3. Write a Simple Report */

data _NULL_;
	set park;

	Total = Museums + Campings;
	
	file "C:\Users\Jihui\Desktop\P6110\SAS\Chapter 6\Report.txt" print;
	title "National parks and monuments in the USA";

	put @5 Name "is a " Type "in " Region "region."
		/ @5 "The number of Museums in " Name "is " Museums ","
		/ @3 "and the number of camp grounds in " Name "is " Campings "."
		/ @5 "That is, there are " Total "facilities in " Name "." //;

	PUT _PAGE_;
run;
