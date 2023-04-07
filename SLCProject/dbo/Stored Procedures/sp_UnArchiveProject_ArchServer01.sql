
CREATE PROCEDURE [dbo].[sp_UnArchiveProject_ArchServer01]
(
	@PSLC_CustomerId		INT
	,@PSLC_UserId			INT
	,@PProjectID			INT
	,@POldSLC_ProjectID		INT
	,@PArchive_ServerId		INT
)
AS
BEGIN

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

	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message VARCHAR(1024)
	DECLARE @ErrorStep VARCHAR(50)
	DECLARE @NumberRecords int, @RowCount int
	DECLARE @RequestId AS INT

	DECLARE @IsProjectMigrationFailed AS INT = 0
	DECLARE @IsRestoreDeleteFailed AS INT = 0

	--Set IsProjectMigrationFailed to 0 to reset it
	SET @IsProjectMigrationFailed = 0
	SET @RequestId = 0

	--Drop all Temp Tables
	DROP TABLE IF EXISTS #NewOldSectionIdMappingSLC;
	DROP TABLE IF EXISTS #NewOldSegmentStatusIdMappingSLC;
	DROP TABLE IF EXISTS #TGTProImgSLC;
	DROP TABLE IF EXISTS #tmp_TgtSectionSLC;
	DROP TABLE IF EXISTS #tmp_TgtSegmentStatusSLC;
	DROP TABLE IF EXISTS #tmpProjectGlobalTermSLC;
	DROP TABLE IF EXISTS #tmpProjectHyperLinkSLC;
	DROP TABLE IF EXISTS #tmpProjectImageSLC;
	DROP TABLE IF EXISTS #tmpProjectNoteSLC;
	DROP TABLE IF EXISTS #tmpProjectNoteImageSLC;
	DROP TABLE IF EXISTS #tmpProjectSectionSLC;
	DROP TABLE IF EXISTS #ProjectSegment_Staging;
	DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
	DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;
	DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;
	DROP TABLE IF EXISTS #tmpProjectSegmentSLC;
	DROP TABLE IF EXISTS #tmpProjectSegmentChoiceSLC;
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
	DROP TABLE IF EXISTS #SegmentComment_Staging;
	DROP TABLE IF EXISTS #TrackAcceptRejectProjectSegmentHistory_Staging;
	DROP TABLE IF EXISTS #TrackProjectSegment_Staging;
	DROP TABLE IF EXISTS #tmpProjectSegmentStatusSLC;
	DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;
	DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;
	DROP TABLE IF EXISTS #MaterialSection_Staging;
	DROP TABLE IF EXISTS #LinkedSections_Staging;
	DROP TABLE IF EXISTS #tmpSectionLevelTrackChangesLoggingSLC;
	DROP TABLE IF EXISTS #tmpTrackAcceptRejectHistorySLC;
	DROP TABLE IF EXISTS #TrackSegmentStatusType_Staging;

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

	--UnArchive Project Data

	DECLARE @New_ProjectID AS INT, @IsOfficeMaster AS INT, @ProjectAccessTypeId AS INT, @ProjectOwnerId AS INT
	DECLARE @OldCount AS INT = 0, @NewCount AS INT = 0, @StepName AS NVARCHAR(100), @Description AS NVARCHAR(500), @Step AS NVARCHAR(100)

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

		--Update previousely migrated projects A_ProjectId to NULL so it wont duplicate the records in other child tables.
		UPDATE P
		SET P.A_ProjectId = NULL, P.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.A_ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId;

		--Move Project table
		--Insert
		INSERT INTO [SLCProject].[dbo].[Project]
		([Name], IsOfficeMaster, [Description], TemplateId, MasterDataTypeId, UserId, CustomerId, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsDeleted, IsNamewithHeld
			,IsMigrated, IsLocked, A_ProjectId, IsProjectMoved, [GlobalProjectID], [IsPermanentDeleted], [ModifiedByFullName], [MigratedDate], [IsArchived], [IsShowMigrationPopup]
			,[LockedBy],[LockedDate],[LockedById],[IsIncomingProject],[TransferredDate])
		SELECT
			S.[Name], S.IsOfficeMaster, S.[Description], S.TemplateId, S.MasterDataTypeId, S.UserId, S.CustomerId, S.CreateDate, S.CreatedBy
			,S.ModifiedBy, S.ModifiedDate, S.IsDeleted, S.IsNamewithHeld, S.IsMigrated, S.IsLocked, S.ProjectId AS A_ProjectId, 0 AS IsProjectMoved
			,S.GlobalProjectID AS [GlobalProjectID], S.[IsPermanentDeleted], S.[ModifiedByFullName], S.[MigratedDate], S.[IsArchived], S.IsShowMigrationPopup
			,S.[LockedBy], S.[LockedDate], S.[LockedById], S.[IsIncomingProject], S.[TransferredDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT @New_ProjectID = ProjectId, @IsOfficeMaster = IsOfficeMaster, @MasterDataTypeId = MasterDataTypeId
		FROM [SLCProject].[dbo].[Project] WITH (NOLOCK) WHERE CustomerId = @SLC_CustomerId AND A_ProjectId = @ProjectID

		--Set IsDeleted flag to 1 for a temporary basis until whole project is Unarchived
		UPDATE P
		SET P.IsDeleted = 1, P.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID;

			
		SELECT @RequestId = RequestId FROM [SLCProject].[dbo].[UnArchiveProjectRequest] WITH (NOLOCK)
		WHERE [SLC_CustomerId] = @SLC_CustomerId AND [SLC_ArchiveProjectId] = @ProjectID
			AND [StatusId] = 1 --StatusId 1 as Queued

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'New Project created', 'New Project created', '1', 3, @OldCount, @NewCount

		--Move ProjectAddress table
		INSERT INTO [SLCProject].[dbo].[ProjectAddress]
		(ProjectId, CustomerId, AddressLine1, AddressLine2, CountryId, StateProvinceId, CityId, PostalCode, CreateDate, CreatedBy, ModifiedBy
			,ModifiedDate, StateProvinceName, CityName)
		SELECT @New_ProjectID AS ProjectId, S.CustomerId, S.AddressLine1, S.AddressLine2, S.CountryId, S.StateProvinceId, S.CityId, S.PostalCode
			,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.StateProvinceName, S.CityName
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectAddress] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectAddress created', 'ProjectAddress created', '2', 5, @OldCount, @NewCount

			
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
			,[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM],[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId]
			,[IsHiddenAllBsdSections],[IsLinkEngineEnabled])
		SELECT @New_ProjectID AS ProjectId,S.[CustomerId],S.[UserId],S.[ProjectTypeId],S.[FacilityTypeId],S.[SizeUoM],S.[IsIncludeRsInSection],S.[IsIncludeReInSection]
			,S.[SpecViewModeId],S.[UnitOfMeasureValueTypeId],S.[SourceTagFormat],S.[IsPrintReferenceEditionDate],S.[IsActivateRsCitation],S.[LastMasterUpdate]
			,S.[BudgetedCostId],S.[BudgetedCost],S.[ActualCost],S.[EstimatedArea],S.[SpecificationIssueDate],S.[SpecificationModifiedDate],S.[ActualCostId]
			,S.[ActualSizeId],S.[EstimatedSizeId],S.[EstimatedSizeUoM],S.[Cost],S.[Size]
			,CASE WHEN S.[ProjectAccessTypeId] IS NULL THEN @ProjectAccessTypeId ELSE S.[ProjectAccessTypeId] END AS [ProjectAccessTypeId]
			,CASE WHEN S.[OwnerId] IS NULL THEN @ProjectOwnerId ELSE S.[OwnerId] END AS [OwnerId],S.[TrackChangesModeId]
			,S.[IsHiddenAllBsdSections],S.[IsLinkEngineEnabled]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSummary created', 'ProjectSummary created', '3', 7, @OldCount, @NewCount

			
		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPrintSetting]
		([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage]
			,[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount],[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo]
			,IsIncludePdfBookmark, BookmarkLevel, IsIncludeOrphanParagraph, IsMarkPagesAsBlank, IsIncludeHeaderFooterOnBlackPages, BlankPagesText
			,IncludeSectionIdAfterEod, IncludeEndOfSection, IncludeDivisionNameandNumber, IsIncludeAuthorForBookMark, IsContinuousPageNumber)
		SELECT @New_ProjectID AS [ProjectId],S.[CustomerId],S.[CreatedBy],S.[CreateDate],S.[ModifiedBy],S.[ModifiedDate],S.[IsExportInMultipleFiles],S.[IsBeginSectionOnOddPage]
			,S.[IsIncludeAuthorInFileName],S.[TCPrintModeId], S.[IsIncludePageCount], S.IsIncludeHyperLink, S.KeepWithNext, S.[IsPrintMasterNote],S.[IsPrintProjectNote],S.[IsPrintNoteImage]
			,S.[IsPrintIHSLogo], S.IsIncludePdfBookmark, S.BookmarkLevel, S.IsIncludeOrphanParagraph, S.IsMarkPagesAsBlank, S.IsIncludeHeaderFooterOnBlackPages, S.BlankPagesText
			,S.IncludeSectionIdAfterEod, S.IncludeEndOfSection, S.IncludeDivisionNameandNumber, S.IsIncludeAuthorForBookMark, S.IsContinuousPageNumber
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPrintSetting] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPrintSetting created', 'ProjectPrintSetting created', '6', 15, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SELECT ROW_NUMBER() OVER(ORDER BY S.SectionId) AS RowNumber, S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
				,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
				,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
				,S.IsHidden, S.SortOrder, S.SectionSource, S.PendingUpdateCount
		INTO #tmp_TgtSectionSLC
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
				,TrackChangeLockedBy, DataMapDateTimeStamp, IsHidden, SortOrder, SectionSource, PendingUpdateCount)
			SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
					,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
					,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
					,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
					,S.IsHidden, S.SortOrder, S.SectionSource, S.PendingUpdateCount
			FROM #tmp_TgtSectionSLC S
			WHERE RowNumber BETWEEN @Start AND @End
 
			SET @Records += @Section_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @Section_BatchSize - 1;
		END

		--SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
		--		,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
		--		,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
		--		,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
		--INTO #tmp_TgtSectionSLC
		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		--WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--INSERT INTO [SLCProject].[dbo].[ProjectSection]
		--(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
		--	,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
		--	,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
		--	,TrackChangeLockedBy, DataMapDateTimeStamp)
		--SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
		--		,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
		--		,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
		--		,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
		--FROM #tmp_TgtSectionSLC S

		SELECT SectionId, ParentSectionId, ProjectId, CustomerId, A_SectionId, SectionSource INTO #tmpProjectSectionSLC
		FROM [SLCProject].[dbo].[ProjectSection] WITH (NOLOCK) WHERE ProjectId = @New_ProjectID AND CustomerId = @SLC_CustomerId

		SELECT ProjectId, CustomerId, SectionId, A_SectionId INTO #NewOldSectionIdMappingSLC FROM #tmpProjectSectionSLC

		--UPDATE ParentSectionId in TGT Section table                  
		UPDATE TGT_TMP SET TGT_TMP.ParentSectionId = NOSM.SectionId
		FROM #tmpProjectSectionSLC TGT_TMP
		INNER JOIN #NewOldSectionIdMappingSLC NOSM ON TGT_TMP.ParentSectionId = NOSM.A_SectionId
		WHERE TGT_TMP.ProjectId = @New_ProjectID;
			
		--UPDATE ParentSectionId in original table                  
		UPDATE PS SET PS.ParentSectionId = PS_TMP.ParentSectionId
		FROM [SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC PS_TMP ON PS.SectionId = PS_TMP.SectionId
		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @SLC_CustomerId;

		DROP TABLE IF EXISTS #tmp_TgtSectionSLC;
		DROP TABLE IF EXISTS #NewOldSectionIdMappingSLC;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSection created', 'ProjectSection created', '7', 17, @OldCount, @NewCount


		--Move ProjectPageSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPageSetting]
		([MarginTop],[MarginBottom],[MarginLeft],[MarginRight],[EdgeHeader],[EdgeFooter],[IsMirrorMargin],[ProjectId],[CustomerId],[SectionId],[TypeId])
		SELECT S.[MarginTop],S.[MarginBottom],S.[MarginLeft],S.[MarginRight],S.[EdgeHeader],S.[EdgeFooter],S.[IsMirrorMargin]
			,@New_ProjectID AS [ProjectId],S.[CustomerId]
			,CASE WHEN S.SectionId IS NULL THEN NULL ELSE PS.SectionId END AS SectionId,S.[TypeId]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPageSetting] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSectionSLC PS ON PS.ProjectId = @New_ProjectID AND PS.A_SectionId = S.SectionId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPageSetting created', 'ProjectPageSetting created', '4', 17, @OldCount, @NewCount

			
		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPaperSetting]
		(PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId, SectionId)
		SELECT S.PaperName, S.PaperWidth, S.PaperHeight, S.PaperOrientation, S.PaperSource, @New_ProjectID AS ProjectId, S.CustomerId
			,CASE WHEN S.SectionId IS NULL THEN NULL ELSE PS.SectionId END AS SectionId
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPaperSetting] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSectionSLC PS ON PS.ProjectId = @New_ProjectID AND PS.A_SectionId = S.SectionId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPaperSetting created', 'ProjectPaperSetting created', '5', 17, @OldCount, @NewCount


		SET @OldCount = 0

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

		SELECT P.GlobalTermId, P.CustomerId, P.ProjectId, P.UserGlobalTermId, P.GlobalTermCode, P.A_GlobalTermId INTO #tmpProjectGlobalTermSLC
		FROM [SLCProject].[dbo].[ProjectGlobalTerm] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectGlobalTerm created', 'ProjectGlobalTerm created', '8', 20, @OldCount, @NewCount

		--Insert #tmpProjectImage table
		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.[ImageId] AS A_ImageId
		INTO #TGTProImgSLC
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectImage] SRC WITH (NOLOCK)
		WHERE SRC.CustomerId = @SLC_CustomerId

		--Update ProjectImage table
		UPDATE TGT
			SET TGT.[ImagePath] = SRC.[ImagePath], TGT.[LuImageSourceTypeId] = SRC.[LuImageSourceTypeId],TGT.[CreateDate] = SRC.[CreateDate]
				,TGT.[ModifiedDate] = SRC.[ModifiedDate],TGT.[SLE_ProjectID] = SRC.[SLE_ProjectID],TGT.[SLE_DocID] = SRC.[SLE_DocID]
				,TGT.[SLE_StatusID] = SRC.[SLE_StatusID],TGT.[SLE_SegmentID] = SRC.[SLE_SegmentID],TGT.[SLE_ImageNo] = SRC.[SLE_ImageNo]
				,TGT.[SLE_ImageID] = SRC.[SLE_ImageID],TGT.[A_ImageId] = SRC.A_ImageId
		FROM [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK)
		INNER JOIN #TGTProImgSLC SRC
			ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND SRC.CustomerId = @SLC_CustomerId
		WHERE TGT.CustomerId = @SLC_CustomerId

		--Insert ProjectImage table
		INSERT INTO [SLCProject].[dbo].[ProjectImage]
		([ImagePath],[LuImageSourceTypeId],[CreateDate],[ModifiedDate],[CustomerId],[SLE_ProjectID],[SLE_DocID],[SLE_StatusID],[SLE_SegmentID]
			,[SLE_ImageNo],[SLE_ImageID],[A_ImageId])
		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.A_ImageId
		FROM #TGTProImgSLC SRC
		LEFT OUTER JOIN [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK) ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND TGT.CustomerId = @SLC_CustomerId
		WHERE SRC.CustomerId = @SLC_CustomerId AND TGT.ImagePath IS NULL

		SELECT I.ImageId, I.CustomerId, I.ImagePath, I.ImageId AS A_ImageId INTO #tmpProjectImageSLC
		FROM [SLCProject].[dbo].[ProjectImage] I WITH (NOLOCK) WHERE I.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #TGTProImgSLC;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectImage created', 'ProjectImage created', '9', 22, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Move ProjectSegment_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentId) AS RowNumber, S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
				,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		INTO #ProjectSegment_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment Staging Loaded', 'ProjectSegment Staging Loaded', '10', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
				AND S.SectionId = S2.A_SectionId
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
		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
		--	AND S.SectionId = S2.A_SectionId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment Records Added', 'ProjectSegment Records Added', '10', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		----Move ProjectSegment_Staging table
		--SELECT S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
		--		,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		--INTO #ProjectSegment_Staging
		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		----INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
		----	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
		--WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId


		SELECT S.SegmentId, S.SegmentStatusId, S.SegmentSource, S.SegmentCode, S.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.A_SegmentId
		INTO #tmpProjectSegmentSLC FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegment_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment created', 'ProjectSegment created', '10', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Insert #tmp_TgtSegmentStatusSLC table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentStatusId) AS RowNumber, S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
			,S.SLE_ProjectSegID, S.SLE_StatusID, S.SegmentStatusId AS A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		INTO #tmp_TgtSegmentStatusSLC
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentStatus Staging Loaded', 'ProjectSegmentStatus Staging Loaded', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Update SectionId in ProjectSegmentStatus table
		UPDATE S
			SET S.SectionId = S1.SectionId
		FROM #tmp_TgtSegmentStatusSLC S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SectionId Updated in ProjectSegmentStatus Staging', 'SectionId Updated in ProjectSegmentStatus Staging', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Update SegmentId in ProjectSegmentStatus table
		UPDATE S
			SET S.SegmentId = S1.SegmentId
		FROM #tmp_TgtSegmentStatusSLC S
		INNER JOIN #tmpProjectSegmentSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.SectionId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SegmentId Updated in ProjectSegmentStatus Staging', 'SegmentId Updated in ProjectSegmentStatus Staging', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @SegmentStatus_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectSegmentStatus table
			INSERT INTO [dbo].[ProjectSegmentStatus]
			(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
				,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
				,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
				,IsDeleted, TrackOriginOrder, MTrackDescription)
			SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
				,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, S.ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
				,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
				,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
			FROM #tmp_TgtSegmentStatusSLC S
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @SegmentStatus_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @SegmentStatus_BatchSize - 1;
		END

		----Move ProjectSegmentStatus table
		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
		--(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
		--	,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
		--	,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
		--	,IsDeleted, TrackOriginOrder, MTrackDescription)
		--SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
		--	,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, S.ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
		--	,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
		--	,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		--FROM #tmp_TgtSegmentStatusSLC S

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Records Inserted ProjectSegmentStatus', 'Records Inserted ProjectSegmentStatus', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SELECT S.* INTO #tmpProjectSegmentStatusSLC FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT SegmentStatusId, A_SegmentStatusId INTO #NewOldSegmentStatusIdMappingSLC
		FROM #tmpProjectSegmentStatusSLC S

		DROP TABLE IF EXISTS #tmp_TgtSegmentStatusSLC;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table created for ProjectSegmentStatus', 'Temp Table created for ProjectSegmentStatus', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--UPDATE ParentSegmentStatusId in temp table
		UPDATE CPSST
		SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId
		FROM #tmpProjectSegmentStatusSLC CPSST
		INNER JOIN #NewOldSegmentStatusIdMappingSLC PPSST
			ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId AND CPSST.ParentSegmentStatusId <> 0

		DROP TABLE IF EXISTS #NewOldSegmentStatusIdMappingSLC;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table - Updated ParentSegmentStatusId', 'Temp Table - Updated ParentSegmentStatusId', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--UPDATE ParentSegmentStatusId in original table
		UPDATE PSS
		SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId
		FROM [dbo].[ProjectSegmentStatus] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentStatusSLC PSS_TMP ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId
		WHERE PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ParentSegmentStatusId in Original Table', 'ParentSegmentStatusId in Original Table', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Update SegmentStatusId in #tmpProjectSegment
		UPDATE PS
			SET PS.SegmentStatusId = SS.SegmentStatusId
		FROM #tmpProjectSegmentSLC PS
		INNER JOIN #tmpProjectSegmentStatusSLC SS ON SS.ProjectId = PS.ProjectId AND SS.CustomerId = PS.CustomerId
			AND SS.SectionId = PS.SectionId AND SS.SegmentId = PS.SegmentId
		WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table - Updated SegmentStatusId', 'Temp Table - Updated SegmentStatusId', '11', 25, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--UPDATE SegmentStatusId in original table
		UPDATE PSS
		SET PSS.SegmentStatusId = PSS_TMP.SegmentStatusId
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
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

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentStatus created', 'ProjectSegmentStatus created', '11', 27, @OldCount, @NewCount

		SET @OldCount = 0

		--SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentGlobalTerm'
		--EXECUTE [DE_Projects_Staging].[dbo].[spb_UnArchiveLog] @SLC_CustomerId, @New_ProjectID, @LogMessage

		--SELECT @OldCount = COUNT(9) FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] WITH (NOLOCK) WHERE CustomerID = @SLC_CustomerId AND ProjectId = @ProjectID
		--IF @Row_Count > 0
		--BEGIN
		--	SET @LogMessage = CAST(@Row_Count AS VARCHAR) + ' OLD ProjectSegmentGlobalTerm records'
		--	EXECUTE [DE_Projects_Staging].[dbo].[spb_UnArchiveLog] @SLC_CustomerId, @New_ProjectID, @LogMessage
		--END

		--Insert ProjectSegmentGlobalTerm_Staging table
		SELECT S.SegmentGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentId, S.mSegmentId, G1.UserGlobalTermId, G1.GlobalTermCode, S.IsLocked
			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentGlobalTerm_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
		LEFT JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] G WITH (NOLOCK) ON S.CustomerId = G.CustomerId AND G.ProjectId = S.ProjectId
			AND G.UserGlobalTermId = S.UserGlobalTermId
		LEFT JOIN #tmpProjectGlobalTermSLC G1 ON G1.CustomerId = G.CustomerId AND G1.A_GlobalTermId = G.GlobalTermId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentGlobalTerm table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentGlobalTerm]
		(CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy
			,ModifiedDate, ModifiedBy, IsDeleted)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentId, S.mSegmentId, S.UserGlobalTermId, S.GlobalTermCode, S.IsLocked
			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		FROM #ProjectSegmentGlobalTerm_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpProjectGlobalTermSLC;
		DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentGlobalTerm created', 'ProjectSegmentGlobalTerm created', '12', 30, @OldCount, @NewCount

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
		LEFT JOIN #tmpProjectSectionSLC S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S2.A_SectionId = S.SectionId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Header created', 'Header created', '13', 32, @OldCount, @NewCount

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
		LEFT JOIN #tmpProjectSectionSLC S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Footer created', 'Footer created', '14', 35, @OldCount, @NewCount

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

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HeaderFooterGlobalTermUsage created', 'HeaderFooterGlobalTermUsage created', '15', 37, @OldCount, @NewCount

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
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId
						
		DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectReferenceStandard created', 'ProjectReferenceStandard created', '16', 40, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice Staging Loaded', 'ProjectSegmentChoice Staging Loaded', '17', 42, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			INNER JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
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
		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
		--INNER JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
		--	AND S.SegmentId = S4.A_SegmentId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice Records Inserted', 'ProjectSegmentChoice Records Inserted', '17', 42, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SELECT C.SegmentChoiceId, C.ProjectId, C.SectionId, C.CustomerId, C.A_SegmentChoiceId INTO #tmpProjectSegmentChoiceSLC FROM [SLCProject].[dbo].[ProjectSegmentChoice] C WITH (NOLOCK)
		WHERE C.ProjectId = @New_ProjectID AND C.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice created', 'ProjectSegmentChoice created', '17', 42, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Insert ProjectChoiceOption_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.ChoiceOptionId, S.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, @New_ProjectID AS ProjectId, S.SectionId, S.CustomerId, S.ChoiceOptionCode
			,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.ChoiceOptionId AS A_ChoiceOptionId, S.IsDeleted
		INTO #ProjectChoiceOption_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK) 
		--	ON S.ProjectId = PSC.ProjectId AND S.Sectionid = PSC.SectionId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectChoiceOption Staging Loaded', 'ProjectChoiceOption Staging Loaded', '18', 45, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentChoiceSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
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
		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentChoiceSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentChoiceId = S3.A_SegmentChoiceId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpProjectSegmentChoiceSLC;
		DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectChoiceOption created', 'ProjectChoiceOption created', '18', 45, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Insert SelectedChoiceOption_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SelectedChoiceOptionId) AS RowNumber, S.SelectedChoiceOptionId, S.SegmentChoiceCode, S.ChoiceOptionCode
				,S.ChoiceOptionSource, S.IsSelected, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId
				,S.OptionJson, S.IsDeleted
		INTO #SelectedChoiceOption_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SelectedChoiceOption] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = 0
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)
		
		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SelectedChoiceOption Staging Loaded', 'SelectedChoiceOption Staging Loaded', '19', 47, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
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
		--INNER JOIN #tmpProjectSectionSLC S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
		--WHERE S.SectionId = S2.A_SectionId AND S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SelectedChoiceOption created', 'SelectedChoiceOption created', '19', 47, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Move ProjectHyperLink table
		SELECT ROW_NUMBER() OVER(ORDER BY S.HyperLinkId) AS RowNumber, S.HyperLinkId, S.SectionId, S.SegmentId
				,S.SegmentStatusId, @New_ProjectID AS ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
				,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
				,S.HyperLinkId AS A_HyperLinkId
		INTO #ProjectHyperLink_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectHyperLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink Staging Loaded', 'ProjectHyperLink Staging Loaded', '20', 50, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			LEFT JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
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
		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
		--LEFT JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
		--	AND S.SegmentId = S4.A_SegmentId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink Records Added', 'ProjectHyperLink Records Added', '20', 50, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SELECT H.HyperLinkId, H.A_HyperLinkId, H.CustomerId, H.ProjectId, H.SectionId, H.SegmentStatusId, H.SegmentId
		INTO #tmpProjectHyperLinkSLC FROM [SLCProject].[dbo].[ProjectHyperLink] H WITH (NOLOCK) WHERE H.ProjectId = @New_ProjectID AND H.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectHyperLink_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table Created from ProjectHyperLink', 'Temp Table Created from ProjectHyperLink', '20', 50, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		-----UPDATE NEW HyperLinkId in SegmentDescription      
		--DECLARE @MultipleHyperlinkCount INT = 0;
		--SELECT COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl FROM ProjectHyperLink WITH (NOLOCK) WHERE ProjectId = @New_ProjectID GROUP BY SegmentStatusId

		--SELECT @MultipleHyperlinkCount = MAX(TotalCountSegmentStatusId) FROM #TotalCountSegmentStatusIdTbl
		--WHILE (@MultipleHyperlinkCount > 0)
		--BEGIN
		--	UPDATE PS
		--		SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')
		--	FROM ProjectHyperLink PHL WITH (NOLOCK)
		--	INNER JOIN ProjectSegment PS WITH (NOLOCK) ON PS.SegmentStatusId = PHL.SegmentStatusId AND PS.SegmentId = PHL.SegmentId AND PS.SectionId = PHL.SectionId
		--		AND PS.ProjectId = PHL.ProjectId AND PS.CustomerId = PHL.CustomerId
		--	WHERE PHL.ProjectId = @New_ProjectID AND PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%' AND PS.SegmentDescription LIKE '%{HL#%'

		--	SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;
		--END


		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentId
						,REPLACE (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentId) AS SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					--INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					--INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
					--	AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%' 
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

		

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HyperLink PlaceHolder Updated', 'HyperLink PlaceHolder Updated', '20', 50, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.SegmentDescription LIKE '%{HL#%';

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink created', 'ProjectHyperLink created', '20', 50, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Insert ProjectNote_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.NoteId) AS RowNumber, S.NoteId, S.SectionId, S.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.Title
				,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.NoteId AS A_NoteId
		INTO #ProjectNote_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectNote] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote Staging Loaded', 'ProjectNote Staging Loaded', '21', 52, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
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
		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote Records Inserted', 'ProjectNote Records Inserted', '21', 52, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SELECT P.NoteId, P.SectionId, P.SegmentStatusId, P.NoteText, P.ProjectId, P.CustomerId, P.A_NoteId INTO #tmpProjectNoteSLC
		FROM [SLCProject].[dbo].[ProjectNote] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectNote_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table created for ProjectNote', 'Temp Table created for ProjectNote', '21', 52, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()


		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNoteSLC A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId
						,REPLACE (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNoteSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'


		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNoteSLC A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNoteSLC PS
					--INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
					--	AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		DROP TABLE IF EXISTS #tmpProjectHyperLinkSLC;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HyperLinkId updated in Temp ProjectNote', 'HyperLinkId updated in Temp ProjectNote', '21', 52, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNoteSLC PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.NoteText LIKE '%{HL#%';

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote created', 'ProjectNote created', '21', 52, @OldCount, @NewCount

		SET @OldCount = 0

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
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentReferenceStandard created', 'ProjectSegmentReferenceStandard created', '22', 55, @OldCount, @NewCount

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
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTab created', 'ProjectSegmentTab created', '23', 57, @OldCount, @NewCount

		--Move ProjectSegmentRequirementTag_Staging table
		SELECT S.SegmentRequirementTagId, S.SectionId, S.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId
				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
		INTO #ProjectSegmentRequirementTag_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentRequirementTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentRequirementTag table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentRequirementTag]
		(SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy
			,mSegmentRequirementTagId, IsDeleted)
		SELECT S2.SectionId, S3.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId
				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
		FROM #ProjectSegmentRequirementTag_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentRequirementTag created', 'ProjectSegmentRequirementTag created', '24', 60, @OldCount, @NewCount

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
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #tmpUserTags;
		DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentUserTag created', 'ProjectSegmentUserTag created', '25', 62, @OldCount, @NewCount

		--Insert ProjectSegmentImage_Staging table
		SELECT S.SegmentImageId, S.SegmentId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
		INTO #ProjectSegmentImage_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentImage table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentImage]
		(SegmentId, SectionId, ImageId, ProjectId, CustomerId, ImageStyle)
		SELECT CASE WHEN S3.SegmentId IS NULL THEN 0 ELSE S3.SegmentId END AS SegmentId, S2.SectionId, S4.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
		FROM #ProjectSegmentImage_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectImageSLC S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT S.SegmentImageId, S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.ImageId INTO #tmpProjectSegmentImage
		FROM [SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK) WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Update Image plaholders with new ImageId in ProjectSegment table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT S5.CustomerId, S5.ProjectId, S5.SectionId, S5.SegmentId
						,REPLACE (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.SegmentId = S5.SegmentId
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId


		--Update Image plaholders with new ImageId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT S5.CustomerId, S5.ProjectId, MAX(S5.SectionId) AS SectionId, MAX(S5.SegmentId) AS SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.SegmentId = S5.SegmentId
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
					GROUP BY S5.ProjectId, S5.CustomerId, S5.SectionId, S5.SegmentId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId
		

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.SegmentDescription LIKE '%{IMG#%';

		DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentImage created', 'ProjectSegmentImage created', '26', 65, @OldCount, @NewCount

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
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectNoteSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.NoteId = S3.A_NoteId
		INNER JOIN #tmpProjectImageSLC S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT P.NoteImageId, P.ProjectId, P.CustomerId, P.SectionId, P.NoteId, P.ImageId INTO #tmpProjectNoteImageSLC FROM [SLCProject].[dbo].[ProjectNoteImage] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId


		--Update Image placeholders with new ImageId in ProjectNote table, THIS CODE WILL USE REPLACE FUNCTION
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNoteSLC A
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId
						,REPLACE (PS.NoteText, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNoteSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectNoteImageSLC S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.NoteId = S5.NoteId
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'


		--Update Image placeholders with new ImageId in ProjectNote table
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNoteSLC A
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNoteSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectNoteImageSLC S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						AND PS.NoteId = S5.NoteId
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
					GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId--, S5.NoteId, S5.ImageId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNoteSLC PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.NoteText LIKE '%{IMG#%';

		DROP TABLE IF EXISTS #tmpProjectImageSLC;
		DROP TABLE IF EXISTS #tmpProjectNoteSLC;
		DROP TABLE IF EXISTS #tmpProjectNoteImageSLC;
		DROP TABLE IF EXISTS #ProjectNoteImage_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNoteImage created', 'ProjectNoteImage created', '27', 67, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		--Move ProjectSegmentLink table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentLinkId) AS RowNumber, S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
			,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
			,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentLinkCode
			,S.SegmentLinkSourceTypeId
		INTO #ProjectSegmentLink_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		SET @TableRows = @@ROWCOUNT

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentLink Staging Loaded', 'ProjectSegmentLink Staging Loaded', '28', 70, @OldCount, @NewCount

		SET @StartTime = GETUTCDATE()

		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectSegmentLink_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectSegmentLink table
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
			(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode
				,TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, IsDeleted
				,CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
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

		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
		--(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode
		--	,TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, IsDeleted
		--	,CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
		--SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
		--	,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
		--	,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
		--	,S.SegmentLinkSourceTypeId
		--FROM #ProjectSegmentLink_Staging S
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;

		SET @EndTime = GETUTCDATE()
		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentLink created', 'ProjectSegmentLink created', '28', 70, @OldCount, @NewCount

		SET @OldCount = 0

		--Move ProjectSegmentTracking table
		SELECT S.[SegmentId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		INTO #ProjectSegmentTracking_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentTracking] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTracking]
		([SegmentId], [ProjectId], [CustomerId], [UserId], [SegmentDescription], [CreatedBy], [CreateDate], [VersionNumber])
		SELECT S1.[SegmentId], S.[ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		FROM #ProjectSegmentTracking_Staging S
		INNER JOIN #tmpProjectSegmentSLC S1 ON S.CustomerId = S1.CustomerId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTracking created', 'ProjectSegmentTracking created', '29', 72, @OldCount, @NewCount

		--Move ProjectDisciplineSection table
		SELECT S.[SectionId], S.[Disciplineld], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[IsActive]
		INTO #ProjectDisciplineSection_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectDisciplineSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectDisciplineSection]
		([SectionId], [Disciplineld], [ProjectId], [CustomerId], [IsActive])
		SELECT S1.[SectionId], S.[Disciplineld], S.[ProjectId], S.[CustomerId], S.[IsActive]
		FROM #ProjectDisciplineSection_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDisciplineSection created', 'ProjectDisciplineSection created', '30', 75, @OldCount, @NewCount

		--Move ProjectDateFormat table
		INSERT INTO [SLCProject].[dbo].[ProjectDateFormat]
		([MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate])
		SELECT S.[MasterDataTypeId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[ClockFormat], S.[DateFormat], S.[CreateDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectDateFormat] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDateFormat created', 'ProjectDateFormat created', '31', 77, @OldCount, @NewCount

		--Move MaterialSection table
		DECLARE @RowExists AS INT = 0

		SELECT @RowExists = COUNT(1) FROM [ARCHIVESERVER01].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		IF @RowExists > 0
		BEGIN
			DECLARE @NumRecords AS INT, @RCount AS INT
			SELECT ROW_NUMBER()OVER(ORDER BY Id DESC) AS RowNumber, @New_ProjectID AS [ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId] INTO #MaterialSection_Staging
			FROM [ARCHIVESERVER01].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
			WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			SET @NumRecords = @@ROWCOUNT
			SET @RCount = 1

			-- loop through all records in the temporary table using the WHILE loop construct
			WHILE @RCount <= @NumRecords
			BEGIN
				DECLARE @strSectionId AS NVARCHAR(MAX)=''
				DECLARE @sectionIds nvarchar(max)=''

				SELECT @strSectionId = SectionId FROM #MaterialSection_Staging WHERE RowNumber = @RCount

				DROP TABLE IF EXISTS #tmpSplitSectionIds;

				SELECT splitdata AS StrSectionId into #tmpSplitSectionIds from dbo.fn_SplitString(@strSectionId,',')

				UPDATE A SET A.StrSectionId = B.SectionId
				FROM #tmpSplitSectionIds A
				INNER JOIN #tmpProjectSectionSLC B ON A.StrSectionId = B.A_SectionId
				WHERE B.ProjectId = @New_ProjectID AND B.CustomerId = @SLC_CustomerId

				SET @sectionIds=(SELECT concat(StrSectionId,',') from #tmpSplitSectionIds for xml PATH(''))

				UPDATE A SET A.SectionId = @sectionIds FROM #MaterialSection_Staging A WHERE RowNumber = @RCount

				SET @RCount = @RCount + 1
			END

			INSERT INTO [SLCProject].[dbo].[MaterialSection]
			([ProjectId], [VimId], [MaterialId], [SectionId], [CustomerId])
			SELECT S.[ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
			FROM #MaterialSection_Staging S
			WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

			DROP TABLE IF EXISTS #MaterialSection_Staging;

		END

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'MaterialSection created', 'MaterialSection created', '32', 80, @OldCount, @NewCount

		--Move LinkedSections table
		SELECT @New_ProjectID AS [ProjectId], S.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		INTO #LinkedSections_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[LinkedSections] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[LinkedSections]
		([ProjectId], [SectionId], [VimId], [MaterialId], [Linkedby], [LinkedDate], [customerId])
		SELECT S.[ProjectId], S1.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		FROM #LinkedSections_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #LinkedSections_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'LinkedSections created', 'LinkedSections created', '33', 82, @OldCount, @NewCount

		--Move ApplyMasterUpdateLog table
		INSERT INTO [SLCProject].[dbo].[ApplyMasterUpdateLog]
		([ProjectId], [LastUpdateDate])
		SELECT @New_ProjectID AS [ProjectId], S.[LastUpdateDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ApplyMasterUpdateLog] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ApplyMasterUpdateLog created', 'ApplyMasterUpdateLog created', '34', 85, @OldCount, @NewCount

		--Move ProjectExport table
		INSERT INTO [SLCProject].[dbo].[ProjectExport]
		([FileName],[ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy],[CreatedByFullName]
			,[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId],[ProjectName],[FileStatus],[PrintFailureReason])
		SELECT [FileName], @New_ProjectID AS [ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy]
			,[CreatedByFullName],[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId],[ProjectName],[FileStatus],[PrintFailureReason]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectExport] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectExport created', 'ProjectExport created', '35', 87, @OldCount, @NewCount

		--Move SegmentComment table
		SELECT @New_ProjectID AS [ProjectId],[SectionId],[SegmentStatusId],[ParentCommentId]
			,[CommentDescription],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[CommentStatusId],[IsDeleted],[userFullName]
			,[SegmentCommentId] AS [A_SegmentCommentId]
		INTO #SegmentComment_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SegmentComment] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Insert SegmentComment table
		INSERT INTO [SLCProject].[dbo].[SegmentComment]
		(ProjectId,[SectionId],[SegmentStatusId],[ParentCommentId],[CommentDescription],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy]
			,[ModifiedDate],[CommentStatusId],[IsDeleted],[userFullName],A_SegmentCommentId)
		SELECT S.ProjectId,S1.[SectionId],S2.[SegmentStatusId],S.[ParentCommentId],S.[CommentDescription],S.[CustomerId],S.[CreatedBy],S.[CreateDate]
			,S.[ModifiedBy],S.[ModifiedDate],S.[CommentStatusId],S.[IsDeleted],S.[userFullName],S.A_SegmentCommentId
		FROM #SegmentComment_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentStatusId = S2.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Update ParentCommentId
		UPDATE CST
			SET CST.ParentCommentId = PST.SegmentCommentId
		FROM [SLCProject].[dbo].[SegmentComment] CST WITH (NOLOCK)
		INNER JOIN [SLCProject].[dbo].[SegmentComment] PST WITH (NOLOCK) ON CST.ProjectId = PST.ProjectId AND CST.CustomerId = PST.CustomerId
			AND CST.SectionId = PST.SectionId AND PST.A_SegmentCommentId = CST.ParentCommentId AND CST.ParentCommentId <> 0
		WHERE CST.ProjectId = @New_ProjectID AND CST.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #SegmentComment_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SegmentComment created', 'SegmentComment created', '36', 90, @OldCount, @NewCount

		--Move TrackAcceptRejectProjectSegmentHistory table
		SELECT [SectionId],[SegmentId], @New_ProjectID AS [ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note]
		INTO #TrackAcceptRejectProjectSegmentHistory_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory]
		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note])
		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[TrackActionId],S.[Note]
		FROM #TrackAcceptRejectProjectSegmentHistory_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentId = S2.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #TrackAcceptRejectProjectSegmentHistory_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'TrackAcceptRejectProjectSegmentHistory created', 'TrackAcceptRejectProjectSegmentHistory created', '37', 92, @OldCount, @NewCount

		--Insert TrackProjectSegment_Staging table
		SELECT [SectionId],[SegmentId],@New_ProjectID AS [ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate]
			,[ChangedDate],[ChangedById],[IsDeleted]
		INTO #TrackProjectSegment_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move TrackProjectSegment table
		INSERT INTO [SLCProject].[dbo].[TrackProjectSegment]
		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate],[ChangedDate],[ChangedById],[IsDeleted])
		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[CreateDate],S.[ChangedDate],S.[ChangedById]
			,S.[IsDeleted]
		FROM #TrackProjectSegment_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentId = S2.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		DROP TABLE IF EXISTS #TrackProjectSegment_Staging;

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'TrackProjectSegment created', 'TrackProjectSegment created', '38', 93, @OldCount, @NewCount

		--Move UserProjectAccessMapping table
		INSERT INTO [SLCProject].[dbo].[UserProjectAccessMapping]
		([ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive])
		SELECT @New_ProjectID AS [ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[UserProjectAccessMapping] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'UserProjectAccessMapping created', 'UserProjectAccessMapping created', '39', 94, @OldCount, @NewCount


		--Move ProjectActivity table
		INSERT INTO [SLCProject].[dbo].[ProjectActivity]
		([ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate])
		SELECT @New_ProjectID AS [ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectActivity] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectActivity created', 'ProjectActivity created', '40', 95, @OldCount, @NewCount


		--Move ProjectLevelTrackChangesLogging table
		INSERT INTO [SLCProject].[dbo].[ProjectLevelTrackChangesLogging]
		([UserId],[ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate])
		SELECT [UserId],@New_ProjectID AS [ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectLevelTrackChangesLogging] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectLevelTrackChangesLogging created', 'ProjectLevelTrackChangesLogging created', '41', 96, @OldCount, @NewCount


		--Insert 
		SELECT [UserId],@New_ProjectID AS [ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate]
		INTO #tmpSectionLevelTrackChangesLoggingSLC
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SectionLevelTrackChangesLogging] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


		--Move SectionLevelTrackChangesLogging table
		INSERT INTO [SLCProject].[dbo].[SectionLevelTrackChangesLogging]
		([UserId],[ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate])
		SELECT S.[UserId],S.[ProjectId],S1.[SectionId],S.[CustomerId],S.[UserEmail],S.[IsTrackChanges],S.[IsTrackChangeLock],S.[CreatedDate]
		FROM #tmpSectionLevelTrackChangesLoggingSLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Update data for BIM files --Replace Old Production ProjectId with newly unarchived ProjectId

		--Update VimDb..VimFileInfo
		UPDATE S SET S.ProjectId = @New_ProjectID
		FROM [VimDb].[dbo].[VimFileInfo] S WITH (NOLOCK)
		WHERE S.ProjectId = @OldSLC_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Update VimDb..RevitExportJobs
		UPDATE S SET S.ProjectId = @New_ProjectID
		FROM [VimDb].[dbo].[RevitExportJobs] S WITH (NOLOCK)
		WHERE S.ProjectId = @OldSLC_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Update VimDb..VimProjectMapping
		UPDATE S SET S.ProjectId = @New_ProjectID
		FROM [VimDb].[dbo].[VimProjectMapping] S WITH (NOLOCK)
		WHERE S.ProjectId = @OldSLC_ProjectID

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SectionLevelTrackChangesLogging created', 'SectionLevelTrackChangesLogging created', '42', 97, @OldCount, @NewCount


		--Insert 
		SELECT [SectionId],@New_ProjectID AS [ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate]
		INTO #tmpTrackAcceptRejectHistorySLC
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackAcceptRejectHistory] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


		--Move TrackAcceptRejectHistory table
		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectHistory]
		([SectionId],[ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate])
		SELECT S1.[SectionId],S.[ProjectId],S.[CustomerId],S.[UserId],S.[TrackActionId],S.[CreateDate]
		FROM #tmpTrackAcceptRejectHistorySLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'TrackAcceptRejectHistory created', 'TrackAcceptRejectHistory created', '43', 98, @OldCount, @NewCount


		--Insert TrackSegmentStatusType table
		SELECT @New_ProjectID AS [ProjectId],[SectionId],[CustomerId],[SegmentStatusId],[SegmentStatusTypeId],[PrevStatusSegmentStatusTypeId],[InitialStatusSegmentStatusTypeId],[IsAccepted],[UserId]
			,[UserFullName],[CreatedDate],[ModifiedById],[ModifiedByUserFullName],[ModifiedDate],[TenantId],[InitialStatus],[IsSegmentStatusChangeBySelection],[CurrentStatus]
			,[SegmentStatusTypeIdBeforeSelection]
		INTO #TrackSegmentStatusType_Staging
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackSegmentStatusType] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		--Move TrackSegmentStatusType table
		INSERT INTO [SLCProject].[dbo].[TrackSegmentStatusType]
		([ProjectId],[SectionId],[CustomerId],[SegmentStatusId],[SegmentStatusTypeId],[PrevStatusSegmentStatusTypeId],[InitialStatusSegmentStatusTypeId],[IsAccepted],[UserId],[UserFullName]
			,[CreatedDate],[ModifiedById],[ModifiedByUserFullName],[ModifiedDate],[TenantId],[InitialStatus],[IsSegmentStatusChangeBySelection],[CurrentStatus]
			,[SegmentStatusTypeIdBeforeSelection])
		SELECT S.[ProjectId],S1.[SectionId],S.[CustomerId],S2.[SegmentStatusId],S.[SegmentStatusTypeId],S.[PrevStatusSegmentStatusTypeId],S.[InitialStatusSegmentStatusTypeId],S.[IsAccepted],S.[UserId]
			,S.[UserFullName],S.[CreatedDate],S.[ModifiedById],S.[ModifiedByUserFullName],S.[ModifiedDate],S.[TenantId],S.[InitialStatus],S.[IsSegmentStatusChangeBySelection],S.[CurrentStatus]
			,S.[SegmentStatusTypeIdBeforeSelection]
		FROM #TrackSegmentStatusType_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegmentStatusSLC S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentStatusId = S2.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--Move FileNameFormatSetting table
		INSERT INTO [dbo].[FileNameFormatSetting]
		([FileFormatCategoryId],[IncludeAutherSectionId],[Separator],[FormatJsonWithPlaceHolder],[ProjectId],[CustomerId],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
		SELECT [FileFormatCategoryId],[IncludeAutherSectionId],[Separator],[FormatJsonWithPlaceHolder],@New_ProjectID AS [ProjectId],[CustomerId],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[FileNameFormatSetting]
		WHERE ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId


		--Move SheetSpecsPageSettings table
		INSERT INTO [dbo].[SheetSpecsPageSettings]
		([PaperSettingKey],[ProjectId],[CustomerId],[Name],[Value],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[IsActive],[IsDeleted])
		SELECT [PaperSettingKey],@New_ProjectID AS [ProjectId],[CustomerId],[Name],[Value],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[IsActive],[IsDeleted]
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SheetSpecsPageSettings]
		WHERE ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId


		----Move SectionDocument related Alternate Document  
		INSERT INTO [dbo].[SectionDocument] (ProjectId, SectionId, SectionDocumentTypeId, DocumentPath, OriginalFileName, CreateDate, CreatedBy)      
		SELECT @New_ProjectID,tgtSect.SectionId ,SD.SectionDocumentTypeId, 
		        REPLACE(REPLACE(SD.DocumentPath,@ProjectID,@New_ProjectID),@SLC_CustomerId,@SLC_CustomerId)  
			    ,SD.OriginalFileName, GETUTCDATE(), CreatedBy
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SectionDocument] SD WITH (NOLOCK)  
		INNER JOIN #tmpProjectSectionSLC tgtSect WITH(NOLOCK) ON SD.ProjectId = @ProjectID AND SD.SectionId = tgtSect.A_SectionId
		WHERE SD.ProjectId = @ProjectID --AND tgtSect.SectionSource = 8


		----Move SheetSpecsPrintSettings related Alternate Document  
		INSERT INTO [dbo].[SheetSpecsPrintSettings] (CustomerId, ProjectId, UserId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, SheetSpecsPrintPreviewLevel)      
		SELECT @SLC_CustomerId, @New_ProjectID, UserId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, SheetSpecsPrintPreviewLevel
		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SheetSpecsPrintSettings] SD WITH (NOLOCK)  
		WHERE SD.ProjectId = @ProjectID


		--Load Project Migration Exception table
		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Choice' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\ch\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'ReferenceStandard' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\rs\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'HyperLink' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\hl\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Image' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\img\#%'

		DROP TABLE IF EXISTS #tmpProjectSegmentSLC;

		--Restore Deleted global data
		EXECUTE [SLCProject].[dbo].[sp_RestoreDeletedGlobalData] @SLC_CustomerId, @New_ProjectID, @IsRestoreDeleteFailed OUTPUT

		IF @IsRestoreDeleteFailed = 1
		BEGIN
			SET @IsProjectMigrationFailed = 1

			--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
			UPDATE P
			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID;

			--Update Project details in Archive server for the project that has been UnArchived successfully
			UPDATE A
			SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
				,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
				,A.DisplayTabId = 2 --ArchivedTab
			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Failed with Restore Delete', 'Failed with Restore Delete', '45', NULL, 0, 0

		END
		ELSE
		BEGIN
			--Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
			UPDATE P 
			SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0, P.ModifiedDate = GETUTCDATE()
			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID

			--Mark Old ProjectID as Deleted in SLCProject..Project table
			UPDATE P
			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @OldSLC_ProjectID;

			--Update Project details in Archive server for the project that has been UnArchived successfully
			UPDATE A
			SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE(), A.SLC_OldProdProjectId_ForBlob = @OldSLC_ProjectID
				,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
				,A.DisplayTabId = 3 --ActiveProjectsTab
				,A.ProcessInitiatedById = 3 --SLC
			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

			--Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
			UPDATE P
			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedDate = GETUTCDATE()
			FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @ProjectID;

			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '44', 100, 0, 0

			UPDATE U
			SET U.SLCProd_ProjectId = @New_ProjectID
			FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
			WHERE U.RequestId = @RequestId;
		END

		----Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
		--UPDATE P 
		--SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0, P.ModifiedDate = GETUTCDATE()
		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID

		----Mark Old ProjectID as Deleted in SLCProject..Project table
		--UPDATE P
		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @OldSLC_ProjectID;

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
		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedDate = GETUTCDATE()
		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @ProjectID;

		--EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '40', 100, 0, 0

		--UPDATE U
		--SET U.SLCProd_ProjectId = @New_ProjectID
		--FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
		--WHERE U.RequestId = @RequestId;

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
		WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID;

		--Update Project details in Archive server for the project that has been UnArchived successfully
		UPDATE A
		SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
			,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
			,A.DisplayTabId = 2 --ArchivedTab
		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
		WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived Failed', 'Project UnArchived Failed', '45', NULL, 0, 0

		SET @ErrorStep = 'UnArchiveProject'

		SELECT @ErrorCode = ERROR_NUMBER()
			, @Return_Message = @ErrorStep + ' '
			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
			+ ERROR_MESSAGE() + ' > ' 
			+ ERROR_PROCEDURE()

		EXEC [SLCProject].[dbo].[spb_LogErrors] @ProjectID, @ErrorCode, @ErrorStep, @Return_Message

    
	END CATCH
		

END

GO



