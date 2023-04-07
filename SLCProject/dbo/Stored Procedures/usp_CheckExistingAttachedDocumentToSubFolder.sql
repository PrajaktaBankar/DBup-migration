CREATE PROCEDURE [dbo].[usp_CheckExistingAttachedDocumentToSubFolder] (
	@CustomerId int,
	@ProjectId int NULL,
	@SectionId int NULL,
	@DocLibraryId bigint NULL,
	@IsAttachedToFolder bit NULL
)
AS
BEGIN
DECLARE @PCustomerId int = @CustomerId;
DECLARE @PProjectId int = @ProjectId;
DECLARE @PSectionId int = @SectionId;
DECLARE @PDocLibraryId bigint = @DocLibraryId;
DECLARE @PIsAttachedToFolder bit = @IsAttachedToFolder;

SELECT
		[DocMappingId]
		,[DocLibraryId]
		,[CustomerId]
		,[ProjectId]
		,[SectionId]
		,[DocLibraryId]
		,[IsAttachedToFolder]
		,[CreatedDate]
		,[CreatedBy]
	FROM [DocLibraryMapping] WITH (NOLOCK) WHERE 
	CustomerId = @PCustomerId 
	AND ProjectId = @ProjectId 
	AND SectionId = @PSectionId 
	AND DocLibraryId = @PDocLibraryId
	AND IsAttachedToFolder = @PIsAttachedToFolder 
	AND ISNULL(IsDeleted, 0) = 0;
END