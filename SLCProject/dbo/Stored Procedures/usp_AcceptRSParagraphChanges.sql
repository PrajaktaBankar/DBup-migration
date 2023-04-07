CREATE PROC [dbo].[usp_AcceptRSParagraphChanges]
(
@SectionId 		 int,
@SegmentId 		 bigint,
@ProjectId 		 int,
@CustomerId 	 int,
@SegmentStatusId bigint,
@SegmentDescription nvarchar(max)=''

)
AS
BEGIN

UPDATE PS
SET PS.SegmentDescription = @SegmentDescription
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId = @SegmentId
AND PS.SectionId = @SectionId
AND PS.ProjectId = @ProjectId
AND PS.CustomerId = @CustomerId


END
GO


