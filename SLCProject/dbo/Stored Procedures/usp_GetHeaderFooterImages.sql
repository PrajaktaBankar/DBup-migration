CREATE PROCEDURE [dbo].[usp_GetHeaderFooterImages]      
(      
 @CustomerId INT,      
 @ProjectId INT      
)      
AS      
BEGIN      
 DECLARE @PCustomerId INT = @CustomerId;      
 DECLARE @PProjectId INT = @ProjectId;     
 DECLARE @PImageSourceTypeId INT = 3;  
      
 SELECT      
  PSI.SegmentImageId    
 ,PIM.ImageId    
 ,PIM.ImagePath AS [Name]    
 ,PSI.ImageStyle    
 FROM ProjectImage PIM WITH (NOLOCK)      
 INNER JOIN ProjectSegmentImage PSI WITH (NOLOCK)      
 ON PIM.ImageId = PSI.ImageId      
 WHERE PSI.CustomerId = @PCustomerId      
 AND PSI.ProjectId = @PProjectId      
 AND PIM.LuImageSourceTypeId=@PImageSourceTypeId  
      
END  
  