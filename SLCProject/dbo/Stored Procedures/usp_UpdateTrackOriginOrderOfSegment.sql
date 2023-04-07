CREATE PROCEDURE [dbo].[usp_UpdateTrackOriginOrderOfSegment] 
	@ProjectId INT, @CustomerId INT, @SectionId INT, @SegmentStatusId BIGINT, @TrackOriginOrder NVARCHAR(2) = NULL
AS  
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
DECLARE @PTrackOriginOrder NVARCHAR(2) = IIF(@TrackOriginOrder = '', NULL, @TrackOriginOrder);

UPDATE PSST
SET PSST.TrackOriginOrder = @PTrackOriginOrder 
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SegmentStatusId = @PSegmentStatusId;
END
GO


