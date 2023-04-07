CREATE PROCEDURE [dbo].[usp_GetSupplementalDocPath]
@DocLibraryId BIGINT
AS
BEGIN

	DECLARE @PDocLibraryId BIGINT = @DocLibraryId;
	SELECT DocumentPath FROM ImportDocLibrary WITH(NOLOCK) WHERE DocLibraryId = @PDocLibraryId;
END