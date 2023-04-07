CREATE PROCEDURE [dbo].[usp_UpdateProjectNote]      
 @SectionId INT,  
 @SegmentStatusId BIGINT,    
 @NoteText NVARCHAR(MAX),    
 @Title  NVARCHAR(500) ,  
 @ProjectId INT=5683,    
 @CustomerId INT=2,    
 @CreatedBy INT ,    
 @ModifiedUserName NVARCHAR(500),   
 @NoteId INT     
    
  AS  
BEGIN  
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
 DECLARE @PNoteText NVARCHAR(MAX) = @NoteText;
 DECLARE @PTitle  NVARCHAR(500) = @Title;
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PCreatedBy INT = @CreatedBy;
 DECLARE @PModifiedUserName NVARCHAR(500) = @ModifiedUserName;
 DECLARE @PNoteId INT = @NoteId;

Update PN SET PN.NoteText=@PNoteText,  
PN.Title=@PTitle ,  
ModifiedDate=GETUTCDATE(),  
ModifiedBy=@PCreatedBy,  
ModifiedUserName=@PModifiedUserName  
from ProjectNote PN  with (nolock) 
WHERE PN.NoteId=@PNoteId
  
select   
NoteId,  
Title,  
NoteText,  
SegmentStatusId,  
CreateDate,  
ModifiedDate,  
CreatedUserName,  
ModifiedUserName,  
'U' AS NoteType ,  
'U' AS Source 
FROM ProjectNote with (nolock)  WHERE
NoteId=@PNoteId 
  
END
GO


