CREATE PROCEDURE [dbo].[usp_GetFacilities]  
(  
@Id INT =0  
)  
AS  
BEGIN
  
  DECLARE @PId INT = @Id;
 
IF(@PId>0)
SELECT
	FacilityTypeId,Name,Description,IsActive,SortOrder
FROM LuFacilityType WITH (NOLOCK)
WHERE FacilityTypeId = @PId
ORDER BY NAME
ELSE
SELECT
	FacilityTypeId,Name,Description,IsActive,SortOrder
FROM LuFacilityType WITH (NOLOCK)
ORDER BY NAME
END

GO
