CREATE PROCEDURE [dbo].[usp_GetSuppDocUsageReport]
(
	@CustomerId INT,
	@DocumentPath NVARCHAR(1000),
	@OriginalFileName NVARCHAR(500)
)

AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId
DECLARE @PDocumentPath NVARCHAR(1000) = '' + CONVERT(NVARCHAR(100), @PCustomerId) + '' + @DocumentPath + '' + @OriginalFileName;
DECLARE @PDocLibraryId BIGINT = (SELECT DocLibraryId FROM ImportDocLibrary WITH (NOLOCK) WHERE CustomerId = @PCustomerId AND DocumentPath =  @PDocumentPath AND ISNULL(IsDeleted, 0) = 0);

-- Get the list of Projects to which the corresponding Supplemental Document is attached
	SELECT 
	Distinct(DLM.ProjectId),
	P.[Name]
	FROM DocLibraryMapping DLM WITH(NOLOCK)
	INNER JOIN Project P WITH(NOLOCK)
	ON DLM.ProjectId = P.ProjectId
	WHERE DLM.CustomerId = @PCustomerId
	AND ISNULL(P.IsPermanentDeleted, 0) = 0
	AND ISNULL(DLM.IsDeleted, 0) = 0
	AND DLM.DocLibraryId = @PDocLibraryId

-- Get the list of Sections and Subfolders to which the corresponding Supplemental Document is attached
	SELECT 
	Distinct(DLM.SectionId),
	DLM.ProjectId,
	PS.Description,
	IsNull(PS.SourceTag, '') As SourceTag,
	IsNull(PS.Author, '') As Author,
	DLM.IsAttachedToFolder,
	PS.ParentSectionId
	FROM DocLibraryMapping DLM WITH(NOLOCK)
	INNER JOIN Project P WITH(NOLOCK)
	ON DLM.ProjectId = P.ProjectId
	INNER JOIN ProjectSection PS WITH(NOLOCK)
	ON PS.SectionId = DLM.SectionId
	WHERE DLM.CustomerId = @PCustomerId
	AND ISNULL(P.IsPermanentDeleted, 0) = 0
	AND ISNULL(DLM.IsDeleted, 0) = 0
	AND ISNULL(PS.IsDeleted, 0) = 0
	AND DLM.DocLibraryId = @PDocLibraryId
	ORDER BY ProjectId, SourceTag 
END