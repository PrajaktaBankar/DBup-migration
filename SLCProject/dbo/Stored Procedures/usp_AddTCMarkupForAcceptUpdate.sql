CREATE PROCEDURE [dbo].[usp_AddTCMarkupForAcceptUpdate]  
(  
  @SegmentStatusId BIGINT,  
  @SegmentDescription NVARCHAR(MAX)  
)  
AS  
BEGIN  
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;  
  
 UPDATE PSS  
 SET PSS.MTrackDescription = @SegmentDescription  
 FROM ProjectSegmentStatus PSS WITH(NOLOCK)
 WHERE PSS.SegmentStatusId = @PSegmentStatusId AND PSS.SegmentSource ='M' AND PSS.SegmentOrigin = 'M'  
END
GO


