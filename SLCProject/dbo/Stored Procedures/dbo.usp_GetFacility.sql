CREATE PROCEDURE [dbo].[usp_GetFacility]  
AS  
BEGIN  
SELECT FacilityTypeId,Name,Description,IsActive,SortOrder FROM LuFacilityType  with (nolock)
End


GO
