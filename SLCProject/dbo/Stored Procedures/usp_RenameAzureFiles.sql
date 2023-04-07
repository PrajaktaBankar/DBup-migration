
CREATE PROCEDURE [dbo].[usp_RenameAzureFiles]
(
	@jsonAzureFilesList NVARCHAR(MAX)
)
AS
BEGIN
	DROP TABLE IF EXISTS #AzureFilesList;
	CREATE TABLE #AzureFilesList (
	CustomerId INT NULL
	,DocumentTypeId INT NULL
	,DocumentPath NVARCHAR (1000) NULL
	,OriginalFileName NVARCHAR (500) NULL
	,FileSize NVARCHAR (100)
	,CreatedBy INT NULL
	,OldDocumentPath NVARCHAR (1000) NULL
	,OldFileName NVARCHAR (500) NULL
	)

	INSERT INTO #AzureFilesList (CustomerId, DocumentTypeId, DocumentPath, OriginalFileName, FileSize, CreatedBy, OldDocumentPath, OldFileName)
	SELECT * FROM OPENJSON(@jsonAzureFilesList)
	WITH (CustomerId INT '$.CustomerId', DocumentTypeId INT '$.DocumentTypeId', DocumentPath NVARCHAR(1000) '$.DocumentPath'
			,OriginalFileName NVARCHAR(500) '$.OriginalFileName', FileSize NVARCHAR(100) '$.FileSize', CreatedBy INT '$.CreatedBy'
			,OldDocumentPath NVARCHAR(1000) '$.OldDocumentPath', OldFileName NVARCHAR(500) '$.OldFileName')

	UPDATE A SET A.DocumentPath = B.DocumentPath, A.OriginalFileName = B.OriginalFileName, A.ModifiedDate = GETUTCDATE(), A.ModifiedBy = B.CreatedBy
	FROM [ImportDocLibrary] A WITH (NOLOCK)
	INNER JOIN #AzureFilesList B ON A.CustomerId = B.CustomerId AND A.DocumentPath = B.OldDocumentPath AND A.OriginalFileName = B.OldFileName
	WHERE ISNULL(A.IsDeleted, 0) = 0

END
GO


