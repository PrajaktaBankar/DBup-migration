CREATE PROCEDURE [dbo].[usp_GetSegmentImages]  
--EXEC [usp_GetSegmentImages] 3652016, 2398, 3009
(  
 @SectionId INT,  
 @CustomerId INT,  
 @ProjectId INT  
)  
AS  
BEGIN  
	DECLARE @PSectionId INT = @SectionId;  
	DECLARE @PCustomerId INT = @CustomerId;  
	DECLARE @PProjectId INT = @ProjectId;  
  
	SELECT  
	 PSI.SegmentImageId
	,PIM.ImageId
	,PIM.ImagePath AS [Name]
	,PSI.ImageStyle
	FROM ProjectImage PIM WITH (NOLOCK)  
	INNER JOIN ProjectSegmentImage PSI WITH (NOLOCK)  
	ON PIM.ImageId = PSI.ImageId  
	WHERE PSI.SectionId = @PSectionId  
	AND PSI.CustomerId = @PCustomerId  
	AND PSI.ProjectId = @PProjectId  
  
END;
