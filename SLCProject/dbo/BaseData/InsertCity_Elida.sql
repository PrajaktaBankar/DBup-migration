Use SLCProject
GO

DECLARE @CountryId INT = (Select CountryId from LuCountry where Countryname like '%United States%')
DECLARE @StateProvinceID INT = (select StateProvinceID from [dbo].[LuStateProvince] where countryId=@CountryId and stateProvinceName like '%Ohio%')

IF NOT EXISTS (select * from Lucity where StateProvinceId=@StateProvinceID and City like '%Elida%')
BEGIN
	        INSERT INTO LuCity VALUES('Elida',@StateProvinceID)
END

