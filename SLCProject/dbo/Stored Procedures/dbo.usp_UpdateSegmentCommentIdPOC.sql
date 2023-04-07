CREATE PROCEDURE [dbo].[usp_UpdateSegmentCommentIdPOC]            
 @SectionId  INT, 
 @SegmentId BIGINT,      
 @Author VARCHAR(MAX),
 @Reference varchar(max),
 @CommentText varchar(max) 
AS        
BEGIN
 UPDATE  C      
 SET C.SegmentId=@SegmentId  
 FROM Comments C WITH (NOLOCK)
 WHERE C.SectionId=@SectionId
 AND C.Author=@Author
 AND C.ReferenceText=@Reference
 AND C.CommentText= @CommentText
END
GO


