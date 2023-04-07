USE [SLCProject_SqlSlcOp004]
GO

DROP TABLE IF EXISTS #TempOptionJson
DROP TABLE IF EXISTS #jsonValue

DECLARE @ProjectId INT =  15344
--DECLARE @SectionId INT = 18760553
DECLARE @OptionJsonTable TABLE  
	(  
	rowNo int,  
	SegmentStatusId int,  
	SegmentChoiceId INT,  
	OptionJson NVARCHAR(MAX)
	);

INSERT INTO @OptionJsonTable (rowNo, SegmentStatusId, SegmentChoiceId,OptionJson)
Select
	ROW_NUMBER() OVER (ORDER BY PSC.SectionId) AS rowNo,
 PSC.SegmentStatusId,
 PSC.SegmentChoiceId,
 PCO.OptionJson
--,PSC.SectionId 
 From ProjectSegmentChoice PSC  WITH(NOLOCK)
INNER JOIN ProjectChoiceOption PCO WITH(NOLOCK)
ON PSC.SegmentChoiceId = PCO.SegmentChoiceId
Where PSC.ProjectId = @ProjectId
--AND PSC.SectionId = @SectionId
AND PCO.optionJson LIKE '_{"OptionTypeId":3,"OptionTypeName":"SectionID",%"Id":0,%' 
AND PCO.optionJson not like '%"Value":"-",%'
AND PCO.OptionJson NOT LIKE '%- Concrete Trenchways%'
AND PSC.ChoiceTypeId = 1 AND ISNULL(PSC.IsDeleted,0) = 0


SELECT rowNo,SegmentChoiceId,SegmentStatusId,OptionJson, c.value into #jsonValue FROM @OptionJsonTable j
CROSS APPLY OPENJSON (j.OptionJson) WITH
(
 value nvarchar(8) '$.Value' 
) c 

--Select * from #jsonValue


DECLARE @count INT;
SET @count = 1;
DECLARE @TotalCount INT = (SELECT count(*) FROM #jsonValue)
DECLARE @sourcetag VARCHAR(10) =''
DECLARE @str NVARCHAR(MAX) ;
DECLARe @CalculatedSectionId INT 
DECLARE @OptionJson NVARCHAR(MAX);


WHILE @count<= @TotalCount
BEGIN

    SET @sourcetag = (Select REPLACE(REPLACE([value],' ',''),'.','') From	#jsonValue WHERE rowNo = @count)
	
   SET @CalculatedSectionId = (Select top 1 SectionCode From ProjectSection WITH(NOLOCK) Where ProjectId = @ProjectId AND SourceTag = @sourcetag and ISNULL(IsDeleted,0)=0);
   IF( @CalculatedSectionId != '')
   BEGIN
	     --SET @OptionJson = (Select REPLACE(OptionJson,'"Id":0','"Id":'+CONVERT(VARCHAR(12), @CalculatedSectionId) +'') From #jsonValue Where rowNo = @count )
		 UPDATE #jsonValue SET OptionJson = REPLACE(OptionJson,'"Id":0','"Id":'+CONVERT(VARCHAR(12), @CalculatedSectionId) +',"IncludeSectionTitle":true')
		 From #jsonValue Where rowNo = @count 
   END

   SET @count = @count + 1;
END;

UPDATE PCO SET PCO.OptionJson = jv.OptionJson
 FROM ProjectChoiceOption PCO WITH(NOLOCK) 
INNER JOIN  #jsonValue jv ON PCO.SegmentChoiceId = jv.SegmentChoiceId
WHERE PCO.ProjectId = @ProjectId 
--and PCO.SectionId = @SectionId
