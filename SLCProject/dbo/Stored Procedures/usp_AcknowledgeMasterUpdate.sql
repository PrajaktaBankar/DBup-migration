CREATE PROCEDURE [dbo].[usp_AcknowledgeMasterUpdate]
(
  @SegmentStatusId BIGINT
)
AS
BEGIN
	DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;

	UPDATE PSS
	SET PSS.MTrackDescription = NULL
	FROM ProjectSegmentStatus PSS WITH(NOLOCK)
	WHERE PSS.SegmentStatusId = @PSegmentStatusId
END
GO


