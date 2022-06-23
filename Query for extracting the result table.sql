
--Querying and restructuring data for final analysis--
use [Data visualization_CompanyFinance]

--Declare varables for dynamically adjusting the range of years used for analysis --
declare @targetYears table (Years int)
insert into @targetYears values (2015), (2016), (2017), (2018), (2019);

declare @NumberOfYears int
SET @NumberOfYears = 5;

--Extract the Companies having completed data within the year range--
With ABC as 
(select [Company ID], 
		count([Company ID]) as 'Count'
from [Company financial report data_V3]
where [year] in (select * from @targetYears)
group by [Company ID]
having count([Company ID]) = @NumberOfYears),

--Extract data under the abovementioned Companies within the year range--
DEF as
(select *
from [Company financial report data_V3]
where [Company ID] in (select [Company ID] from ABC)
	  and [Year] in (select * from @targetYears)
ORDER BY [Company ID],[Year] OFFSET 0 ROWS),

--Add columns for displaying companies net income and total revenue from the previous year --
G as
(select a.[Company ID],
	   a.[Year],
	   a.[Net Income],
	   a.[Total Revenue],
	   CASE
		WHEN a.[Year] = (select min([Years]) from @targetYears) THEN a.[Net income]
		ELSE x.[Net income]
		END as Previous_Year_Income, 
	   CASE
		WHEN a.[Year] = (select min([Years]) from @targetYears) THEN a.[Total Revenue]
		ELSE x.[Total Revenue]
		END as Previous_Year_TolRevenue
from DEF a
outer apply(select * from DEF b where a.[Company ID] = b.[Company ID] and a.[Year] -1 = b.[Year]) x),

/*Add a boolean column for each of the criterias to determine whether there is an increase compared with the previous years. In addition, using "Sum" 
  function for determining if all criterias increase constantly within the year range. Return the companies' ID having such performance.*/
select distinct [Company ID], CountForIncrese_netIncome, CountForIncrese_TolRevenue
into CompanyInGdPerformance
from G T1
cross apply(select 
				sum(case when [Net Income] - [Previous_Year_Income] >0 then 1 else 0 end) as CountForIncrese_netIncome,
				sum(case when [Total Revenue] - [Previous_Year_TolRevenue] >0 then 1 else 0 end) as CountForIncrese_TolRevenue
			from G T2
			where T1.[Company ID] = T2.[Company ID]
			group by T2.[Company ID]) x
where CountForIncrese_netIncome = @NumberOfYears -1 and CountForIncrese_TolRevenue = @NumberOfYears -1

--Return the % increase of net income and total revenue from the start to the end of the year range for those companies--
H as
(select distinct [Company ID],
	   [% increase in Net Income],
	   [% increase in Total Revenue]
from DEF T1
cross apply(select
				(max([Net Income]) - min([Net Income]))/abs(min([Net Income])) as '% increase in Net Income',
				(max([Total Revenue]) - min([Total Revenue]))/abs(min([Total Revenue])) as '% increase in Total Revenue'
			from DEF T2
			where T1.[Company ID] = T2.[Company ID]and [Company ID] in (select [Company ID] from CompanyInGdPerformance)
			group by [Company ID]) x)

--Match the name for those companies, and rearrange the companies by % increase of net income in descending order--
select T2.[Name], T1.*
into [Final output_]
from H T1
left join [Company Info_20220531] T2
on T1.[Company ID] = T2.[Company ID]
order by [% increase in Net Income] desc


