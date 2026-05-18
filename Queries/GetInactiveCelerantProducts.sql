-- Returns inactive products. Inactive is any product with STATUS_FINISH = 'Y', or:
-- 1. Product is Active
-- 2. Quantity On Hand is 0 (summed from all stores)
-- 3. Quantity On Order is 0
-- 4. Last Sold date is at least 1 year ago
-- 5. Last Received date is at least 1 year ago
SELECT	tickets.STYLE_ID,
		tickets.BRAND, 
		tickets.STYLE, 
		tickets.DESCRIPTION, 
		tickets.DEPT, 
		tickets.TYP, 
		tickets.SUBTYP_1,
		tickets.OF1 AS [Season],
		SUM(buckets.QOH) AS [QOH], 
		MAX(buckets.LAST_SOLD) AS [Last Sold], 
		MAX(buckets.LAST_RCVD) AS [Last Received],
		styles.DATE_ENTERED AS [Created],
		styles.STATUS_FINISH AS [Inactive]
FROM VW_TICKETS tickets
INNER JOIN TB_SKU_BUCKETS buckets
ON buckets.SKU_ID = tickets.SKU_ID
AND buckets.STORE_ID = tickets.STORE_ID
INNER JOIN TB_STYLES styles
ON styles.STYLE_ID = tickets.STYLE_ID
GROUP BY tickets.STYLE_ID, tickets.BRAND, tickets.STYLE, tickets.DESCRIPTION, tickets.DEPT, tickets.TYP, tickets.SUBTYP_1, tickets.OF1, styles.DATE_ENTERED, styles.STATUS_FINISH
HAVING SUM(buckets.QOH) = 0 
   AND SUM(buckets.QOO) = 0 
   AND (MAX(buckets.LAST_SOLD) IS NULL OR MAX(buckets.LAST_SOLD)  <= DATEADD(year, -1, GETDATE())) 
   AND (MAX(buckets.LAST_RCVD) IS NULL OR MAX(buckets.LAST_RCVD)  <= DATEADD(year, -1, GETDATE()))
ORDER BY tickets.BRAND, tickets.OF1, [Last Sold] ASC;