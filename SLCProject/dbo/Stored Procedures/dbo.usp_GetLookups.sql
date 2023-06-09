CREATE PROCEDURE [dbo].[usp_GetLookups]         
@CountryId INT NULL=NULL, @StateProvinceId INT NULL=NULL, @opr VARCHAR (2) NULL=NULL          
AS          
BEGIN
        
  DECLARE @PCountryId INT = @CountryId;
        
  DECLARE @PStateProvinceId INT = @StateProvinceId;
        
  DECLARE @Popr VARCHAR (2) = @opr;
        
        
    IF (upper(@Popr) = 'CN')          
        BEGIN
SELECT
	x.CountryId
   ,x.CountryName
   ,x.CountryCode
   ,x.CurrencyName
   ,x.CurrencyDigitalCode
   ,x.CurrencyAbbreviation
   ,x.CurrencySymbol
   ,x.DisplayOrder
FROM (SELECT
		c.CountryId
	   ,c.CountryName
	   ,c.CountryCode
	   ,CASE
			WHEN c.CountryId IN (42, 239) THEN 'A'
			ELSE c.CountryName
		END AS DisplayOrderbyName
	   ,c.CurrencyAbbreviation
	   ,c.CurrencySymbol
	   ,c.DisplayOrder
	   ,c.CurrencyName
	   ,c.CurrencyDigitalCode
	FROM LuCountry AS c WITH (NOLOCK)
	WHERE c.IsDeleted = 0
	AND EXISTS (SELECT
			TOP 1 1
		FROM LuStateProvince AS s WITH (NOLOCK)
		WHERE c.CountryId = s.CountryId
		AND EXISTS (SELECT
				StateProvinceID
			FROM LuCity WITH (NOLOCK)
			WHERE StateProvinceID = s.StateProvinceID
			AND c.IsDeleted = 0))) AS x
ORDER BY x.DisplayOrderbyName;
END
IF (UPPER(@Popr) = 'ST')
BEGIN

SELECT
	x.StateProvinceID
   ,x.CountryID
   ,x.StateProvinceAbbreviation
   ,x.StateProvinceName

FROM (SELECT
		s.StateProvinceID
	   ,s.CountryID
	   ,s.StateProvinceAbbreviation
	   ,s.StateProvinceName
	FROM LuStateProvince AS s WITH (NOLOCK)
	WHERE s.CountryID = @PCountryId
	AND EXISTS (SELECT
			 CityId,City,StateProvinceId
		FROM LuCity AS c WITH (NOLOCK)
		WHERE s.StateProvinceID = c.StateProvinceId)) AS x
ORDER BY x.StateProvinceName

END
IF (UPPER(@Popr) = 'CT')
BEGIN
SELECT
	c.CityId
   ,REPLACE(c.City, '--', '-') AS City
   ,c.StateProvinceId
FROM LuCity AS c WITH (NOLOCK)
WHERE StateProvinceId = @PStateProvinceId
ORDER BY c.City
END
IF (UPPER(@Popr) = 'PS')
BEGIN
SELECT
	ProjectUoMId
   ,Description
FROM LuProjectUoM WITH (NOLOCK)
END

IF (UPPER(@Popr) = 'PA')
BEGIN
SELECT
	ProjectAccessTypeId
   ,Name
   ,Description
   ,IsActive
FROM LuProjectAccessType WITH (NOLOCK)
END

END
GO