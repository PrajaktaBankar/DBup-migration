CREATE PROC [dbo].[usp_GetAllChildSegments]
(
@SegmentStatusString NVARCHAR(MAX) 
)
AS
BEGIN
  
DECLARE @TempSegment AS Table(ParentSegmentStatusId BIGINT)
INSERT INTO @TempSegment(ParentSegmentStatusId)
SELECT 
    value AS ParentSegmentStatusId 
FROM 
    STRING_SPLIT(@SegmentStatusString, ','); 

 SELECT PSS.SegmentStatusId,TS.ParentSegmentStatusId,SegmentStatusTypeId FROM ProjectSegmentStatus  PSS WITH (NOLOCK)
 INNER JOIN @TempSegment TS ON PSS.ParentSegmentStatusId =TS.ParentSegmentStatusId
 INNER JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK) ON
 PSS.SegmentStatusId=PSRT.SegmentStatusId
 WHERE
  PSS.SegmentStatusTypeId<6
 AND ISNULL(PSS.IsDeleted,0)=0
 AND(PSRT.RequirementTagId=22 OR  PSRT.RequirementTagId=24)
END
GO


