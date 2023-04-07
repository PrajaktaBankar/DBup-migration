
CREATE PROCEDURE [dbo].[usp_DeleteAzureFiles]
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
	)

	INSERT INTO #AzureFilesList (CustomerId, DocumentTypeId, DocumentPath, OriginalFileName, FileSize, CreatedBy)
	SELECT * FROM OPENJSON(@jsonAzureFilesList)
	WITH (CustomerId INT '$.CustomerId', DocumentTypeId INT '$.DocumentTypeId', DocumentPath NVARCHAR(1000) '$.DocumentPath'
			,OriginalFileName NVARCHAR(500) '$.OriginalFileName', FileSize NVARCHAR(100) '$.FileSize', CreatedBy INT '$.CreatedBy')

	UPDATE A SET A.IsDeleted = 1, ModifiedDate = GETUTCDATE(), A.ModifiedBy = B.CreatedBy
	FROM [ImportDocLibrary] A WITH (NOLOCK)
	INNER JOIN #AzureFilesList B ON A.CustomerId = B.CustomerId AND A.DocumentPath = B.DocumentPath AND A.OriginalFileName = B.OriginalFileName
	WHERE ISNULL(A.IsDeleted, 0) = 0
	
END
GO


