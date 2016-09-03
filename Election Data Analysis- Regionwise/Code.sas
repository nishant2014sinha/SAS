

/* Libref sasdata created -*/

filename elecdata 'D:\Study_material_MS_MIS\summer16\sas_data\election_hist.csv';

/*libref mylib created for following steps-*/

filename regdata 'D:\Study_material_MS_MIS\summer16\sas_data\region6.dat';

/*Step 2-Creating user defined formats for campaign type, party, and election status (results)*/
/*Dollar sign is used for char format eg. 'I'='Incumbent', char or numeric is decided by 'I' and not 
'Incumbent', incumbent is just a label , so therefore cmptype is a char with dollar sign*/
proc format ;
	value $cmptype 'I' = 'Incumbent'
				   'C' = 'Challenger'
				   'O' = 'Open Seat';
	 
	value partyfmt 1='Democratic'
				   2='Republican'
				   3='Other Party';
			       
	value $elecstatfmt 'W'='Won' 
					   'L'='Lost'
					   'R'='Runoff'
					   other ='N/A';
run;

/*Step 3- Creating two SAS datasets in the work library*/

data elections 
	 incomplete;

	 /*Defining the length of the variables*/
	 /*Note: The order of the variables defined in the length is how the order of variables will be in output
	 Because the length statement is compile time statement. */
	length Cand_ID $ 9 Cand_Name $ 38 Type $ 1 Party_Desig $ 3 State $ 2 District $ 2 Special_Stat $ 1 
		   Primary_Stat $ 1 Runoff_Stat $ 1 General_Stat $ 1 Year 4 Party 8 Receipts 8 Transfers_From 8 
           Disbursements 8 Transfers_To 8 Start_Cash 8 End_Cash 8 Cand_Contrib 8 Cand_Loans 8 Other_Loans 8
           Cand_Repay 8 Other_Repay 8 Debts 8 Ind_Contrib 8 General_Pct 8 Pol_Contrib 8 Party_Contrib 8 
		   End_Date 8 Ind_Refunds 8 Ctte_Refunds 8 months_since 8;
	/*Truncover option is used so that data is not skipped at EOF*/
	/*Skipping the first line in dataset as it contains headers- firstobs=2*/
	/*Date format of end date is informat, as we are telling sas how to read it*/
	/*':' is used with the informat as date is in non formatted form  */
	infile elecdata dsd Firstobs=2 TRUNCOVER;
	input  Year Cand_Id $ Cand_Name $ Type $ Party Party_Desig $ Receipts Transfers_From Disbursements  
		   Transfers_to Start_Cash End_Cash Cand_Contrib Cand_Loans Other_Loans Cand_Repay Other_Repay
		   Debts Ind_Contrib State $ District $ Special_Stat $ Primary_Stat $ Runoff_Stat $  
		   General_Stat $ General_Pct Pol_Contrib Party_Contrib End_Date :mmddyy10. Ind_Refunds Ctte_Refunds;

	/*Formatting the variables as per the output*/ 
	/*Again, here we use $ sign with general_stat special_stat etc. but not with party*/
	/*Party is to formatted into a partyfmt which is actually numeric but labelled into a char */
	format End_Date worddate12.
		   party partyfmt.	
		   General_Stat $elecstatfmt. 
		   Special_Stat $elecstatfmt. 
           Primary_Stat $elecstatfmt. 
           Runoff_Stat $elecstatfmt.
		   Type $cmptype.;
	If End_date ne . then 
		months_since= INTCK('month', End_Date, '01Aug2016'd);
	if _ERROR_=1 THEN OUTPUT incomplete;
	else OUTPUT elections;
run;

/*Step 4 - Readign region6.dat file */
/*Width of file calculated by opening the file in notepad++ and checking values of column at the bottom of it*/
/*'/' is used to change the pointer to next line and keeping a hold on the data read into input buffer */
/*Truncover option is used for. Forces the INPUT statement to stop reading when it gets to 
the end of a short line. This option will not skip information*/

data region;
	infile regdata truncover;
	length School $42. Street $30. Dist_Type $16. Address $40. Dist_ID $8. Phone $15.
		   County $20. Fax $20. Email $40. WebSite $40. city $20. state $2. zip $12.;
	input School $42. @43 Street $30. / @16 Dist_Type $16. @43 Address $40. / @16 Dist_ID $8. 
		  @50 Phone $15. / County $20. @48 Fax $20. / @43 Email $40. / @43 WebSite $40. ;

		/*breaking down Address into city , state and zip*/
	City= scan (Address, 1,',');
	Remaining = scan (Address, 2,',');
	State=scan (Remaining, 1,' ');
	Zip= scan (Remaining, 2,' ');
	drop Address Remaining; 
run;

/*Step 5-*/

filename otppdf 'D:\Study_material_MS_MIS\summer16\assignment\sas\asgn 11\nishant2014sinha_HW11_output.pdf';
/*pages in a landscape layout*/
/*Starting page number is 2 */
/*suupress printing of dates */
options orientation= landscape nodate pageno=2;
ods pdf file = otppdf;

/*Step 6- Print a sample of 15 records from the campaign year 2004*/
title1 "Federal Election Campaign Data";
title3 "Sample from the Year 2004";
proc print data = elections (obs=15) split='*';
	where year=2004;
	/*temporary label for the “months since” variable*/

	Label months_since='Months Since*End of*Campaign';
run;

/*Step 7- Proc univariate - to check extreme observations to check the data for candidate loans
and other loans*/
title3;
title2 'Analysis of Candidate and Other Loans';
proc univariate data= elections;
	var  Cand_Loans Other_Loans;
run;

/*Step 8-SUMMARY procedure to caluclate average candidate contribution and candidate loans grouped by Party variable*/
/*We have mentioned mean here in proc summary statement but this will only affect the output display of proc statment*/
/*In output data set i.e. elect_summary we will get complete summary(not just the mean)because the "mean" in proc
  statement affects only the proc and not the output data set
*/
/*To do so we have mentioned "mean" in the output statement */
title2;
title3 'Average Candidate Contributions and Loans by Political Party';
proc summary data = elections mean nonobs; 
	var Cand_Contrib Cand_Loans;
	class Party;
	/*When statistics are listed in the OUTPUT statement the structure of the output data set changes. */
	/*Example: output out=means1(drop=_type_ _freq_) n= min= max= mean= std= median= / autoname; */
	output out = elect_summary(Drop= _STAT_) MEAN=  ; 
	/*dropping _stat_ variable as per the required output*/
run;

/*Step 9- Print out the data portion of the summary data set*/
/*format for analysis variables to show them as currency with no decimal places - dollar8. */
proc print data = elect_summary  label;
	format Cand_Contrib dollar8. Cand_Loans dollar8.;
	label Cand_Contrib='avg_contrib' 
		  Cand_Loans='avg_loans';
run;

/*Step 10- Print out the number of schools in each county (frequency of counties)*/
/*option that will also print out the number of counties in the data.- Nlevels*/
title1 'Texas Education Agency Region VI';
title2 'Number of Counties and Schools in Each County';
proc freq data= region nlevels;
	tables County;
run;

/*Step 11- data portion of the Region6, Suppress the printing of observations.*/
/*date print at top of the page- date , dtreset*/
options date dtreset;
title2 'Listing of Schools and Contact Information';

proc print data = region noobs;
run;


/*Step 12-Housekeeping step to clear titles and footnotes */
title;
footnote;
ods pdf close;
