CREATE PROC [dbo].[usp_GetSupplementalDocsForPrint]
@CustomerId INT,
@ProjectId INT,
@SectionsIds NVARCHAR(MAX)
AS
BEGIN

DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionsIds NVARCHAR(MAX) = @SectionsIds;

DROP TABLE IF EXISTS #SectionsIdsTbl;

CREATE TABLE #SectionsIdsTbl
(SortOrder INT IDENTITY(1,1), SectionId INT);

INSERT INTO #SectionsIdsTbl (SectionId)
SELECT splitdata
FROM dbo.fn_SplitString(@SectionsIds, ',');

DECLARE @SourceTagFormat NVARCHAR(50);
SELECT @SourceTagFormat = PS.SourceTagFormat
FROM ProjectSummary PS WITH (NOLOCK)
WHERE PS.CustomerId = @PCustomerId AND PS.ProjectId = @PProjectId ;

SELECT D.DocMappingId, D.CustomerId, D.ProjectId, D.SectionId, D.DocLibraryId, D.SortOrder, 
D.IsActive, D.IsDeleted, ID.DocumentTypeId, ID.DocumentPath, ID.OriginalFileName,
PS.SourceTag AS SectionSourceTag, ISNULL(@SourceTagFormat, '999999') AS SourceTagFormat, PS.SortOrder AS SectionSortOrder
FROM DocLibraryMapping D WITH(NOLOCK) 
INNER JOIN #SectionsIdsTbl S ON S.SectionId = D.SectionId
INNER JOIN ImportDocLibrary ID WITH(NOLOCK) ON ID.CustomerId = D.CustomerId AND ID.DocLibraryId = D.DocLibraryId
INNER JOIN ProjectSection PS WITH(NOLOCK) ON PS.CustomerId = @PCustomerId AND PS.ProjectId = @PProjectId AND PS.SectionId = S.SectionId
WHERE D.CustomerId = @CustomerId AND D.ProjectId = @ProjectId 
AND ISNULL(D.IsActive, 0) = 1 AND ISNULL(D.IsDeleted, 0) = 0
ORDER BY S.SortOrder, D.DocMappingId;

END