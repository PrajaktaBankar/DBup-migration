CREATE PROCEDURE [dbo].[usp_ResolveComment]  
(  
	@CommentId INT,
	@CommentStatusId INT,
	@UserId INT
)  
AS  
BEGIN

 DECLARE @PSegmentCommentId INT = @CommentId;
 DECLARE @PStatusId INT = @CommentStatusId;
 DECLARE @PCreatedById INT = @UserId;

UPDATE SC
SET CommentStatusId = @PStatusId
   ,ModifiedBy = @UserId
   ,ModifiedDate = GETUTCDATE()
FROM SegmentComment SC WITH (NOLOCK)
WHERE CreatedBy = @PCreatedById
AND SC.SegmentCommentId = @PSegmentCommentId

END