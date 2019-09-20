
*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Chapter 11: Exporting Datasets        *
* Jihui Lee (Columbia University)       *
*****************************************;

data example; 
	input A B C D E; 
	datalines; 
	1 . 1 0 1 
	0 . . 1 1 
	1 1 0 1 . 
	; 
run; 

/* 11.1. PROC EXPORT */

* CSV;
proc export data=example 
			outfile="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 11\example.csv"
			dbms= csv replace;
run;

* xlsx;
proc export data=example 
			outfile="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 11\example.xlsx"
			dbms= xlsx replace;
			sheet= "sheetname";
run;

* TXT;
proc export data=example 
			outfile="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 11\example.txt"
			dbms=tab replace;
*			delimiter="&";
run;

/* 11.2. Export Using ODS */

* CSV; * ODS print with the obs,and there is no . in the new csv.; 
ods csv file="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 11\example2.csv";
proc print data=example; run;
ods csv close;

* HTML;
ods html file="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 11\example2.html";
proc print data=example; run;
ods html close;

* XLS;
ods html file="C:\Users\Jihui\Desktop\P6110\SAS\Chapter 11\example2.xls";
proc print data=example; run;
ods html close;
