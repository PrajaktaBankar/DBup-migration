USE [SLCProject_SqlSlcOp004]
GO
DECLARE @SegmentBtagTable TABLE  
	(  
	rowNo int,  
	SegmentId int,  
	SegmentStatusId INT,  
	SectionId INT,
	ProjectId int,
	CustomerId INT,
	SegmentDescription varchar(max),
	IsDeleted bit
	);
				
INSERT INTO @SegmentBtagTable (rowNo, SegmentId, SegmentStatusId, SectionId,ProjectId,CustomerId,SegmentDescription,IsDeleted)
	SELECT
	ROW_NUMBER() OVER (ORDER BY PS.SegmentId) AS rowNo
	,PS.SegmentId
	,PS.SegmentStatusId
	,PS.SectionId
	,PS.ProjectId
	,PS.CustomerId
	,PS.SegmentDescription
	,PS.IsDeleted
	FROM ProjectSegment PS WITH(NOLOCK)
	WHERE SectionId=23262648
    AND ProjectId = 18689 
    AND ISNULL(IsDeleted,0)=0
    AND SegmentDescription 
    LIKE '%<b style%' 


DECLARE @count INT;
SET @count = 1;
DECLARE @TotalCount INT = (SELECT count(*) FROM @SegmentBtagTable)
DECLARE @Descr VARCHAR(MAX) =''
    
WHILE @count<= @TotalCount
BEGIN
   PRINT @count
   SET @Descr = (Select SegmentDescription From	@SegmentBtagTable WHERE rowNo = @count)
   UPDATE @SegmentBtagTable  
   SET SegmentDescription = REPLACE(REPLACE(REPLACE(SegmentDescription, '<b style="mso-bidi-font-weight:normal;">',''), '</b>', ''),'<b style="mso-bidi-font-weight:  normal;">','')
   WHERE rowNo = @count

   SET @count = @count + 1;
END;

UPDATE PS SET PS.SegmentDescription =
temp.SegmentDescription
 FROM ProjectSegment PS 
INNER JOIN  @SegmentBtagTable  temp
ON PS.SegmentId = temp.SegmentId

