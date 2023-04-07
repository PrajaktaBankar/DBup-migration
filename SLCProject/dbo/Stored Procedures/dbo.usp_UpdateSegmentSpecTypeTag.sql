CREATE PROCEDURE [dbo].[usp_UpdateSegmentSpecTypeTag]
@SegmentViewTagJson NVARCHAR (MAX) NULL  
AS    
BEGIN
DECLARE @PSegmentViewTagJson NVARCHAR(MAX) = @SegmentViewTagJson;
    
 DECLARE @SegmentViewTagTable TABLE(  
 SegmentStatusId BIGINT NULL, 
 SpecTypeTagId INT NULL
 );
INSERT INTO @SegmentViewTagTable (SegmentStatusId, SpecTypeTagId)
	SELECT
		SegmentStatusId
	   ,SpecTypeTagId
	FROM OPENJSON(@PSegmentViewTagJson)
	WITH (
	SegmentStatusId BIGINT '$.SegmentStatusId',
	SpecTypeTagId INT '$.SpecTypeTagId'
	);

UPDATE PSS
SET PSS.SpecTypeTagId = SVTT.SpecTypeTagId
FROM @SegmentViewTagTable SVTT
INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)
	ON SVTT.SegmentStatusId = PSS.SegmentStatusId;
	
END
GO


