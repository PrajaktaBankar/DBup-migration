
CREATE PROCEDURE [dbo].[sp_ArchiveProject_SLC01]
(
	@SLC_CustomerId					INT
	,@Old_SLC_ArchiveProjectId		INT
	,@SLC_ProdProjectId				INT
)
AS
BEGIN
  
	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message NVARCHAR(MAX)
	DECLARE @ErrorStep VARCHAR(50)
	DECLARE @NumberRecords int, @RowCount int

	DECLARE @NumberProjects int, @ProjectCount int

	BEGIN TRY

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
		DROP TABLE IF EXISTS #tmpTrackAcceptRejectHistorySLC;
		DROP TABLE IF EXISTS #tmpTrackSegmentStatusTypeSLC;

		DECLARE @NewArchive_ProjectID AS INT
		DECLARE @Row_Count AS INT = 0, @LogMessage AS NVARCHAR(250)

		INSERT INTO [SLCProject].[dbo].[Project]
		([Name], IsOfficeMaster, [Description], TemplateId, MasterDataTypeId, UserId, CustomerId, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsDeleted, IsNamewithHeld
			,IsMigrated, IsLocked, A_ProjectId, IsProjectMoved, [GlobalProjectID], [IsPermanentDeleted], [ModifiedByFullName], [MigratedDate], [IsArchived],[IsShowMigrationPopup]
			,[LockedBy],[LockedDate],[LockedById],[IsIncomingProject],[TransferredDate])
		SELECT
			S.[Name], S.IsOfficeMaster, S.[Description], S.TemplateId, S.MasterDataTypeId, S.UserId, S.CustomerId, S.CreateDate, S.CreatedBy
			,S.ModifiedBy, S.ModifiedDate, S.IsDeleted, S.IsNamewithHeld, S.IsMigrated, S.IsLocked, S.ProjectId AS A_ProjectId, 0 AS IsProjectMoved
			,S.GlobalProjectID AS [GlobalProjectID], S.[IsPermanentDeleted], S.[ModifiedByFullName], S.[MigratedDate], S.[IsArchived], S.[IsShowMigrationPopup]
			,S.[LockedBy], S.[LockedDate], S.[LockedById], S.[IsIncomingProject], S.[TransferredDate]
		FROM [SLCSERVER01].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		SELECT @NewArchive_ProjectID = ProjectId FROM [SLCProject].[dbo].[Project] WITH (NOLOCK) WHERE CustomerId = @SLC_CustomerId AND A_ProjectId = @SLC_ProdProjectId

		SET @LogMessage = CHAR(13)+CHAR(10) + 'Project'
		--UnArchive Logging starts here
		INSERT INTO [DE_Projects_Staging].[dbo].[ArchiveLog] (CustomerID, ProjectID, LogMessage, StartTime, EndTime) 
		VALUES (@SLC_CustomerId, @NewArchive_ProjectID, 'Archival Starts here', GETUTCDATE(), NULL)

		SET @LogMessage = ' NEW ProjectId - ' + CAST(@NewArchive_ProjectID AS VARCHAR)
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Set IsDeleted flag to 1 for a temporary basis until whole project is Unarchived
		UPDATE P
		SET P.IsDeleted = 1
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @NewArchive_ProjectID


		--ProjectAddress


		SET @LogMessage = CHAR(13)+CHAR(10) + 'Project Address'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		INSERT INTO [SLCProject].[dbo].[ProjectAddress]
		(ProjectId, CustomerId, AddressLine1, AddressLine2, CountryId, StateProvinceId, CityId, PostalCode, CreateDate, CreatedBy, ModifiedBy, ModifiedDate
			,StateProvinceName, CityName)
		SELECT @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.AddressLine1, S.AddressLine2, S.CountryId, S.StateProvinceId, S.CityId, S.PostalCode
			,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.StateProvinceName, S.CityName
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectAddress] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--UserFolder

		SET @LogMessage = CHAR(13)+CHAR(10) + 'UserFolder'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		
		--Move UserFolder table
		INSERT INTO [SLCProject].[dbo].[UserFolder]
		(FolderTypeId, ProjectId, UserId, LastAccessed, CustomerId, LastAccessByFullName)
		SELECT S.FolderTypeId, @NewArchive_ProjectID AS ProjectId, S.UserId, S.LastAccessed, S.CustomerId, S.LastAccessByFullName
		FROM [SLCSERVER01].[SLCProject].[dbo].[UserFolder] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--ProjectSummary

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSummary'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectSummary table
		INSERT INTO [SLCProject].[dbo].[ProjectSummary]
		([ProjectId],[CustomerId],[UserId],[ProjectTypeId],[FacilityTypeId],[SizeUoM],[IsIncludeRsInSection],[IsIncludeReInSection],[SpecViewModeId]
			,[UnitOfMeasureValueTypeId],[SourceTagFormat],[IsPrintReferenceEditionDate],[IsActivateRsCitation],[LastMasterUpdate],[BudgetedCostId],[BudgetedCost]
			,[ActualCost],[EstimatedArea],[SpecificationIssueDate],[SpecificationModifiedDate],[ActualCostId],[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM]
			,[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId],[IsHiddenAllBsdSections],[IsLinkEngineEnabled])
		SELECT @NewArchive_ProjectID AS ProjectId,[CustomerId],[UserId],[ProjectTypeId],[FacilityTypeId],[SizeUoM]
			,[IsIncludeRsInSection],[IsIncludeReInSection],[SpecViewModeId],[UnitOfMeasureValueTypeId],[SourceTagFormat],[IsPrintReferenceEditionDate]
			,[IsActivateRsCitation],[LastMasterUpdate],[BudgetedCostId],[BudgetedCost],[ActualCost],[EstimatedArea],[SpecificationIssueDate],[SpecificationModifiedDate]
			,[ActualCostId],[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM],[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId]
			,[IsHiddenAllBsdSections],[IsLinkEngineEnabled]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--ProjectPrintSetting
		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectPrintSetting'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPrintSetting]
		([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage]
			,[IsIncludeAuthorInFileName],[TCPrintModeId], [IsIncludePageCount], IsIncludeHyperLink, KeepWithNext, IsPrintMasterNote, IsPrintProjectNote
			,IsPrintNoteImage, IsPrintIHSLogo, IsIncludePdfBookmark, BookmarkLevel, IsIncludeOrphanParagraph, IsMarkPagesAsBlank, IsIncludeHeaderFooterOnBlackPages
			,BlankPagesText, IncludeSectionIdAfterEod, IncludeEndOfSection, IncludeDivisionNameandNumber, IsIncludeAuthorForBookMark, IsContinuousPageNumber)
		SELECT @NewArchive_ProjectID AS [ProjectId],S.[CustomerId],S.[CreatedBy],S.[CreateDate],S.[ModifiedBy],S.[ModifiedDate],S.[IsExportInMultipleFiles],S.[IsBeginSectionOnOddPage]
						,S.[IsIncludeAuthorInFileName],S.[TCPrintModeId], S.[IsIncludePageCount], S.IsIncludeHyperLink, S.KeepWithNext, S.IsPrintMasterNote, S.IsPrintProjectNote
						,S.IsPrintNoteImage, S.IsPrintIHSLogo, S.IsIncludePdfBookmark, S.BookmarkLevel, S.IsIncludeOrphanParagraph, S.IsMarkPagesAsBlank, S.IsIncludeHeaderFooterOnBlackPages
						,S.BlankPagesText, S.IncludeSectionIdAfterEod, S.IncludeEndOfSection, S.IncludeDivisionNameandNumber, S.IsIncludeAuthorForBookMark, S.IsContinuousPageNumber
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectPrintSetting] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		
		--ProjectSection

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSection'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		SELECT S.ParentSectionId, S.mSectionId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
				,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
				,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
				,S.IsHidden, S.SortOrder, S.SectionSource, S.PendingUpdateCount
		INTO #tmp_TgtSection
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectSection]
		(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
			,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
			,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
			,TrackChangeLockedBy, DataMapDateTimeStamp, IsHidden, SortOrder, SectionSource, PendingUpdateCount)
		SELECT S.ParentSectionId, S.mSectionId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
				,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
				,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
				,S.IsHidden, S.SortOrder, S.SectionSource, S.PendingUpdateCount
		FROM #tmp_TgtSection S

		SELECT SectionId, ParentSectionId, ProjectId, CustomerId, A_SectionId, SectionSource INTO #tmpProjectSection
		FROM [SLCProject].[dbo].[ProjectSection] WITH (NOLOCK) WHERE ProjectId = @NewArchive_ProjectID AND CustomerId = @SLC_CustomerId

		SELECT SectionId, A_SectionId INTO #NewOldSectionIdMapping FROM #tmpProjectSection

		--UPDATE ParentSectionId in TGT Section table                  
		UPDATE TGT_TMP SET TGT_TMP.ParentSectionId = NOSM.SectionId
		FROM #tmpProjectSection TGT_TMP
		INNER JOIN #NewOldSectionIdMapping NOSM ON TGT_TMP.ParentSectionId = NOSM.A_SectionId
		WHERE TGT_TMP.ProjectId = @NewArchive_ProjectID;
			
		--UPDATE ParentSectionId in original table                  
		UPDATE PS SET PS.ParentSectionId = PS_TMP.ParentSectionId
		FROM [SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
		INNER JOIN #tmpProjectSection PS_TMP ON PS.SectionId = PS_TMP.SectionId
		WHERE PS.ProjectId = @NewArchive_ProjectID AND PS.CustomerId = @SLC_CustomerId;

		
		--ProjectPageSetting

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectPageSetting'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectPageSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPageSetting]
		([MarginTop],[MarginBottom],[MarginLeft],[MarginRight],[EdgeHeader],[EdgeFooter],[IsMirrorMargin],[ProjectId],[CustomerId],[SectionId],[TypeId])
		SELECT S.[MarginTop],S.[MarginBottom],S.[MarginLeft],S.[MarginRight],S.[EdgeHeader],S.[EdgeFooter],S.[IsMirrorMargin]
			,@NewArchive_ProjectID AS [ProjectId],S.[CustomerId]
			,CASE WHEN S.SectionId IS NULL THEN NULL ELSE PS.SectionId END AS SectionId,S.[TypeId]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectPageSetting] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSection PS ON PS.ProjectId = @NewArchive_ProjectID AND PS.A_SectionId = S.SectionId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--ProjectPaperSetting

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectPaperSetting'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPaperSetting]
		(PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId, SectionId)
		SELECT S.PaperName, S.PaperWidth, S.PaperHeight, S.PaperOrientation, S.PaperSource, @NewArchive_ProjectID AS ProjectId, S.CustomerId
			,CASE WHEN S.SectionId IS NULL THEN NULL ELSE PS.SectionId END AS SectionId
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectPaperSetting] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSection PS ON PS.ProjectId = @NewArchive_ProjectID AND PS.A_SectionId = S.SectionId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--ProjectGlobalTerm

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectGlobalTerm'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectGlobalTerm table
		INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
			,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
		SELECT S.mGlobalTermId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode, S.CreatedDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy, S.SLE_GlobalChoiceID, S.UserGlobalTermId, S.IsDeleted, S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--ProjectSegment

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegment'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		SELECT S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
				,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		INTO #ProjectSegment_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Insert ProjectSegment Table
		INSERT INTO [SLCProject].[dbo].[ProjectSegment]
		(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
			,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
		SELECT NULL AS SegmentStatusId, S2.SectionId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
				,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		FROM #ProjectSegment_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT S.SegmentId, S.SegmentStatusId, S.SegmentSource, S.SegmentCode, S.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.A_SegmentId
		INTO #tmpProjectSegment FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId



		--ProjectSegmentStatus

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentStatus'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectSegmentStatus table

		SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
			,S.SLE_ProjectSegID, S.SLE_StatusID, S.SegmentStatusId AS A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		INTO #tmp_TgtSegmentStatus
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Update SectionId in ProjectSegmentStatus table
		UPDATE S
			SET S.SectionId = S1.SectionId
		FROM #tmp_TgtSegmentStatus S
		INNER JOIN #tmpProjectSection S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		--Update SegmentId in ProjectSegmentStatus table
		UPDATE S
			SET S.SegmentId = S1.SegmentId
		FROM #tmp_TgtSegmentStatus S
		--FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.SectionId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId;


		--Insert ProjectSegmentStatus
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
		(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
			,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
			,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
			,IsDeleted, TrackOriginOrder, MTrackDescription)
		SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
			,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		FROM #tmp_TgtSegmentStatus S

		SELECT S.* INTO #tmpProjectSegmentStatus FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

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
		WHERE PSS.ProjectId = @NewArchive_ProjectID
		AND PSS.CustomerId = @SLC_CustomerId;


		--Update SegmentStatusId in #tmpProjectSegment
		UPDATE PS
			SET PS.SegmentStatusId = SS.SegmentStatusId
		FROM #tmpProjectSegment PS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentStatus SS WITH (NOLOCK) ON SS.ProjectId = PS.ProjectId AND SS.CustomerId = PS.CustomerId
			AND SS.SectionId = PS.SectionId AND SS.SegmentId = PS.SegmentId
		WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId;

		--UPDATE SegmentStatusId in original table
		UPDATE PSS
		SET PSS.SegmentStatusId = PSS_TMP.SegmentStatusId
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @NewArchive_ProjectID AND PSS.CustomerId = @SLC_CustomerId;







		--ProjectSegmentGlobalTerm

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentGlobalTerm'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectSegmentGlobalTerm table
		SELECT S.SegmentGlobalTermId, S.CustomerId, @NewArchive_ProjectID AS ProjectId, S.SectionId, S.SegmentId, S.mSegmentId, S.UserGlobalTermId, S.GlobalTermCode, S.IsLocked
			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentGlobalTerm_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Header

		SET @LogMessage = CHAR(13)+CHAR(10) + 'Header'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move Header table
		INSERT INTO [SLCProject].[dbo].[Header]
		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
			,ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_HeaderId
			,HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader
			,IsShowLineBelowHeader)
		SELECT @NewArchive_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltHeader, S.FPHeader, S.UseSeparateFPHeader, S.HeaderFooterCategoryId
			,S.[DateFormat], S.TimeFormat, S.HeaderId AS A_HeaderId, S.HeaderFooterDisplayTypeId, S.DefaultHeader, S.FirstPageHeader, S.OddPageHeader, S.EvenPageHeader
			,S.DocumentTypeId, S.IsShowLineAboveHeader, S.IsShowLineBelowHeader
		FROM [SLCSERVER01].[SLCProject].[dbo].[Header] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSection S2 ON S2.ProjectId = @NewArchive_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S2.A_SectionId = S.SectionId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Footer

		SET @LogMessage = CHAR(13)+CHAR(10) + 'Footer'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move Footer table
		INSERT INTO [SLCProject].[dbo].[Footer]
		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
			,ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_FooterId
			,HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId, IsShowLineAboveFooter
			,IsShowLineBelowFooter)
		SELECT @NewArchive_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltFooter, S.FPFooter, S.UseSeparateFPFooter, S.HeaderFooterCategoryId
			,S.[DateFormat], S.TimeFormat, S.FooterId AS A_FooterId, S.HeaderFooterDisplayTypeId, S.DefaultFooter, S.FirstPageFooter, S.OddPageFooter, S.EvenPageFooter
			,S.DocumentTypeId, S.IsShowLineAboveFooter, IsShowLineBelowFooter
		FROM [SLCSERVER01].[SLCProject].[dbo].[Footer] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSection S2 ON S2.ProjectId = @NewArchive_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId



		--HeaderFooterGlobalTermUsage

		SET @LogMessage = CHAR(13)+CHAR(10) + 'HeaderFooterGlobalTermUsage'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move HeaderFooterGlobalTermUsage table
		SELECT S.HeaderFooterGTId, S.HeaderId, S.FooterId, S.UserGlobalTermId, S.CustomerId, @NewArchive_ProjectID AS ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
		INTO #HeaderFooterGlobalTermUsage_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move HeaderFooterGlobalTermUsage table
		INSERT INTO [SLCProject].[dbo].[HeaderFooterGlobalTermUsage]
		(HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
		SELECT S2.HeaderId, S3.FooterId, S.UserGlobalTermId, S.CustomerId, S.ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
		FROM #HeaderFooterGlobalTermUsage_Staging S
		LEFT JOIN [SLCProject].[dbo].[Header] S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.HeaderId = S2.A_HeaderId
		LEFT JOIN [SLCProject].[dbo].[Footer] S3 WITH (NOLOCK) ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S.FooterId = S3.A_FooterId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--ProjectReferenceStandard

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectReferenceStandard'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectReferenceStandard table
		SELECT @NewArchive_ProjectID AS ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
			,S.SectionId, S.CustomerId, S.ProjRefStdId, S.IsDeleted
		INTO #ProjectReferenceStandard_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move ProjectReferenceStandard table
		INSERT INTO [SLCProject].[dbo].[ProjectReferenceStandard]
		(ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)
		SELECT S.ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
			,S2.SectionId, S.CustomerId, S.IsDeleted
		FROM #ProjectReferenceStandard_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId



		--ProjectSegmentChoice

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentChoice'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectSegmentChoice_Staging table
		SELECT S.SegmentChoiceId, S.SectionId, S.SegmentStatusId, S.SegmentId, S.ChoiceTypeId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
				,S.SegmentChoiceId AS A_SegmentChoiceId, S.IsDeleted
		INTO #ProjectSegmentChoice_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentChoice] S WITH (NOLOCK)
		--INNER JOIN [SLCSERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentChoice table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
		(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
			,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
		SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
				,S.A_SegmentChoiceId, S.IsDeleted
		FROM #ProjectSegmentChoice_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		INNER JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
			AND S.SegmentId = S4.A_SegmentId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT C.SegmentChoiceId, C.ProjectId, C.SectionId, C.CustomerId, C.A_SegmentChoiceId INTO #tmpProjectSegmentChoice FROM [SLCProject].[dbo].[ProjectSegmentChoice] C WITH (NOLOCK)
		WHERE C.ProjectId = @NewArchive_ProjectID AND C.CustomerId = @SLC_CustomerId

		
		--ProjectChoiceOption

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectChoiceOption'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectChoiceOption_Staging table
		SELECT S.ChoiceOptionId, S.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, @NewArchive_ProjectID AS ProjectId, S.SectionId, S.CustomerId, S.ChoiceOptionCode
			,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.ChoiceOptionId AS A_ChoiceOptionId, S.IsDeleted
		INTO #ProjectChoiceOption_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
		--INNER JOIN [SLCSERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK) 
		--	ON S.ProjectId = PSC.ProjectId AND S.Sectionid = PSC.SectionId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--SelectedChoiceOption

		SET @LogMessage = CHAR(13)+CHAR(10) + 'SelectedChoiceOption'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert SelectedChoiceOption_Staging table
		SELECT S.SelectedChoiceOptionId, S.SegmentChoiceCode, S.ChoiceOptionCode
				,S.ChoiceOptionSource, S.IsSelected, S.SectionId, @NewArchive_ProjectID AS ProjectId, S.CustomerId
				,S.OptionJson, S.IsDeleted
		INTO #SelectedChoiceOption_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[SelectedChoiceOption] S WITH (NOLOCK)
		--INNER JOIN [SLCSERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)	
		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move SelectedChoiceOption table
		INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
		(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
		SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
		FROM #SelectedChoiceOption_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--ProjectHyperLink

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectHyperLink'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectHyperLink table
		SELECT S.HyperLinkId, S.SectionId, S.SegmentId
				,S.SegmentStatusId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
				,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
				,S.HyperLinkId AS A_HyperLinkId
		INTO #ProjectHyperLink_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectHyperLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT H.HyperLinkId, H.A_HyperLinkId, H.CustomerId, H.ProjectId, H.SectionId, H.SegmentStatusId, H.SegmentId
		INTO #tmpProjectHyperLink FROM [SLCProject].[dbo].[ProjectHyperLink] H WITH (NOLOCK) WHERE H.ProjectId = @NewArchive_ProjectID AND H.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId

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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId

		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegment A
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegment PS
					--INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					--INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
					--	AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId

		----Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
		--UPDATE A
		--	SET A.SegmentDescription = B.NewSegmentDescription
		--FROM #tmpProjectSegment A
		--INNER JOIN (
		--			SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentId) AS SegmentId
		--				,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
		--			FROM #tmpProjectSegment PS
		--			INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
		--			INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
		--				AND PS.SegmentStatusId = S3.SegmentStatusId
		--			INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
		--				AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
		--			WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
		--			GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		--) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		--WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @NewArchive_ProjectID AND PSS.CustomerId = @SLC_CustomerId;


		--ProjectNote

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectNote'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectNote_Staging table
		SELECT S.NoteId, S.SectionId, S.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.Title
				,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.NoteId AS A_NoteId
		INTO #ProjectNote_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectNote] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT P.NoteId, P.SectionId, P.SegmentStatusId, P.NoteText, P.ProjectId, P.CustomerId, P.A_NoteId INTO #tmpProjectNote
		FROM [SLCProject].[dbo].[ProjectNote] P WITH (NOLOCK)
		WHERE P.ProjectId = @NewArchive_ProjectID AND P.CustomerId = @SLC_CustomerId

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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

		----Upate HyperLink placeholders with new HyperLinkId in ProjectNote table
		--UPDATE A
		--	SET A.NoteText = B.NoteText
		--FROM #tmpProjectNote A
		--INNER JOIN (
		--			SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentStatusId) AS SegmentStatusId
		--				,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
		--			FROM #tmpProjectNote PS
		--			INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
		--			INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
		--				AND PS.SegmentStatusId = S3.SegmentStatusId
		--			INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
		--				AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
		--			WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
		--			GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		--) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		--WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNote PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @NewArchive_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		
		--ProjectSegmentReferenceStandard

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentReferenceStandard'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectSegmentReferenceStandard_Staging table
		SELECT S.SegmentRefStandardId, S.SectionId, S.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
				,@NewArchive_ProjectID AS ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
		INTO #ProjectSegmentReferenceStandard_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--ProjectSegmentTab

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentTab'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectSegmentTab_Staging table
		SELECT S.SegmentTabId, S.CustomerId, @NewArchive_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy
		INTO #ProjectSegmentTab_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentTab] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentTab table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTab]
		(CustomerId, ProjectId, SectionId, SegmentStatusId, TabTypeId, TabPosition, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy
		FROM #ProjectSegmentTab_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--ProjectSegmentRequirementTag

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentRequirementTag'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectSegmentRequirementTag_Staging table
		SELECT S.SegmentRequirementTagId, S.SectionId, S.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, @NewArchive_ProjectID AS ProjectId, S.CustomerId
				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
		INTO #ProjectSegmentRequirementTag_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentRequirementTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--ProjectSegmentUserTag

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentUserTag'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectSegmentUserTag_Staging table
		SELECT S.SegmentUserTagId, S.CustomerId, @NewArchive_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy
				,S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentUserTag_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentUserTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentUserTag table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentUserTag]
		(CustomerId, ProjectId, SectionId, SegmentStatusId, UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		FROM #ProjectSegmentUserTag_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--ProjectSegmentImage

		SELECT I.ImageId, I.CustomerId, I.ImagePath, I.ImageId AS A_ImageId INTO #tmpProjectImage
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectImage] I WITH (NOLOCK) WHERE I.CustomerId = @SLC_CustomerId

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentImage'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectSegmentImage_Staging table
		SELECT S.SegmentImageId, S.SegmentId, S.SectionId, S.ImageId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
		INTO #ProjectSegmentImage_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move ProjectSegmentImage table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentImage]
		(SegmentId, SectionId, ImageId, ProjectId, CustomerId, ImageStyle)
		SELECT CASE WHEN S3.SegmentId IS NULL THEN 0 ELSE S3.SegmentId END AS SegmentId, S2.SectionId, S4.ImageId, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
		FROM #ProjectSegmentImage_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectImage S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		LEFT JOIN #tmpProjectSegment S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT S.SegmentImageId, S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.ImageId INTO #tmpProjectSegmentImage
		FROM [SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK) WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId

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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
					GROUP BY S5.ProjectId, S5.CustomerId, S5.SectionId, S5.SegmentId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId AND B.NewSegmentDescription <> ''
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @NewArchive_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		
		--ProjectNoteImage

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectNoteImage'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert ProjectNoteImage_Staging table
		SELECT S.NoteImageId, S.NoteId, S.SectionId, S.ImageId, @NewArchive_ProjectID AS ProjectId, S.CustomerId
		INTO #ProjectNoteImage_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectNoteImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move ProjectNoteImage table
		INSERT INTO [SLCProject].[dbo].[ProjectNoteImage]
		(NoteId, SectionId, ImageId, ProjectId, CustomerId)
		SELECT S3.NoteId, S2.SectionId, S4.ImageId, S.ProjectId, S.CustomerId
		FROM #ProjectNoteImage_Staging S
		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectNote S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.NoteId = S3.A_NoteId
		INNER JOIN #tmpProjectImage S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		SELECT P.NoteImageId, P.ProjectId, P.CustomerId, P.SectionId, P.NoteId, P.ImageId INTO #tmpProjectNoteImage FROM [SLCProject].[dbo].[ProjectNoteImage] P WITH (NOLOCK)
		WHERE P.ProjectId = @NewArchive_ProjectID AND P.CustomerId = @SLC_CustomerId

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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'


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
					WHERE PS.ProjectID = @NewArchive_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
					GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId--, S5.NoteId, S5.ImageId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId AND B.NoteText <> ''
		WHERE A.ProjectId = @NewArchive_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNote PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @NewArchive_ProjectID AND PSS.CustomerId = @SLC_CustomerId;


		--ProjectSegmentLink

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentLink'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectSegmentLink table
		SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
			,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
			,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, @NewArchive_ProjectID AS ProjectId, S.CustomerId, S.SegmentLinkCode
			,S.SegmentLinkSourceTypeId
		INTO #ProjectSegmentLink_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

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
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--ProjectSegmentTracking

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentTracking'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectSegmentTracking table
		SELECT S.[SegmentId], @NewArchive_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		INTO #ProjectSegmentTracking_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectSegmentTracking] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTracking]
		([SegmentId], [ProjectId], [CustomerId], [UserId], [SegmentDescription], [CreatedBy], [CreateDate], [VersionNumber])
		SELECT S1.[SegmentId], S.[ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		FROM #ProjectSegmentTracking_Staging S
		INNER JOIN #tmpProjectSegment S1 ON S.CustomerId = S1.CustomerId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--ProjectDisciplineSection

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectDisciplineSection'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectDisciplineSection table
		SELECT S.[SectionId], S.[Disciplineld], @NewArchive_ProjectID AS [ProjectId], S.[CustomerId], S.[IsActive]
		INTO #ProjectDisciplineSection_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectDisciplineSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[ProjectDisciplineSection]
		([SectionId], [Disciplineld], [ProjectId], [CustomerId], [IsActive])
		SELECT S1.[SectionId], S.[Disciplineld], S.[ProjectId], S.[CustomerId], S.[IsActive]
		FROM #ProjectDisciplineSection_Staging S
		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--ProjectDateFormat

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectDateFormat'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectDateFormat table
		INSERT INTO [SLCProject].[dbo].[ProjectDateFormat]
		([MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate])
		SELECT S.[MasterDataTypeId], @NewArchive_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[ClockFormat], S.[DateFormat], S.[CreateDate]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectDateFormat] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--MaterialSection

		SET @LogMessage = CHAR(13)+CHAR(10) + 'MaterialSection'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		DECLARE @RowExists AS INT = 0

		SELECT @RowExists = COUNT(1) FROM [SLCSERVER01].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		IF @RowExists > 0
		BEGIN
			DECLARE @NumRecords AS INT, @RCount AS INT
			SELECT ROW_NUMBER()OVER(ORDER BY Id DESC) AS RowNumber, @NewArchive_ProjectID AS [ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId] INTO #MaterialSection_Staging
			FROM [SLCSERVER01].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
			WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

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
				INNER JOIN #tmpProjectSection B ON A.StrSectionId = B.A_SectionId
				WHERE B.ProjectId = @NewArchive_ProjectID AND B.CustomerId = @SLC_CustomerId

				SET @sectionIds=(SELECT concat(StrSectionId,',') from #tmpSplitSectionIds for xml PATH(''))

				UPDATE A SET A.SectionId = @sectionIds FROM #MaterialSection_Staging A WHERE RowNumber = @RCount

				SET @RCount = @RCount + 1
			END

			INSERT INTO [SLCProject].[dbo].[MaterialSection]
			([ProjectId], [VimId], [MaterialId], [SectionId], [CustomerId])
			SELECT S.[ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
			FROM #MaterialSection_Staging S
			WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

			DROP TABLE IF EXISTS #MaterialSection_Staging;

		END


		--LinkedSections

		SET @LogMessage = CHAR(13)+CHAR(10) + 'LinkedSections'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move LinkedSections table
		SELECT @NewArchive_ProjectID AS [ProjectId], S.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		INTO #LinkedSections_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[LinkedSections] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[LinkedSections]
		([ProjectId], [SectionId], [VimId], [MaterialId], [Linkedby], [LinkedDate], [customerId])
		SELECT S.[ProjectId], S1.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		FROM #LinkedSections_Staging S
		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--ApplyMasterUpdateLog

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ApplyMasterUpdateLog'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ApplyMasterUpdateLog table
		INSERT INTO [SLCProject].[dbo].[ApplyMasterUpdateLog]
		([ProjectId], [LastUpdateDate])
		SELECT @NewArchive_ProjectID AS [ProjectId], S.[LastUpdateDate]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ApplyMasterUpdateLog] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId

		
		--ProjectExport

		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectExport'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move ProjectExport table
		INSERT INTO [SLCProject].[dbo].[ProjectExport]
		([FileName],[ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy],[CreatedByFullName]
			,[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId],[ProjectName],[FileStatus],[PrintFailureReason])
		SELECT [FileName], @NewArchive_ProjectID AS [ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate]
			,[IsDeleted],[CreatedDate],[CreatedBy],[CreatedByFullName],[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId]
			,[ProjectName],[FileStatus],[PrintFailureReason]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectExport] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--SegmentComment

		SET @LogMessage = CHAR(13)+CHAR(10) + 'SegmentComment'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert SegmentComment_Staging table
		SELECT 0 AS CycleID, @NewArchive_ProjectID AS [ProjectId],[SectionId],[SegmentStatusId],[ParentCommentId]
			,[CommentDescription],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[CommentStatusId],[IsDeleted],[userFullName]
			,[SegmentCommentId] AS [A_SegmentCommentId]
		INTO #SegmentComment_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[SegmentComment] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Insert SegmentComment table
		INSERT INTO [SLCProject].[dbo].[SegmentComment]
		(ProjectId,[SectionId],[SegmentStatusId],[ParentCommentId],[CommentDescription],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate]
			,[CommentStatusId],[IsDeleted],[userFullName],A_SegmentCommentId)
		SELECT S.ProjectId,S1.[SectionId],S2.[SegmentStatusId],S.[ParentCommentId],S.[CommentDescription],S.[CustomerId],S.[CreatedBy],S.[CreateDate]
			,S.[ModifiedBy],S.[ModifiedDate],S.[CommentStatusId],S.[IsDeleted],S.[userFullName],S.A_SegmentCommentId
		FROM #SegmentComment_Staging S
		INNER JOIN [SLCProject].[dbo].[ProjectSection] S1 WITH (NOLOCK) ON S1.CustomerId = S.CustomerId AND S1.ProjectId = S.ProjectId AND S1.A_SectionId = S.SectionId
		INNER JOIN [SLCProject].[dbo].[ProjectSegmentStatus] S2 WITH (NOLOCK) ON S2.CustomerId = S.CustomerId AND S2.ProjectId = S.ProjectId AND S2.SectionId = S1.SectionId
			AND S2.A_SegmentStatusId = S.SegmentStatusId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Update ParentCommentId
		UPDATE CST
			SET CST.ParentCommentId = PST.SegmentCommentId
		FROM [SLCProject].[dbo].[SegmentComment] CST WITH (NOLOCK)
		INNER JOIN [SLCProject].[dbo].[SegmentComment] PST WITH (NOLOCK) ON PST.CustomerId = CST.CustomerId AND PST.ProjectId = CST.ProjectId
			AND PST.SectionId = CST.SectionId AND CST.ParentCommentId = PST.A_SegmentCommentId AND CST.ParentCommentId <> 0
		WHERE CST.ProjectId = @NewArchive_ProjectID AND CST.CustomerId = @SLC_CustomerId

		--TrackAcceptRejectProjectSegmentHistory

		SET @LogMessage = CHAR(13)+CHAR(10) + 'TrackAcceptRejectProjectSegmentHistory'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move TrackAcceptRejectProjectSegmentHistory table
		SELECT [SectionId],[SegmentId], @NewArchive_ProjectID AS [ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note]
		INTO #TrackAcceptRejectProjectSegmentHistory_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory]
		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note])
		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[TrackActionId],S.[Note]
		FROM #TrackAcceptRejectProjectSegmentHistory_Staging S
		INNER JOIN #tmpProjectSection S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegment S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentId = S2.A_SegmentId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--TrackProjectSegment

		SET @LogMessage = CHAR(13)+CHAR(10) + 'TrackProjectSegment'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Insert TrackProjectSegment_Staging table
		SELECT [SectionId],[SegmentId],@NewArchive_ProjectID AS [ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate]
			,[ChangedDate],[ChangedById],[IsDeleted]
		INTO #TrackProjectSegment_Staging
		FROM [SLCSERVER01].[SLCProject].[dbo].[TrackProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId

		--Move TrackProjectSegment table
		INSERT INTO [SLCProject].[dbo].[TrackProjectSegment]
		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate],[ChangedDate],[ChangedById],[IsDeleted])
		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[CreateDate],S.[ChangedDate],S.[ChangedById]
			,S.[IsDeleted]
		FROM #TrackProjectSegment_Staging S
		INNER JOIN #tmpProjectSection S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegment S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentId = S2.A_SegmentId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId

		
		--UserProjectAccessMapping

		SET @LogMessage = CHAR(13)+CHAR(10) + 'UserProjectAccessMapping'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Move UserProjectAccessMapping table
		INSERT INTO [SLCProject].[dbo].[UserProjectAccessMapping]
		([ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive])
		SELECT @NewArchive_ProjectID AS [ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive]
		FROM [SLCSERVER01].[SLCProject].[dbo].[UserProjectAccessMapping] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Move ProjectActivity table
		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectActivity'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		INSERT INTO [SLCProject].[dbo].[ProjectActivity]
		([ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate])
		SELECT @NewArchive_ProjectID AS [ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectActivity] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Move ProjectLevelTrackChangesLogging table
		SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectLevelTrackChangesLogging'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		INSERT INTO [SLCProject].[dbo].[ProjectLevelTrackChangesLogging]
		([UserId],[ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate])
		SELECT [UserId],@NewArchive_ProjectID AS [ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate]
		FROM [SLCSERVER01].[SLCProject].[dbo].[ProjectLevelTrackChangesLogging] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Insert 
		SET @LogMessage = CHAR(13)+CHAR(10) + 'SectionLevelTrackChangesLogging'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		SELECT [UserId],@NewArchive_ProjectID AS [ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate]
		INTO #tmpSectionLevelTrackChangesLoggingSLC
		FROM [SLCSERVER01].[SLCProject].[dbo].[SectionLevelTrackChangesLogging] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Move SectionLevelTrackChangesLogging table
		INSERT INTO [SLCProject].[dbo].[SectionLevelTrackChangesLogging]
		([UserId],[ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate])
		SELECT S.[UserId],S.[ProjectId],S1.[SectionId],S.[CustomerId],S.[UserEmail],S.[IsTrackChanges],S.[IsTrackChangeLock],S.[CreatedDate]
		FROM #tmpSectionLevelTrackChangesLoggingSLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSection S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Insert 
		SET @LogMessage = CHAR(13)+CHAR(10) + 'TrackAcceptRejectHistory'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		SELECT [SectionId],@NewArchive_ProjectID AS [ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate]
		INTO #tmpTrackAcceptRejectHistorySLC
		FROM [SLCSERVER01].[SLCProject].[dbo].[TrackAcceptRejectHistory] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Move TrackAcceptRejectHistory table
		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectHistory]
		([SectionId],[ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate])
		SELECT S1.[SectionId],S.[ProjectId],S.[CustomerId],S.[UserId],S.[TrackActionId],S.[CreateDate]
		FROM #tmpTrackAcceptRejectHistorySLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSection S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Insert 
		SET @LogMessage = CHAR(13)+CHAR(10) + 'TrackSegmentStatusType'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		SELECT @NewArchive_ProjectID AS [ProjectId],[SectionId],[CustomerId],[SegmentStatusId],[SegmentStatusTypeId],[PrevStatusSegmentStatusTypeId],[InitialStatusSegmentStatusTypeId],[IsAccepted]
			,[UserId],[UserFullName],[CreatedDate],[ModifiedById],[ModifiedByUserFullName],[ModifiedDate],[TenantId],[InitialStatus],[IsSegmentStatusChangeBySelection],[CurrentStatus]
			,[SegmentStatusTypeIdBeforeSelection]
		INTO #tmpTrackSegmentStatusTypeSLC
		FROM [SLCSERVER01].[SLCProject].[dbo].[TrackSegmentStatusType] S WITH (NOLOCK)
		WHERE S.ProjectId = @SLC_ProdProjectId AND S.CustomerId = @SLC_CustomerId


		--Move TrackSegmentStatusType table
		INSERT INTO [SLCProject].[dbo].[TrackSegmentStatusType]
		([ProjectId],[SectionId],[CustomerId],[SegmentStatusId],[SegmentStatusTypeId],[PrevStatusSegmentStatusTypeId],[InitialStatusSegmentStatusTypeId],[IsAccepted],[UserId],[UserFullName]
			,[CreatedDate],[ModifiedById],[ModifiedByUserFullName],[ModifiedDate],[TenantId],[InitialStatus],[IsSegmentStatusChangeBySelection],[CurrentStatus]
			,[SegmentStatusTypeIdBeforeSelection])
		SELECT S.[ProjectId],S1.[SectionId],S.[CustomerId],S2.[SegmentStatusId],S.[SegmentStatusTypeId],S.[PrevStatusSegmentStatusTypeId],S.[InitialStatusSegmentStatusTypeId],S.[IsAccepted],S.[UserId]
			,S.[UserFullName],S.[CreatedDate],S.[ModifiedById],S.[ModifiedByUserFullName],S.[ModifiedDate],S.[TenantId],S.[InitialStatus],S.[IsSegmentStatusChangeBySelection],S.[CurrentStatus]
			,S.[SegmentStatusTypeIdBeforeSelection]
		FROM #tmpTrackSegmentStatusTypeSLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSection S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		INNER JOIN #tmpProjectSegmentStatus S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
						AND S.SegmentStatusId = S2.A_SegmentStatusId
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId


		--Move FileNameFormatSetting table
		INSERT INTO [dbo].[FileNameFormatSetting]
		([FileFormatCategoryId],[IncludeAutherSectionId],[Separator],[FormatJsonWithPlaceHolder],[ProjectId],[CustomerId],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
		SELECT [FileFormatCategoryId],[IncludeAutherSectionId],[Separator],[FormatJsonWithPlaceHolder],@NewArchive_ProjectID AS [ProjectId],[CustomerId],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate]
		FROM [SLCSERVER01].[SLCProject].[dbo].[FileNameFormatSetting]
		WHERE ProjectId = @SLC_ProdProjectId AND CustomerId = @SLC_CustomerId


		--Move SheetSpecsPageSettings table
		INSERT INTO [dbo].[SheetSpecsPageSettings]
		([PaperSettingKey],[ProjectId],[CustomerId],[Name],[Value],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[IsActive],[IsDeleted])
		SELECT [PaperSettingKey],@NewArchive_ProjectID AS [ProjectId],[CustomerId],[Name],[Value],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[IsActive],[IsDeleted]
		FROM [SLCSERVER01].[SLCProject].[dbo].[SheetSpecsPageSettings]
		WHERE ProjectId = @SLC_ProdProjectId AND CustomerId = @SLC_CustomerId


		----Move SectionDocument related Alternate Document  
		INSERT INTO [dbo].[SectionDocument] (ProjectId, SectionId, SectionDocumentTypeId, DocumentPath, OriginalFileName, CreateDate, CreatedBy)      
		SELECT @NewArchive_ProjectID,tgtSect.SectionId ,SD.SectionDocumentTypeId, 
		        REPLACE(REPLACE(SD.DocumentPath,@SLC_ProdProjectId,@NewArchive_ProjectID),@SLC_CustomerId,@SLC_CustomerId)  
			    ,SD.OriginalFileName, GETUTCDATE(), CreatedBy
		FROM [SLCSERVER01].[SLCProject].[dbo].[SectionDocument] SD WITH (NOLOCK)  
		INNER JOIN #tmpProjectSection tgtSect WITH(NOLOCK) ON SD.ProjectId = @SLC_ProdProjectId AND SD.SectionId = tgtSect.A_SectionId
		WHERE SD.ProjectId = @SLC_ProdProjectId --AND tgtSect.SectionSource = 8


		----Move SheetSpecsPrintSettings related Alternate Document  
		INSERT INTO [dbo].[SheetSpecsPrintSettings] (CustomerId, ProjectId, UserId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, SheetSpecsPrintPreviewLevel)      
		SELECT @SLC_CustomerId, @NewArchive_ProjectID, UserId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, SheetSpecsPrintPreviewLevel
		FROM [SLCSERVER01].[SLCProject].[dbo].[SheetSpecsPrintSettings] SD WITH (NOLOCK)  
		WHERE SD.ProjectId = @SLC_ProdProjectId


		--Load Project Migration Exception table
		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Choice' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\ch\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'ReferenceStandard' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\rs\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'HyperLink' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\hl\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Image' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegment S
		WHERE S.ProjectId = @NewArchive_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\img\#%'


		--Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
		UPDATE P
		SET P.IsDeleted = 0, P.IsShowMigrationPopup = 0
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @NewArchive_ProjectID AND P.CustomerId = @SLC_CustomerId

		--Update IsDeleted and IsPermanantDeleted flag to true because now we should delete old Archived project since the same project has been archived again.
		UPDATE P
		SET P.IsDeleted = 1, P.IsPermanentDeleted = 1
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @Old_SLC_ArchiveProjectId AND P.CustomerId = @SLC_CustomerId

		--Mark Production ProjectID as Deleted in SLCProject..Project table so it can be physically deleted from the table on weekend
		UPDATE P SET P.IsDeleted = 1, P.IsPermanentDeleted = 1 FROM [SLCSERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @SLC_ProdProjectId AND P.CustomerId = @SLC_CustomerId

		--Update Project details in Archive server for the project that has been Archived
		UPDATE A SET A.SLC_ArchiveProjectId = @NewArchive_ProjectID, A.IsArchived = 1, A.ArchiveTimeStamp = GETUTCDATE()
			,A.InProgressStatusId = 2 --(SELECT [InProgressStatusId] FROM [DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'ArchiveCompleted')
			,A.DisplayTabId = 2 --ArchivedTab
			,A.PDFGenerationStatusId = 1 --Init
			,A.ProcessInitiatedById = 3 --SLC
		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
		WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ProdProjectId = @SLC_ProdProjectId

		--Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
		UPDATE P SET P.IsDeleted = 1, P.IsPermanentDeleted = 1 FROM [SLCSERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @SLC_ProdProjectId AND P.CustomerId = @SLC_CustomerId

		SET @LogMessage = ' Project Archival completed successfully'
		EXECUTE [DE_Projects_Staging].[dbo].[spb_ArchiveLog] @SLC_CustomerId, @NewArchive_ProjectID, @LogMessage

		--Update EndTime after project is Archived successfully
		UPDATE A
		SET A.EndTime = GETUTCDATE()
		FROM [DE_Projects_Staging].[dbo].[ArchiveLog] A WITH (NOLOCK)
		WHERE A.ProjectID = @NewArchive_ProjectID AND A.CustomerID = @SLC_CustomerId

	END TRY

	BEGIN CATCH
		/*************************************
		*  Get the Error Message for @@Error
		*************************************/

		--Delete from SLCProjectMapping table as Cycle could not be loaded successfully.
		--DELETE FROM [DE_Projects_Staging].[dbo].[SLCProjectMapping] WHERE CustomerID = @SLC_CustomerId AND CycleID = @CycleID;
		--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
		UPDATE P SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @NewArchive_ProjectID AND P.CustomerId = @SLC_CustomerId;

		--Update Project details in Archive server for the project that has been UnArchived failed
		UPDATE A SET A.SLC_ArchiveProjectId = @Old_SLC_ArchiveProjectId, A.IsArchived = 0
			,A.InProgressStatusId = 6 --ArchiveFailed --(SELECT [InProgressStatusId] FROM [VM-DEV-DBDC\SLCARCHSERVER].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'ArchiveFailed')
			,A.DisplayTabId = 3 --ActiveProjectsTab
		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
		WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ProdProjectId = @SLC_ProdProjectId

		--Update IsArchived to 0 for prodprojectid in SLC Production server
		--Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
		UPDATE P SET P.IsArchived = 0 FROM [SLCSERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @SLC_ProdProjectId AND P.CustomerId = @SLC_CustomerId

		SET @ErrorStep = 'ArchiveProject'

		SELECT @ErrorCode = ERROR_NUMBER()
			, @Return_Message = @ErrorStep + ' '
			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
			+ ERROR_MESSAGE() + ' > ' 
			+ ERROR_PROCEDURE()

		EXEC [DE_Projects_Staging].[dbo].[spb_LogErrors] 0, @ErrorCode, @ErrorStep, @Return_Message

    
	END CATCH

END


GO


