Use SLCProject
GO

DROP TABLE IF EXISTS #ProjectList;
SELECT (ROW_NUMBER() OVER (ORDER BY ProjectId)) As RowId
,ProjectId,CustomerId 
INTO #ProjectList 
FROM Project WITH (NOLOCK);

DECLARE @i int =1, @Count int = (select COUNT(1) FROM #ProjectList);

WHILE @i <= @Count
begin

print @i;

Declare @ProjectId int =0;
Declare @CustomerId int =0;

SELECT @ProjectId = ProjectId
	  ,@CustomerId = CustomerId
 FROM #ProjectList
WHERE RowId = @i;

DROP TABLE IF EXISTS  #t;

SELECT
 (ROW_NUMBER() OVER (ORDER BY SourceTag,Author)-1) AS SortOrderId, SectionId
 , ProjectId,CustomerId
 INTO #t
FROM ProjectSection WITH (NOLOCK)
WHERE ProjectId=@ProjectId AND CustomerId = @CustomerId  
ORDER BY SourceTag,Author

update PS
SET SortOrder = T.SortOrderId
FROM #t T INNER JOIN
ProjectSection  PS WITH (NOLOCK)
ON PS.SectionId = T.SectionId
AND PS.ProjectId= T.ProjectId
AND PS.CustomerId = T.CustomerId

UPDATE PS
SET
SourceTag ='20'
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @ProjectId AND PS.CustomerId = @CustomerId
AND PS.SourceTag='200'

set @i = @i + 1;
End;
