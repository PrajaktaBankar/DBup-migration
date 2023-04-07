CREATE PROC [dbo].[usp_AddComment]      
(      
 @ProjectId INT,      
 @SectionId INT,      
 @SegmentStatusId BIGINT,      
 @ParentCommentId INT=null,      
 @CustomerId INT,      
 @UserId INT,      
 @UserFullName nvarchar(200)='Unknown User',    
 @CommentDescription NVARCHAR(2000)      
)      
AS      
BEGIN  
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
 DECLARE @PParentCommentId INT = @ParentCommentId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PUserFullName nvarchar(200) = @UserFullName;
 DECLARE @PCommentDescription NVARCHAR(2000) = @CommentDescription;

INSERT INTO SegmentComment (ProjectId, SectionId, SegmentStatusId  
, ParentCommentId, CommentDescription, CustomerId, CreatedBy  
, CreateDate, ModifiedBy, ModifiedDate, CommentStatusId, IsDeleted, UserFullName)  
 VALUES (@PProjectId, @PSectionId, @PSegmentStatusId, @PParentCommentId, @PCommentDescription, @PCustomerId, @PUserId, GETUTCDATE(), @PUserId, GETUTCDATE(), 1, 0, @PUserFullName)  
  
DECLARE @COMMENTID INT = SCOPE_IDENTITY()  
  
SELECT  
 SegmentCommentId  
   ,ProjectId  
   ,SectionId  
   ,SegmentStatusId  
   ,ParentCommentId  
   ,CommentDescription  
   ,CustomerId  
   ,CreatedBy  
   ,CreateDate  
   ,ModifiedBy  
   ,ModifiedDate  
   ,CommentStatusId  
   ,IsDeleted  
   ,UserFullName  
   ,'' AS CommentStatusDescription  
FROM SegmentComment WITH (NOLOCK)  
WHERE SegmentCommentId = @COMMENTID  
END
GO


