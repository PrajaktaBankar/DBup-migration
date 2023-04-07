CREATE PROCEDURE [dbo].[usp_SetDeleteFlagForSegmentComments]  
(  
 @SegmentStatusId BIGINT,  
 @IsDeleted bit,
 @PrevSegmentStatusId BIGINT   --This is for future implementations
)    
AS    
BEGIN
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
 DECLARE @PIsDeleted bit = @IsDeleted;
 DECLARE @PPrevSegmentStatusId BIGINT = @PrevSegmentStatusId;

UPDATE SC
SET SC.IsDeleted = @PIsDeleted
FROM SegmentComment SC WITH (NOLOCK)
WHERE SC.SegmentStatusId = @PSegmentStatusId

SELECT DISTINCT
	IsDeleted
FROM SegmentComment WITH (NOLOCK)
WHERE SegmentStatusId = @PSegmentStatusId
END
GO


