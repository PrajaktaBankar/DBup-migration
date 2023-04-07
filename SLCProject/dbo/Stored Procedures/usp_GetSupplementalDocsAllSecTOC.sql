CREATE PROCEDURE [dbo].[usp_GetSupplementalDocsAllSecTOC] 
@CustomerId INT,
@ProjectId INT
AS
BEGIN

DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;

SELECT 
D.DocMappingId, 
D.CustomerId, 
D.ProjectId, 
D.SectionId, 
D.DocLibraryId,  
D.IsActive, 
D.IsDeleted, 
ID.DocumentTypeId,  
ID.OriginalFileName
FROM DocLibraryMapping D WITH(NOLOCK) 
INNER JOIN ImportDocLibrary ID WITH(NOLOCK) ON ID.CustomerId = D.CustomerId AND ID.DocLibraryId = D.DocLibraryId
INNER JOIN ProjectSection PS WITH(NOLOCK) ON PS.CustomerId = @PCustomerId AND PS.ProjectId = @PProjectId AND PS.SectionId = D.SectionId
WHERE D.CustomerId = @PCustomerId AND D.ProjectId = @PProjectId 
AND ISNULL(D.IsDeleted, 0) = 0
ORDER BY PS.SortOrder, D.DocMappingId;
END