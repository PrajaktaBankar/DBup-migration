CREATE PROCEDURE [dbo].[usp_MappingDocumentToSubFolder] (
	@CustomerId int,
	@ProjectId int NULL,
	@SectionId int NULL,
	@DocLibraryId bigint NULL,
	@IsAttachedToFolder bit NULL,
	@CreatedBy int NULL,
	@AttachedByFullName NVARCHAR(500)
)
AS
BEGIN
DECLARE @PCustomerId int = @CustomerId;
DECLARE @PProjectId int = @ProjectId;
DECLARE @PSectionId int = @SectionId;
DECLARE @PDocLibraryId bigint = @DocLibraryId;
DECLARE @PIsAttachedToFolder bit = @IsAttachedToFolder;
DECLARE @PCreatedBy int = @CreatedBy;
DECLARE @PAttachedByFullName NVARCHAR(500) = @AttachedByFullName

	INSERT INTO [DocLibraryMapping]
	([CustomerId],[ProjectId],[SectionId],[DocLibraryId],[IsActive],[IsAttachedToFolder],[CreatedDate],[CreatedBy],[ModifiedDate], [ModifiedBy], [AttachedByFullName])
	VALUES (@PCustomerId, @ProjectId, @SectionId, @DocLibraryId, 1, @IsAttachedToFolder, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), @PCreatedBy, @PAttachedByFullName);

	DECLARE @NewDocMappingId BIGINT = SCOPE_IDENTITY();
	
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
		,[AttachedByFullName]
	FROM [DocLibraryMapping] WITH (NOLOCK) WHERE DocMappingId = @NewDocMappingId;

	--Update Last accessed date of Section
	UPDATE [ProjectSection] SET ModifiedBy = @PCreatedBy, ModifiedDate = GETUTCDATE() WHERE SectionId = @PSectionId;

END