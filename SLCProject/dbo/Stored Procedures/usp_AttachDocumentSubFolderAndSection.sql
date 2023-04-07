CREATE PROCEDURE [dbo].[usp_AttachDocumentSubFolderAndSection]
(
	@CustomerId INT,
	@ProjectId INT NULL,
	@SectionId INT NULL,
	@IsAttachedToFolder BIT NULL,
	@CreatedBy INT NULL,
	@AttachedByFullName NVARCHAR(500),
	@AttachedFileJson NVARCHAR(MAX)
)
AS BEGIN

DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PIsAttachedToFolder BIT = @IsAttachedToFolder;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PAttachedByFullName NVARCHAR(500) = @AttachedByFullName;
DECLARE @PAttachedFileJson NVARCHAR(MAX) = @AttachedFileJson;


CREATE TABLE #TempTable (
	RowId INT IDENTITY(1,1),
	OrignalFileName NVARCHAR(500) NULL,
	FilePath NVARCHAR(1000) NULL,
	FileStatus INT DEFAULT 0,
	StatusMessage NVARCHAR(500) NULL
);


INSERT INTO #TempTable (OrignalFileName, FilePath)
SELECT * FROM OpenJson(@PAttachedFileJson)
WITH (
    OrignalFileName NVARCHAR(500) '$.FileName',
    FilePath NVARCHAR(1000) '$.DocumentPath'
);

DECLARE @RowCount BIGINT = 0;
SELECT @RowCount = COUNT(1) FROM #TempTable;

DECLARE @Counter INT;
SET @Counter = 1;

--For get DocLibaryId for File
DECLARE @DocLibaryId bigint;
-- For create path for file
DECLARE @DocumentPath NVARCHAR(MAX);
-- Get file path from #TempTable
DECLARE @FilePath NVARCHAR(1000);
-- Get file name from #TempTable
DECLARE @OrignalFileName NVARCHAR(500);
-- Get error message
DECLARE @ErrorMessage NVARCHAR(MAX);

WHILE (@Counter <= @RowCount)
BEGIN
	
	SELECT @FilePath = FilePath FROM #TempTable WHERE RowId = @Counter;
	SELECT @OrignalFileName = OrignalFileName FROM #TempTable WHERE RowId = @Counter;
	--Create document path to match record with ImportDocLibrary
	SELECT @DocumentPath = '' + CONVERT(NVARCHAR(100), @PCustomerId) + '' + @FilePath + '' + @OrignalFileName;
	-- Get DocLibaryId from FilePath and CustomerId
	SELECT @DocLibaryId = DocLibraryId FROM ImportDocLibrary WITH (NOLOCK) WHERE CustomerId = @PCustomerId AND DocumentPath =  @DocumentPath AND ISNULL(IsDeleted, 0) = 0;
	
	IF (@DocLibaryId > 0)
		BEGIN
			-- Check if file is already attached to subfolder/section
			IF NOT EXISTS(SELECT * FROM DocLibraryMapping WITH (NOLOCK) WHERE 
															CustomerId = @PCustomerId 
															AND ProjectId = @ProjectId 
															AND SectionId = @PSectionId 
															AND DocLibraryId = @DocLibaryId
															AND IsAttachedToFolder = @PIsAttachedToFolder 
															AND ISNULL(IsDeleted, 0) = 0)
			BEGIN
				-- Insert statement begins here
				BEGIN TRY
					-- If file is not attached then attach file to subfolder/section
					INSERT INTO [DocLibraryMapping]
								([CustomerId],
								[ProjectId],
								[SectionId],
								[DocLibraryId],
								[IsActive],
								[IsAttachedToFolder],
								[CreatedDate],
								[CreatedBy],
								[ModifiedDate], 
								[ModifiedBy], 
								[AttachedByFullName])
						VALUES (@PCustomerId, 
								@ProjectId, 
								@PSectionId, 
								@DocLibaryId, 
								1, 
								@PIsAttachedToFolder, 
								GETUTCDATE(), 
								@PCreatedBy, 
								GETUTCDATE(), 
								@PCreatedBy, 
								@PAttachedByFullName);
					-- If file is attached to subfolder/section then set FileStatus = 1
					UPDATE #TempTable
						SET FileStatus = 1, StatusMessage = 'File attached successfully'
						WHERE RowID = @Counter
				END TRY
				--If any error while insert operation catch here
				BEGIN CATCH
					-- If any error while insert record then set FileStatus = 4
					SELECT @ErrorMessage = ERROR_MESSAGE();
					UPDATE #TempTable
						SET FileStatus = 4, StatusMessage = @ErrorMessage
						WHERE RowID = @Counter
				END CATCH
			END
			ELSE			
			BEGIN
				-- If file is already attached to subfolder/section then update FileStatus = 2
				UPDATE #TempTable
					SET FileStatus = 2, StatusMessage = 'File already exists in record'
					WHERE RowID = @Counter
			END
		END
		ELSE
		BEGIN
			-- If file not found from FilePath and CustomerId then update FileStatus = 3
			UPDATE #TempTable
			SET FileStatus = 3, StatusMessage = 'File not exists in doc library record'
			WHERE RowID = @Counter
		END
    SET @Counter  = @Counter  + 1;
END
-- Update last modified date for section
UPDATE [ProjectSection] SET ModifiedBy = @PCreatedBy, ModifiedDate = GETUTCDATE() WHERE SectionId = @PSectionId;
-- Return file status response

--Save attach logs in DocLibraryAttachLog 
DECLARE @LogErrorMessage NVARCHAR(MAX);
BEGIN TRY
	INSERT INTO DocLibraryAttachLog(
	CustomerId, 
	ProjectId, 
	SectionId, 
	OrignalFileName, 
	DocumentPath, 
	IsAttachedToFolder,
	CreatedBy,
	IsFailed,
	StatusMessage,
	CreatedDate)
	SELECT @PCustomerId,
		   @PProjectId, 
		   @PSectionId,
		   t.OrignalFileName,
		   t.FilePath,
		   @PIsAttachedToFolder,
		   @PCreatedBy,
		   1,
		   t.StatusMessage,
		   GETUTCDATE()
	FROM #TempTable t WHERE t.FileStatus = 4
END TRY
BEGIN CATCH
	SELECT @LogErrorMessage = ERROR_MESSAGE();
		INSERT INTO BsdLogging..DBLogging (
			ArtifactName
			,DBServerName
			,DBServerIP
			,CreatedDate
			,LevelType
			,InputData
			,ErrorProcedure
			,ErrorMessage
			)
			VALUES (
			'usp_AttachDocumentSubFolderAndSection'
			,@@SERVERNAME
			,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))
			,Getdate()
			,'Error'
			,concat(' CustomerId: ' , @CustomerId , 'ProjectId: ' , @ProjectId , ' SectionId: ' , @SectionId , 'IsAttachedToFolder:', @IsAttachedToFolder, 'CreatedBy:', @CreatedBy, 'AttachedByFullName:', @AttachedByFullName, 'AttachedFileJson:', @AttachedFileJson)
			,'usp_AttachDocumentSubFolderAndSection'
			,ISNULL(@ErrorMessage, '')
			)
END CATCH
SELECT * FROM #TempTable;
END