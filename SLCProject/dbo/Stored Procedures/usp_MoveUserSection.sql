CREATE PROCEDURE [dbo].[usp_MoveUserSection]      
(      
 @ProjectId INT,      
 @CustomerId INT,    
 @UserId INT,     
 @SectionId INT,    
 @ParentSectionId INT,    
 @SourceTag  VARCHAR(18)    
)      
AS      
BEGIN              
    
/*    
  changed for Bug https://bsdsoftlink.visualstudio.com/SLE-Web/_workitems/edit/67874/    
      */    
DECLARE @Author NVARCHAR(1000);       

SELECT @Author = Author, @SourceTag = SourceTag FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId=@ProjectId;     
-- Get the NewSortorder for moved Section        
DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@ProjectId, @CustomerId, @ParentSectionId, @SourceTag, @Author);        
        
UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS         
WITH(NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND SortOrder = @SortOrder;        
        

UPDATE  PS    
SET PS.ParentSectionId=@ParentSectionId 
,PS.SortOrder = @SortOrder   
FROM ProjectSection PS WITH(NOLOCK)   
WHERE PS.SectionId=@SectionId and     
PS.projectId=@ProjectId and PS.CustomerId=@CustomerId  
    
Execute [dbo].usp_SetDivisionIdForUserSection @ProjectId,@SectionId,@CustomerId    
    
SELECT @SectionId as SectionId    
    
END 