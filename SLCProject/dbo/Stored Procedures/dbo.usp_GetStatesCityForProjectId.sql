CREATE PROCEDURE [dbo].[usp_GetStatesCityForProjectId]     
@ProjectId INT 
AS    
BEGIN
DECLARE @PProjectId INT = @ProjectId;

DECLARE @CountryId INT = 0;
DECLARE @StateProvinceId INT = 0;
DECLARE @CityId INT = 0;

SELECT
	@CountryId = CountryId
   ,@StateProvinceId = StateProvinceId
   ,@CityId = CityId
FROM ProjectAddress WITH (NOLOCK)
WHERE ProjectId = @PProjectId

SELECT
	StateProvinceID
   ,StateProvinceName
FROM LuStateProvince WITH (NOLOCK)
WHERE StateProvinceId = @StateProvinceId
SELECT
	CityId
   ,City
FROM LuCity WITH (NOLOCK)
WHERE CityId = @CityId

SELECT
	StateProvinceID
   ,CountryID
   ,StateProvinceAbbreviation
   ,StateProvinceName
FROM LuStateProvince WITH (NOLOCK)
WHERE CountryID = @CountryId
SELECT
	CityId
   ,City
   ,StateProvinceId
FROM LuCity WITH (NOLOCK)
WHERE StateProvinceId = @StateProvinceId

END

GO
