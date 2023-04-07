CREATE PROCEDURE [dbo].[usp_UpdateComment]  
(
 @CommentId INT,  
 @CommentDescription NVARCHAR(2000),
 @UserId INT
)  
AS  
BEGIN
 DECLARE @PCommentId INT = @CommentId;
 DECLARE @PCommentDescription NVARCHAR(2000) = @CommentDescription;
 DECLARE @PUserId INT = @UserId;


UPDATE SC
SET SC.CommentDescription = @PCommentDescription
   ,SC.ModifiedBy = @PUserId
   ,SC.ModifiedDate = GETUTCDATE()
FROM SegmentComment SC WITH (NOLOCK)
WHERE SC.SegmentCommentId = @PCommentId
AND CreatedBy = @PUserId

END