CREATE PROCEDURE [dbo].[usp_UpdateProjectSegment]            
 @SegmentId  BIGINT,       
 @SegmentDescription NVARCHAR(MAX)
AS        
BEGIN
 DECLARE @PSegmentId  BIGINT = @SegmentId;
 DECLARE @PSegmentDescription NVARCHAR(MAX) = @SegmentDescription;
UPDATE PS
SET PS.SegmentDescription = @PSegmentDescription
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId = @PSegmentId
END
GO


