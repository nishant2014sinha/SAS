

/*Step 2 Libref sasdata created with readonly access-
*/

libname sasdata 'D:\Study_material_MS_MIS\summer16\sas_data' access= readonly;

/*Step 3 libref mylib created for following steps-
*/

libname MYLIB 'D:\Study_material_MS_MIS\summer16\sas_datasets';

/*Step 4- output file pdf 
*/

filename otppdf 'D:\Study_material_MS_MIS\summer16\assignment\sas\asgn 7\nishant2014sinha_HW07_output.pdf';
ods pdf file = otppdf bookmarkgen=yes bookmarklist=hide;

/*Step 5- creating the data step 
*/
data MYLIB.TEXAS_HS;
set sasdata.tx_schools;
 where  (FR >0 | SO >0| JR>0 | SR>0);
    
DROP state type level F16 F17;

    enrollment= sum(FR,SO,JR,SR);
    Load_Date= today();
	Format load_date mmddyy10. ;

	LABEL fte_teachers='Teachers (FTE)'
          ptr='Student/Teacher Ratio'
          control='School Type'
          gr8='Eighth Graders'
          fr='Freshmen'
          so='Sophomores'
          jr='Juniors'
          sr='Seniors'
          enrollment='HS Enrollment'
          load_date='Load Date';
    
run;


/*Step 6* - Print the descriptor portion of your new data set*/

proc contents data= MYLIB.TEXAS_HS;
run;

/*Step 7- Print the first 9 observations of Texas_HS*/

proc print data = MYLIB.TEXAS_HS (obs=9) label;
run;

/*Step 8- Creating the data set Academy excluding ACADEMY H S in Bell County*/

data ACADEMY;
	SET MYLIB.TEXAS_HS;
	KEEP School Enrollment Control County;
	Where (School contains "ACADEMY"); 
    IF (School IN('ACADEMY H S') & County  IN ('BELL COUNTY') )  THEN DELETE;
    
run;

/*Step 9- Print the data portion of the academy*/

proc print data = ACADEMY label;
	var school enrollment control county;
run;

/*Step 10- Creating a data set where the number of senior is more than 25% of enrollment
but eliminate those schools where all of the enrollment is made up of seniors.*/

data sr25;
	SET MYLIB.TEXAS_HS;
	Keep school county gr8 fr so jr sr enrollment;
	where (sr>(0.25*enrollment));
	if (sr EQ enrollment) THEN DELETE ;
RUN;


/*Step 11- Print the data portion of sr25*/
PROC PRINT DATA = sr25 NOOBS LABEL;
var SCHOOL ENROLLMENT SR JR SO FR GR8 COUNTY;
run;

/*Step 12- creating 3 data sets OneA TAPS1 Align16*/
data OneA (DROP = control fte_teachers ptr division)
	 TAPS1 (DROP = control fte_teachers ptr county division)
	 Align16 (DROP = control fte_teachers ptr);
	 
	SET MYLIB.TEXAS_HS;

    WHERE (FR >0 & SO >0 & JR >0 &  SR>0);
    
	length division $ 7;
    IF (upcase(control = "Public")) then DO;
		   	IF (enrollment<105) then
				division= '1A';
			ELSE IF  (105<=enrollment<=219) then
				division= '2A';
			ELSE IF  (220<=enrollment<=464) then
				division= '3A';
			ELSE IF (465<=enrollment<=1059) then
				division= '4A';
    		ELSE IF  (1060<=enrollment<=2099) then
				division= '5A';
			ELSE IF (enrollment => 2100) then
				division= '6A';

    END;

	ELSE IF (upcase(control = "Private")) then DO;
		   IF  (enrollment <=55) THEN 
				division= 'TAPS1'; 
		   ELSE IF (enrollment =>111) then 
				division= 'TAPS3';
		   ELSE IF (56<=enrollment<=110) THEN
				division= 'TAPS2';

    END;
	
    
	Output Align16;

	IF division= '1A' THEN OUTPUT OneA;
	
	IF division= 'TAPS1' THEN OUTPUT TAPS1;
	
RUN;


/* Step 13 - create a temporary data set named GradeCount, variables: School,
Division, Grade and Students, Create 2 variables grade and students. 
Grade = Freshman or Sophomore or Junior or  Eight or Senior 
Students = count of Freshman or Sophomore or Junior or  Eight gradres or Senior
*/
data GradeCount;
	set Align16;
Keep School Division Grade students;
length grade $10;
if (gr8>0) then do;
	grade = 'Eighth';
	Students=gr8;
	output;
end;
if fr>0 then do;
	grade = 'Freshman';
	Students=fr;
	output;
end;
if so>0 then do;
	grade = 'Sophomore';
	Students=so;
	output;
end;
if jr>0 then do;
	grade = 'Junior';
	Students=jr;
	output;
end;
if sr>0 then do;
	grade = 'Senior';
	Students=sr;
	output;
end;

run;

/* Step 14* - show the contents of the work library without displaying the
descriptor portion of each dataset*/
proc datasets lib=work; 
run;

/*Step 15 - Print 50 observations from Align16 beginning with B F TERRY HS*/
proc print data= Align16 (FIRSTOBS=96 OBS=146) noobs label;
run;

/* Step 16 - Print last 30 observations of the data set OneA*/
proc print data=OneA (FIRSTOBS=454 OBS=483) Noobs label; 
run;

/* Step 17 - Print the TAPS1 data set*/
proc print data= TAPS1 label;
run;


/* Step 18 - Print the first 38 observations from the GradeCount*/

proc print data= GradeCount (obs=38) label;
run;

/* Step 19* - print a report based on the
GradeCount data set*/

proc tabulate data=gradecount;
class division grade;
var students;
table grade='Grade', division*students=' '*sum=' '*f=comma7.;
run;

ods pdf close;





   
