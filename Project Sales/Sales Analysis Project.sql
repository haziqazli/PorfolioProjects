--Inspecting Data
select *
from [dbo].[sales_data_sample]

-- Indentify unit value in data
select distinct STATUS from [dbo].[sales_data_sample]  --- plot
select distinct PRODUCTLINE from [dbo].[sales_data_sample] --- plot
select distinct COUNTRY from [dbo].[sales_data_sample] --- plot
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct DEALSIZE from [dbo].[sales_data_sample]--- plot
select distinct TERRITORY from [dbo].[sales_data_sample]--- plot

-- Analysis

-- 1) Identify sales for productline (Grouping sale with productline)
SELECT PRODUCTLINE, SUM (SALES) REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC 

--2) DEALSIZE that has highest sales (REVENUE)
SELECT DEALSIZE, SUM (SALES) REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY 2 DESC


-- 3) Year that has highest sales (REVENUE)
SELECT YEAR_ID, SUM (SALES) REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY 2 DESC 

--- why does year 2005 has lowest sale?

SELECT DISTINCT MONTH_ID
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2005

SELECT DISTINCT MONTH_ID
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004
ORDER BY MONTH_ID

SELECT DISTINCT MONTH_ID
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003
ORDER BY MONTH_ID

-- 4) Which month has highest Item Sales ?
SELECT MONTH_ID, SUM (SALES) REVENUE , COUNT (ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
GROUP BY MONTH_ID
ORDER BY 2 DESC 

-- 5) Month with highest Item Sales & order according to each year

--- 2003
SELECT MONTH_ID, SUM (SALES) REVENUE , COUNT (ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC  

--- 2004
SELECT MONTH_ID, SUM (SALES) REVENUE , COUNT (ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC

--for 2005, the data shows does not fully reflect on sale because only have 5 months
--- 2005
SELECT MONTH_ID, SUM (SALES) REVENUE , COUNT (ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID
ORDER BY 2 DESC

-- it shows that Month = 11 has the highest sales

-- 6) identify what type of Item 

--- 2003
SELECT MONTH_ID, PRODUCTLINE, SUM (SALES) REVENUE , COUNT (ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

--- 2004
SELECT MONTH_ID, PRODUCTLINE, SUM (SALES) REVENUE , COUNT (ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


-- 7) Identify Loyal Customer 
--- Using RFM Method

DROP TABLE IF EXISTS #RFM

;with rfm as
(
SELECT 
	CUSTOMERNAME,
	SUM(SALES) Monetary,
	COUNT(ORDERNUMBER) Frequency,
	MAX(ORDERDATE) last_order_date,
	(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) max_order_date,
	DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) Recency
FROM [dbo].[sales_data_sample]
GROUP BY CUSTOMERNAME
),
rfm_calc as
(
	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency desc) R,
		NTILE(4) OVER (ORDER BY Frequency) F,
		NTILE(4) OVER (ORDER BY Monetary) M
	from rfm r

)
SELECT c.* , R + F + M as RFM_Cell,
CAST(R as varchar) + CAST(F as varchar) + CAST(M as varchar) RFM_Cell_String
INTO #RFM
from rfm_calc c

SELECT *
FROM #RFM

SELECT CUSTOMERNAME , R , F, M,
	CASE
		WHEN RFM_Cell_String IN (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'Lost Customer'
		WHEN RFM_Cell_String IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'Slipping Away'
		WHEN RFM_Cell_String IN (311, 411, 331) THEN 'New Customer'
		WHEN RFM_Cell_String IN (222, 223, 233, 322) THEN 'Potential Lost Customer'
		WHEN RFM_Cell_String IN (323, 333, 321, 422, 332, 432) THEN 'Active'
		WHEN RFM_Cell_String IN (433, 434, 443, 444) THEN 'Loyal'
	END RFM_Segment

FROM #RFM

-- 8) What product are most often sold together?

SELECT DISTINCT ORDERNUMBER, STUFF(

	(SELECT ',' + PRODUCTCODE
	FROM [dbo].[sales_data_sample] p
	WHERE ORDERNUMBER IN 
		(

			SELECT ORDERNUMBER
			FROM(
				SELECT ORDERNUMBER, COUNT(*) rn
				FROM [dbo].[sales_data_sample]
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
			)m
			WHERE rn = 3
		)
		AND p.ORDERNUMBER = s.ORDERNUMBER
		FOR XML PATH (''))
		, 1, 1, '') Product_Code

FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC
