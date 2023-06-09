CREATE PROCEDURE [dbo].[usp_getProjectsByID]  
@ProjectId INT = 0
AS       
BEGIN
	  DECLARE @PProjectId INT = @ProjectId;
SELECT
	p.ProjectId
   ,p.Name
   ,p.Description
   ,p.UserId
   ,p.CustomerId
   ,p.CreatedBy
   ,p.CreateDate
   ,p.CreateDate
   ,p.ModifiedBy
   ,p.ModifiedDate
FROM [Project] p WITH (NOLOCK)
WHERE ProjectId = @PprojectId

SELECT
	PA.AddressId
   ,PA.ProjectId
   ,PA.CustomerId
   ,PA.AddressLine1
   ,PA.AddressLine2
   ,PA.CityId
   ,PA.CountryId
   ,PA.StateProvinceId
   ,PA.PostalCode
   ,PA.CreatedBy
   ,PA.ModifiedBy
   ,PA.ModifiedDate
FROM [ProjectAddress] PA WITH (NOLOCK)
WHERE ProjectId = @PprojectId


SELECT
	PS.ProjectSummaryId
   ,PS.ProjectId
   ,PS.CustomerId
   ,PS.UserId
   ,PS.ProjectTypeId
   ,PS.FacilityTypeId
   ,PS.ActualSizeId
   ,PS.SizeUoM
   ,PS.ActualCostId
   ,PS.IsIncludeRsInSection
   ,PS.IsIncludeReInSection
   ,PS.SpecViewModeId
   ,PS.SourceTagFormat
   ,PS.IsActivateRsCitation
   ,PS.UnitOfMeasureValueTypeId
FROM [ProjectSummary] PS WITH (NOLOCK)
WHERE ProjectId = @PprojectId


SELECT
	*
FROM [UserFolder] WITH (NOLOCK)
WHERE ProjectId = @PprojectId

END

GO
