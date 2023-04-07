CREATE PROCEDURE [dbo].[usp_GetSupplementalDocsForTransfer]
@CustomerId INT,
@ProjectId INT
AS

BEGIN

	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PProjectId INT = @ProjectId;

	DROP TABLE IF EXISTS #TempDocLibraryIds

	-- Get DocLibraryId which needs to sent in Target customer
	SELECT DISTINCT DLM.DocLibraryId 
	INTO #TempDocLibraryIds
	FROM DocLibraryMapping DLM WITH(NOLOCK)
	INNER JOIN ImportDocLibrary IDL WITH(NOLOCK) ON IDL.DocLibraryId = DLM.DocLibraryId 
	WHERE DLM.CustomerId = @PCustomerId AND DLM.ProjectId = @PProjectId AND ISNULL(DLM.IsDeleted, 0) = 0;

	SELECT IDL.DocumentPath, IDL.OriginalFileName
	FROM ImportDocLibrary IDL WITH(NOLOCK)
	INNER JOIN #TempDocLibraryIds T ON T.DocLibraryId = IDL.DocLibraryId;

END