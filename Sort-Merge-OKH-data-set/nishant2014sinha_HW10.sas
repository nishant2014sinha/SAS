

/* Libref sasdata created with readonly access-*/

libname hwdata 'D:\Study_material_MS_MIS\summer16\sas_data' access= readonly;

/*libref mylib created for following steps-*/

libname mylib 'D:\Study_material_MS_MIS\summer16\sas_datasets';
/* keeping a seperate copies of data set to work on it*/
data mid;
	set hwdata.ok_mid;
run;

data high;
	set hwdata.ok_high;
run;

/*sorting the copies of the data set by  mapcity school*/
proc sort data = mid;
	by  mapcity school;
run;

proc sort data = high;
	by  mapcity school;
run;


/*Step 2- Using a single merge step, created three data sets */
data MATCHED_SCHOOLS(Drop= Ungraded--HSTotal i MI: HS:) 
	 HIGH_NOMATCH (KEEP= school MapCity MailCity County) 
	 MID_NOMATCH  (KEEP= school MapCity MailCity County);
	merge mid(in=mi rename= (grade7-grade12=MIgd7-MIgd12 PTRATIO=MI_PTR) DROP= Teachers) 
			/*dropping variables - teachers, renaming NUMERIC VARS -grades, PTRATIO*/
		 high(in=hi rename= (grade7-grade12=HSgd7-Hsgd12 PTRATIO=HS_PTR) DROP= Teachers);
		 	/*dropping variables - teachers, renaming NUMERIC VARS -grades, PTRATIO*/
	by mapcity school ;
	/* Creating 3 array vars and 2 variables Teachers and students*/
	length Teachers 8. Students 8.;
	array contrib1{*} MIgd:;
	array contrib2{*} HSgd:;
	array contrib3{*} Grade7-Grade12;
	/*Formating ptr as per the dedired output*/
	format Combined_PTR 8.2;
	/*Initialzing teachers to zero for every itiration of data step*/
	teachers=0 ;
	/* Only For matched output, we compute grades 7-12 , sum of teachers, sum of students and PTR*/
	IF (MI=1 AND HI= 1) THEN DO;
		do i=1 to DIM(contrib1);
			/* Sum of each grade in both the data sets, example: sum of grade 7 of mid schools and 
				sum of grade 7 of high schools and so on */
			contrib3{i}=  SUM (contrib1{i},contrib2{i});
			/* Running Sum of teachers for each school for all the grades 7-12 */
			/* Sum is calculated inly when the value on the grade is >0 */
			if (contrib1{i} ne . and contrib1{i} ne 0 )  then 
				 teachers + (contrib1{i}/MI_PTR);
			if (contrib2{i} ne . and contrib2{i} ne 0) then
				 teachers +(contrib2{i}/HS_PTR);
		end;

		/*Rounding off the value to highest integer*/
		teachers= CEIL(teachers);
		/*total number of students in grades 7 through 12 in each school, */
		students= SUM(OF Grade:);
		/*Pupil/Teacher ratio using the total number of students divided by Teachers*/
		
		if (teachers ne . and teachers ne 0) then 
			Combined_PTR= Students/teachers;
		/**/
		output MATCHED_SCHOOLS ;
	END;
	/*Creating a temporary data set of High Schools with no matching record in ok_mid */
	if HI=1 and MI= 0 THEN  OUTPUT HIGH_NOMATCH; 
	/*Create a temporary data set of Middle Schools with no matching record in ok_high*/
	If HI=0 and MI= 1 THEN  OUTPUT MID_NOMATCH;

run;


/*Step 3- Output is printed with a landscape layout, date/time resets to the current time
		  Suppressing the printing of page numbers on the page.*/


/*output file pdf */

filename otppdf 'D:\Study_material_MS_MIS\summer16\assignment\sas\asgn 10\nishant2014sinha_HW10_output.pdf';
options orientation= landscape nonumber dtreset;
ods pdf file = otppdf;

/*Step 4- Order of the observations in the “Matched Schools”
data set (from step 2a) by descending Pupil/Teacher Ratio and descending number of Student*/

PROC SORT DATA= MATCHED_SCHOOLS ;  
	BY descending Combined_PTR descending students;
RUN;

/*Step 5- Printing the “top 20” schools based on highest PTR.*/

PROC PRINT DATA = MATCHED_SCHOOLS (obs=20) split='*' noobs;
	
	title1 "Oklahoma Public Schools";
	/*there is a blank line between the two titles, Therefore title2 is not mentioned*/
	title3 "Twenty Schools with Highest Pupil/Teacher Ratios";
	footnote1 "Source: National Center for Education Statistics (nces.ed.gov)";
	/*temporary labels to match the eCampus output*/
	label Combined_PTR='Pupil/Teacher*Ratio' 
		  mapcity='City';/*MapCity as the City variable*/
	var School Mapcity County Teachers Students Combined_PTR;

RUN;

/*Step 6- Suppressing the printing of the date and time on the remaining pages- nodate
		  Suppressing footnote on the remaining pages.*/
options orientation= landscape nonumber nodate;
footnote;

/*Step 7- print a frequency count, in order of freq */

proc freq data= MATCHED_SCHOOLS order = freq;
 	tables county/ nocum;
 	title1 "Oklahoma Public Schools";
 	title2 "Number of Schools by County";
run;



/*Step 8- MEANS procedure to reproduce the report beginning on the sixth page of output as given*/

options pageno=6;
/*Analysis statistics are only carried out to two decimal places, maxdec=2*/
proc means data = MATCHED_SCHOOLS mean median Q1 Q3 maxdec=2;
	var Combined_PTR;
	class county;
	title1 "Oklahoma Public Schools";
	/*there is a blank line between the two titles, Therefore title2 is not mentioned*/
	title3 "Analysis of Pupil/Teacher Ratio by County";

run;

/*Step 9-TABULATE procedure to create the report*/
/*report beginning on the sixth page of output as given*/

options pageno=10;
proc tabulate DATA= MATCHED_SCHOOLS ;
	class county;
	var Combined_PTR;
	/*Adding a line showing overall statistics, County all*/
	table County all, Combined_PTR*(N mean Median Q1 Q3);
run;

/*Step 10- Print the descriptor portion of all data sets in the WORK library.*/

proc contents data= work. _all_;
	title1 "Description of Data Sets in the Work Library";
run;

ods pdf close;


