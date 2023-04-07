
CREATE PROCEDURE [dbo].[usp_UploadAzureFile] (
	@CustomerId int,
	@DocumentTypeId int,
	@DocumentPath nvarchar(1000) NULL,
	@OriginalFileName nvarchar (500) NULL,
	@FileSize nvarchar (100) NULL,
	@IsDeleted bit NULL,
	@CreatedBy int NULL
)
AS
BEGIN
DECLARE @PCustomerId int = @CustomerId;
DECLARE @PDocumentTypeId int = @DocumentTypeId;
DECLARE @PDocumentPath NVARCHAR(1000) = @DocumentPath;
DECLARE @POriginalFileName NVARCHAR(500) = @OriginalFileName;
DECLARE @PFileSize NVARCHAR(100) = @FileSize;
DECLARE @PIsDeleted NVARCHAR(100) = @IsDeleted;
DECLARE @PCreatedBy INT = @CreatedBy;

	INSERT INTO [ImportDocLibrary]
	([CustomerId],[DocumentTypeId],[DocumentPath],[OriginalFileName],[FileSize],[IsDeleted],[CreatedDate],[CreatedBy])
	VALUES (@PCustomerId, @PDocumentTypeId, @PDocumentPath, @POriginalFileName, @PFileSize, @PIsDeleted, GETUTCDATE(), @PCreatedBy);

	DECLARE @NewDocLibraryId BIGINT = SCOPE_IDENTITY();

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
	FROM [ImportDocLibrary] WITH (NOLOCK) WHERE DocLibraryId = @NewDocLibraryId;
    
END
GO


