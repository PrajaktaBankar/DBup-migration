CREATE PROCEDURE [dbo].[usp_GetCityState]  
(  
 @projectId nvarchar(max)  
)  
AS  
BEGIN  
DECLARE @PprojectId nvarchar(max) = @projectId;
Select Distinct top 50 CityId, City ,StateProvinceId from LuCity  with (nolock)
 order by StateProvinceId
 
END



GO
