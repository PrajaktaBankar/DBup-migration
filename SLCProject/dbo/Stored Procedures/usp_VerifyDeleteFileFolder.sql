
CREATE PROCEDURE [dbo].[usp_VerifyDeleteFileFolder]
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

	SELECT CASE WHEN EXISTS (SELECT * FROM [ImportDocLibrary] A WITH (NOLOCK)
				INNER JOIN #AzureFilesList B ON A.CustomerId = B.CustomerId AND A.DocumentPath = B.DocumentPath AND A.OriginalFileName = B.OriginalFileName
				INNER JOIN [DocLibraryMapping] C WITH (NOLOCK) ON A.CustomerId = C.CustomerId AND A.DocLibraryId = C.DocLibraryId
				INNER JOIN [Project] D WITH (NOLOCK) ON C.CustomerId = D.CustomerId AND C.ProjectId = D.ProjectId
				WHERE ISNULL(A.IsDeleted, 0) = 0 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(D.IsPermanentDeleted, 0) = 0)
	THEN CAST(1 AS BIT)
	ELSE CAST(0 AS BIT) END AS FileAvailable

	
END
GO


