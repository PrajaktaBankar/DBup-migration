CREATE PROCEDURE [dbo].[usp_SaveAndUpdateRvtFileDetails]
@RevitFileId INT NULL=NULL, @FileName NVARCHAR (100) NULL=NULL, @FileSize VARCHAR (150) NULL, @CustomerId INT NULL, @UserId INT NULL, @ProjectId INT NULL, @UploadedBy INT NULL, @ExtVimId INT NULL=NULL, @CommandType NVARCHAR (1) NULL='S', @UniqueId NVARCHAR (50) NULL=NULL
AS
BEGIN
DECLARE @PRevitFileId INT = @RevitFileId;
DECLARE @PFileName NVARCHAR (100) = @FileName;
DECLARE @PFileSize VARCHAR (150) = @FileSize;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PUploadedBy INT = @UploadedBy;
DECLARE @PExtVimId INT = @ExtVimId;
DECLARE @PCommandType NVARCHAR (1) = @CommandType;
DECLARE @PUniqueId NVARCHAR (50) = @UniqueId;

    IF (@PCommandType = 'A')
        BEGIN
INSERT INTO [ProjectRevitFile] ([FileName], [FileSize], [CustomerId], [UserId], [UploadedDate], [UploadedBy], [ExtVimId], [IsDeleted], [ProjectId], [UniqueId])
	SELECT
		@PFileName
	   ,@PFileSize
	   ,@PCustomerId
	   ,@PUserId
	   ,GETDATE()
	   ,@PUploadedBy
	   ,@PExtVimId
	   ,'false'
	   ,NULLIF(@PProjectId, 0)
	   ,@PUniqueId;
IF ((SELECT
			COUNT(*)
		FROM Project WITH (NOLOCK)
		WHERE ProjectId = @PProjectId)
	> 0)
BEGIN
DECLARE @rvtFileId AS INT = @@identity;
INSERT INTO [ProjectRevitFileMapping]
	VALUES (@rvtFileId, @PProjectId, 1, GETDATE(), NULL, @PCustomerId, @PUserId);
END
END
ELSE
IF (@PCommandType = 'U'
	AND @PRevitFileId IS NOT NULL)
BEGIN
UPDATE PRF
SET PRF.ExtVimId = @PExtVimId
FROM ProjectRevitFile PRF WITH (NOLOCK)
WHERE PRF.RevitFileId = @PRevitFileId;
END
END

GO
