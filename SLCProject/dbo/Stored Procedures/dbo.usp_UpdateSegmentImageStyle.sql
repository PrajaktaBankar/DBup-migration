CREATE PROCEDURE [dbo].[usp_UpdateSegmentImageStyle]
(  
 @SegmentImageId INT,  
 @ImageStyle NVARCHAR(200)
) 
AS  
BEGIN  
	DECLARE @PSegmentImageId INT = @SegmentImageId;  
	DECLARE @PImageStyle NVARCHAR(200) = @ImageStyle;
  
	UPDATE PSI  
	SET PSI.ImageStyle = @PImageStyle
	FROM ProjectSegmentImage PSI WITH (NOLOCK)  
	WHERE PSI.SegmentImageId = @PSegmentImageId

END