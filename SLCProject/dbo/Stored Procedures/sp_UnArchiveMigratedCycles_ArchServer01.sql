
CREATE PROCEDURE [dbo].[sp_UnArchiveMigratedCycles_ArchServer01]
(
	@PSLC_CustomerId		INT
	,@PSLC_UserId			INT
	,@PProjectID			INT
	,@POldSLC_ProjectID		INT
	,@PArchive_ServerId		INT
)
AS
BEGIN
	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message VARCHAR(1024)
	DECLARE @ErrorStep VARCHAR(50)
	DECLARE @NumberRecords int, @RowCount int
	DECLARE @RequestId AS INT

	--Handled Parameter Sniffing here
	DECLARE @SLC_CustomerId INT
	SET @SLC_CustomerId = @PSLC_CustomerId
	DECLARE @SLC_UserId INT
	SET @SLC_UserId = @PSLC_UserId
	DECLARE @ProjectID INT
	SET @ProjectID = @PProjectID
	DECLARE @OldSLC_ProjectID INT
	SET @OldSLC_ProjectID = @POldSLC_ProjectID
	DECLARE @Archive_ServerId INT
	SET @Archive_ServerId = @PArchive_ServerId

	--IF OBJECT_ID('tempdb..#tmpUnArchiveCycleIDs') IS NOT NULL DROP TABLE #tmpUnArchiveCycleIDs
	--CREATE TABLE #tmpUnArchiveCycleIDs
	--(
	--	RowID					INT IDENTITY(1, 1), 
	--	CycleID					BIGINT NULL,
	--	CustomerID				INT NOT NULL,
	--	SubscriptionID			INT NULL, 
	--	ProjectID				INT NOT NULL,
	--	SLC_CustomerId			INT NOT NULL,
	--	SLC_UserId				INT NOT NULL,
	--	SLC_ArchiveProjectId	INT NOT NULL,
	--	SLC_ProdProjectId		INT NULL,
	--	SLC_ServerId			INT NULL,
	--	MigrateStatus			INT NULL,
	--	CreatedDate				DATETIME NULL,
	--	MovedDate				DATETIME NULL,
	--	MigratedDate			DATETIME NULL,
	--	IsProcessed				BIT NULL DEFAULT((0))
	--)
	
	DECLARE @IsProjectMigrationFailed AS INT = 0
	DECLARE @IsRestoreDeleteFailed AS INT = 0

	--Drop all Temp Tables
	DROP TABLE IF EXISTS #NewOldSectionIdMapping;
	DROP TABLE IF EXISTS #NewOldSegmentStatusIdMapping;
	DROP TABLE IF EXISTS #TGTProImg;
	DROP TABLE IF EXISTS #tmp_TgtSection;
	DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;
	DROP TABLE IF EXISTS #tmpProjectGlobalTerm;
	DROP TABLE IF EXISTS #tmpProjectHyperLink;
	DROP TABLE IF EXISTS #tmpProjectImage;
	DROP TABLE IF EXISTS #tmpProjectNote;
	DROP TABLE IF EXISTS #tmpProjectNoteImage;
	DROP TABLE IF EXISTS #tmpProjectSection;
	DROP TABLE IF EXISTS #ProjectSegment_Staging;
	DROP TABLE IF EXISTS #tmpProjectSegment;
	DROP TABLE IF EXISTS #tmpProjectSegmentChoice;
	DROP TABLE IF EXISTS #tmpProjectSegmentImage;
	DROP TABLE IF EXISTS #tmpProjectSegmentStatus;
	DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;
	DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;
	DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;
	DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;
	DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;
	DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;
	DROP TABLE IF EXISTS #ProjectHyperLink_Staging;
	DROP TABLE IF EXISTS #ProjectNote_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;
	DROP TABLE IF EXISTS #ProjectNoteImage_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;
	DROP TABLE IF EXISTS #MaterialSection_Staging;
	DROP TABLE IF EXISTS #LinkedSections_Staging;

	DROP TABLE IF EXISTS #Staging_ProjectGTerm;

	CREATE TABLE #Staging_ProjectGTerm
	(
		mGlobalTermId INT NULL
		,ProjectId INT NULL
		,CustomerId INT NULL
		,[Name] NVARCHAR(500) NULL
		,[value] NVARCHAR(500) NULL
		,GlobalTermSource CHAR(1) NULL
		,GlobalTermCode INT NULL
		,CreatedDate DATETIME2(7) NULL
		,CreatedBy INT NULL
		,ModifiedDate DATETIME2(7) NULL
		,ModifiedBy INT NULL
		,SLE_GlobalChoiceID INT NULL
		,UserGlobalTermId INT NULL
		,IsDeleted BIT NULL
		,A_GlobalTermId INT NULL
		,GlobalTermFieldTypeId SMALLINT NULL
		,OldValue NVARCHAR(500) NULL
	)

	DECLARE @Records INT = 1; 
	DECLARE @TableRows INT;
	DECLARE @Section_BatchSize INT;
	DECLARE @Segment_BatchSize INT;
	DECLARE @SegmentStatus_BatchSize INT;
	DECLARE @ProjectSegmentChoice_BatchSize INT;
	DECLARE @ProjectChoiceOption_BatchSize INT;
	DECLARE @SelectedChoiceOption_BatchSize INT;
	DECLARE @ProjectHyperLink_BatchSize INT;
	DECLARE @ProjectNote_BatchSize INT;
	DECLARE @ProjectSegmentLink_BatchSize INT;
	DECLARE @Start INT = 1;
	DECLARE @End INT;
	DECLARE @StartTime AS DATETIME = GETUTCDATE()
	DECLARE @EndTime AS DATETIME = GETUTCDATE()
	DECLARE @MasterDataTypeId AS INT

	--INSERT INTO #tmpUnArchiveCycleIDs (CycleID, CustomerID, SubscriptionID, ProjectID, SLC_CustomerId, SLC_UserId, SLC_ArchiveProjectId, SLC_ProdProjectId, SLC_ServerId, MigrateStatus, MigratedDate, IsProcessed)
	--SELECT AP.CycleID, AP.LegacyCustomerID, AP.LegacySubscriptionID, AP.LegacyProjectID, AP.SLC_CustomerId, AP.SLC_UserId, AP.SLC_ArchiveProjectId, AP.SLC_ProdProjectId, AP.SLC_ServerId, AP.MigrateStatus, AP.MigratedDate, 0 AS IsProcessed
	--FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)
	----INNER JOIN [SQLADMINOP].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = AP.SLC_CustomerId 
	--	--AND AP.TenantDbServerId IN (SELECT TenantDbServerId FROM [SQLADMINOP].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))
	--WHERE AP.InProgressStatusId = 3 --UnArchiveInitiated
	--	AND AP.ProcessInitiatedById IN (1,2) --SLE or SLEWeb
	--	AND AP.MigrateStatus = 1 AND AP.DisplayTabId = 1 --MigratedTab
	--	AND AP.IsArchived = 1
	--	--AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SQLADMINOP].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))

	---- Get the number of records in the temporary table
	--SET @NumberRecords = @@ROWCOUNT
	--SET @RowCount = 1

	---- loop through all records in the temporary table using the WHILE loop construct
	--WHILE @RowCount <= @NumberRecords
	--BEGIN
	--	--Set IsProjectMigrationFailed to 0 to reset it
	--	SET @IsProjectMigrationFailed = 0

	--	DECLARE @CustomerID INT, @SubscriptionID INT, @SLE_ProjectID INT, @MigrateStatus INT, @MigratedDate DATETIME, @SLC_CustomerId INT, @SLC_UserId INT, @ProjectID INT, @IsProcessed INT, @CycleID BIGINT
	--		, @SLC_ServerId INT, @OldSLC_ProjectID INT
	--	--Get next CycleID
	--	SELECT @CustomerID = CustomerID, @SubscriptionID = SubscriptionID, @SLE_ProjectID = ProjectID, @SLC_CustomerId = SLC_CustomerId, @SLC_UserId = SLC_UserId, @CycleID = CycleID
	--		,@MigrateStatus = MigrateStatus, @ProjectID = SLC_ArchiveProjectId, @OldSLC_ProjectID = ISNULL(SLC_ProdProjectId, 0), @SLC_ServerId = SLC_ServerId, @MigratedDate = MigratedDate, @IsProcessed = IsProcessed
	--	FROM #tmpUnArchiveCycleIDs WHERE RowID = @RowCount AND IsProcessed = 0


	BEGIN TRY

		IF(EXISTS(SELECT TOP 1 1 FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK) WHERE Servername=@@servername))
		BEGIN
			SELECT TOP 1 @Section_BatchSize=ProjectSection,
				@SegmentStatus_BatchSize=ProjectSegmentStatus,
				@Segment_BatchSize =ProjectSegment,
				@ProjectSegmentChoice_BatchSize =ProjectSegmentChoice,
				@ProjectChoiceOption_BatchSize =ProjectChoiceOption,
				@SelectedChoiceOption_BatchSize =SelectedChoiceOption,
				@ProjectSegmentLink_BatchSize =ProjectSegmentLink,
				@ProjectHyperLink_BatchSize =ProjectHyperLink,
				@ProjectNote_BatchSize =ProjectNote
				FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK)
				WHERE Servername=@@servername
		END
		ELSE
		BEGIN
			SELECT TOP 1 @Section_BatchSize=ProjectSection,
				@SegmentStatus_BatchSize=ProjectSegmentStatus,
				@Segment_BatchSize =ProjectSegment,
				@ProjectSegmentChoice_BatchSize =ProjectSegmentChoice,
				@ProjectChoiceOption_BatchSize =ProjectChoiceOption,
				@SelectedChoiceOption_BatchSize =SelectedChoiceOption,
				@ProjectSegmentLink_BatchSize =ProjectSegmentLink,
				@ProjectHyperLink_BatchSize =ProjectHyperLink,
				@ProjectNote_BatchSize =ProjectNote
				FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK)
				WHERE Servername IS NULL
		END

		--UnArchive Project Data

			
		SET @RequestId = 0

		DECLARE @New_ProjectID AS INT, @IsOfficeMaster AS INT, @ProjectAccessTypeId AS INT, @ProjectOwnerId AS INT

		DECLARE @OldCount AS INT = 0, @NewCount AS INT = 0, @StepName AS NVARCHAR(100), @Description AS NVARCHAR(500), @Step AS NVARCHAR(100)

		--Update previousely migrated projects A_ProjectId to NULL so it wont duplicate the records in other child tables.
		UPDATE P SET P.A_ProjectId = NULL
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE A_ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId;

		--Move Project table
		--Insert
		INSERT INTO [SLCProject].[dbo].[Project]
		([Name], IsOfficeMaster, [Description], TemplateId, MasterDataTypeId, UserId, CustomerId, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsDeleted, IsNamewithHeld
			,IsMigrated, IsLocked, A_ProjectId, IsProjectMoved, [GlobalProjectID], [IsPermanentDeleted], [ModifiedByFullName], [MigratedDate], [IsArchived], [IsShowMigrationPopup]
			,[LockedBy],[LockedDate],[LockedById])
		SELECT
			S.[Name], S.IsOfficeMaster, S.[Description], S.TemplateId, S.MasterDataTypeId, S.UserId, S.CustomerId, S.CreateDate, S.CreatedBy
			,S.ModifiedBy, S.ModifiedDate, S.IsDeleted, S.IsNamewithHeld, S.IsMigrated, S.IsLocked, S.ProjectId AS A_ProjectId, 0 AS IsProjectMoved
			,S.GlobalProjectID AS [GlobalProjectID], S.[IsPermanentDeleted], S.[ModifiedByFullName], S.[MigratedDate], S.[IsArchived], S.[IsShowMigrationPopup]
			,S.[LockedBy], S.[LockedDate], S.[LockedById]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT @New_ProjectID = ProjectId, @IsOfficeMaster = IsOfficeMaster, @MasterDataTypeId = MasterDataTypeId
		FROM [SLCProject].[dbo].[Project] WITH (NOLOCK) WHERE A_ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId
		
		--Set IsDeleted flag to 1 for a temporary basis until whole project is Unarchived
		UPDATE P
			SET IsDeleted = 1--, ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID

		--Get RequestId from 
		SELECT @RequestId = RequestId FROM [SLCProject].[dbo].[UnArchiveProjectRequest] WITH (NOLOCK)
		WHERE [SLC_CustomerId] = @SLC_CustomerId AND [SLC_ArchiveProjectId] = @ProjectID AND [StatusId] = 1--StatusId 1 as Queued

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'New Project created', 'New Project created', '1', 3, @New_ProjectID, @NewCount

		--Move ProjectAddress table
		INSERT INTO [SLCProject].[dbo].[ProjectAddress]
		(ProjectId, CustomerId, AddressLine1, AddressLine2, CountryId, StateProvinceId, CityId, PostalCode, CreateDate, CreatedBy, ModifiedBy
			,ModifiedDate, StateProvinceName, CityName)
		SELECT @New_ProjectID AS ProjectId, S.CustomerId, S.AddressLine1, S.AddressLine2, S.CountryId, S.StateProvinceId, S.CityId, S.PostalCode
			,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.StateProvinceName, S.CityName
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectAddress] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project Address created', 'Project Address created', '2', 6, @OldCount, @NewCount

			
		--Move UserFolder table
		INSERT INTO [SLCProject].[dbo].[UserFolder]
		(FolderTypeId, ProjectId, UserId, LastAccessed, CustomerId, LastAccessByFullName)
		SELECT S.FolderTypeId, @New_ProjectID AS ProjectId, S.UserId, S.LastAccessed, S.CustomerId, S.LastAccessByFullName
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[UserFolder] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		
		EXECUTE [SLCProject].[dbo].[usp_GetMigratedProjectDefaultPrivacySetting] @SLC_CustomerId, @SLC_UserId, @IsOfficeMaster, @ProjectAccessTypeId OUTPUT, @ProjectOwnerId OUTPUT

		--Move ProjectSummary table
		INSERT INTO [SLCProject].[dbo].[ProjectSummary]
		([ProjectId],[CustomerId],[UserId],[ProjectTypeId],[FacilityTypeId],[SizeUoM],[IsIncludeRsInSection],[IsIncludeReInSection]
			,[SpecViewModeId],[UnitOfMeasureValueTypeId],[SourceTagFormat],[IsPrintReferenceEditionDate],[IsActivateRsCitation],[LastMasterUpdate]
			,[BudgetedCostId],[BudgetedCost],[ActualCost],[EstimatedArea],[SpecificationIssueDate],[SpecificationModifiedDate],[ActualCostId]
			,[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM],[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId])
		SELECT @New_ProjectID AS ProjectId,S.[CustomerId],S.[UserId],S.[ProjectTypeId],S.[FacilityTypeId],S.[SizeUoM],S.[IsIncludeRsInSection],S.[IsIncludeReInSection]
			,S.[SpecViewModeId],S.[UnitOfMeasureValueTypeId],S.[SourceTagFormat],S.[IsPrintReferenceEditionDate],S.[IsActivateRsCitation],S.[LastMasterUpdate]
			,S.[BudgetedCostId],S.[BudgetedCost],S.[ActualCost],S.[EstimatedArea],S.[SpecificationIssueDate],S.[SpecificationModifiedDate],S.[ActualCostId]
			,S.[ActualSizeId],S.[EstimatedSizeId],S.[EstimatedSizeUoM],S.[Cost],S.[Size],@ProjectAccessTypeId AS [ProjectAccessTypeId],@ProjectOwnerId AS [OwnerId],S.[TrackChangesModeId]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSummary created', 'ProjectSummary created', '3', 9, @OldCount, @NewCount


		--Move ProjectPageSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPageSetting]
		([MarginTop],[MarginBottom],[MarginLeft],[MarginRight],[EdgeHeader],[EdgeFooter],[IsMirrorMargin],[ProjectId],[CustomerId])
		SELECT S.[MarginTop],S.[MarginBottom],S.[MarginLeft],S.[MarginRight],S.[EdgeHeader],S.[EdgeFooter],S.[IsMirrorMargin]
			,@New_ProjectID AS [ProjectId],S.[CustomerId]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPageSetting] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPageSetting created', 'ProjectPageSetting created', '4', 12, @OldCount, @NewCount

			
		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPaperSetting]
		(PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId)
		SELECT S.PaperName, S.PaperWidth, S.PaperHeight, S.PaperOrientation, S.PaperSource, @New_ProjectID AS ProjectId, S.CustomerId
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPaperSetting] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPaperSetting created', 'ProjectPaperSetting created', '5', 15, @OldCount, @NewCount

			
		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPrintSetting]
		([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage]
			,[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount],[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo]
			,IsIncludePdfBookmark, BookmarkLevel)
		SELECT @New_ProjectID AS [ProjectId],S.[CustomerId],S.[CreatedBy],S.[CreateDate],S.[ModifiedBy],S.[ModifiedDate],S.[IsExportInMultipleFiles],S.[IsBeginSectionOnOddPage]
			,S.[IsIncludeAuthorInFileName],S.[TCPrintModeId], S.[IsIncludePageCount], S.IsIncludeHyperLink, S.KeepWithNext, S.[IsPrintMasterNote],S.[IsPrintProjectNote],S.[IsPrintNoteImage]
			,S.[IsPrintIHSLogo], S.IsIncludePdfBookmark, S.BookmarkLevel
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPrintSetting] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPrintSetting created', 'ProjectPrintSetting created', '6', 18, @OldCount, @NewCount

		SELECT ROW_NUMBER() OVER(ORDER BY S.SectionId) AS RowNumber, S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
				,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
				,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
				,S.IsHidden, S.SortOrder
		INTO #tmp_TgtSection
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @Section_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			INSERT INTO [SLCProject].[dbo].[ProjectSection]
			(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
				,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
				,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
				,TrackChangeLockedBy, DataMapDateTimeStamp, IsHidden, SortOrder)
			SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
					,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
					,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
					,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
					,S.IsHidden, S.SortOrder
			FROM #tmp_TgtSection S
			WHERE RowNumber BETWEEN @Start AND @End
 
			SET @Records += @Section_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @Section_BatchSize - 1;
		END

		--INSERT INTO [SLCProject].[dbo].[ProjectSection]
		--(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
		--	,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
		--	,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
		--	,TrackChangeLockedBy, DataMapDateTimeStamp)
		--SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
		--		,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
		--		,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
		--		,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
		--FROM #tmp_TgtSection S

		SELECT SectionId, ParentSectionId, ProjectId, CustomerId, A_SectionId INTO #tmpProjectSection
		FROM [SLCProject].[dbo].[ProjectSection] WITH (NOLOCK) WHERE ProjectId = @New_ProjectID AND CustomerId = @SLC_CustomerId

		SELECT ProjectId, CustomerId, SectionId, A_SectionId INTO #NewOldSectionIdMapping FROM #tmpProjectSection

		--UPDATE ParentSectionId in TGT Section table                  
		UPDATE TGT_TMP SET TGT_TMP.ParentSectionId = NOSM.SectionId
		FROM #tmpProjectSection TGT_TMP
		INNER JOIN #NewOldSectionIdMapping NOSM ON TGT_TMP.ParentSectionId = NOSM.A_SectionId
		WHERE TGT_TMP.ProjectId = @New_ProjectID;
			
		--UPDATE ParentSectionId in original table                  
		UPDATE PS SET PS.ParentSectionId = PS_TMP.ParentSectionId
		FROM [SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
		INNER JOIN #tmpProjectSection PS_TMP ON PS.SectionId = PS_TMP.SectionId
		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @SLC_CustomerId;

		DROP TABLE IF EXISTS #tmp_TgtSection;
		DROP TABLE IF EXISTS #NewOldSectionIdMapping;
			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSection created', 'ProjectSection created', '7', 21, @OldCount, @NewCount

		--DELETE FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection]
		--WHERE ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId

		--INSERT INTO [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection]
		--(SectionId, ProjectId, CustomerId)
		--SELECT PS.SectionId, PS.ProjectId, PS.CustomerId
		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
		--WHERE PS.ProjectId = @ProjectID AND PS.CustomerId = @SLC_CustomerId
		--AND ISNULL(PS.IsDeleted, 0) = 0;

		
		--Load data from Archive server to temp table
		INSERT INTO #Staging_ProjectGTerm
		SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, S.CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode, S.CreatedDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy, S.SLE_GlobalChoiceID, S.UserGlobalTermId, S.IsDeleted, S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Add if Master GlobalTerms are missing in the Archived projects by comparing SLCMaster..GlobalTerm table
		INSERT INTO #Staging_ProjectGTerm
		SELECT A.GlobalTermId AS mGlobalTermId, @New_ProjectID AS ProjectId, @SLC_CustomerId AS CustomerId, A.[Name], A.[value], 'M' AS GlobalTermSource, A.GlobalTermCode, A.CreateDate AS CreatedDate
			,@SLC_UserId AS CreatedBy, A.CreateDate AS ModifiedDate, @SLC_UserId AS ModifiedBy, NULL AS SLE_GlobalChoiceID, NULL AS UserGlobalTermId, 0 AS IsDeleted
			,NULL AS A_GlobalTermId, A.GlobalTermFieldTypeId, NULL AS OldValue
		FROM [SLCMaster].[dbo].[GlobalTerm] A WITH (NOLOCK)
		LEFT JOIN #Staging_ProjectGTerm B WITH (NOLOCK) ON A.GlobalTermId = B.mGlobalTermId AND B.ProjectId = @New_ProjectID AND B.CustomerId = @SLC_CustomerId
		WHERE A.MasterDataTypeId = @MasterDataTypeId AND B.mGlobalTermId IS NULL


		--Move ProjectGlobalTerm table
		INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
			,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
		SELECT S.mGlobalTermId, S.ProjectId, S.CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode, S.CreatedDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy, S.SLE_GlobalChoiceID, S.UserGlobalTermId, S.IsDeleted, S.A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		FROM #Staging_ProjectGTerm S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #Staging_ProjectGTerm;

		----Move ProjectGlobalTerm table
		--INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		--([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
		--	,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
		--SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, S.CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode, S.CreatedDate, S.CreatedBy
		--		,S.ModifiedDate, S.ModifiedBy, S.SLE_GlobalChoiceID, S.UserGlobalTermId, S.IsDeleted, S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
		--WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT P.GlobalTermId, P.CustomerId, P.ProjectId, P.UserGlobalTermId, P.GlobalTermCode, P.A_GlobalTermId INTO #tmpProjectGlobalTerm
		FROM [SLCProject].[dbo].[ProjectGlobalTerm] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectGlobalTerm created', 'ProjectGlobalTerm created', '8', 24, @OldCount, @NewCount

		--Insert #tmpProjectImage table
		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.[ImageId] AS A_ImageId
		INTO #TGTProImg
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectImage] SRC WITH (NOLOCK)
		WHERE SRC.CustomerId = @SLC_CustomerId

		--Update ProjectImage table
		UPDATE TGT
			SET TGT.[ImagePath] = SRC.[ImagePath], TGT.[LuImageSourceTypeId] = SRC.[LuImageSourceTypeId],TGT.[CreateDate] = SRC.[CreateDate]
				,TGT.[ModifiedDate] = SRC.[ModifiedDate],TGT.[SLE_ProjectID] = SRC.[SLE_ProjectID],TGT.[SLE_DocID] = SRC.[SLE_DocID]
				,TGT.[SLE_StatusID] = SRC.[SLE_StatusID],TGT.[SLE_SegmentID] = SRC.[SLE_SegmentID],TGT.[SLE_ImageNo] = SRC.[SLE_ImageNo]
				,TGT.[SLE_ImageID] = SRC.[SLE_ImageID],TGT.[A_ImageId] = SRC.A_ImageId
		FROM [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK)
		INNER JOIN #TGTProImg SRC
			ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND SRC.CustomerId = @SLC_CustomerId
		WHERE TGT.CustomerId = @SLC_CustomerId

		--Insert ProjectImage table
		INSERT INTO [SLCProject].[dbo].[ProjectImage]
		([ImagePath],[LuImageSourceTypeId],[CreateDate],[ModifiedDate],[CustomerId],[SLE_ProjectID],[SLE_DocID],[SLE_StatusID],[SLE_SegmentID]
			,[SLE_ImageNo],[SLE_ImageID],[A_ImageId])
		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.A_ImageId
		FROM #TGTProImg SRC
		LEFT OUTER JOIN [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK) ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND TGT.CustomerId = @SLC_CustomerId
		WHERE SRC.CustomerId = @SLC_CustomerId AND TGT.ImagePath IS NULL

		SELECT I.ImageId, I.CustomerId, I.ImagePath, I.A_ImageId INTO #tmpProjectImage
		FROM [SLCProject].[dbo].[ProjectImage] I WITH (NOLOCK) WHERE I.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #TGTProImg;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectImage created', 'ProjectImage created', '9', 27, @OldCount, @NewCount

		--Move ProjectSegment_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentId) AS RowNumber, S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
				,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		INTO #ProjectSegment_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @Segment_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Insert ProjectSegment Table
			INSERT INTO [SLCProject].[dbo].[ProjectSegment]
			(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
				,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
			SELECT NULL AS SegmentStatusId, S2.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
					,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
			FROM #ProjectSegment_Staging S
			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @Segment_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @Segment_BatchSize - 1;
		END

		----Insert ProjectSegment Table
		--INSERT INTO [SLCProject].[dbo].[ProjectSegment]
		--(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
		--	,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
		--SELECT NULL AS SegmentStatusId, S2.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
		--		,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		--FROM #ProjectSegment_Staging S
		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT S.SegmentId, S.SegmentStatusId, S.SegmentSource, S.SegmentCode, S.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.A_SegmentId
		INTO #tmpProjectSegment FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegment_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment created', 'ProjectSegment created', '10', 30, @OldCount, @NewCount


		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentStatusId) AS RowNumber, S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
			,S.SLE_ProjectSegID, S.SLE_StatusID, S.SegmentStatusId AS A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		INTO #tmp_TgtSegmentStatus
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		--Update SectionId in ProjectSegmentStatus table
		UPDATE S
			SET S.SectionId = S1.SectionId
		FROM #tmp_TgtSegmentStatus S
		INNER JOIN #tmpProjectSection S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Update SegmentId in ProjectSegmentStatus table
		UPDATE S
			SET S.SegmentId = S1.SegmentId
		FROM #tmp_TgtSegmentStatus S
		--FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.SectionId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId;

		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @SegmentStatus_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Insert ProjectSegmentStatus
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
			(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
				,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
				,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
				,IsDeleted, TrackOriginOrder, MTrackDescription)
			SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
				,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
				,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
				,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
			FROM #tmp_TgtSegmentStatus S
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @SegmentStatus_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @SegmentStatus_BatchSize - 1;
		END

		----Insert ProjectSegmentStatus
		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
		--(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
		--	,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
		--	,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
		--	,IsDeleted, TrackOriginOrder, MTrackDescription)
		--SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
		--	,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
		--	,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
		--	,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		--FROM #tmp_TgtSegmentStatus S

		SELECT S.* INTO #tmpProjectSegmentStatus FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT SegmentStatusId, A_SegmentStatusId INTO #NewOldSegmentStatusIdMapping
		FROM #tmpProjectSegmentStatus S

		--UPDATE ParentSegmentStatusId in temp table
		UPDATE CPSST
		SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId
		FROM #tmpProjectSegmentStatus CPSST
		INNER JOIN #NewOldSegmentStatusIdMapping PPSST
			ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId AND CPSST.ParentSegmentStatusId <> 0

		--UPDATE ParentSegmentStatusId in original table
		UPDATE PSS
		SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId
		FROM [SLCProject].[dbo].[ProjectSegmentStatus] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentStatus PSS_TMP ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID
		AND PSS.CustomerId = @SLC_CustomerId;


		--Update SegmentStatusId in #tmpProjectSegment
		UPDATE PS
			SET PS.SegmentStatusId = SS.SegmentStatusId
		FROM #tmpProjectSegment PS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentStatus SS WITH (NOLOCK) ON SS.ProjectId = PS.ProjectId AND SS.CustomerId = PS.CustomerId
			AND SS.SectionId = PS.SectionId AND SS.SegmentId = PS.SegmentId
		WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId;

		--UPDATE SegmentStatusId in original table
		UPDATE PSS
		SET PSS.SegmentStatusId = PSS_TMP.SegmentStatusId
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		----RefStdCode need NOT be updated because there is no difference between RefStdCode on any of the SLC Servers

		------Update SegmentDescription for ReferenceStandard Paragraph with new tag {RSTEMP#[RefStdCode]} when it is Master RefStdCode
		----UPDATE P
		----SET P.SegmentDescription = ([DE_Projects_Staging].[dbo].[fn_ReplaceSLEPlaceHolder] (P.SegmentDescription, '{RSTEMP#', '{RSTEMP#'
		----		, [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
		----		, NEWRS.RefStdCode))
		----FROM [SLCProject].[dbo].[ProjectSegment] P 
		----INNER JOIN [SLCProject].[dbo].[ProjectSegmentStatus] PS WITH (NOLOCK) ON PS.CustomerId = P.CustomerId AND PS.ProjectId = P.ProjectId AND PS.SectionId = P.SectionId
		----	AND PS.SegmentId = P.SegmentId
		----INNER JOIN [ARCHIVESERVER01].[SLCMaster].[dbo].[ReferenceStandard] OLDRS WITH (NOLOCK) ON OLDRS.MasterDataTypeId = 1 AND OLDRS.IsObsolete = 0
		----	AND OLDRS.RefStdCode = [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
		----INNER JOIN [SLCMaster].[dbo].[ReferenceStandard] NEWRS WITH (NOLOCK) ON NEWRS.RefStdName = OLDRS.RefStdName AND NEWRS.MasterDataTypeId = 1 AND NEWRS.IsObsolete = 0
		----WHERE PS.CustomerId = @SLC_CustomerId AND PS.ProjectId = @New_ProjectID AND PS.IsRefStdParagraph = 1
		----	AND [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription) < 10000000

		DROP TABLE IF EXISTS #NewOldSegmentStatusIdMapping;
		DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentStatus created', 'ProjectSegmentStatus created', '11', 33, @OldCount, @NewCount

		--Insert ProjectSegmentGlobalTerm_Staging table
		SELECT S.SegmentGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentId, S.mSegmentId, G1.UserGlobalTermId, G1.GlobalTermCode, S.IsLocked
			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentGlobalTerm_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
		LEFT JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] G WITH (NOLOCK) ON G.CustomerId = S.CustomerId AND G.ProjectId = S.ProjectId
			AND G.UserGlobalTermId = S.UserGlobalTermId
		LEFT JOIN #tmpProjectGlobalTerm G1 ON G1.CustomerId = G.CustomerId AND G1.A_GlobalTermId = G.GlobalTermId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentGlobalTerm table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentGlobalTerm]
		(CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy
			,ModifiedDate, ModifiedBy, IsDeleted)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentId, S.mSegmentId, S.UserGlobalTermId, S.GlobalTermCode, S.IsLocked
			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		FROM #ProjectSegmentGlobalTerm_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		LEFT JOIN #tmpProjectSegment S3 ON S2.ProjectId = S3.ProjectId AND S2.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpProjectGlobalTerm;
		DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
		
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentGlobalTerm created', 'ProjectSegmentGlobalTerm created', '12', 36, @OldCount, @NewCount

		--Move Header table
		INSERT INTO [SLCProject].[dbo].[Header]
		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
			,ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_HeaderId
			,HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader
			,IsShowLineBelowHeader)
		SELECT @New_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltHeader, S.FPHeader, S.UseSeparateFPHeader, S.HeaderFooterCategoryId
			,S.[DateFormat], S.TimeFormat, S.HeaderId AS A_HeaderId, S.HeaderFooterDisplayTypeId, S.DefaultHeader, S.FirstPageHeader, S.OddPageHeader, S.EvenPageHeader
			,S.DocumentTypeId, S.IsShowLineAboveHeader, S.IsShowLineBelowHeader
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Header] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSection S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S2.A_SectionId = S.SectionId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Header created', 'Header created', '13', 39, @OldCount, @NewCount

		--Move Footer table
		INSERT INTO [SLCProject].[dbo].[Footer]
		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
			,ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_FooterId
			,HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId, IsShowLineAboveFooter
			,IsShowLineBelowFooter)
		SELECT @New_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltFooter, S.FPFooter, S.UseSeparateFPFooter, S.HeaderFooterCategoryId
			,S.[DateFormat], S.TimeFormat, S.FooterId AS A_FooterId, S.HeaderFooterDisplayTypeId, S.DefaultFooter, S.FirstPageFooter, S.OddPageFooter, S.EvenPageFooter
			,S.DocumentTypeId, S.IsShowLineAboveFooter, IsShowLineBelowFooter
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Footer] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSection S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Footer created', 'Footer created', '14', 42, @OldCount, @NewCount


		--Move HeaderFooterGlobalTermUsage_Staging table
		SELECT S.HeaderFooterGTId, S.HeaderId, S.FooterId, G1.UserGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
		INTO #HeaderFooterGlobalTermUsage_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
		LEFT JOIN [SLCProject].[dbo].[UserGlobalTerm] G1 WITH (NOLOCK) ON G1.CustomerId = S.CustomerId AND G1.UserGlobalTermId = S.UserGlobalTermId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move HeaderFooterGlobalTermUsage table
		INSERT INTO [SLCProject].[dbo].[HeaderFooterGlobalTermUsage]
		(HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
		SELECT S2.HeaderId, S3.FooterId, S.UserGlobalTermId, S.CustomerId, S.ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
		FROM #HeaderFooterGlobalTermUsage_Staging S
		LEFT JOIN [SLCProject].[dbo].[Header] S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.HeaderId = S2.A_HeaderId
		LEFT JOIN [SLCProject].[dbo].[Footer] S3 WITH (NOLOCK) ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S.FooterId = S3.A_FooterId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HeaderFooterGlobalTermUsage created', 'HeaderFooterGlobalTermUsage created', '15', 45, @OldCount, @NewCount

		
		--Insert ProjectReferenceStandard_Staging table
		SELECT @New_ProjectID AS ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
			,S.SectionId, S.CustomerId, S.ProjRefStdId, S.IsDeleted
		INTO #ProjectReferenceStandard_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectReferenceStandard table
		INSERT INTO [SLCProject].[dbo].[ProjectReferenceStandard]
		(ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)
		SELECT S.ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
			,S2.SectionId, S.CustomerId, S.IsDeleted
		FROM #ProjectReferenceStandard_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId
		
		DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectReferenceStandard created', 'ProjectReferenceStandard created', '16', 48, @OldCount, @NewCount

		--Insert ProjectSegmentChoice_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.SegmentChoiceId, S.SectionId, S.SegmentStatusId, S.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
				,S.SegmentChoiceId AS A_SegmentChoiceId, S.IsDeleted
		INTO #ProjectSegmentChoice_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentChoice] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectSegmentChoice table
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
			(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
				,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
			SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
					,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
					,S.A_SegmentChoiceId, S.IsDeleted
			FROM #ProjectSegmentChoice_Staging S
			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			INNER JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
				AND S.SegmentId = S4.A_SegmentId
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @ProjectSegmentChoice_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1;
		END

		----Move ProjectSegmentChoice table
		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
		--(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
		--	,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
		--SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
		--		,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
		--		,S.A_SegmentChoiceId, S.IsDeleted
		--FROM #ProjectSegmentChoice_Staging S
		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
		--INNER JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
		--	AND S.SegmentId = S4.A_SegmentId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT C.SegmentChoiceId, C.ProjectId, C.SectionId, C.CustomerId, C.A_SegmentChoiceId INTO #tmpProjectSegmentChoice FROM [SLCProject].[dbo].[ProjectSegmentChoice] C WITH (NOLOCK)
		WHERE C.ProjectId = @New_ProjectID AND C.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice created', 'ProjectSegmentChoice created', '17', 51, @OldCount, @NewCount

		--Insert ProjectChoiceOption_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.ChoiceOptionId, S.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, @New_ProjectID AS ProjectId, S.SectionId, S.CustomerId, S.ChoiceOptionCode
			,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.ChoiceOptionId AS A_ChoiceOptionId, S.IsDeleted
		INTO #ProjectChoiceOption_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK) 
		--	ON S.ProjectId = PSC.ProjectId AND S.Sectionid = PSC.SectionId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectChoiceOption_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectChoiceOption table
			INSERT INTO [SLCProject].[dbo].[ProjectChoiceOption]
			(SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
				,A_ChoiceOptionId, IsDeleted)
			SELECT S3.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, S.ProjectId, S2.SectionId, S.CustomerId, S.ChoiceOptionCode
				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.A_ChoiceOptionId, S.IsDeleted
			FROM #ProjectChoiceOption_Staging S
			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentChoice S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentChoiceId = S3.A_SegmentChoiceId
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @ProjectChoiceOption_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectChoiceOption_BatchSize - 1;
		END

		----Move ProjectChoiceOption table
		--INSERT INTO [SLCProject].[dbo].[ProjectChoiceOption]
		--(SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
		--	,A_ChoiceOptionId, IsDeleted)
		--SELECT S3.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, S.ProjectId, S2.SectionId, S.CustomerId, S.ChoiceOptionCode
		--	,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.A_ChoiceOptionId, S.IsDeleted
		--FROM #ProjectChoiceOption_Staging S
		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentChoice S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentChoiceId = S3.A_SegmentChoiceId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpProjectSegmentChoice;
		DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectChoiceOption created', 'ProjectChoiceOption created', '18', 54, @OldCount, @NewCount

		--Insert SelectedChoiceOption_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SelectedChoiceOptionId) AS RowNumber, S.SelectedChoiceOptionId, S.SegmentChoiceCode, S.ChoiceOptionCode
				,S.ChoiceOptionSource, S.IsSelected, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId
				,S.OptionJson, S.IsDeleted
		INTO #SelectedChoiceOption_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SelectedChoiceOption] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)	
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @SelectedChoiceOption_BatchSize - 1
		WHILE @Records <= @TableRows
		BEGIN
			--Move SelectedChoiceOption table
			INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
			(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
			SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
			FROM #SelectedChoiceOption_Staging S
			--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSection S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
			WHERE S.SectionId = S2.A_SectionId AND S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND S.RowNumber BETWEEN @Start AND @End

			SET @Records += @SelectedChoiceOption_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @SelectedChoiceOption_BatchSize - 1;
		END

		----Move SelectedChoiceOption table
		--INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
		--(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
		--SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
		--FROM #SelectedChoiceOption_Staging S
		--INNER JOIN #tmpProjectSection S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SelectedChoiceOption created', 'SelectedChoiceOption created', '19', 57, @OldCount, @NewCount

		--Move ProjectHyperLink table
		SELECT ROW_NUMBER() OVER(ORDER BY S.HyperLinkId) AS RowNumber, S.HyperLinkId, S.SectionId, S.SegmentId
				,S.SegmentStatusId, @New_ProjectID AS ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
				,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
				,S.HyperLinkId AS A_HyperLinkId
		INTO #ProjectHyperLink_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectHyperLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectHyperLink_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectHyperLink table
			INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
			(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
				,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
			SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
					,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
					,S.A_HyperLinkId
			FROM #ProjectHyperLink_Staging S
			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			LEFT JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
				AND S.SegmentId = S4.A_SegmentId
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @ProjectHyperLink_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectHyperLink_BatchSize - 1;
		END

		----Move ProjectHyperLink table
		--INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
		--(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
		--	,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
		--SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
		--		,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
		--		,S.A_HyperLinkId
		--FROM #ProjectHyperLink_Staging S
		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
		--LEFT JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
		--	AND S.SegmentId = S4.A_SegmentId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT H.HyperLinkId, H.A_HyperLinkId, H.CustomerId, H.ProjectId, H.SectionId, H.SegmentStatusId, H.SegmentId
		INTO #tmpProjectHyperLink FROM [SLCProject].[dbo].[ProjectHyperLink] H WITH (NOLOCK) WHERE H.ProjectId = @New_ProjectID AND H.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegment A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentId
						,REPLACE (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegment PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegment A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentId) AS SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegment PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegment A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegment PS
					--INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					--INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
					--	AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%' 
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId


		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		
		DROP TABLE IF EXISTS #ProjectHyperLink_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink created', 'ProjectHyperLink created', '20', 60, @OldCount, @NewCount

		--Insert ProjectNote_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.NoteId) AS RowNumber, S.NoteId, S.SectionId, S.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.Title
				,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.NoteId AS A_NoteId
		INTO #ProjectNote_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectNote] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectNote_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectNote table
			INSERT INTO [SLCProject].[dbo].[ProjectNote]
			(SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName
				,ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
			SELECT S2.SectionId, S3.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId, S.Title
					,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
			FROM #ProjectNote_Staging S
			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @ProjectNote_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectNote_BatchSize - 1;
		END

		----Move ProjectNote table
		--INSERT INTO [SLCProject].[dbo].[ProjectNote]
		--(SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName
		--	,ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
		--SELECT S2.SectionId, S3.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId, S.Title
		--		,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
		--FROM #ProjectNote_Staging S
		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT P.NoteId, P.SectionId, P.SegmentStatusId, P.NoteText, P.ProjectId, P.CustomerId, P.A_NoteId INTO #tmpProjectNote
		FROM [SLCProject].[dbo].[ProjectNote] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId


		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNote A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId
						,REPLACE (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNote PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNote A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNote PS
					--INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					--INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
					--	AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNote PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		DROP TABLE IF EXISTS #ProjectNote_Staging;
		DROP TABLE IF EXISTS #tmpProjectHyperLink;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote created', 'ProjectNote created', '21', 63, @OldCount, @NewCount

		--Insert ProjectSegmentReferenceStandard_Staging table
		SELECT S.SegmentRefStandardId, S.SectionId, S.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
				,@New_ProjectID AS ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
		INTO #ProjectSegmentReferenceStandard_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


		--Move ProjectSegmentReferenceStandard table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentReferenceStandard]
		(SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, mSegmentId, ProjectId, CustomerId
			,RefStdCode, IsDeleted)
		SELECT S2.SectionId, S3.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
				,S.ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
		FROM #ProjectSegmentReferenceStandard_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		LEFT JOIN #tmpProjectSegment S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentReferenceStandard created', 'ProjectSegmentReferenceStandard created', '22', 66, @OldCount, @NewCount

		--Insert ProjectSegmentTab_Staging table
		SELECT S.SegmentTabId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy
		INTO #ProjectSegmentTab_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentTab] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentTab table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTab]
		(CustomerId, ProjectId, SectionId, SegmentStatusId, TabTypeId, TabPosition, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy
		FROM #ProjectSegmentTab_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTab created', 'ProjectSegmentTab created', '23', 69, @OldCount, @NewCount

		--Move ProjectSegmentRequirementTag_Staging table
		SELECT S.SegmentRequirementTagId, S.SectionId, S.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId
				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
		INTO #ProjectSegmentRequirementTag_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentRequirementTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentRequirementTag table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentRequirementTag]
		(SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId
			,IsDeleted)
		SELECT S2.SectionId, S3.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId
				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
		FROM #ProjectSegmentRequirementTag_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentRequirementTag created', 'ProjectSegmentRequirementTag created', '24', 72, @OldCount, @NewCount

		--Insert ProjectSegmentUserTag_Staging table
		SELECT S.SegmentUserTagId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentUserTag_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentUserTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Get UserTags used for project
		SELECT DISTINCT UserTagId INTO #tmpUserTags FROM #ProjectSegmentUserTag_Staging S WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Restore projects user tags used in a project and that are marked Deleted
		UPDATE U SET IsDeleted = 0
		FROM [SLCProject].[dbo].[ProjectUserTag] U WITH (NOLOCK) WHERE U.CustomerId = @SLC_CustomerId AND U.UserTagId IN (SELECT UserTagId FROM #tmpUserTags)
			AND U.IsDeleted = 1

		--Move ProjectSegmentUserTag table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentUserTag]
		(CustomerId, ProjectId, SectionId, SegmentStatusId, UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		FROM #ProjectSegmentUserTag_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpUserTags;
		DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentUserTag created', 'ProjectSegmentUserTag created', '25', 75, @OldCount, @NewCount

		--Insert ProjectSegmentImage_Staging table
		SELECT S.SegmentImageId, S.SegmentId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
		INTO #ProjectSegmentImage_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentImage table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentImage]
		(SegmentId, SectionId, ImageId, ProjectId, CustomerId, ImageStyle)
		SELECT S3.SegmentId, S2.SectionId, S4.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
		FROM #ProjectSegmentImage_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegment S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		INNER JOIN #tmpProjectImage S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT S.SegmentImageId, S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.ImageId INTO #tmpProjectSegmentImage
		FROM [SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK) WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Update Image plaholders with new ImageId in ProjectSegment table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegment A
		INNER JOIN (
					SELECT S5.CustomerId, S5.ProjectId, S5.SectionId, S5.SegmentId
						,REPLACE (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegment PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.SegmentId = S5.SegmentId
					INNER JOIN #tmpProjectImage ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId


		--Update Image plaholders with new ImageId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegment A
		INNER JOIN (
					SELECT S5.CustomerId, S5.ProjectId, MAX(S5.SectionId) AS SectionId, MAX(S5.SegmentId) AS SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegment PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.SegmentId = S5.SegmentId
					INNER JOIN #tmpProjectImage ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
					GROUP BY S5.ProjectId, S5.CustomerId, S5.SectionId, S5.SegmentId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId


		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		DROP TABLE IF EXISTS #tmpProjectSegmentImage;
		DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentImage created', 'ProjectSegmentImage created', '26', 78, @OldCount, @NewCount

		--Insert ProjectNoteImage_Staging table
		SELECT S.NoteImageId, S.NoteId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId
		INTO #ProjectNoteImage_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectNoteImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectNoteImage table
		INSERT INTO [SLCProject].[dbo].[ProjectNoteImage]
		(NoteId, SectionId, ImageId, ProjectId, CustomerId)
		SELECT S3.NoteId, S2.SectionId, S4.ImageId, S.ProjectId, S.CustomerId
		FROM #ProjectNoteImage_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectNote S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.NoteId = S3.A_NoteId
		INNER JOIN #tmpProjectImage S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT P.NoteImageId, P.ProjectId, P.CustomerId, P.SectionId, P.NoteId, P.ImageId INTO #tmpProjectNoteImage FROM [SLCProject].[dbo].[ProjectNoteImage] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId


		--Update Image placeholders with new ImageId in ProjectNote table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNote A
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId
						,REPLACE (PS.NoteText, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNote PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectNoteImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.NoteId = S5.NoteId
					INNER JOIN #tmpProjectImage ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'

		--Update Image placeholders with new ImageId in ProjectNote table
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNote A
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNote PS
					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectNoteImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.NoteId = S5.NoteId
					INNER JOIN #tmpProjectImage ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
					GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId--, S5.NoteId, S5.ImageId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'


		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNote PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		DROP TABLE IF EXISTS #tmpProjectImage;
		DROP TABLE IF EXISTS #tmpProjectNote;
		DROP TABLE IF EXISTS #tmpProjectSegmentStatus;
		DROP TABLE IF EXISTS #ProjectNoteImage_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNoteImage created', 'ProjectNoteImage created', '27', 81, @OldCount, @NewCount

		--Move ProjectSegmentLink table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentLinkId) AS RowNumber, S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
			,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
			,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentLinkCode
			,S.SegmentLinkSourceTypeId
		INTO #ProjectSegmentLink_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectSegmentLink_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Insert ProjectSegmentLink table
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
			(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource
				,TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId
				,IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
			SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
				,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
				,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
				,S.SegmentLinkSourceTypeId
			FROM #ProjectSegmentLink_Staging S
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @ProjectSegmentLink_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectSegmentLink_BatchSize - 1;
		END

		----Insert ProjectSegmentLink table
		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
		--(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource
		--	,TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId
		--	,IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
		--SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
		--	,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
		--	,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
		--	,S.SegmentLinkSourceTypeId
		--FROM #ProjectSegmentLink_Staging S
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentLink created', 'ProjectSegmentLink created', '28', 84, @OldCount, @NewCount

		--Move ProjectSegmentTracking table
		SELECT S.[SegmentId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		INTO #ProjectSegmentTracking_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentTracking] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTracking]
		([SegmentId], [ProjectId], [CustomerId], [UserId], [SegmentDescription], [CreatedBy], [CreateDate], [VersionNumber])
		SELECT S1.[SegmentId], S.[ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		FROM #ProjectSegmentTracking_Staging S
		INNER JOIN #tmpProjectSegment S1 ON S.CustomerId = S1.CustomerId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTracking created', 'ProjectSegmentTracking created', '29', 87, @OldCount, @NewCount

		--Move ProjectDisciplineSection table
		SELECT S.[SectionId], S.[Disciplineld], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[IsActive]
		INTO #ProjectDisciplineSection_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectDisciplineSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectDisciplineSection]
		([SectionId], [Disciplineld], [ProjectId], [CustomerId], [IsActive])
		SELECT S1.[SectionId], S.[Disciplineld], S.[ProjectId], S.[CustomerId], S.[IsActive]
		FROM #ProjectDisciplineSection_Staging S
		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDisciplineSection created', 'ProjectDisciplineSection created', '30', 90, @OldCount, @NewCount

		--Move ProjectDateFormat table
		INSERT INTO [SLCProject].[dbo].[ProjectDateFormat]
		([MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate])
		SELECT S.[MasterDataTypeId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[ClockFormat], S.[DateFormat], S.[CreateDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectDateFormat] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDateFormat created', 'ProjectDateFormat created', '31', 93, @OldCount, @NewCount

		--Move MaterialSection table
		SELECT @New_ProjectID AS [ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
		INTO #MaterialSection_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[MaterialSection]
		([ProjectId], [VimId], [MaterialId], [SectionId], [CustomerId])
		SELECT S.[ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
		FROM #MaterialSection_Staging S
		--INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #MaterialSection_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'MaterialSection created', 'MaterialSection created', '32', 96, @OldCount, @NewCount

		--Move LinkedSections table
		SELECT @New_ProjectID AS [ProjectId], S.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		INTO #LinkedSections_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[LinkedSections] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[LinkedSections]
		([ProjectId], [SectionId], [VimId], [MaterialId], [Linkedby], [LinkedDate], [customerId])
		SELECT S.[ProjectId], S1.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		FROM #LinkedSections_Staging S
		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpProjectSection;
		DROP TABLE IF EXISTS #LinkedSections_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'LinkedSections created', 'LinkedSections created', '33', 99, @OldCount, @NewCount

		--Load Project Migration Exception table
		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Choice' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\ch\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'ReferenceStandard' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\rs\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'HyperLink' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\hl\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Image' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\img\#%'

		DROP TABLE IF EXISTS #tmpProjectSegment;

		----Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
		--UPDATE P
		--SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0--, P.ModifiedDate = GETUTCDATE()
		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

		----Mark Old ProjectID as Deleted in SLCProject..Project table
		--UPDATE P
		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.ProjectId = @OldSLC_ProjectID AND P.CustomerId = @SLC_CustomerId;

		----Update Project details in Archive server for the project that has been UnArchived successfully
		--UPDATE A
		--SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE()
		--	,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
		--	,A.DisplayTabId = 3 --ActiveProjectsTab
		--	,A.ProcessInitiatedById = 3 --SLC
		--FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
		--WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

		----Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
		--UPDATE P
		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1
		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId;

		--EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '34', 100, 0, 0

		--UPDATE U
		--SET U.SLCProd_ProjectId = @New_ProjectID
		--FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
		--WHERE U.RequestId = @RequestId;

		--Restore Deleted global data
		EXECUTE [SLCProject].[dbo].[sp_RestoreDeletedGlobalData] @SLC_CustomerId, @New_ProjectID, @IsRestoreDeleteFailed OUTPUT

		IF @IsRestoreDeleteFailed = 1
		BEGIN
			SET @IsProjectMigrationFailed = 1

			--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
			UPDATE P
			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId;

			--Update Project details in Archive server for the project that has been UnArchived successfully
			UPDATE A
			SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
				,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
				,A.DisplayTabId = 1 --MigratedTab
			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Failed with Restore Delete', 'Failed with Restore Delete', '35', NULL, 0, 0
		END
		ELSE
		BEGIN
			--Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
			UPDATE P
			SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0--, P.ModifiedDate = GETUTCDATE()
			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

			--Mark Old ProjectID as Deleted in SLCProject..Project table
			UPDATE P
			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.ProjectId = @OldSLC_ProjectID AND P.CustomerId = @SLC_CustomerId;

			--Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
			UPDATE P
			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1
			FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId;

			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '34', 100, 0, 0

			UPDATE U
			SET U.SLCProd_ProjectId = @New_ProjectID
			FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
			WHERE U.RequestId = @RequestId;

			--Update Project details in Archive server for the project that has been UnArchived successfully
			UPDATE A
			SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE()
				,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
				,A.DisplayTabId = 3 --ActiveProjectsTab
				,A.ProcessInitiatedById = 3 --SLC
			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

		END

	END TRY

	BEGIN CATCH
		/*************************************
		*  Get the Error Message for @@Error
		*************************************/
		--Set IsProjectMigrationFailed to 1
		SET @IsProjectMigrationFailed = 1

		--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
		UPDATE P
		SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId;

		--Update Project details in Archive server for the project that has been UnArchived successfully
		UPDATE A
		SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
			,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
			,A.DisplayTabId = 1 --MigratedTab
		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
		WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived Failed', 'Project UnArchived Failed', '35', NULL, 0, 0

		SET @ErrorStep = 'UnArchiveMigrateProjectTables'

		SELECT @ErrorCode = ERROR_NUMBER()
			, @Return_Message = @ErrorStep + ' '
			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
			+ ERROR_MESSAGE() + ' > ' 
			+ ERROR_PROCEDURE()

		EXEC [SLCProject].[dbo].[spb_LogErrors] @ProjectID, @ErrorCode, @ErrorStep, @Return_Message

    
	END CATCH
		
	--	--Update Processed to 1
	--	UPDATE A
	--	SET A.IsProcessed = 1
	--	FROM #tmpUnArchiveCycleIDs A
	--	WHERE SLC_CustomerId = @SLC_CustomerId AND SLC_ArchiveProjectId = @ProjectID;

	--	SET @RowCount = @RowCount + 1
	--END

	--DROP TABLE #tmpUnArchiveCycleIDs
END

GO


