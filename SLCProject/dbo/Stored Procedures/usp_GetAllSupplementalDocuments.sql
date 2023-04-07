CREATE PROCEDURE [dbo].[usp_GetAllSupplementalDocuments](   
		@CustomerId int,
		@ProjectId int,
        @SectionId int
)
AS
BEGIN
     DECLARE @PCustomerID INT = @CustomerID;
     DECLARE @PProjectId int = @ProjectId;    
     DECLARE @PSectionId INT = @SectionId; 

    SET NOCOUNT ON;
    SELECT
    docLib.ProjectId,
    docLib.CustomerId,
    docLib.SectionId,
    docLib.DocLibraryId,
    docLib.IsActive,
    docLib.IsAttachedToFolder,
    docLib.DocMappingId,
    importDocs.FileSize,
    importDocs.OriginalFileName,
    docLib.CreatedDate,
    docLib.CreatedBy,
    docLib.ModifiedDate,
    docLib.ModifiedBy,
	docLib.AttachedByFullName,
    importDocs.DocumentPath
FROM DocLibraryMapping docLib WITH (NOLOCK)
INNER JOIN ImportDocLibrary importDocs ON docLib.DocLibraryId = importDocs.DocLibraryId
WHERE docLib.CustomerId = @PCustomerID  AND
	  docLib.ProjectId = @PProjectId AND   
      docLib.SectionId = @PSectionId AND
      ISNULL(docLib.IsDeleted, 0) = 0
ORDER BY docLib.DocMappingId
END