CREATE PROC [dbo].[usp_DeleteComment]  
(
 @CommentId INT,
 @UserId INT
)  
AS  
BEGIN
  DECLARE @PCommentId INT = @CommentId;
  DECLARE @PUserId INT = @UserId;

UPDATE SC
SET SC.IsDeleted = 1
FROM SegmentComment SC WITH (NOLOCK)
WHERE SC.SegmentCommentId = @PCommentId
OR SC.ParentCommentId = @PCommentId
AND CreatedBy = @PUserId

SELECT
	SC.IsDeleted
FROM SegmentComment SC WITH (NOLOCK)
WHERE SC.SegmentCommentId = @PCommentId
AND CreatedBy = @PUserId

END