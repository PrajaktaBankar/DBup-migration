CREATE PROCEDURE [dbo].[usp_GetGlobalTermsCount]   
 @CustomerId INT,             
 @ProjectId INT                
AS                
BEGIN

DECLARE  @PCustomerId INT = @CustomerId
DECLARE  @PProjectId INT = @ProjectId

SELECT DISTINCT
	COUNT(PGT.GlobalTermId) AS termsCount
FROM ProjectGlobalTerm PGT (NOLOCK)
INNER JOIN ProjectAddress PA (NOLOCK)
	ON PA.ProjectId = PGT.ProjectId
		AND PA.CustomerId = PGT.CustomerId
LEFT OUTER JOIN LuCity LC (NOLOCK)
	ON LC.CityId = PA.CityId
LEFT OUTER JOIN LuStateProvince LS (NOLOCK)
	ON LS.StateProvinceID = PA.StateProvinceId
WHERE PGT.ProjectId = @PProjectId
AND (PGT.CustomerId = @PCustomerId
AND (PGT.Name = 'Project Location State'
AND PGT.GlobalTermFieldTypeId <> 3)
OR (PGT.Name = 'Project Location Province'
AND PGT.GlobalTermFieldTypeId <> 3)
OR (PGT.Name = 'Project Location City'
AND PGT.GlobalTermFieldTypeId <> 3)
OR (PGT.Name = 'Specs Due Date'
AND PGT.GlobalTermFieldTypeId <> 2)
OR (PGT.Name = 'Contract Documents Due Date'
AND PGT.GlobalTermFieldTypeId <> 2)
OR (PGT.Name = 'Bid Date'
AND PGT.GlobalTermFieldTypeId <> 2)
OR (PGT.Name = 'Project Completion Date'
AND PGT.GlobalTermFieldTypeId <> 2))

END


GO
