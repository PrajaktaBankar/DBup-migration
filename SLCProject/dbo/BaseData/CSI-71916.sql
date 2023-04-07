--Execute this on Server 5
--Customer Support 71916: Restored Project shows divisions out of order - 73937/4484
--Record will be affected 1401

DROP TABLE IF EXISTS  #TempSortOrderResult;

SELECT
(ROW_NUMBER() OVER (ORDER BY SourceTag,Author)-1) AS SortOrderId, 
SectionId,
ProjectId,
CustomerId
INTO #TempSortOrderResult
FROM ProjectSection WITH (NOLOCK)
WHERE ProjectId = 8830 AND CustomerId = 4484  
ORDER BY SourceTag,Author

UPDATE PS
SET SortOrder = T.SortOrderId
FROM #TempSortOrderResult T INNER JOIN
ProjectSection  PS WITH (NOLOCK)
ON PS.SectionId = T.SectionId
AND PS.ProjectId = T.ProjectId
AND PS.CustomerId = T.CustomerId 

