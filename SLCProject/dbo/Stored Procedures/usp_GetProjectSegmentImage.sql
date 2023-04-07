CREATE PROCEDURE usp_GetProjectSegmentImage    
(  
	@SectionId INT  
)  
As    
BEGIN    
  
SET NOCOUNT ON;  
--FETCH REQUIRED IMAGES FROM DB    
SELECT    
   PSI.SegmentImageId,    
   IMG.ImageId,    
   IMG.ImagePath,    
   ISNULL(PSI.ImageStyle, '') AS ImageStyle    
FROM    
   ProjectSegmentImage PSI WITH (NOLOCK)    
   INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PSI.ImageId = IMG.ImageId    
WHERE    
   PSI.SectionId = @SectionId    
   AND IMG.LuImageSourceTypeId = 1    
    
END