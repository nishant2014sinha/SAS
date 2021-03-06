
libname hwdata 'D:\Study_material_MS_MIS\summer16\sas_data' access= readonly;
libname mylib 'D:\Study_material_MS_MIS\summer16\sas_datasets';
filename otppdf 'D:\Study_material_MS_MIS\summer16\assignment\sas\asgn 9\nishant2014sinha_HW09_output.pdf';
ods pdf file = otppdf bookmarkgen=yes;

/*Step 2-Rotating the sas dataset to create a narrow data set*/ 
data mylib.employee;
/*keeping variables required */
set hwdata.fixerup_2016 (keep= Employee_ID charity:);

/*keeping variables for the correct output*/
	keep i Organization Employee_ID;
	drop charity:;
	array contrib{*} charity:;
	do i=1 to dim(contrib);
		IF (contrib{i} ne '')THEN DO;
			Organization=contrib{i};
			output;
		END;
	END;
run;


/*Step 3- Sorting the new data set,mylib.employee, by organization*/
proc sort data = mylib.employee;
	by organization;
run;

/*Step 4- Creating a copy of charities data set for merging steps*/
data charitycp;
	set hwdata.charities;
run;
/*Sorting charitycp by organization. */
proc sort data = charitycp;
	by organization;
run;

/*Step 5- Merging the datasets created in step4 and step2*/

/*Both the data set needs to be merged by one or more column vairable*/


data mrgempcht;
	merge mylib.employee(in=emp) charitycp(in=cht);
	by Organization;
	drop org_id;
/*no charities are included in the data when there have been no 
contributions made to that organization.*/
	if (emp=1 and cht=1);
run;



/*Step 6- Transposing the datasets by employee id created in step5*/
/*Keping only the category and removing the rest of the columns*/

proc sort data=mrgempcht;
	by employee_id i;
run;

proc transpose 
		data = mrgempcht
		out = mrgtrans(drop= _name_ _label_)
		prefix=Donee_Type;
		by employee_id;
		var category;
run;

proc print data = mrgtrans;
run;

/*Step 7- match merge original fixerup_2016 and dataset created in step 6*/

data WORK.GIVING_ANALYSIS;
	merge hwdata.fixerup_2016 mrgtrans;
	by employee_id;
	DROP i;
	Label env_amt='Environment Amount'
		  relief_amt='Relief Amount'
		  total='Total Contributions'
		  gift_pct='% of Salary Given';
	FORMAT gift_pct PERCENT8.1;
	LENGTH total env_amt relief_amt 8;
/* 4 new variables*/
/*env_amt: contains the amount the employee contributed to Environment charities
  relief_amt: for the total the employee donated to Relief organizations. 
  total: that contains the total amount the employee donated to all charities. 
  gift_pct: that shows the percentage of the employee’s salary that was contributed
*/
	total=0;env_amt=0; relief_amt=0;
	array amt{*} amount:;
	array orgtype{*} $ Donee_Type:;
	DO i= 1 to dim(orgtype);
		
		if (orgtype{i} ne '') then 
			total +amt{i};
		If (upcase(orgtype{i}) eq 'ENVIRONMENT') then 
			env_amt+amt{i};
		If (upcase(orgtype{i}) eq 'RELIEF') then 
			relief_amt+amt{i}; 
		
	END;

	gift_pct= (TOTAL/SALARY);

	output;
run;

/*Step 8- Printing the descriptor and  data portion of the final data set*/
/*suppress the printing of observation numbers*/

proc contents data= GIVING_ANALYSIS;
run;

proc print data= GIVING_ANALYSIS NOOBS LABEL;
VAR employee_id Name department salary env_amt relief_amt total gift_pct ;
run;

/*Step 9 - Pdf close*/
ods pdf close;
