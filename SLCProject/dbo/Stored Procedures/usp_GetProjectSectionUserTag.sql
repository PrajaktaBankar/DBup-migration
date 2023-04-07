CREATE PROC usp_GetProjectSectionUserTag
(  
@ProjectId INT = 0,    
@CustomerId INT = 0,    
@SectionId  INT = 0   
)    
AS BEGIN    
  
SET NOCOUNT ON;  
   --FETCH SEGMENT USER TAGS LIST    
SELECT    
   PSUT.SegmentUserTagId,    
   PSUT.SegmentStatusId,    
   PSUT.UserTagId,    
   PUT.TagType,    
   PUT.Description AS TagName    
FROM    
   ProjectSegmentUserTag PSUT WITH (NOLOCK)    
   INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId    
WHERE    
   PSUT.ProjectId = @ProjectId    
   AND PSUT.CustomerId = @CustomerId    
   AND PSUT.SectionId = @SectionId    
END