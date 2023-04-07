
DROP TABLE IF EXISTS #ProjectIdsOfCustomer

SELECT
	ProjectId
   ,ROW_NUMBER() OVER (ORDER BY CustomerId) AS rowno INTO #ProjectIdsOfCustomer
FROM Project WITH(NOLOCK)
WHERE CustomerId = 783
 DECLARE @rowcount int=( SELECT
		COUNT(ProjectId)
	FROM #ProjectIdsOfCustomer)
 WHILE (@rowcount>0)
 begin
DECLARE @ProjectId int=( SELECT
		ProjectId
	FROM #ProjectIdsOfCustomer
	WHERE rowno = @rowcount)
PRINT @ProjectId

DELETE X
FROM (SELECT
		ROW_NUMBER() OVER (PARTITION BY Name ORDER BY GlobalTermId DESC) AS rowid
	   ,*
	FROM ProjectGlobalTerm 
	WHERE ProjectId = @ProjectId) AS X
WHERE X.rowid > 1

SET @rowcount = @rowcount - 1;
 END