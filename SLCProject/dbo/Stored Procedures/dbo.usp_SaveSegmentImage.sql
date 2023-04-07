CREATE PROCEDURE [dbo].[usp_SaveSegmentImage]  
(  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@SegmentId BIGINT NULL,  
@SectionId INT NULL,  
@ImageId INT NULL,  
@ImageStyle NVARCHAR(200)=NULL
)  
AS  
BEGIN
  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSegmentId BIGINT = @SegmentId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PImageId INT = @ImageId;
DECLARE @PImageStyle NVARCHAR(200) = @ImageStyle;


INSERT INTO ProjectSegmentImage (ProjectId, CustomerId, SegmentId, SectionId, ImageId,ImageStyle)
	VALUES (@PProjectId, @PCustomerId, @PSegmentId, @PSectionId, @PImageId,@PImageStyle)

SELECT
	SegmentImageId
FROM ProjectSegmentImage WITH (NOLOCK)
WHERE SegmentImageId = SCOPE_IDENTITY();

END
GO


