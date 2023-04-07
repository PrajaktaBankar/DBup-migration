CREATE PROCEDURE [dbo].[usp_GetDocLibraryDocFromFilePath] (
	@DocumentPath nvarchar(1000) NULL,
	@CustomerId INT
)
AS
BEGIN
DECLARE @PDocumentPath NVARCHAR(1000) = @DocumentPath;
DECLARE @PCustomerId INT = @CustomerId;

	SELECT
		[DocLibraryId]
		,[CustomerId]
		,[DocumentTypeId]
		,[DocumentPath]
		,[OriginalFileName]
		,[FileGUID]
		,[FileSize]
		,[IsDeleted]
		,[CreatedDate]
		,[CreatedBy]
		,[ModifiedDate]
		,[ModifiedBy]
	FROM [ImportDocLibrary] WITH (NOLOCK) WHERE [CustomerId] = @PCustomerId AND DocumentPath = @PDocumentPath AND ISNULL(IsDeleted, 0) = 0;

END