--Company Financial Report Data (Child Table) --


--0/Null value checking in column "Net Income" and "Total Revenue"--
use [Data visualization_CompanyFinance]

SELECT count(*) as 'Result'
  FROM [Data visualization_CompanyFinance].[dbo].[Company financial report data]
  where [Net Income] is null or 
		[Total Revenue] is null or
		[Net Income] = 0 or
		[Total Revenue] = 0

--Remove all rows under the Company ID which contains 0/null value in columns "Net Income" and "Total Revenue" in any year--
select *
into [Data visualization_CompanyFinance].[dbo].[Company financial report data_V2]
from [Data visualization_CompanyFinance].[dbo].[Company financial report data]
where [Company ID] not in (SELECT distinct [Company ID]
						FROM [Data visualization_CompanyFinance].[dbo].[Company financial report data]
						where [Total Revenue] is null or 
							  [Net Income] is null or
							  [Net Income] = 0 or
							  [Total Revenue] = 0)

--Check for any record entered repeatedly entered for the same Company ID and Year--
with abc as
(select *,
ROW_NUMBER() OVER (PARTITION BY [Company ID], [Year] ORDER BY [Company ID]) AS count_for_duplicate
FROM [Company financial report data_V2]),

--Return the Company ID having repeated records--
ID_with_duplicate as
(select distinct [Company ID]
from abc
where count_for_duplicate >1)

--Remove all rows under the Company ID having reepeated records--
select *
into [Company financial report data_V3]
from [Company financial report data_V2]
where [Company ID] not in (select * from ID_with_duplicate)


--Company Data (Parent Table)--

--Check for the uniqueness of Company ID and Company Name in the parent table--

SELECT [Company ID], COUNT([Company ID])
FROM [Company Info_20220531]
GROUP BY [Company ID]
having COUNT([Company ID]) > 1

SELECT [Name], COUNT([Name])
FROM [Company Info_20220531]
GROUP BY [Name]
having COUNT([Name]) > 1

/*Referential integrity between Company Id (From child table) and Company Name (From parent table)*/
select a.*, b.[Name]
from [Company financial report data_V3] a
left join [Company Info_20220531] b
on a.[Company ID] = b.[Company ID]
where b.[Name] is null

