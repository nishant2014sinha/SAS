
libname okschl 'D:\Study_material_MS_MIS\summer16\sas_data' access= readonly;
libname MYLIB 'D:\Study_material_MS_MIS\summer16\sas_datasets';

/*Step 2- */

data MYLIB.OK_CLEAN ;
	set okschl.ok_schools( rename =(County=COUNTYOKH grade8=chG8 grade9=chG9 grade10=chG10 grade11=chG11 grade12=chG12));	

	/*Step 2a- remove the word COUNTY from each value*/
	length county $ 12; /*reduce the length of the County variable by 7*/
	County = Tranwrd(CountyOKH, ' COUNTY', '');
	Label county='County';

	/*Step 2b- Convert the Grade8-Grade12 variables from char to numeric using SELECT */

		SELECT;
			when (chg8 = 'n/a' or chg8 ='*') Grade8=.;
			otherwise Grade8=input(chg8,comma6.);
		end;
		SELECT;
			when (chg9 = 'n/a' or chg9 ='*') Grade9=.;
			otherwise Grade9=input(chg9,comma6.);
		end;
		SELECT;
			when (chg10 = 'n/a' or chg10 ='*') Grade10=.;
			otherwise Grade10=input(chg10,comma6.);
			
		end;
		SELECT;
			when (chg11= 'n/a' or chg11 ='*') Grade11=.;
			otherwise Grade11=input(chg11,comma6.);
		end;
		SELECT;
			when  (chg12 = 'n/a' or chg12 ='*') Grade12=.;
			otherwise Grade12=input(chg12,comma6.);
		end;
	

	/*Step 2c- Correcting the misspelled names of the city  */

	select (city);
		when ('CHUOTEAU') city= 'CHOUTEAU';
		when ('OKC') city ='OKLAHOMA CITY';
		when ('JENKS') city ='TULSA';
		when ('MUSKOGE') city ='MUSKOGEE';
		when ('RUSHSPRINGS')city = 'RUSH SPRINGS';
		when ('SEMIONOLE')city ='SEMINOLE';
		when ('COFFEYVILLE') city = 'SOUTH COFFEYVILLE';
		when ('WOOWARD') city = 'WOODWARD';
		otherwise;
	end;

	/*Step 2d- If the county is ALFALFA, set the city to CHEROKEE */
	
if county='ALFALFA' then city='CHEROKEE';
drop CountyOKH chG8 chG9 chG10 chG11 chG12;
run;

/*Step 3- Summarizing Data */



/*Step 3a-  Sorting the clean data*/

proc sort data =MYLIB.OK_CLEAN;
	by City;
run;

/*Step 3b- removing the grades variable  */
data CITYSTATS (DROP= grade: school);
	set MYLIB.OK_CLEAN ;
	by city;

/*Summary statements to accumulate the total number of students in each grade*/
	length cty8 cty9 cty10 cty11 cty12 8.;
	length hs_now HS_next Change 8.;
	LABEL cty8='Eighth Graders' 
		  cty9= 'Freshmen'
		  cty10='Sophomores'
		  cty11='Juniors'
		  cty12='Seniors'
		  hs_now='Current Enrollment'
		  HS_next='Projected Enrollment';
	format change percent8.1;

	if first.city then do;
		cty8=0;cty9=0;cty10=0;cty11=0;cty12=0;
	end;
	cty8+grade8;
	cty9+grade9;
	cty10+grade10;
	cty11+grade11;
	cty12+grade12;
	
	if last.city THEN DO;

	/*Current Enrollment or hs_now - sum of grades 9 through 12 for each city.*/

	hs_now= sum(of cty9-cty12);

	/*Projected Enrollment that is a sum of grades 8 through 11 */

	HS_next=sum(of cty8-cty11); 

	/* Variable Change that is the percentage change of the projected enrollment compared to the current enrollment*/
	if (hs_now>0) then change=(HS_next-hs_now)/hs_now;
	
	if (cty8>0 & cty9>0 & cty10>0 & cty11>0 & cty12>0)then output;

run;
/*Step 4- output file pdf 
*/
filename otppdf 'D:\Study_material_MS_MIS\summer16\assignment\sas\assgn 8\nishant2014sinha_HW08_output.pdf';
ods pdf file = otppdf bookmarkgen=no;

/*Step 5- Print the descriptor and data portions of both data sets created in previous steps*/


PROC CONTENTS DATA =MYLIB.OK_CLEAN;
RUN;

proc print data =MYLIB.OK_CLEAN   label;
	var City School County Grade8 Grade9 Grade10 Grade11 Grade12;
run;
proc contents data =CITYSTATS;
run;

proc print data =CITYSTATS  label;
	VAR CITY COUNTY cty8 cty9 cty10 cty11 cty12 hs_now hs_next change ;
run;

/*Step 6- Closing the pdf file*/
ods pdf close;

