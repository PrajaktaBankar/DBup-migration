CREATE PROCEDURE [dbo].[usp_InsertNewProjectAddress]        
@ProjectId INT,    
@CustomerId  INT,    
@AddressLine1  INT,    
@AddressLine2  INT,    
@CountryId  INT,    
@StateProvinceId  INT,    
@CityId  INT,    
@PostalCode  NVARCHAR(MAX),    
@CreatedBy     INT,  
@City nvarchar(50)=null,  
@StateProvinceName nvarchar(50)=null  
  AS    
begin
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId  INT = @CustomerId;
DECLARE @PAddressLine1  INT = @AddressLine1;
DECLARE @PAddressLine2  INT = @AddressLine2;
DECLARE @PCountryId  INT = @CountryId;
DECLARE @PStateProvinceId  INT = @StateProvinceId;
DECLARE @PCityId  INT = @CityId;
DECLARE @PPostalCode  NVARCHAR(MAX) = @PostalCode;
DECLARE @PCreatedBy     INT = @CreatedBy;
DECLARE @PCity nvarchar(50) = @City;
DECLARE @PStateProvinceName nvarchar(50) = @StateProvinceName;

  If(@PStateProvinceId=0)   
  Begin
SET @PStateProvinceId = NULL
  
  End
  ELSE
	BEGIN
SET @StateProvinceName = NULL
	END;

IF (@PCityId = 0)
BEGIN
SET @PCityId = NULL
  
  End
  ELSE
  BEGIN
SET @PCity = NULL
	END;

BEGIN
INSERT INTO ProjectAddress (ProjectId
, CustomerId
, AddressLine1
, AddressLine2
, CountryId
, StateProvinceId
, CityId
, PostalCode
, CreateDate
, CreatedBy
, ModifiedBy
, ModifiedDate
, CityName
, StateProvinceName)
	VALUES (@PProjectId, @PCustomerId, @PAddressLine1, @PAddressLine2, @PCountryId, @PStateProvinceId, @PCityId, @PPostalCode, GETUTCDATE(), @PCreatedBy, @PCreatedBy, GETUTCDATE(), @PCity, @PStateProvinceName)

END
END

GO
