CREATE PROC [dbo].[usp_GetProjectSectionsUpdateCount]
@CustomerId INT,
@ProjectId INT,
@CatalogType NVARCHAR(100) = 'FS'
AS

BEGIN

	DECLARE @PCustomerId INT = @CustomerId; 
	DECLARE @PProjectId INT = @ProjectId; 
	DECLARE @PCatalogType NVARCHAR(100) = @CatalogType; 

	SELECT SectionId, ISNULL(PendingUpdateCount, 0) AS UpdateCount FROM ProjectSection WITH(NOLOCK) 
		WHERE CustomerId = @PCustomerId AND ProjectId = @PProjectId
		AND ISNULL(IsDeleted, 0) = 0;

END