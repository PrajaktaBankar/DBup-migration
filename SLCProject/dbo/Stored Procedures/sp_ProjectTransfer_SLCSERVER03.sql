CREATE PROCEDURE [dbo].[sp_ProjectTransfer_SLCSERVER03]
(
	@TransferRequestId	INT
	,@ProjectName NVARCHAR(500)
	,@SourceCustomerID	INT
	,@SourceProjectID	INT
	,@SourceServerID	INT
	,@TargetCustomerID	INT
	,@TargetUserID		INT
	,@TargetServerId	INT
	,@TargetProjectID	INT OUTPUT
)
AS
BEGIN
  
	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message VARCHAR(1024)
	DECLARE @ErrorStep VARCHAR(50)
	DECLARE @NumberRecords int, @RowCount int
	DECLARE @New_ProjectID INT = 0
	--DECLARE @RequestId AS INT
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
	DECLARE @RequestId AS INT
	DECLARE @CONST_START_CODE AS INT = 1000000
	DECLARE @IsProjectMigrationFailed AS INT = 0

	--Set IsProjectMigrationFailed to 0 to reset it
	SET @IsProjectMigrationFailed = 0
	--SET @RequestId = 0

	BEGIN TRY

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
		DROP TABLE IF EXISTS #tmpProjectSegmentSLC;
		DROP TABLE IF EXISTS #tmpProjectSegmentChoiceSLC;
		DROP TABLE IF EXISTS #tmpProjectSegmentImageSLC;
		DROP TABLE IF EXISTS #tmpProjectSegmentStatusSLC;
		DROP TABLE IF EXISTS #ProjectSegment_Staging;
		DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
		DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;
		DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;
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
		DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;
		DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;
		DROP TABLE IF EXISTS #MaterialSection_Staging;
		DROP TABLE IF EXISTS #LinkedSections_Staging;
		DROP TABLE IF EXISTS #SegmentComment_Staging;
		DROP TABLE IF EXISTS #TrackAcceptRejectProjectSegmentHistory_Staging;
		DROP TABLE IF EXISTS #TrackProjectSegment_Staging;
		DROP TABLE IF EXISTS #TMPREFSTDID;
		DROP TABLE IF EXISTS #TMPTemplateId;
		DROP TABLE IF EXISTS #tmpSectionLevelTrackChangesLoggingSLC;
		DROP TABLE IF EXISTS #tmpProSeg;
		DROP TABLE IF EXISTS #tmpProChOption;
		DROP TABLE IF EXISTS #tmpTrackAcceptRejectHistorySLC;
		DROP TABLE IF EXISTS #TrackSegmentStatusType_Staging;

		--DECLARE @New_ProjectID AS INT
		DECLARE @OldCount AS INT = 0, @NewCount AS INT = 0, @StepName AS NVARCHAR(100), @Description AS NVARCHAR(500), @Step AS NVARCHAR(100)
		DECLARE @Row_Count AS INT = 0, @LogMessage AS NVARCHAR(250)
		

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


		--Transfer Global Data


		--Get all global data used in Senders project

		--Get ProjectChoiceOption table from source to find what GlobalTermCode and RefStdCode have been used in Choices
		SELECT ProjectId, CustomerId, OptionJson INTO #tmpProChOption
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SELECT DISTINCT B.RefStdCode, @SourceCustomerID AS SourceCustomerId INTO #tmpRCDInOJson FROM #tmpProChOption A
		CROSS APPLY OPENJSON(A.OptionJson)
		WITH (RefStdCode int '$.Id') B
		WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID AND OptionJson LIKE '%ReferenceStandard%'
		
		SELECT DISTINCT A.RefStdId AS RefStandardId INTO #tmpRefStdIdInOptionJson FROM [SLCSERVER03].[SLCProject].[dbo].[ReferenceStandard] A WITH (NOLOCK)
		INNER JOIN #tmpRCDInOJson B ON A.CustomerId = B.SourceCustomerId AND A.RefStdCode = B.RefStdCode
		WHERE A.CustomerId = @SourceCustomerID AND A.RefStdCode IS NOT NULL;

		--ReferenceStandard
		CREATE TABLE #TMPREFSTDID (RefStandardId	INT)

		SELECT DISTINCT RefStandardId
		INTO #tmpRefStdIdInProjRefStandard
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND RefStdSource = 'U'

		SELECT DISTINCT CustomerId, RefStdEditionId
		INTO #tmpRefStdEdId
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND RefStdSource = 'U'

		SELECT DISTINCT RefStandardId
		INTO #tmpRefStdIdInProjSegmentRefStandard
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND RefStandardSource = 'U'

		INSERT INTO #TMPREFSTDID SELECT RefStandardId FROM #tmpRefStdIdInProjRefStandard;
		INSERT INTO #TMPREFSTDID SELECT RefStandardId FROM #tmpRefStdIdInProjSegmentRefStandard;
		INSERT INTO #TMPREFSTDID SELECT RefStandardId FROM #tmpRefStdIdInOptionJson;

		--Template
		SELECT DISTINCT TemplateId INTO #TMPTemplateIdInProject
		FROM [SLCSERVER03].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND ISNULL(TemplateId, 0) > 0

		SELECT DISTINCT TemplateId INTO #TMPTemplateIdInProjectSection
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND ISNULL(TemplateId, 0) > 0

		CREATE TABLE #TMPTemplateId (TemplateId	INT)

		INSERT INTO #TMPTemplateId SELECT TemplateId FROM #TMPTemplateIdInProject
		INSERT INTO #TMPTemplateId SELECT TemplateId FROM #TMPTemplateIdInProjectSection

		--UserGlobalTerm
		SELECT DISTINCT UserGlobalTermId INTO #tmpUserGlobalTermIdInProSegGlobalTerm
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND S.UserGlobalTermId IS NOT NULL

		SELECT DISTINCT UserGlobalTermId INTO #tmpUserGlobalTermIdInHeaderFooter
		FROM [SLCSERVER03].[SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND S.UserGlobalTermId IS NOT NULL

		--Get UserGlobalTermCode used in ProjectChoiceOption

		SELECT DISTINCT B.UserGlobalTermCode, @SourceCustomerID AS SourceCustomerId INTO #tmpUsGloTermCodeInOJson FROM #tmpProChOption A
		CROSS APPLY OPENJSON(A.OptionJson)
		WITH (UserGlobalTermCode int '$.Id') B
		WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID AND OptionJson LIKE '%GlobalTerm%'
		
		SELECT DISTINCT A.UserGlobalTermId INTO #tmpUserGlobalTermIdInOptionJson FROM [SLCProject].[dbo].[ProjectGlobalTerm] A WITH (NOLOCK)
		INNER JOIN #tmpUsGloTermCodeInOJson B ON A.CustomerId = B.SourceCustomerId AND A.ProjectId = @SourceProjectID AND A.GlobalTermCode = B.UserGlobalTermCode
		WHERE A.CustomerId = @SourceCustomerID AND A.ProjectId = @SourceProjectID AND A.UserGlobalTermId IS NOT NULL;

		--Get UserGlobalTerms used in SegmentDescription directly

		SELECT ProjectId, CustomerId, SegmentDescription INTO #tmpProSeg
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		DECLARE @ROWC AS INT
		DECLARE @TOTALROWS AS INT
		CREATE TABLE #tmpUserGlobalTermIdInProSegmentDescription (UserGlobalTermId	INT)

		CREATE TABLE #tmpGlobalTermsUsed (RowID INT IDENTITY(1, 1), ProjectId INT NOT NULL, CustomerId INT NOT NULL, SegmentDescription NVARCHAR(MAX) NULL, IsProcessed BIT NOT NULL DEFAULT (0))

		INSERT INTO #tmpGlobalTermsUsed (ProjectId, CustomerId, SegmentDescription, IsProcessed)
		SELECT S.ProjectId, S.CustomerId, S.SegmentDescription, 0 AS IsProcessed FROM #tmpProSeg S
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND S.SegmentDescription LIKE '%{GT#%'

		-- Get the number of records in the temporary table
		SET @TOTALROWS = @@ROWCOUNT
		SET @ROWC = 1

		-- loop through all records in the temporary table using the WHILE loop construct
		WHILE @ROWC <= @TOTALROWS
		BEGIN
	
			DECLARE @Seg_Description AS NVARCHAR(MAX)

			SELECT @Seg_Description = SegmentDescription FROM #tmpGlobalTermsUsed WHERE RowID = @ROWC AND IsProcessed = 0

			DECLARE @OldGlobalTermID INT
				, @NewGlobalTermCode INT
				, @I INT
				, @K INT
				, @tmp VARCHAR(20) = ''
				, @OldPlaceHolder VARCHAR(20) = ''
				, @ReplaceString NVARCHAR(50)
				, @HeaderFooterText NVARCHAR(MAX) = @Seg_Description
				, @retString NVARCHAR(MAX) = ''
				, @OldGlobalTerm VARCHAR(20) = ''
				, @OldStringTAG VARCHAR(7) = '{GT#'
				, @intGlobalTermCount AS INT
				, @RowCnt AS INT = 0
				, @UserGlobalTermId AS INT = 0

			SET @intGlobalTermCount = (LEN(@HeaderFooterText) - LEN(REPLACE(@HeaderFooterText, @OldStringTAG, ''))) / LEN(@OldStringTAG)

			-- loop through all records in the temporary table using the WHILE loop construct
			WHILE @RowCnt < @intGlobalTermCount
			BEGIN
				IF CHARINDEX(@OldStringTAG,@HeaderFooterText) > 0
				BEGIN
					SELECT @I = CHARINDEX(@OldStringTAG,@HeaderFooterText)
					SELECT @K = PATINDEX('%}%',SUBSTRING(@HeaderFooterText, @I + 1, LEN(@HeaderFooterText)))
					SELECT @OldPlaceHolder = SUBSTRING(@HeaderFooterText, @I, @K + 1)
					SELECT @tmp = SUBSTRING(@HeaderFooterText, @I, @K)
					SELECT @tmp = LTRIM(RTRIM(REPLACE(@tmp, @OldStringTAG, '')))
					IF ISNUMERIC(@tmp) = 1
						SELECT @OldGlobalTermID = @tmp

					IF @OldGlobalTermID > 0
					BEGIN
						SELECT @UserGlobalTermId = UserGlobalTermId FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] WITH (NOLOCK) WHERE CustomerId = @SourceCustomerID AND ProjectId = @SourceProjectID
						AND GlobalTermCode = @OldGlobalTermID AND UserGlobalTermId IS NOT NULL;
						IF @UserGlobalTermId > 0
						BEGIN
							INSERT INTO #tmpUserGlobalTermIdInProSegmentDescription (UserGlobalTermId) VALUES (@UserGlobalTermId)
						END
					END
		
				END
				SET @RowCnt = @RowCnt + 1
			END

			UPDATE #tmpGlobalTermsUsed SET IsProcessed = 1 WHERE RowID = @ROWC;

			SET @ROWC = @ROWC + 1
		END

		DROP TABLE IF EXISTS #tmpGlobalTermsUsed
		DROP TABLE IF EXISTS #tmpProSeg
		DROP TABLE IF EXISTS #tmpProChOption;

		CREATE TABLE #TMPUserGlobalTermId (UserGlobalTermId	INT)

		INSERT INTO #TMPUserGlobalTermId SELECT UserGlobalTermId FROM #tmpUserGlobalTermIdInProSegGlobalTerm
		INSERT INTO #TMPUserGlobalTermId SELECT UserGlobalTermId FROM #tmpUserGlobalTermIdInHeaderFooter
		INSERT INTO #TMPUserGlobalTermId SELECT UserGlobalTermId FROM #tmpUserGlobalTermIdInProSegmentDescription
		INSERT INTO #TMPUserGlobalTermId SELECT UserGlobalTermId FROM #tmpUserGlobalTermIdInOptionJson

		--ProjectUserTag
		SELECT DISTINCT UserTagId INTO #TMPUserTagId
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentUserTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID




		--ReferenceStandard
		SELECT S.[RefStdId],S.[RefStdName],S.[RefStdSource],S.[ReplaceRefStdId],S.[ReplaceRefStdSource],S.[mReplaceRefStdId],S.[IsObsolete],S.[RefStdCode],S.[CreateDate]
			,S.[CreatedBy],S.[ModifiedDate],S.[ModifiedBy],@TargetCustomerID AS [CustomerId],S.[IsDeleted],S.[IsLocked],S.[IsLockedByFullName],S.[IsLockedById]
			,S.RefStdId AS [A_RefStdId]
		INTO #UsedReferenceStandard
		FROM [SLCSERVER03].[SLCProject].[dbo].[ReferenceStandard] S WITH (NOLOCK)
		WHERE S.CustomerId = @SourceCustomerID AND S.RefStdId IN (SELECT RefStandardId FROM #TMPREFSTDID)

		--ReferenceStandardEdition
		SELECT S.[RefStdEditionId],S.[RefEdition],S.[RefStdTitle],S.[LinkTarget],S.[CreateDate],S.[CreatedBy],S.[RefStdId],@TargetCustomerID AS [CustomerId],S.[ModifiedDate]
			,S.[ModifiedBy],S.[RefStdEditionId] AS [A_RefStdEditionId]
		INTO #UsedReferenceStandardEdition
		FROM [SLCSERVER03].[SLCProject].[dbo].[ReferenceStandardEdition] S WITH (NOLOCK)
		WHERE S.CustomerId = @SourceCustomerID AND S.RefStdId IN (SELECT RefStdId FROM #UsedReferenceStandard)

		--Template
		SELECT S.TemplateId,S.[Name],S.[TitleFormatId],S.[SequenceNumbering],@TargetCustomerID AS [CustomerId],S.[IsSystem],S.[IsDeleted],S.[CreatedBy],S.[CreateDate]
			,S.[ModifiedBy],S.[ModifiedDate],S.[MasterDataTypeId],S.[TemplateId] AS [A_TemplateId],S.[ApplyTitleStyleToEOS]
		INTO #UsedTemplate
		FROM [SLCSERVER03].[SLCProject].[dbo].[Template] S WITH (NOLOCK)
		WHERE S.CustomerId = @SourceCustomerID AND S.TemplateId IN (SELECT TemplateId FROM #TMPTemplateId) --AND IsSystem = 0

		--UserGlobalTerm
		SELECT S.UserGlobalTermId,S.[Name], S.[Name] AS [Value],S.[CreatedDate],S.[CreatedBy],@TargetCustomerID AS [CustomerId],NULL AS [ProjectId],S.[IsDeleted]
			,S.[UserGlobalTermId] AS [A_UserGlobalTermId], S.CustomerId AS SourceCustomerID
		INTO #UsedUserGlobalTerm
		FROM [SLCSERVER03].[SLCProject].[dbo].[UserGlobalTerm] S WITH (NOLOCK)
		WHERE S.CustomerId = @SourceCustomerID AND S.UserGlobalTermId IN (SELECT UserGlobalTermId FROM #TMPUserGlobalTermId)

		--ProjectUserTag
		SELECT S.UserTagId,@TargetCustomerID AS [CustomerId],S.[TagType],S.[Description],S.[SortOrder],S.[IsSystemTag],S.[CreateDate],S.[CreatedBy],S.[ModifiedDate]
			,S.[ModifiedBy],S.[UserTagId] AS [A_UserTagId]
		INTO #UsedProjectUserTag
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectUserTag] S WITH (NOLOCK)
		WHERE S.CustomerId = @SourceCustomerID AND S.UserTagId IN (SELECT UserTagId FROM #TMPUserTagId)



		--Get already exist global data into temp table

		--ReferenceStandard
		SELECT S.[RefStdId],S.[RefStdName],S.[RefStdSource],S.[ReplaceRefStdId],S.[ReplaceRefStdSource],S.[mReplaceRefStdId],S.[IsObsolete],S.[RefStdCode],S.[CreateDate]
			,S.[CreatedBy],S.[ModifiedDate],S.[ModifiedBy],S.[CustomerId],S.[IsDeleted],S.[IsLocked],S.[IsLockedByFullName],S.[IsLockedById]
			,S1.RefStdId AS [A_RefStdId], S1.RefStdName AS SourceDescription, @SourceCustomerID AS SourceCustomerId, S1.RefStdCode AS SourceRefStdCode
		INTO #AlreadyExReferenceStandard
		FROM [SLCProject].[dbo].[ReferenceStandard] S WITH (NOLOCK)
		INNER JOIN #UsedReferenceStandard S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[RefStdName] = S1.[RefStdName] AND S.IsDeleted = 0
		WHERE S.CustomerId = @TargetCustomerID

		--Template
		SELECT S.[TemplateId],S.[Name],S.[TitleFormatId],S.[SequenceNumbering],S.[CustomerId],S.[IsSystem],S.[IsDeleted],S.[CreatedBy],S.[CreateDate]
			,S.[ModifiedBy],S.[ModifiedDate],S.[MasterDataTypeId],S1.[TemplateId] AS [A_TemplateId], S1.[Name] AS SourceDescription ,S.[ApplyTitleStyleToEOS], @SourceCustomerID AS SourceCustomerId
		INTO #AlreadyExTemplate
		FROM [SLCProject].[dbo].[Template] S WITH (NOLOCK)
		INNER JOIN #UsedTemplate S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[Name] = S1.[Name] AND S.IsDeleted = 0
		WHERE S.CustomerId = @TargetCustomerID

		--UserGlobalTerm
		SELECT S.[UserGlobalTermId],S.[Name],S.[Value],S.[CreatedDate],S.[CreatedBy],S.[CustomerId],S.[ProjectId],S.[IsDeleted]
			,S1.[UserGlobalTermId] AS [A_UserGlobalTermId], S1.[Name] AS SourceDescription, @SourceCustomerID AS SourceCustomerId
		INTO #AlreadyExUserGlobalTerm
		FROM [SLCProject].[dbo].[UserGlobalTerm] S WITH (NOLOCK)
		INNER JOIN #UsedUserGlobalTerm S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[Name] = S1.[Name] AND S.IsDeleted = 0
		WHERE S.CustomerId = @TargetCustomerID

		--ProjectUserTag
		SELECT S.[UserTagId],S.[CustomerId],S.[TagType],S.[Description],S.[SortOrder],S.[IsSystemTag],S.[CreateDate],S.[CreatedBy],S.[ModifiedDate]
			,S.[ModifiedBy],S1.[UserTagId] AS [A_UserTagId], S1.TagType AS SourceDescription, @SourceCustomerID AS SourceCustomerId
		INTO #AlreadyExProjectUserTag
		FROM [SLCProject].[dbo].[ProjectUserTag] S WITH (NOLOCK)
		INNER JOIN #UsedProjectUserTag S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[TagType] = S1.[TagType] AND S.[Description] = S1.[Description]
		WHERE S.CustomerId = @TargetCustomerID


		--Load Already Exists Global data into Central servers Log Table

		--ReferenceStandard
		INSERT INTO [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferConflictLog]
		([TransferRequestId], ProjectName, SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetUserId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, [Status], CreatedDate, LastUpdateDate)
		SELECT @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetUserID, @TargetServerId
			,1 AS ItemTypeId, [A_RefStdId] AS SourceItemId, SourceDescription, [RefStdId] AS TargetItemId, RefStdName AS TargetDescription, NULL AS [Status]
			,GETUTCDATE() AS CreatedDate, NULL AS LastUpdateDate
		FROM #AlreadyExReferenceStandard

		--Template
		INSERT INTO [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferConflictLog]
		([TransferRequestId], ProjectName, SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetUserId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, [Status], CreatedDate, LastUpdateDate)
		SELECT @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetUserID, @TargetServerId
			,2 AS ItemTypeId, [A_TemplateId] AS SourceItemId, SourceDescription, [TemplateId] AS TargetItemId, [Name] AS TargetDescription, NULL AS [Status]
			,GETUTCDATE() AS CreatedDate, NULL AS LastUpdateDate
		FROM #AlreadyExTemplate

		--UserGlobalTerm
		INSERT INTO [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferConflictLog]
		([TransferRequestId], ProjectName, SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetUserId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, [Status], CreatedDate, LastUpdateDate)
		SELECT @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetUserID, @TargetServerId
			,3 AS ItemTypeId, [A_UserGlobalTermId] AS SourceItemId, SourceDescription, [UserGlobalTermId] AS TargetItemId, [Name] AS TargetDescription, NULL AS [Status]
			,GETUTCDATE() AS CreatedDate, NULL AS LastUpdateDate
		FROM #AlreadyExUserGlobalTerm

		--ProjectUserTag
		INSERT INTO [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferConflictLog]
		([TransferRequestId], ProjectName, SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetUserId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, [Status], CreatedDate, LastUpdateDate)
		SELECT @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetUserID, @TargetServerId
			,4 AS ItemTypeId, [A_UserTagId] AS SourceItemId, SourceDescription, [UserTagId] AS TargetItemId, [TagType] AS TargetDescription, NULL AS [Status]
			,GETUTCDATE() AS CreatedDate, NULL AS LastUpdateDate
		FROM #AlreadyExProjectUserTag



		--Add new data to Global tables

		DECLARE @LastRefStdCode AS BIGINT
		--Get Max RefStdCode from SLCProject..[ReferenceStandard] table into @LastRefStdCode to add user added Reference Standards with sequencial number.
		SELECT TOP 1 @LastRefStdCode = [RefStdCode] FROM [SLCProject].[dbo].[ReferenceStandard] WITH (NOLOCK) ORDER BY [RefStdCode] DESC

		--ReferenceStandard
		INSERT INTO [SLCProject].[dbo].[ReferenceStandard]
		([RefStdName],[RefStdSource],[ReplaceRefStdId],[ReplaceRefStdSource],[mReplaceRefStdId],[IsObsolete],[RefStdCode],[CreateDate]
			,[CreatedBy],[ModifiedDate],[ModifiedBy],[CustomerId],[IsDeleted],[IsLocked],[IsLockedByFullName],[IsLockedById],[A_RefStdId],[IsTransferred])
		SELECT S.[RefStdName],S.[RefStdSource],S.[ReplaceRefStdId],S.[ReplaceRefStdSource],S.[mReplaceRefStdId],S.[IsObsolete]
			,ROW_NUMBER()OVER(ORDER BY S.RefStdID DESC) + @LastRefStdCode AS [RefStdCode]--S.[RefStdCode]
			,S.[CreateDate]
			,S.[CreatedBy],S.[ModifiedDate],S.[ModifiedBy],@TargetCustomerID AS [CustomerId],S.[IsDeleted],S.[IsLocked],S.[IsLockedByFullName],S.[IsLockedById]
			,S.RefStdId AS [A_RefStdId], 1 AS [IsTransferred]
		FROM #UsedReferenceStandard S WITH (NOLOCK)
		LEFT OUTER JOIN #AlreadyExReferenceStandard S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.RefStdId = S1.[A_RefStdId]
		WHERE S1.RefStdId IS NULL AND S.CustomerId = @TargetCustomerID

		SELECT S.RefStdId, S.A_RefStdId, S.CustomerId, @SourceCustomerID AS SourceCustomerId, S.RefStdName, S.RefStdCode, S1.RefStdCode AS SourceRefStdCode
		INTO #TmpNewlyAddedRefStds
		FROM [SLCProject].[dbo].[ReferenceStandard] S WITH (NOLOCK)
		INNER JOIN #UsedReferenceStandard S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.RefStdName = S1.RefStdName AND S.[IsTransferred] = 1
		LEFT OUTER JOIN #AlreadyExReferenceStandard S2 WITH (NOLOCK) ON S1.CustomerId = S2.CustomerId AND S1.RefStdId = S2.[A_RefStdId]
		WHERE S2.RefStdId IS NULL AND S.CustomerId = @TargetCustomerID AND S.[IsTransferred] = 1 and isnull(S.isdeleted,0)=0

		--ReferenceStandardEdition
		INSERT INTO [SLCProject].[dbo].[ReferenceStandardEdition]
		([RefEdition],[RefStdTitle],[LinkTarget],[CreateDate],[CreatedBy],[RefStdId],[CustomerId],[ModifiedDate],[ModifiedBy],[A_RefStdEditionId])
		SELECT S.[RefEdition],S.[RefStdTitle],S.[LinkTarget],S.[CreateDate],S.[CreatedBy],S2.[RefStdId],@TargetCustomerID AS [CustomerId],S.[ModifiedDate]
			,S.[ModifiedBy],S.[RefStdEditionId] AS [A_RefStdEditionId]
		FROM #UsedReferenceStandardEdition S WITH (NOLOCK)
		INNER JOIN #TmpNewlyAddedRefStds S2 ON S.CustomerId = S2.CustomerId AND S.RefStdId = S2.A_RefStdId
		--INNER JOIN #UsedReferenceStandard E ON S.CustomerId = E.CustomerId AND S.RefStdId = E.RefStdID
		--INNER JOIN #TmpNewlyAddedRefStds S2 ON E.CustomerId = S2.CustomerId AND E.RefStdId = S2.A_RefStdId AND E.RefStdName = S2.RefStdName
		--LEFT OUTER JOIN #AlreadyExReferenceStandard S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.RefStdId = S1.[A_RefStdId]
		--WHERE S1.RefStdId IS NULL AND S.CustomerId = @TargetCustomerID
		WHERE S.CustomerId = @TargetCustomerID

		--#TmpNewlyAddedRefEditions
		SELECT A.RefStdId, S2.A_RefStdId, A.A_RefStdEditionId, A.RefStdEditionId, A.CustomerId, @SourceCustomerID AS SourceCustomerId
		INTO #TmpNewlyAddedRefEditions
		FROM [SLCProject].[dbo].[ReferenceStandardEdition] A WITH (NOLOCK)
		INNER JOIN #TmpNewlyAddedRefStds S2 ON A.CustomerId = S2.CustomerId AND A.RefStdId = S2.RefStdId
		INNER JOIN #UsedReferenceStandardEdition S WITH (NOLOCK) ON A.CustomerId = S.CustomerId AND S2.A_RefStdId = S.RefStdId AND A.[A_RefStdEditionId] = S.RefStdEditionId
		WHERE S.CustomerId = @TargetCustomerID

		--#TmpRefEditSource
		SELECT A.RefStdId, A.RefStdEditionId, A.RefEdition, A.RefStdTitle, A.LinkTarget, A.CustomerId AS SourceCustomerId, @TargetCustomerID AS CustomerId, NULL AS NewRefEditionId
		INTO #TmpRefEditSource
		FROM [SLCSERVER03].[SLCProject].[dbo].[ReferenceStandardEdition] A WITH (NOLOCK)
		INNER JOIN #tmpRefStdEdId S WITH (NOLOCK) ON A.CustomerId = S.CustomerId AND A.RefStdEditionId = S.RefStdEditionId
		WHERE S.CustomerId = @SourceCustomerID

		--#TmpRefEditTarget
		SELECT A.RefStdId, S.A_RefStdId, A.A_RefStdEditionId, A.RefStdEditionId, A.RefEdition, A.RefStdTitle, A.LinkTarget, A.CustomerId, @SourceCustomerID AS SourceCustomerId
		INTO #TmpRefEditTarget
		FROM [SLCProject].[dbo].[ReferenceStandardEdition] A WITH (NOLOCK)
		INNER JOIN #AlreadyExReferenceStandard S ON A.CustomerId = S.CustomerId AND A.RefStdId = S.RefStdId
		WHERE S.CustomerId = @TargetCustomerID

		UPDATE A SET A.NewRefEditionId = B.RefStdEditionId
		FROM #TmpRefEditSource A
		INNER JOIN #TmpRefEditTarget B ON B.CustomerId = A.CustomerId AND B.A_RefStdId = A.RefStdId AND B.RefEdition = A.RefEdition AND B.RefStdTitle = A.RefStdTitle AND B.LinkTarget = A.LinkTarget
		WHERE A.CustomerId = @TargetCustomerID

		UPDATE A SET A.NewRefEditionId = B.RefStdEditionId
		FROM #TmpRefEditSource A
		INNER JOIN 
		(SELECT CustomerId, A_RefStdId, MAX(RefStdEditionId) AS RefStdEditionId FROM #TmpRefEditTarget WHERE CustomerId = @TargetCustomerID GROUP BY CustomerId, A_RefStdId)
		B ON B.CustomerId = A.CustomerId AND B.A_RefStdId = A.RefStdId
		WHERE A.CustomerId = @TargetCustomerID AND A.NewRefEditionId IS NULL
		


		--Template
		INSERT INTO [SLCProject].[dbo].[Template]
		([Name],[TitleFormatId],[SequenceNumbering],[CustomerId],[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate]
			,[MasterDataTypeId],[A_TemplateId],[ApplyTitleStyleToEOS],[IsTransferred])
		SELECT S.[Name],S.[TitleFormatId],S.[SequenceNumbering],@TargetCustomerID AS [CustomerId],S.[IsSystem],S.[IsDeleted],S.[CreatedBy],S.[CreateDate]
			,S.[ModifiedBy],S.[ModifiedDate],S.[MasterDataTypeId],S.[TemplateId] AS [A_TemplateId],S.[ApplyTitleStyleToEOS], 1 AS [IsTransferred]
		FROM #UsedTemplate S WITH (NOLOCK)
		LEFT OUTER JOIN #AlreadyExTemplate S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.TemplateId = S1.A_TemplateId
		WHERE S1.TemplateId IS NULL AND S.CustomerId = @TargetCustomerID

		SELECT S.TemplateId, S.A_TemplateId, S.CustomerId, S.[Name], @SourceCustomerID AS SourceCustomerId
		INTO #TmpNewlyAddedTemplates
		FROM [SLCProject].[dbo].[Template] S WITH (NOLOCK)
		INNER JOIN #UsedTemplate S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[Name] = S1.[Name] AND S.[IsTransferred] = 1
		LEFT OUTER JOIN #AlreadyExTemplate S2 WITH (NOLOCK) ON S1.CustomerId = S2.CustomerId AND S1.TemplateId = S2.A_TemplateId
		WHERE S2.TemplateId IS NULL AND S.CustomerId = @TargetCustomerID AND S.[IsTransferred] = 1

		--Get StyleIds used for Template
		SELECT DISTINCT S.StyleId, S2.[Name], T.TemplateId, T.A_TemplateId, @TargetCustomerID AS CustomerId
		INTO #InsertStyleIds
		FROM [SLCSERVER03].[SLCProject].[dbo].[TemplateStyle] S WITH (NOLOCK)
		INNER JOIN [SLCSERVER03].[SLCProject].[dbo].[Style] S2 WITH (NOLOCK) ON S.CustomerId = S2.CustomerId AND S.StyleId = S2.StyleId
		INNER JOIN #TmpNewlyAddedTemplates T WITH (NOLOCK) ON T.CustomerId = @TargetCustomerID AND S.TemplateId = T.A_TemplateId
		WHERE S.CustomerId = @SourceCustomerID AND T.CustomerId = @TargetCustomerID

		--Style
		INSERT INTO [SLCProject].[dbo].[Style]
		([Alignment],[IsBold],[CharAfterNumber],[CharBeforeNumber],[FontName],[FontSize],[HangingIndent],[IncludePrevious],[IsItalic],[LeftIndent]
			,[NumberFormat],[NumberPosition],[PrintUpperCase],[ShowNumber],[StartAt],[Strikeout],[Name],[TopDistance],[Underline],[SpaceBelowParagraph]
			,[IsSystem],[CustomerId],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[Level],[MasterDataTypeId],[A_StyleId],[IsTransferred])
		SELECT S.[Alignment],S.[IsBold],S.[CharAfterNumber],S.[CharBeforeNumber],S.[FontName],S.[FontSize],S.[HangingIndent],S.[IncludePrevious],S.[IsItalic],S.[LeftIndent]
			,S.[NumberFormat],S.[NumberPosition],S.[PrintUpperCase],S.[ShowNumber],S.[StartAt],S.[Strikeout],S.[Name],S.[TopDistance],S.[Underline],S.[SpaceBelowParagraph]
			,S.[IsSystem],@TargetCustomerID AS [CustomerId],S.[IsDeleted],S.[CreatedBy],S.[CreateDate],S.[ModifiedBy],S.[ModifiedDate],S.[Level],S.[MasterDataTypeId]
			,S.[StyleId] AS [A_StyleId], 1 AS [IsTransferred]
		FROM [SLCSERVER03].[SLCProject].[dbo].[Style] S WITH (NOLOCK)
		WHERE S.CustomerId = @SourceCustomerID AND S.StyleId IN (SELECT StyleId FROM #InsertStyleIds)

		SELECT S.StyleId, S.A_StyleId, S.CustomerId, S.[Name], @SourceCustomerID AS SourceCustomerId INTO #TmpNewlyAddedStyles
		FROM [SLCProject].[dbo].[Style] S WITH (NOLOCK)
		INNER JOIN #InsertStyleIds S2 WITH (NOLOCK) ON S.CustomerId = S2.CustomerId AND S.A_StyleId = S2.StyleId AND S.[Name] = S2.[Name] AND S.[IsTransferred] = 1
		WHERE S.CustomerId = @TargetCustomerID AND S.[IsTransferred] = 1

		--TemplateStyle
		INSERT [SLCProject].[dbo].[TemplateStyle]
		([TemplateId],[StyleId],[Level],[CustomerId],[A_TemplateStyleId])
		SELECT S1.[TemplateId],S2.[StyleId],S.[Level],@TargetCustomerID AS [CustomerId],S.[TemplateStyleId] AS [A_TemplateStyleId]
		FROM [SLCSERVER03].[SLCProject].[dbo].[TemplateStyle] S WITH (NOLOCK)
		INNER JOIN #TmpNewlyAddedTemplates S1 WITH (NOLOCK) ON S1.SourceCustomerId = S.CustomerId AND S1.A_TemplateId = S.TemplateId
		INNER JOIN #TmpNewlyAddedStyles S2 WITH (NOLOCK) ON S2.SourceCustomerId = S.CustomerId AND S2.A_StyleId = S.StyleId
		WHERE S.CustomerId = @SourceCustomerID


		--UserGlobalTerm
		INSERT INTO [SLCProject].[dbo].[UserGlobalTerm]
		([Name],[Value],[CreatedDate],[CreatedBy],[CustomerId],[ProjectId],[IsDeleted],[A_UserGlobalTermId],[IsTransferred])
		SELECT S.[Name],S.[Value],S.[CreatedDate],S.[CreatedBy],@TargetCustomerID AS [CustomerId],NULL AS [ProjectId],S.[IsDeleted]
			,S.[UserGlobalTermId] AS [A_UserGlobalTermId], 1 AS [IsTransferred]
		FROM #UsedUserGlobalTerm S WITH (NOLOCK)
		LEFT OUTER JOIN #AlreadyExUserGlobalTerm S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.UserGlobalTermId = S1.A_UserGlobalTermId
		WHERE S1.UserGlobalTermId IS NULL AND S.CustomerId = @TargetCustomerID

		SELECT S.UserGlobalTermId, S.A_UserGlobalTermId, S.CustomerId, S.[Name], @SourceCustomerID AS SourceCustomerId
		INTO #TmpNewlyUserGlobalTerm
		FROM [SLCProject].[dbo].[UserGlobalTerm] S WITH (NOLOCK)
		INNER JOIN #UsedUserGlobalTerm S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[Name] = S1.[Name] AND S.IsDeleted = 0 AND S.[IsTransferred] = 1
		LEFT OUTER JOIN #AlreadyExUserGlobalTerm S2 WITH (NOLOCK) ON S1.CustomerId = S2.CustomerId AND S1.UserGlobalTermId = S2.A_UserGlobalTermId
		WHERE S2.UserGlobalTermId IS NULL AND S.CustomerId = @TargetCustomerID AND S.[IsTransferred] = 1

		--ProjectUserTag
		INSERT INTO [SLCProject].[dbo].[ProjectUserTag]
		([CustomerId],[TagType],[Description],[SortOrder],[IsSystemTag],[CreateDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[A_UserTagId],[IsTransferred])
		SELECT @TargetCustomerID AS [CustomerId],S.[TagType],S.[Description],S.[SortOrder],S.[IsSystemTag],S.[CreateDate],S.[CreatedBy],S.[ModifiedDate]
			,S.[ModifiedBy],S.[UserTagId] AS [A_UserTagId], 1 AS [IsTransferred]
		FROM #UsedProjectUserTag S WITH (NOLOCK)
		LEFT OUTER JOIN #AlreadyExProjectUserTag S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.UserTagId = S1.A_UserTagId
		WHERE S1.UserTagId IS NULL AND S.CustomerId = @TargetCustomerID

		SELECT S.UserTagId, S.A_UserTagId, S.CustomerId, S.[TagType], @SourceCustomerID AS SourceCustomerId
		INTO #TmpNewlyProjectUserTag
		FROM [SLCProject].[dbo].[ProjectUserTag] S WITH (NOLOCK)
		INNER JOIN #UsedProjectUserTag S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.[TagType] = S1.[TagType] AND S.[Description] = S1.[Description] AND S.[IsTransferred] = 1
		LEFT OUTER JOIN #AlreadyExProjectUserTag S2 WITH (NOLOCK) ON S1.CustomerId = S2.CustomerId AND S1.UserTagId = S2.A_UserTagId
		WHERE S2.UserTagId IS NULL AND S.CustomerId = @TargetCustomerID AND S.[IsTransferred] = 1

		
		--Add newly added global data to ProjectTransferGlobalDataAuditLog

		--ReferenceStandard
		INSERT INTO [SLCProject].[dbo].[ProjectTransferGlobalDataAuditLog]
		(SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, CreatedDate, RequestId)
		SELECT @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetServerId
			,1 AS ItemTypeId, [A_RefStdId] AS SourceItemId, RefStdName AS SourceDescription, [RefStdId] AS TargetItemId, RefStdName AS TargetDescription
			,GETUTCDATE() AS CreatedDate, @TransferRequestId AS RequestId
		FROM #TmpNewlyAddedRefStds

		--Template
		INSERT INTO [SLCProject].[dbo].[ProjectTransferGlobalDataAuditLog]
		(SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, CreatedDate, RequestId)
		SELECT @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetServerId
			,2 AS ItemTypeId, [A_TemplateId] AS SourceItemId, [Name] AS SourceDescription, [TemplateId] AS TargetItemId, [Name] AS TargetDescription
			,GETUTCDATE() AS CreatedDate, @TransferRequestId AS RequestId
		FROM #TmpNewlyAddedTemplates

		--UserGlobalTerm
		INSERT INTO [SLCProject].[dbo].[ProjectTransferGlobalDataAuditLog]
		(SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, CreatedDate, RequestId)
		SELECT @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetServerId
			,3 AS ItemTypeId, [A_UserGlobalTermId] AS SourceItemId, [Name] AS SourceDescription, [UserGlobalTermId] AS TargetItemId, [Name] AS TargetDescription
			,GETUTCDATE() AS CreatedDate, @TransferRequestId AS RequestId
		FROM #TmpNewlyUserGlobalTerm

		--ProjectUserTag
		INSERT INTO [SLCProject].[dbo].[ProjectTransferGlobalDataAuditLog]
		(SourceCustomerId, SourceProjectId, SourceServerId, TargetCustomerId, TargetProjectId, TargetServerId
			,ItemTypeId, SourceItemId, SourceDescription, TargetItemId, TargetDescription, CreatedDate, RequestId)
		SELECT @SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, @TargetProjectID, @TargetServerId
			,4 AS ItemTypeId, [A_UserTagId] AS SourceItemId, [TagType] AS SourceDescription, [UserTagId] AS TargetItemId, [TagType] AS TargetDescription
			,GETUTCDATE() AS CreatedDate, @TransferRequestId AS RequestId
		FROM #TmpNewlyProjectUserTag



		DECLARE @TemplateCount AS INT = 0
		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @TargetCustomerID AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount <= 0
		BEGIN
			--Add System Templates for Customer
			INSERT INTO [SLCProject].[dbo].[Template]
			([Name],[TitleFormatId],[SequenceNumbering],[CustomerId],[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId]
				,[ApplyTitleStyleToEOS],[IsTransferred])
			SELECT [Name],[TitleFormatId],[SequenceNumbering],@TargetCustomerID,[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId]
				,[ApplyTitleStyleToEOS],[IsTransferred]
			FROM [SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId IS NULL AND ISNULL(IsSystem, 0) = 1

			--Add TemplateStyle for System Templates
			INSERT INTO [SLCProject].[dbo].[TemplateStyle]
			([TemplateId],[StyleId],[Level],[CustomerId],[A_TemplateStyleId])
			SELECT C.TemplateId, B.StyleId, B.[Level], @TargetCustomerID, [A_TemplateStyleId]
			FROM [SLCProject].[dbo].[Template] A WITH (NOLOCK)
			INNER JOIN [SLCProject].[dbo].[TemplateStyle] B WITH (NOLOCK) ON A.TemplateId = B.TemplateId
			INNER JOIN [SLCProject].[dbo].[Template] C WITH (NOLOCK) ON C.CustomerId = @TargetCustomerID AND ISNULL(C.IsSystem, 0) = 1 AND C.[Name] = A.[Name]
			WHERE A.CustomerId IS NULL AND ISNULL(A.IsSystem, 0) = 1
	
		END

		--Transfer Project Data
		SET @RequestId = 0
		
		DECLARE @IsOfficeMaster AS INT, @ProjectAccessTypeId AS INT, @ProjectOwnerId AS INT, @SpecViewModeId AS INT, @MasterDataTypeId AS INT, @SenderProjectViewTypeId AS INT

		--Update previousely migrated projects A_ProjectId to NULL so it wont duplicate the records in other child tables.
		UPDATE P SET P.A_ProjectId = NULL
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE CustomerId = @TargetCustomerID AND A_ProjectId = @SourceProjectID;

		--Move Project table
		--Insert
		INSERT INTO [SLCProject].[dbo].[Project]
		([Name], IsOfficeMaster, [Description], TemplateId, MasterDataTypeId, UserId, CustomerId, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsDeleted, IsNamewithHeld
			,IsMigrated, IsLocked, A_ProjectId, IsProjectMoved, [GlobalProjectID], [IsPermanentDeleted], [ModifiedByFullName], [MigratedDate], [IsArchived], [IsShowMigrationPopup]
			,[LockedBy],[LockedDate],[LockedById],[IsIncomingProject],[TransferredDate])
		SELECT
			S.[Name], S.IsOfficeMaster, S.[Description], CASE WHEN T1.TemplateId IS NULL THEN IIF(T2.TemplateId IS NULL, S.TemplateId, T2.TemplateId) ELSE T1.TemplateId END AS TemplateId
			,S.MasterDataTypeId, @TargetUserID AS UserId, @TargetCustomerID AS CustomerId, S.CreateDate, @TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy
			,S.ModifiedDate, S.IsDeleted, S.IsNamewithHeld, S.IsMigrated, 0 AS IsLocked, S.ProjectId AS A_ProjectId, 0 AS IsProjectMoved
			,S.GlobalProjectID AS [GlobalProjectID], S.[IsPermanentDeleted], S.[ModifiedByFullName], S.[MigratedDate], S.[IsArchived], S.[IsShowMigrationPopup]
			,NULL AS [LockedBy],NULL AS [LockedDate],NULL AS [LockedById],1 AS [IsIncomingProject], GETUTCDATE() AS [TransferredDate]
		FROM [SLCSERVER03].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
		--LEFT JOIN [SLCProject].[dbo].[Template] T WITH (NOLOCK) ON T.CustomerId = @TargetCustomerID AND T.A_TemplateId = S.TemplateId
		LEFT JOIN #TmpNewlyAddedTemplates T1 ON T1.SourceCustomerId = S.CustomerId AND T1.A_TemplateId = S.TemplateId
		LEFT JOIN #AlreadyExTemplate T2 ON T2.SourceCustomerId = S.CustomerId AND T2.A_TemplateId = S.TemplateId
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SELECT TOP 1 @New_ProjectID = ProjectId, @IsOfficeMaster = IsOfficeMaster, @MasterDataTypeId = MasterDataTypeId FROM [SLCProject].[dbo].[Project] WITH (NOLOCK) WHERE CustomerId = @TargetCustomerID AND A_ProjectId = @SourceProjectID ORDER BY ProjectID DESC

		--Insert System Templates into Temp table
		SELECT T1.TemplateId AS SourceTemplateId, T1.[Name] AS SourceTemplateName, @SourceCustomerID AS SourceCustomerId, @TargetCustomerID AS TargetCustomerID, NULL AS TargetTemplateId
		INTO #TmpSystemTemplates FROM [SLCSERVER03].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @SourceCustomerID AND ISNULL(T1.IsSystem, 0) = 1

		--Update System TemplateIds from Target Customers account in Temp Table
		UPDATE T1 SET T1.TargetTemplateId = T2.TemplateId
		FROM #TmpSystemTemplates T1
		INNER JOIN [SLCProject].[dbo].[Template] T2 WITH (NOLOCK) ON T1.TargetCustomerID = T2.CustomerId AND T1.[SourceTemplateName] = T2.[Name] AND ISNULL(T2.IsSystem, 0) = 1
		WHERE T2.CustomerId = @TargetCustomerID
		

		UPDATE S SET TemplateId = T1.TargetTemplateId
		FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
		INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.SourceTemplateId AND S.CustomerId = T1.TargetCustomerID
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		----Get RequestId from 
		--SELECT @RequestId = RequestId FROM [SLCProject].[dbo].[ProjectTransferRequest] WITH (NOLOCK)
		--WHERE SourceCustomerId = @SourceCustomerID AND SourceProjectId = @SourceProjectID AND SourceServerId = @SourceServerID AND TargetCustomerId = @TargetCustomerID
		--	AND [StatusId] = 1--StatusId 1 as Queued

		SELECT @RequestId = RequestId FROM [SLCProject].[dbo].[CopyProjectRequest] WITH (NOLOCK)
		WHERE CustomerId = @TargetCustomerID AND TransferRequestId = @TransferRequestId AND [StatusId] = 1--StatusId 1 as Queued

		--UPDATE New ProjectId
		UPDATE P SET P.TargetProjectId = @New_ProjectID
		FROM [SLCProject].[dbo].[CopyProjectRequest] P WITH (NOLOCK)
		WHERE P.CustomerId = @TargetCustomerID AND P.TransferRequestId = @TransferRequestId
			AND P.[StatusId] = 1--StatusId 1 as Queued

		----UPDATE New ProjectId
		--UPDATE P SET P.TargetProjectId = @New_ProjectID
		--FROM [SLCProject].[dbo].[ProjectTransferRequest] P WITH (NOLOCK)
		--WHERE P.SourceCustomerId = @SourceCustomerID AND P.SourceProjectId = @SourceProjectID AND P.SourceServerId = @SourceServerID AND P.TargetCustomerId = @TargetCustomerID
		--	AND P.[StatusId] = 1--StatusId 1 as Queued

		--Update Status to Running on Central server
		UPDATE P
			SET P.TargetProjectId = @New_ProjectID, P.StatusId = 2, P.StartTime = GETUTCDATE()
		FROM [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferQueue] P WITH (NOLOCK)
		WHERE TransferRequestId = @TransferRequestId

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'New Project created', 'New Project created', 1, 1, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 3, 0, '', ''

		--Set IsDeleted flag to 1 for a temporary basis until whole project is transferred
		UPDATE P
		SET P.IsDeleted = 1--, P.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID;


		INSERT INTO [SLCProject].[dbo].[ProjectAddress]
		(ProjectId, CustomerId, AddressLine1, AddressLine2, CountryId, StateProvinceId, CityId, PostalCode, CreateDate, CreatedBy, ModifiedBy
			,ModifiedDate, StateProvinceName, CityName)
		SELECT @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.AddressLine1, S.AddressLine2, S.CountryId, S.StateProvinceId, S.CityId
			,S.PostalCode, S.CreateDate, @TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.ModifiedDate, S.StateProvinceName, S.CityName
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectAddress] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Project Address created', 'Project Address created', 1, 2, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 6, 0, '', ''
			
		--Move UserFolder table
		INSERT INTO [SLCProject].[dbo].[UserFolder]
		(FolderTypeId, ProjectId, UserId, LastAccessed, CustomerId, LastAccessByFullName)
		SELECT S.FolderTypeId, @New_ProjectID AS ProjectId, @TargetUserID AS UserId, S.LastAccessed, @TargetCustomerID AS CustomerId, S.LastAccessByFullName
		FROM [SLCSERVER03].[SLCProject].[dbo].[UserFolder] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [SLCProject].[dbo].[usp_GetTransferProjectDefaultPrivacySetting] @TargetCustomerID, @TargetUserID, @IsOfficeMaster, @ProjectAccessTypeId OUTPUT, @ProjectOwnerId OUTPUT

		--Add user into the Project Team Member list when project type is Private/Hidden    
		IF(@ProjectAccessTypeId IN (2,3) AND @ProjectOwnerId IS NULL)
		BEGIN
			EXEC [SLCProject].[dbo].[usp_ApplyProjectDefaultSetting] @IsOfficeMaster, @New_ProjectID, @TargetUserID, @TargetCustomerID, 3 --Transferred Project
		END

		SELECT @SenderProjectViewTypeId = S.[SpecViewModeId] FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK) WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Get SpecViewModeId
		EXEC [SLCAdmin].[Authentication].[dbo].[usp_GetTransferProjectViewTypeId] @MasterDataTypeId, @SenderProjectViewTypeId, @SourceCustomerID, @TargetCustomerID, @SpecViewModeId OUTPUT

		--Move ProjectSummary table
		INSERT INTO [SLCProject].[dbo].[ProjectSummary]
		([ProjectId],[CustomerId],[UserId],[ProjectTypeId],[FacilityTypeId],[SizeUoM],[IsIncludeRsInSection],[IsIncludeReInSection]
			,[SpecViewModeId],[UnitOfMeasureValueTypeId],[SourceTagFormat],[IsPrintReferenceEditionDate],[IsActivateRsCitation],[LastMasterUpdate]
			,[BudgetedCostId],[BudgetedCost],[ActualCost],[EstimatedArea],[SpecificationIssueDate],[SpecificationModifiedDate],[ActualCostId]
			,[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM],[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId], [IsHiddenAllBsdSections],[IsLinkEngineEnabled])
		SELECT @New_ProjectID AS ProjectId,@TargetCustomerID AS [CustomerId],@TargetUserID AS [UserId],S.[ProjectTypeId],S.[FacilityTypeId],S.[SizeUoM],S.[IsIncludeRsInSection],S.[IsIncludeReInSection]
			,@SpecViewModeId AS [SpecViewModeId],S.[UnitOfMeasureValueTypeId],S.[SourceTagFormat],S.[IsPrintReferenceEditionDate],S.[IsActivateRsCitation],S.[LastMasterUpdate]
			,S.[BudgetedCostId],S.[BudgetedCost],S.[ActualCost],S.[EstimatedArea],S.[SpecificationIssueDate],S.[SpecificationModifiedDate],S.[ActualCostId]
			,S.[ActualSizeId],S.[EstimatedSizeId],S.[EstimatedSizeUoM],S.[Cost],S.[Size],@ProjectAccessTypeId AS [ProjectAccessTypeId],@ProjectOwnerId AS [OwnerId]
			,S.[TrackChangesModeId], S.[IsHiddenAllBsdSections],S.[IsLinkEngineEnabled]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSummary created', 'ProjectSummary created', 1, 3, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 9, 0, '', ''
			
		
		--Move ProjectPrintSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPrintSetting]
		([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage]
			,[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount],[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo]
			,IsIncludePdfBookmark,BookmarkLevel, IsIncludeOrphanParagraph, IsMarkPagesAsBlank, IsIncludeHeaderFooterOnBlackPages, BlankPagesText
			,IncludeSectionIdAfterEod, IncludeEndOfSection, IncludeDivisionNameandNumber, IsIncludeAuthorForBookMark, IsContinuousPageNumber)
		SELECT @New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],@TargetUserID AS [CreatedBy],S.[CreateDate],@TargetUserID AS [ModifiedBy],S.[ModifiedDate],S.[IsExportInMultipleFiles],S.[IsBeginSectionOnOddPage]
			,S.[IsIncludeAuthorInFileName],S.[TCPrintModeId], S.[IsIncludePageCount], S.IsIncludeHyperLink, S.KeepWithNext, S.[IsPrintMasterNote],S.[IsPrintProjectNote],S.[IsPrintNoteImage]
			,S.[IsPrintIHSLogo],S.IsIncludePdfBookmark,S.BookmarkLevel, S.IsIncludeOrphanParagraph, S.IsMarkPagesAsBlank, S.IsIncludeHeaderFooterOnBlackPages, S.BlankPagesText
			,S.IncludeSectionIdAfterEod, S.IncludeEndOfSection, S.IncludeDivisionNameandNumber, S.IsIncludeAuthorForBookMark, S.IsContinuousPageNumber
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectPrintSetting] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectPrintSetting created', 'ProjectPrintSetting created', 1, 6, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 16, 0, '', ''

		
		--Move ProjectSection table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SectionId) AS RowNumber, S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, @TargetUserID AS UserId, S.DivisionId, S.DivisionCode, S.[Description]
				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
				,S.CreateDate, @TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
				,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp, S.IsHidden, S.SortOrder
				,S.SectionSource, S.PendingUpdateCount  
		INTO #tmp_TgtSectionSLC
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

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
			SELECT S.ParentSectionId, S.mSectionId, S.ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
					,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author
					,CASE WHEN T1.TemplateId IS NULL THEN IIF(T2.TemplateId IS NULL, S.TemplateId, T2.TemplateId) ELSE T1.TemplateId END AS TemplateId
					,S.SectionCode, S.IsDeleted, 0 AS IsLocked, NULL AS LockedBy, NULL LockedByFullName
					,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
					,A_SectionId, CASE WHEN S.IsLockedImportSection IS NULL THEN NULL ELSE '' END AS IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock
					,S.TrackChangeLockedBy, S.DataMapDateTimeStamp, S.IsHidden, S.SortOrder, S.SectionSource, S.PendingUpdateCount
			FROM #tmp_TgtSectionSLC S
			--LEFT JOIN [SLCProject].[dbo].[Template] S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.TemplateId = S1.A_TemplateId
			LEFT JOIN #TmpNewlyAddedTemplates T1 ON T1.CustomerId = S.CustomerId AND T1.A_TemplateId = S.TemplateId
			LEFT JOIN #AlreadyExTemplate T2 ON T2.CustomerId = S.CustomerId AND T2.A_TemplateId = S.TemplateId
			WHERE RowNumber BETWEEN @Start AND @End
 
			SET @Records += @Section_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @Section_BatchSize - 1;
		END

		SELECT SectionId, ParentSectionId, ProjectId, CustomerId, A_SectionId , SectionSource INTO #tmpProjectSectionSLC
		FROM [SLCProject].[dbo].[ProjectSection] WITH (NOLOCK) WHERE ProjectId = @New_ProjectID AND CustomerId = @TargetCustomerID

		UPDATE S SET TemplateId = T1.TargetTemplateId
		FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.SourceTemplateId AND S.CustomerId = T1.TargetCustomerID
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		SELECT SectionId, A_SectionId INTO #NewOldSectionIdMappingSLC FROM #tmpProjectSectionSLC

		--UPDATE ParentSectionId in TGT Section table                  
		UPDATE TGT_TMP SET TGT_TMP.ParentSectionId = NOSM.SectionId
		FROM #tmpProjectSectionSLC TGT_TMP
		INNER JOIN #NewOldSectionIdMappingSLC NOSM ON TGT_TMP.ParentSectionId = NOSM.A_SectionId
		WHERE TGT_TMP.ProjectId = @New_ProjectID;
			
		--UPDATE ParentSectionId in original table                  
		UPDATE PS SET PS.ParentSectionId = PS_TMP.ParentSectionId
		FROM [SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC PS_TMP ON PS.SectionId = PS_TMP.SectionId
		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @TargetCustomerID;

		DROP TABLE IF EXISTS #tmp_TgtSectionSLC;
		DROP TABLE IF EXISTS #NewOldSectionIdMappingSLC;

		--Move CustomerDivision
		SELECT A.CustomerId, A.DivisionId, B.DivisionCode, B.DivisionTitle, B.IsActive, B.MasterDataTypeId, B.FormatTypeId, B.IsDeleted
			,@TargetUserID AS CreatedBy, B.CreatedDate, @TargetUserID AS ModifiedBy, B.ModifiedDate INTO #tmpUserDivisionsInProject
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSection] A WITH (NOLOCK)
		INNER JOIN [SLCSERVER03].[SLCProject].[dbo].[CustomerDivision] B WITH (NOLOCK) ON A.CustomerId = B.CustomerId AND A.DivisionId = B.DivisionId
		WHERE A.ProjectId = @SourceProjectID AND A.CustomerId = @SourceCustomerID AND A.IsLastLevel = 0

		--Insert record into CustomerDivision table if DivisionCode and DivisionTitle pair does NOT already exists in Target Customer Account
		INSERT INTO [SLCProject].[dbo].[CustomerDivision]
		(DivisionCode, DivisionTitle, IsActive, MasterDataTypeId, FormatTypeId, IsDeleted, CustomerId, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate)
		SELECT A.DivisionCode, A.DivisionTitle, A.IsActive, A.MasterDataTypeId, A.FormatTypeId, A.IsDeleted, @TargetCustomerID AS CustomerId, A.CreatedBy, A.CreatedDate
			,A.ModifiedBy, A.ModifiedDate
		FROM #tmpUserDivisionsInProject A WITH (NOLOCK)
		LEFT JOIN [SLCProject].[dbo].[CustomerDivision] B WITH (NOLOCK) ON B.CustomerId = @TargetCustomerID AND ISNULL(A.DivisionCode, '') = ISNULL(B.DivisionCode, '') AND A.DivisionTitle = B.DivisionTitle
		WHERE B.DivisionId IS NULL

		--Update new DivisionId from Target Customers account
		UPDATE A SET A.DivisionId = C.DivisionId
		FROM [SLCProject].[dbo].[ProjectSection] A WITH (NOLOCK)
		INNER JOIN #tmpUserDivisionsInProject B WITH (NOLOCK) ON A.DivisionId = B.DivisionId
		INNER JOIN [SLCProject].[dbo].[CustomerDivision] C WITH (NOLOCK) ON ISNULL(B.DivisionCode, '') = ISNULL(C.DivisionCode, '') AND B.DivisionTitle = C.DivisionTitle AND C.CustomerId = @TargetCustomerID
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #tmpUserDivisionsInProject;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSection created', 'ProjectSection created', 1, 7, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 18, 0, '', ''

		--DELETE FROM [SLCSERVER03].[SLCProject].[dbo].[Staging_ProjectSection]
		--WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID

		--INSERT INTO [SLCSERVER03].[SLCProject].[dbo].[Staging_ProjectSection]
		--(SectionId, ProjectId, CustomerId)
		--SELECT PS.SectionId, PS.ProjectId, PS.CustomerId
		--FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
		--WHERE PS.ProjectId = @SourceProjectID AND PS.CustomerId = @SourceCustomerID
		--AND ISNULL(PS.IsDeleted, 0) = 0;

		
		--Move ProjectPageSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPageSetting]
		([MarginTop],[MarginBottom],[MarginLeft],[MarginRight],[EdgeHeader],[EdgeFooter],[IsMirrorMargin],[ProjectId],[CustomerId],[SectionId],[TypeId])
		SELECT S.[MarginTop],S.[MarginBottom],S.[MarginLeft],S.[MarginRight],S.[EdgeHeader],S.[EdgeFooter],S.[IsMirrorMargin]
			,@New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId]
			,CASE WHEN S.SectionId IS NULL THEN NULL ELSE PS.SectionId END AS SectionId,S.[TypeId]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectPageSetting] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSectionSLC PS ON PS.ProjectId = @New_ProjectID AND PS.A_SectionId = S.SectionId
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectPageSetting created', 'ProjectPageSetting created', 1, 4, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 18, 0, '', ''
		
			
		--Move ProjectPaperSetting table
		INSERT INTO [SLCProject].[dbo].[ProjectPaperSetting]
		(PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId, SectionId)
		SELECT S.PaperName, S.PaperWidth, S.PaperHeight, S.PaperOrientation, S.PaperSource, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId
			,CASE WHEN S.SectionId IS NULL THEN NULL ELSE PS.SectionId END AS SectionId
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectPaperSetting] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSectionSLC PS ON PS.ProjectId = @New_ProjectID AND PS.A_SectionId = S.SectionId
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectPaperSetting created', 'ProjectPaperSetting created', 1, 5, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 18, 0, '', ''

		--Move ProjectGlobalTerm table

		--Master Global Term
		INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
			,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
		SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode
				,S.CreatedDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy, S.SLE_GlobalChoiceID, S.[UserGlobalTermId], S.IsDeleted
				,S.[UserGlobalTermId] AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND GlobalTermSource = 'M'

		-- Gather all the unique UserGlobalTerm from all the projects and use min value for GlobalTermCode.
		DECLARE @GlobalTermCode TABLE (MinGlobalTermCode INT,UserGlobalTermId INT);
		INSERT @GlobalTermCode SELECT MIN(GlobalTermCode) AS MinGlobalTermCode, UserGlobalTermId FROM [SLCProject].[dbo].[ProjectGlobalTerm] WITH (NOLOCK)
		WHERE CustomerId = @TargetCustomerID AND ISNULL(IsDeleted, 0) = 0 AND GlobalTermSource = 'U' AND UserGlobalTermId IS NOT NULL GROUP BY UserGlobalTermId

		DECLARE @LastGlobalTermCode AS INT
		SELECT @LastGlobalTermCode = MAX(GlobalTermCode) FROM [SLCProject].[dbo].[ProjectGlobalTerm] WITH (NOLOCK) WHERE CustomerId = @TargetCustomerID and GlobalTermSource = 'U';

		--Project User Global Term should always be above million so as to not overlap with Master Global Term Code
		if isnull(@LastGlobalTermCode,0)<@CONST_START_CODE
			set @LastGlobalTermCode = @CONST_START_CODE

		INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		(mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermCode, GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy
			,UserGlobalTermId, IsDeleted)
		SELECT NULL AS GlobalTermId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, [Name], [Value]
			,CASE WHEN MGTC.MinGlobalTermCode IS NULL 
				THEN ROW_NUMBER()OVER(ORDER BY UGT.UserGlobalTermId DESC) + @LastGlobalTermCode
				ELSE MGTC.MinGlobalTermCode END AS GlobalTermCode
			,'U', GETUTCDATE()
			,@TargetUserID AS CreatedBy, GETUTCDATE(), @TargetUserID AS ModifiedBy, UGT.UserGlobalTermId AS UserGlobalTermId, ISNULL(IsDeleted, 0) AS IsDeleted
		FROM [SLCProject].[dbo].[UserGlobalTerm] UGT WITH (NOLOCK)
		LEFT JOIN @GlobalTermCode MGTC ON UGT.UserGlobalTermId = MGTC.UserGlobalTermId
		WHERE CustomerId = @TargetCustomerID AND IsDeleted = 0--AND ISNULL(IsTransferred, 0) = 0

		--Update Project Value from Source customers library to Receivers library for already added Project Global Term above
		SELECT B.SourceCustomerID, B.CustomerId, B.[Name], A.[value] AS ProjectValue INTO #tmpProjectValuesGlobalTerm 
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] A WITH (NOLOCK)
		INNER JOIN #UsedUserGlobalTerm B ON A.CustomerId = B.SourceCustomerID AND A.[Name] = B.[Name] AND B.IsDeleted = 0 AND A.IsDeleted = 0
		WHERE A.CustomerId = @SourceCustomerID AND A.ProjectId = @SourceProjectID AND A.IsDeleted = 0

		UPDATE A SET A.[value] = B.ProjectValue
		FROM [SLCProject].[dbo].[ProjectGlobalTerm] A WITH (NOLOCK)
		INNER JOIN #tmpProjectValuesGlobalTerm B ON A.CustomerId = B.CustomerId AND A.[Name] = B.[Name] AND A.IsDeleted = 0
		WHERE A.CustomerId = @TargetCustomerID AND A.ProjectId = @New_ProjectID

		DROP TABLE IF EXISTS #tmpProjectValuesGlobalTerm;

		--Get GlobalTermCode for Already Exist Global Terms
		SELECT @SourceCustomerID AS SourceCustomerId, A.CustomerId AS TargetCustomerId, A.[Name], MAX(B.UserGlobalTermId) AS TargetUserGlobalTermId, MIN(GlobalTermCode) AS TargetGlobalTermCode
			,MAX(B.A_UserGlobalTermId) AS SourceUserGlobalTermId, NULL AS SourceGlobalTermCode INTO #tmpAlExGlobalTerm
		FROM [SLCProject].[dbo].[ProjectGlobalTerm] A WITH (NOLOCK)
		INNER JOIN #AlreadyExUserGlobalTerm B ON A.CustomerId = B.CustomerId AND A.[Name] = B.[Name]
		GROUP BY A.CustomerId, A.[Name]

		UPDATE A
			SET A.SourceGlobalTermCode = B.GlobalTermCode
		FROM #tmpAlExGlobalTerm A
		INNER JOIN [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] B WITH (NOLOCK) ON A.SourceCustomerId = B.CustomerId AND B.ProjectId = @SourceProjectID
			AND A.SourceUserGlobalTermId = B.UserGlobalTermId
		WHERE A.SourceCustomerId = @SourceCustomerID AND B.ProjectId = @SourceProjectID


		--Get GlobalTermCode for Newly Added Global Terms
		SELECT @SourceCustomerID AS SourceCustomerId, A.CustomerId AS TargetCustomerId, A.[Name], MAX(B.UserGlobalTermId) AS TargetUserGlobalTermId, MIN(GlobalTermCode) AS TargetGlobalTermCode
			,MAX(B.A_UserGlobalTermId) AS SourceUserGlobalTermId, NULL AS SourceGlobalTermCode INTO #tmpNewlyAdGlobalTerm
		FROM [SLCProject].[dbo].[ProjectGlobalTerm] A WITH (NOLOCK)
		INNER JOIN #TmpNewlyUserGlobalTerm B ON A.CustomerId = B.CustomerId AND A.[Name] = B.[Name]
		GROUP BY A.CustomerId, A.[Name]

		UPDATE A
			SET A.SourceGlobalTermCode = B.GlobalTermCode
		FROM #tmpNewlyAdGlobalTerm A
		INNER JOIN [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] B WITH (NOLOCK) ON A.SourceCustomerId = B.CustomerId AND B.ProjectId = @SourceProjectID
			AND A.SourceUserGlobalTermId = B.UserGlobalTermId
		WHERE A.SourceCustomerId = @SourceCustomerID AND B.ProjectId = @SourceProjectID


		SELECT * INTO #tmpTargetGlobalTerm
		FROM #tmpAlExGlobalTerm A
		UNION
		SELECT * FROM #tmpNewlyAdGlobalTerm B

		DECLARE @MAXVALUE AS BIGINT
		SELECT @MAXVALUE = MAX(TargetGlobalTermCode) FROM #tmpTargetGlobalTerm

		SELECT *, @MAXVALUE + ROW_NUMBER() OVER(ORDER BY TargetGlobalTermCode) AS TempGlobalTermCode INTO #tmpGTReplacement FROM #tmpTargetGlobalTerm

		--Add new global term to existing projects
		INSERT INTO [ProjectGlobalTerm] (ProjectId, CustomerId, [Name], [Value], GlobalTermSource, CreatedDate, CreatedBy, UserGlobalTermId, GlobalTermCode)
		SELECT P.ProjectId, @TargetCustomerID AS CustomerId, A.[Name], A.[Name] AS [Value],'U' AS GlobalTermSource, GETUTCDATE() AS CreatedDate
			,@TargetUserID AS CreatedBy, A.TargetUserGlobalTermId AS UserGlobalTermId, A.TargetGlobalTermCode AS GlobalTermCode
		FROM Project P WITH(NOLOCK)
		CROSS JOIN #tmpNewlyAdGlobalTerm A
		WHERE P.CustomerId = @TargetCustomerID AND P.ProjectId NOT IN (@New_ProjectID) AND ISNULL(P.IsDeleted, 0) = 0;

		--INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		--([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
		--	,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
		--SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode
		--		,S.CreatedDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy, S.SLE_GlobalChoiceID, U1.UserGlobalTermId, S.IsDeleted
		--		,S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		--FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
		--INNER JOIN #AlreadyExUserGlobalTerm U1 ON U1.SourceCustomerId = S.CustomerId AND U1.A_UserGlobalTermId = S.UserGlobalTermId
		--WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		----New Added Global Term
		--INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
		--([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
		--	,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
		--SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode
		--		,S.CreatedDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy, S.SLE_GlobalChoiceID, U2.UserGlobalTermId, S.IsDeleted
		--		,S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
		--FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
		--INNER JOIN #TmpNewlyUserGlobalTerm U2 ON U2.SourceCustomerId = S.CustomerId AND U2.A_UserGlobalTermId = S.UserGlobalTermId
		--WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID
		

		SELECT P.GlobalTermId, P.CustomerId, P.ProjectId, P.UserGlobalTermId, P.GlobalTermCode, P.A_GlobalTermId INTO #tmpProjectGlobalTermSLC
		FROM [SLCProject].[dbo].[ProjectGlobalTerm] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @TargetCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectGlobalTerm created', 'ProjectGlobalTerm created', 1, 8, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 20, 0, '', ''

		CREATE TABLE #tmpImagesUsedInHeaderFooter (ImageId	INT)

		INSERT INTO #tmpImagesUsedInHeaderFooter (ImageId)
		SELECT DISTINCT ImageId FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentImage] WITH (NOLOCK) WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID

		INSERT INTO #tmpImagesUsedInHeaderFooter (ImageId)
		SELECT DISTINCT ImageId FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectNoteImage] WITH (NOLOCK) WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID

		--Insert #tmpProjectImage table
		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],@TargetCustomerID AS [CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.[ImageId] AS A_ImageId
		INTO #TGTProImgSLC
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectImage] SRC WITH (NOLOCK)
		WHERE SRC.ImageId IN (SELECT DISTINCT ImageId FROM #tmpImagesUsedInHeaderFooter)

		DROP TABLE IF EXISTS #tmpImagesUsedInHeaderFooter;

		--Update A_ImageId as NULL for TargetCustomerId as we dont want to use old Ids
		UPDATE TGT SET TGT.A_ImageId = NULL
		FROM [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK)
		WHERE TGT.CustomerId = @TargetCustomerID AND TGT.A_ImageId IS NOT NULL

		--Update ProjectImage table
		UPDATE TGT
			SET TGT.[A_ImageId] = SRC.A_ImageId
		FROM [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK)
		INNER JOIN #TGTProImgSLC SRC WITH (NOLOCK)
			ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND SRC.CustomerId = @TargetCustomerID
		WHERE TGT.CustomerId = @TargetCustomerID

		--Insert ProjectImage table
		INSERT INTO [SLCProject].[dbo].[ProjectImage]
		([ImagePath],[LuImageSourceTypeId],[CreateDate],[ModifiedDate],[CustomerId],[SLE_ProjectID],[SLE_DocID],[SLE_StatusID],[SLE_SegmentID]
			,[SLE_ImageNo],[SLE_ImageID],[A_ImageId])
		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.A_ImageId
		FROM #TGTProImgSLC SRC
		LEFT OUTER JOIN [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK) ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND TGT.CustomerId = @TargetCustomerID
		WHERE SRC.CustomerId = @TargetCustomerID AND TGT.ImagePath IS NULL

		SELECT I.ImageId, I.CustomerId, I.ImagePath, I.A_ImageId INTO #tmpProjectImageSLC
		FROM [SLCProject].[dbo].[ProjectImage] I WITH (NOLOCK) WHERE I.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #TGTProImgSLC;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectImage created', 'ProjectImage created', 1, 9, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 22, 0, '', ''


		--Move ProjectSegment_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentId) AS RowNumber, S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.SegmentDescription, S.SegmentSource
			,S.SegmentCode, @TargetUserID AS CreatedBy, S.CreateDate, @TargetUserID AS ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID
			,S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
		INTO #ProjectSegment_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SET @TableRows = @@ROWCOUNT

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegment Staging Loaded', 'ProjectSegment Staging Loaded', 1, 10, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 25, 0, '', ''

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
			SELECT NULL AS SegmentStatusId, S2.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
					,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
			FROM #ProjectSegment_Staging S
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
				AND S.SectionId = S2.A_SectionId
			WHERE S.RowNumber BETWEEN @Start AND @End AND S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

			SET @Records += @Segment_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @Segment_BatchSize - 1;
		END

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegment Records Added', 'ProjectSegment Records Added', 1, 10, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 25, 0, '', ''

		SELECT S.SegmentId, S.SegmentStatusId, S.SegmentSource, S.SegmentCode, S.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.A_SegmentId, BaseSegmentDescription
		INTO #tmpProjectSegmentSLC FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectSegment_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegment created', 'ProjectSegment created', 1, 10, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 25, 0, '', ''

		--Move ProjectSegmentStatus table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentStatusId) AS RowNumber, S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
			,S.SLE_ProjectSegID, S.SLE_StatusID, S.SegmentStatusId AS A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
		INTO #tmp_TgtSegmentStatusSLC
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SET @TableRows = @@ROWCOUNT

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentStatus Staging Loaded', 'ProjectSegmentStatus Staging Loaded', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		--Update SectionId in ProjectSegmentStatus table
		UPDATE S
			SET S.SectionId = S1.SectionId
		FROM #tmp_TgtSegmentStatusSLC S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'SectionId Updated in ProjectSegmentStatus Staging', 'SectionId Updated in ProjectSegmentStatus Staging', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		--Update SegmentId in ProjectSegmentStatus table
		UPDATE S
			SET S.SegmentId = S1.SegmentId
		FROM #tmp_TgtSegmentStatusSLC S
		--FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
			AND S.SectionId = S1.SectionId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'SegmentId Updated in ProjectSegmentStatus Staging', 'SegmentId Updated in ProjectSegmentStatus Staging', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @SegmentStatus_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectSegmentStatus table
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
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

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Records Inserted ProjectSegmentStatus', 'Records Inserted ProjectSegmentStatus', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		SELECT S.* INTO #tmpProjectSegmentStatusSLC FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		SELECT SegmentStatusId, A_SegmentStatusId INTO #NewOldSegmentStatusIdMappingSLC
		FROM #tmpProjectSegmentStatusSLC S

		DROP TABLE IF EXISTS #tmp_TgtSegmentStatusSLC;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Temp Table created for ProjectSegmentStatus', 'Temp Table created for ProjectSegmentStatus', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		--UPDATE ParentSegmentStatusId in temp table
		UPDATE CPSST
		SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId
		FROM #tmpProjectSegmentStatusSLC CPSST
		INNER JOIN #NewOldSegmentStatusIdMappingSLC PPSST
			ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId AND CPSST.ParentSegmentStatusId <> 0

		DROP TABLE IF EXISTS #NewOldSegmentStatusIdMappingSLC;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Temp Table - Updated ParentSegmentStatusId', 'Temp Table - Updated ParentSegmentStatusId', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		--UPDATE ParentSegmentStatusId in original table
		UPDATE PSS
		SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId
		FROM [SLCProject].[dbo].[ProjectSegmentStatus] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentStatusSLC PSS_TMP ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID
		AND PSS.CustomerId = @TargetCustomerID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ParentSegmentStatusId in Original Table', 'ParentSegmentStatusId in Original Table', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		--Update SegmentStatusId in #tmpProjectSegment
		UPDATE PS
			SET PS.SegmentStatusId = SS.SegmentStatusId
		FROM #tmpProjectSegmentSLC PS
		INNER JOIN #tmpProjectSegmentStatusSLC SS ON SS.ProjectId = PS.ProjectId AND SS.CustomerId = PS.CustomerId
			AND SS.SectionId = PS.SectionId AND SS.SegmentId = PS.SegmentId
		WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Temp Table - Updated SegmentStatusId', 'Temp Table - Updated SegmentStatusId', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 26, 0, '', ''

		--UPDATE SegmentStatusId in original table
		UPDATE PSS
		SET PSS.SegmentStatusId = PSS_TMP.SegmentStatusId
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		--Update SegmentDescription for ReferenceStandard Paragraph with new tag {RSTEMP#[RefStdCode]} for newly added User RefStdCode
		UPDATE P
		SET P.SegmentDescription = ([SLCProject].[dbo].[fn_ReplaceSLEPlaceHolder] (P.SegmentDescription, '{RSTEMP#', '{RSTEMP#'
				, [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
				, NEWRS.RefStdCode))
			,P.BaseSegmentDescription = ([SLCProject].[dbo].[fn_ReplaceSLEPlaceHolder] (P.BaseSegmentDescription, '{RSTEMP#', '{RSTEMP#'
				, [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.BaseSegmentDescription)
				, NEWRS.RefStdCode))
		FROM #tmpProjectSegmentSLC P 
		INNER JOIN #tmpProjectSegmentStatusSLC PS WITH (NOLOCK) ON PS.CustomerId = P.CustomerId AND PS.ProjectId = P.ProjectId AND PS.SectionId = P.SectionId
			AND PS.SegmentId = P.SegmentId
		INNER JOIN #TmpNewlyAddedRefStds NEWRS WITH (NOLOCK) ON NEWRS.CustomerId = P.CustomerId AND NEWRS.SourceRefStdCode = [SLCProject].[dbo].[fn_GetRESTempPlaceholder_UserAddedRS](P.SegmentDescription)
		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @TargetCustomerID AND PS.IsRefStdParagraph = 1
			AND [SLCProject].[dbo].[fn_GetRESTempPlaceholder_UserAddedRS](P.SegmentDescription) > @CONST_START_CODE

		--Update SegmentDescription for ReferenceStandard Paragraph with new tag {RSTEMP#[RefStdCode]} for already exist User RefStdCode
		UPDATE P
		SET P.SegmentDescription = ([SLCProject].[dbo].[fn_ReplaceSLEPlaceHolder] (P.SegmentDescription, '{RSTEMP#', '{RSTEMP#'
				, [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
				, NEWRS.RefStdCode))
			,P.BaseSegmentDescription = ([SLCProject].[dbo].[fn_ReplaceSLEPlaceHolder] (P.BaseSegmentDescription, '{RSTEMP#', '{RSTEMP#'
				, [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.BaseSegmentDescription)
				, NEWRS.RefStdCode))
		FROM #tmpProjectSegmentSLC P 
		INNER JOIN #tmpProjectSegmentStatusSLC PS WITH (NOLOCK) ON PS.CustomerId = P.CustomerId AND PS.ProjectId = P.ProjectId AND PS.SectionId = P.SectionId
			AND PS.SegmentId = P.SegmentId
		INNER JOIN #AlreadyExReferenceStandard NEWRS WITH (NOLOCK) ON NEWRS.CustomerId = P.CustomerId AND NEWRS.SourceRefStdCode = [SLCProject].[dbo].[fn_GetRESTempPlaceholder_UserAddedRS](P.SegmentDescription)
		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @TargetCustomerID AND PS.IsRefStdParagraph = 1
			AND [SLCProject].[dbo].[fn_GetRESTempPlaceholder_UserAddedRS](P.SegmentDescription) > @CONST_START_CODE

		
		--Get all ProjectSegment records in temp table where {GT# is used in SegmentDescription with more than 1 million GlobalTermCode
		SELECT ROW_NUMBER() OVER(ORDER BY SegmentId) AS RowId, ProjectId, SegmentId, SegmentDescription INTO #tmpGTUsedInSegmentDescription
		FROM #tmpProjectSegmentSLC A WITH (NOLOCK)
		WHERE A.ProjectId = @New_ProjectID AND PATINDEX('%{GT#%',A.SegmentDescription) > 0

		SELECT @NumberRecords = COUNT(*) FROM #tmpGTUsedInSegmentDescription
		SET @RowCount = 1

		WHILE @RowCount <= @NumberRecords
		BEGIN
			DECLARE @SID AS INT, @SDESC AS NVARCHAR(MAX), @GTTotalCount AS INT = 0, @GTStart AS INT = 1, @GTID AS INT, @TEMPGTCODE AS INT = 0, @TARGETGTCODE AS INT = 0

			SELECT @SID = SegmentId, @SDESC = SegmentDescription FROM #tmpGTUsedInSegmentDescription WHERE RowId = @RowCount
			DROP TABLE IF EXISTS #tmpGTs;
			SELECT Ids, 0 AS IsProcessed INTO #tmpGTs FROM [dbo].[fn_GetIdSegmentDescription] (@SDESC, '{GT#') WHERE Ids > @CONST_START_CODE

			SELECT @GTTotalCount = COUNT(Ids) FROM #tmpGTs
			--First get SourceGTCodes updated to TempGTCodes to avoid overlapping GT Codes
			WHILE @GTStart <= @GTTotalCount
			BEGIN
				SELECT TOP 1 @GTID = Ids FROM #tmpGTs WHERE IsProcessed = 0
				IF ISNULL(@GTID, 0) > 0
				BEGIN
					SELECT @TEMPGTCODE = TempGlobalTermCode FROM #tmpGTReplacement WHERE SourceGlobalTermCode = @GTID
					UPDATE A
						SET SegmentDescription = REPLACE(SegmentDescription, '{GT#'+CAST(@GTID AS VARCHAR(32))+'}', '{GT#'+CAST(@TEMPGTCODE AS VARCHAR(32))+'}')
						, BaseSegmentDescription = REPLACE(BaseSegmentDescription, '{GT#'+CAST(@GTID AS VARCHAR(32))+'}', '{GT#'+CAST(@TEMPGTCODE AS VARCHAR(32))+'}')
					FROM #tmpProjectSegmentSLC A WHERE SegmentId = @SID AND ProjectId = @New_ProjectID
				END
				UPDATE #tmpGTs SET IsProcessed = 1 WHERE Ids = @GTID

				SET @GTStart = @GTStart + 1
			END

			--Now update TargetGTCode where TempGTCodes so real project global term codes from target project will be displayed
			SET @GTStart = 1
			SELECT @GTTotalCount = COUNT(Ids) FROM #tmpGTs
			UPDATE #tmpGTs SET IsProcessed = 0

			WHILE @GTStart <= @GTTotalCount
			BEGIN
				SELECT TOP 1 @GTID = Ids FROM #tmpGTs WHERE IsProcessed = 0
				IF ISNULL(@GTID, 0) > 0
				BEGIN
					SELECT @TARGETGTCODE = TargetGlobalTermCode, @TEMPGTCODE = TempGlobalTermCode FROM #tmpGTReplacement WHERE SourceGlobalTermCode = @GTID
					UPDATE A
						SET SegmentDescription = REPLACE(SegmentDescription, '{GT#'+CAST(@TEMPGTCODE AS VARCHAR(32))+'}', '{GT#'+CAST(@TARGETGTCODE AS VARCHAR(32))+'}')
						, BaseSegmentDescription = REPLACE(BaseSegmentDescription, '{GT#'+CAST(@TEMPGTCODE AS VARCHAR(32))+'}', '{GT#'+CAST(@TARGETGTCODE AS VARCHAR(32))+'}')
					FROM #tmpProjectSegmentSLC A WHERE SegmentId = @SID AND ProjectId = @New_ProjectID
				END
				UPDATE #tmpGTs SET IsProcessed = 1 WHERE Ids = @GTID

				SET @GTStart = @GTStart + 1
			END

			--#tmpGTReplacement
			SET @RowCount = @RowCount + 1
		END
		
		----Update GlobalTerm placeholders with new GlobalTermCode in ProjectSegment table
		--UPDATE A
		--	SET A.SegmentDescription = B.NewSegmentDescription
		--FROM #tmpProjectSegmentSLC A
		--INNER JOIN (
		--			SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentId
		--				,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS NewSegmentDescription
		--			FROM #tmpProjectSegmentSLC PS
		--			INNER JOIN #tmpTargetGlobalTerm GTNEW ON PS.CustomerId = GTNEW.TargetCustomerId
		--			WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID AND PS.SegmentDescription LIKE '%{GT#%'
		--			GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentId
		--) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		--WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID


		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentStatus created', 'ProjectSegmentStatus created', 1, 11, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 27, 0, '', ''

		----RefStdCode need NOT be updated because there is no difference between RefStdCode on any of the SLC Servers

		------Update SegmentDescription for ReferenceStandard Paragraph with new tag {RSTEMP#[RefStdCode]} when it is Master RefStdCode
		----UPDATE P
		----SET P.SegmentDescription = ([SLCProject].[dbo].[fn_ReplaceSLEPlaceHolder] (P.SegmentDescription, '{RSTEMP#', '{RSTEMP#'
		----		, [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
		----		, NEWRS.RefStdCode))
		----FROM [SLCProject].[dbo].[ProjectSegment] P 
		----INNER JOIN [SLCProject].[dbo].[ProjectSegmentStatus] PS WITH (NOLOCK) ON PS.CustomerId = P.CustomerId AND PS.ProjectId = P.ProjectId AND PS.SectionId = P.SectionId
		----	AND PS.SegmentId = P.SegmentId
		----INNER JOIN [SLCSERVER03].[SLCMaster].[dbo].[ReferenceStandard] OLDRS WITH (NOLOCK) ON OLDRS.MasterDataTypeId = 1 AND OLDRS.IsObsolete = 0
		----	AND OLDRS.RefStdCode = [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
		----INNER JOIN [SLCMaster].[dbo].[ReferenceStandard] NEWRS WITH (NOLOCK) ON NEWRS.RefStdName = OLDRS.RefStdName AND NEWRS.MasterDataTypeId = 1 AND NEWRS.IsObsolete = 0
		----WHERE PS.CustomerId = @SourceCustomerID AND PS.ProjectId = @New_ProjectID AND PS.IsRefStdParagraph = 1
		----	AND [SLCProject].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription) < @CONST_START_CODE0


		--SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentGlobalTerm'
		--EXECUTE [SLCProject].[dbo].[spb_UnArchiveLog] @SourceCustomerID, @SourceProjectID, @LogMessage

		--SELECT @OldCount = COUNT(9) FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] WITH (NOLOCK) WHERE CustomerID = @SourceCustomerID AND ProjectId = @SourceProjectID
		--IF @Row_Count > 0
		--BEGIN
		--	SET @LogMessage = CAST(@Row_Count AS VARCHAR) + ' OLD ProjectSegmentGlobalTerm records'
		--	EXECUTE [SLCProject].[dbo].[spb_UnArchiveLog] @SourceCustomerID, @SourceProjectID, @LogMessage
		--END

		--Insert ProjectSegmentGlobalTerm_Staging table
		SELECT S.SegmentGlobalTermId, @TargetCustomerID AS CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentId, S.mSegmentId, G1.TargetUserGlobalTermId AS UserGlobalTermId
			,G1.TargetGlobalTermCode AS GlobalTermCode, S.IsLocked, S.LockedByFullName, S.UserLockedId, S.CreatedDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentGlobalTerm_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
		LEFT JOIN #tmpTargetGlobalTerm G1 ON S.CustomerId = G1.SourceCustomerId AND S.UserGlobalTermId = G1.SourceUserGlobalTermId
		--LEFT JOIN [SLCSERVER03].[SLCProject].[dbo].[ProjectGlobalTerm] G WITH (NOLOCK) ON S.CustomerId = G.CustomerId AND G.UserGlobalTermId = S.UserGlobalTermId
		--LEFT JOIN #tmpProjectGlobalTermSLC G1 ON G1.CustomerId = @TargetCustomerID AND G1.A_GlobalTermId = G.GlobalTermId
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		
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
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #tmpProjectGlobalTermSLC;
		DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentGlobalTerm created', 'ProjectSegmentGlobalTerm created', 1, 12, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 30, 0, '', ''

		
		--Move Header table
		INSERT INTO [SLCProject].[dbo].[Header]
		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
			,ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_HeaderId
			,HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader
			,IsShowLineBelowHeader)
		SELECT @New_ProjectID AS ProjectId, S2.SectionId, @TargetCustomerID AS CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
			,@TargetUserID AS CreatedBy, S.CreatedDate, @TargetUserID AS ModifiedBy, S.ModifiedDate, S.TypeId, S.AltHeader, S.FPHeader, S.UseSeparateFPHeader, S.HeaderFooterCategoryId
			,S.[DateFormat], S.TimeFormat, S.HeaderId AS A_HeaderId, S.HeaderFooterDisplayTypeId, S.DefaultHeader, S.FirstPageHeader, S.OddPageHeader, S.EvenPageHeader
			,S.DocumentTypeId, S.IsShowLineAboveHeader, S.IsShowLineBelowHeader
		FROM [SLCSERVER03].[SLCProject].[dbo].[Header] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSectionSLC S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @TargetCustomerID AND S2.A_SectionId = S.SectionId
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Update Image placeholders with new ImageId in Header table
		UPDATE A
			SET A.DefaultHeader = B.DefaultHeader, A.FirstPageHeader = B.FirstPageHeader, A.OddPageHeader = B.OddPageHeader, A.EvenPageHeader = B.EvenPageHeader
		FROM [SLCProject].[dbo].[Header] A WITH (NOLOCK)
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.HeaderId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.DefaultHeader, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS DefaultHeader
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.FirstPageHeader, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS FirstPageHeader
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.OddPageHeader, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS OddPageHeader
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.EvenPageHeader, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS EvenPageHeader
					FROM [SLCProject].[dbo].[Header] PS WITH (NOLOCK)
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID
					GROUP BY PS.CustomerId, PS.ProjectId, PS.HeaderId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID


		--Update GlobalTerm placeholders with new GlobalTermCode in Header table
		UPDATE A
			SET A.DefaultHeader = B.DefaultHeader, A.FirstPageHeader = B.FirstPageHeader, A.OddPageHeader = B.OddPageHeader, A.EvenPageHeader = B.EvenPageHeader
		FROM [SLCProject].[dbo].[Header] A WITH (NOLOCK)
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.HeaderId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.DefaultHeader, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS DefaultHeader
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.FirstPageHeader, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS FirstPageHeader
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.OddPageHeader, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS OddPageHeader
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.EvenPageHeader, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS EvenPageHeader
					FROM [SLCProject].[dbo].[Header] PS WITH (NOLOCK)
					INNER JOIN #tmpTargetGlobalTerm GTNEW ON PS.CustomerId = GTNEW.TargetCustomerId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID
					GROUP BY PS.CustomerId, PS.ProjectId, PS.HeaderId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Header created', 'Header created', 1, 13, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 32, 0, '', ''

		
		--Move Footer table
		INSERT INTO [SLCProject].[dbo].[Footer]
		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
			,ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_FooterId
			,HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId, IsShowLineAboveFooter
			,IsShowLineBelowFooter)
		SELECT @New_ProjectID AS ProjectId, S2.SectionId, @TargetCustomerID AS CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
			,@TargetUserID AS CreatedBy, S.CreatedDate, @TargetUserID AS ModifiedBy, S.ModifiedDate, S.TypeId, S.AltFooter, S.FPFooter, S.UseSeparateFPFooter, S.HeaderFooterCategoryId
			,S.[DateFormat], S.TimeFormat, S.FooterId AS A_FooterId, S.HeaderFooterDisplayTypeId, S.DefaultFooter, S.FirstPageFooter, S.OddPageFooter, S.EvenPageFooter
			,S.DocumentTypeId, S.IsShowLineAboveFooter, IsShowLineBelowFooter
		FROM [SLCSERVER03].[SLCProject].[dbo].[Footer] S WITH (NOLOCK)
		LEFT JOIN #tmpProjectSectionSLC S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @TargetCustomerID AND S.SectionId = S2.A_SectionId
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID


		--Update Image placeholders with new ImageId in Footer table
		UPDATE A
			SET A.DefaultFooter = B.DefaultFooter, A.FirstPageFooter = B.FirstPageFooter, A.OddPageFooter = B.OddPageFooter, A.EvenPageFooter = B.EvenPageFooter
		FROM [SLCProject].[dbo].[Footer] A WITH (NOLOCK)
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.FooterId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.DefaultFooter, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS DefaultFooter
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.FirstPageFooter, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS FirstPageFooter
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.OddPageFooter, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS OddPageFooter
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.EvenPageFooter, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS EvenPageFooter
					FROM [SLCProject].[dbo].[Footer] PS WITH (NOLOCK)
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID
					GROUP BY PS.CustomerId, PS.ProjectId, PS.FooterId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID


		--Update GlobalTerm placeholders with new GlobalTermCode in Footer table
		UPDATE A
			SET A.DefaultFooter = B.DefaultFooter, A.FirstPageFooter = B.FirstPageFooter, A.OddPageFooter = B.OddPageFooter, A.EvenPageFooter = B.EvenPageFooter
		FROM [SLCProject].[dbo].[Footer] A WITH (NOLOCK)
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.FooterId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.DefaultFooter, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS DefaultFooter
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.FirstPageFooter, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS FirstPageFooter
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.OddPageFooter, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS OddPageFooter
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.EvenPageFooter, '{GT#'+CAST(GTNEW.SourceGlobalTermCode AS VARCHAR(32))+'}', '{GT#'+CAST(GTNEW.TargetGlobalTermCode AS VARCHAR(32))+'}') AS EvenPageFooter
					FROM [SLCProject].[dbo].[Footer] PS WITH (NOLOCK)
					INNER JOIN #tmpTargetGlobalTerm GTNEW ON PS.CustomerId = GTNEW.TargetCustomerId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID
					GROUP BY PS.CustomerId, PS.ProjectId, PS.FooterId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID


		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Footer created', 'Footer created', 1, 14, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 35, 0, '', ''


		--Move HeaderFooterGlobalTermUsage_Staging table
		SELECT S.HeaderFooterGTId, S.HeaderId, S.FooterId
			,CASE WHEN U1.UserGlobalTermId IS NULL THEN U2.UserGlobalTermId ELSE U1.UserGlobalTermId END AS UserGlobalTermId
			,@TargetCustomerID AS CustomerId, @New_ProjectID AS ProjectId
			,S.HeaderFooterCategoryId, S.CreatedDate, @TargetUserID AS CreatedById
		INTO #HeaderFooterGlobalTermUsage_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
		--LEFT JOIN [SLCProject].[dbo].[UserGlobalTerm] G1 WITH (NOLOCK) ON G1.CustomerId = @TargetCustomerID AND G1.A_UserGlobalTermId = S.UserGlobalTermId
		LEFT JOIN #AlreadyExUserGlobalTerm U1 ON U1.SourceCustomerId = S.CustomerId AND U1.A_UserGlobalTermId = S.UserGlobalTermId
		LEFT JOIN #TmpNewlyUserGlobalTerm U2 ON U2.SourceCustomerId = S.CustomerId AND U2.A_UserGlobalTermId = S.UserGlobalTermId
		
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move HeaderFooterGlobalTermUsage table
		INSERT INTO [SLCProject].[dbo].[HeaderFooterGlobalTermUsage]
		(HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
		SELECT S2.HeaderId, S3.FooterId, S.UserGlobalTermId, S.CustomerId, S.ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
		FROM #HeaderFooterGlobalTermUsage_Staging S
		LEFT JOIN [SLCProject].[dbo].[Header] S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.HeaderId = S2.A_HeaderId
		LEFT JOIN [SLCProject].[dbo].[Footer] S3 WITH (NOLOCK) ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S.FooterId = S3.A_FooterId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'HeaderFooterGlobalTermUsage created', 'HeaderFooterGlobalTermUsage created', 1, 15, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 37, 0, '', ''


		--Insert ProjectReferenceStandard_Staging table
		SELECT @New_ProjectID AS ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
			,S.SectionId, @TargetCustomerID AS CustomerId, S.ProjRefStdId, S.IsDeleted
		INTO #ProjectReferenceStandard_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID AND ISNULL(S.IsDeleted,0)=0

		--Move ProjectReferenceStandard table
		INSERT INTO [SLCProject].[dbo].[ProjectReferenceStandard]
		(ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)
		SELECT S.ProjectId
			--,CASE WHEN S.RefStdSource = 'M' THEN S.RefStandardId ELSE S3.RefStdId END AS RefStandardId
			,CASE WHEN S.RefStdSource = 'M' THEN S.RefStandardId ELSE IIF(S3A.RefStdId IS NULL, S3B.RefStdId, S3A.RefStdId) END AS RefStandardId
			,S.RefStdSource, S.mReplaceRefStdId
			--,CASE WHEN S.RefStdSource = 'M' THEN S.RefStdEditionId ELSE S4.RefStdEditionId END AS RefStdEditionId, S.IsObsolete
			,CASE WHEN S.RefStdSource = 'M' THEN S.RefStdEditionId ELSE IIF(S4A.RefStdEditionId IS NULL, S4B.NewRefEditionId, S4A.RefStdEditionId) END AS RefStdEditionId, S.IsObsolete
			--,CASE WHEN S.RefStdSource = 'M' THEN S.RefStdCode ELSE S3.RefStdCode END AS RefStdCode
			,CASE WHEN S.RefStdSource = 'M' THEN S.RefStdCode ELSE IIF(S3A.RefStdId IS NULL, S3B.RefStdCode, S3A.RefStdCode) END AS RefStdCode
			,S.PublicationDate, S2.SectionId, S.CustomerId, S.IsDeleted
		FROM #ProjectReferenceStandard_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		--LEFT JOIN [SLCProject].[dbo].[ReferenceStandard] S3 WITH (NOLOCK) ON S.CustomerId = S3.CustomerId AND S.RefStandardId = S3.A_RefStdId
		LEFT JOIN #AlreadyExReferenceStandard S3A ON S.CustomerId = S3A.CustomerId AND S.RefStandardId = S3A.A_RefStdId
		LEFT JOIN #TmpNewlyAddedRefStds S3B ON S.CustomerId = S3B.CustomerId AND S.RefStandardId = S3B.A_RefStdId
		--LEFT JOIN [SLCProject].[dbo].[ReferenceStandardEdition] S4 WITH (NOLOCK) ON S.CustomerId = S4.CustomerId AND S.RefStdEditionId = S4.A_RefStdEditionId
		LEFT JOIN #TmpNewlyAddedRefEditions S4A ON S.CustomerId = S4A.CustomerId AND S.RefStdEditionId = S4A.A_RefStdEditionId
		LEFT JOIN #TmpRefEditSource S4B ON S.CustomerId = S4B.CustomerId AND S.RefStdEditionId = S4B.RefStdEditionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID
		
		DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectReferenceStandard created', 'ProjectReferenceStandard created', 1, 16, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 40, 0, '', ''

		--Insert ProjectSegmentChoice_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.SegmentChoiceId, S.SectionId, S.SegmentStatusId, S.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId
			,S.SegmentChoiceSource, S.SegmentChoiceCode, @TargetUserID AS CreatedBy, S.CreateDate, @TargetUserID AS ModifiedBy, S.ModifiedDate, S.SLE_DocID
			,S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID, S.SegmentChoiceId AS A_SegmentChoiceId, S.IsDeleted
		INTO #ProjectSegmentChoice_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentChoice] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SET @TableRows = @@ROWCOUNT

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentChoice created', 'ProjectSegmentChoice created', 1, 17, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 42, 0, '', ''
		
		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectSegmentChoice table
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
			(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
				,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
			SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, S.ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
					,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
					,S.A_SegmentChoiceId, S.IsDeleted
			FROM #ProjectSegmentChoice_Staging S
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			INNER JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
				AND S.SegmentId = S4.A_SegmentId
			WHERE S.RowNumber BETWEEN @Start AND @End AND S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

			SET @Records += @ProjectSegmentChoice_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1;
		END

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentChoice Records Inserted', 'ProjectSegmentChoice Records Inserted', 1, 17, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 42, 0, '', ''

		SELECT C.SegmentChoiceId, C.ProjectId, C.SectionId, C.CustomerId, C.A_SegmentChoiceId INTO #tmpProjectSegmentChoiceSLC
		FROM [SLCProject].[dbo].[ProjectSegmentChoice] C WITH (NOLOCK)
		WHERE C.ProjectId = @New_ProjectID AND C.CustomerId = @TargetCustomerID
		
		DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentChoice created', 'ProjectSegmentChoice created', 1, 17, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 42, 0, '', ''

		
		--Insert ProjectChoiceOption_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.ChoiceOptionId, S.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, @New_ProjectID AS ProjectId, S.SectionId
			,@TargetCustomerID AS CustomerId, S.ChoiceOptionCode, @TargetUserID AS CreatedBy, S.CreateDate, @TargetUserID AS ModifiedBy, S.ModifiedDate
			,S.ChoiceOptionId AS A_ChoiceOptionId, S.IsDeleted
		INTO #ProjectChoiceOption_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID
		
		SET @TableRows = @@ROWCOUNT

		--Replace new GlobalTermCode from OptionJson
		UPDATE t SET t.OptionJson = JSON_MODIFY(t.OptionJson,'$['+q.[key]+'].Id',A.TargetGlobalTermCode)
		FROM #tmpTargetGlobalTerm A WITH (NOLOCK)
		INNER JOIN #ProjectChoiceOption_Staging t
		CROSS APPLY OPENJSON(t.OptionJson) q ON JSON_VALUE(q.value,'$.Id')= A.SourceGlobalTermCode
		WHERE t.ProjectId = @New_ProjectID AND t.CustomerId = @TargetCustomerID AND t.OptionJson LIKE '%GlobalTerm%'

		SELECT A.CustomerId, A.SourceCustomerId, A.RefStdCode, A.SourceRefStdCode INTO #tmpRefStdCodes
		FROM #TmpNewlyAddedRefStds A
		UNION
		SELECT B.CustomerId, B.SourceCustomerId, B.RefStdCode, B.SourceRefStdCode FROM #AlreadyExReferenceStandard B

		--Replace new RefStdCode from OptionJson
		UPDATE t SET t.OptionJson = JSON_MODIFY(t.OptionJson,'$['+q.[key]+'].Id',A.RefStdCode)
		FROM #tmpRefStdCodes A WITH (NOLOCK)
		INNER JOIN #ProjectChoiceOption_Staging t
		CROSS APPLY OPENJSON(t.OptionJson) q ON JSON_VALUE(q.value,'$.Id')= A.SourceRefStdCode
		WHERE t.ProjectId = @New_ProjectID AND t.CustomerId = @TargetCustomerID AND t.OptionJson LIKE '%ReferenceStandard%'

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectChoiceOption Staging Loaded', 'ProjectChoiceOption Staging Loaded', 1, 18, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 45, 0, '', ''

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
			WHERE S.RowNumber BETWEEN @Start AND @End AND S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID
		
			SET @Records += @ProjectChoiceOption_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectChoiceOption_BatchSize - 1;
		END
		
		DROP TABLE IF EXISTS #tmpProjectSegmentChoiceSLC;
		DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectChoiceOption created', 'ProjectChoiceOption created', 1, 18, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 45, 0, '', ''


		--Insert SelectedChoiceOption_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SelectedChoiceOptionId) AS RowNumber, S.SelectedChoiceOptionId, S.SegmentChoiceCode, S.ChoiceOptionCode
				,S.ChoiceOptionSource, S.IsSelected, S.SectionId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.OptionJson, S.IsDeleted
		INTO #SelectedChoiceOption_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[SelectedChoiceOption] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID
		
		SET @TableRows = @@ROWCOUNT
		
		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'SelectedChoiceOption Staging Loaded', 'SelectedChoiceOption Staging Loaded', 1, 19, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 47, 0, '', ''

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
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID AND S.RowNumber BETWEEN @Start AND @End
		
			SET @Records += @SelectedChoiceOption_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @SelectedChoiceOption_BatchSize - 1;
		END
		
		DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'SelectedChoiceOption created', 'SelectedChoiceOption created', 1, 19, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 47, 0, '', ''


		--Move ProjectHyperLink table
		SELECT ROW_NUMBER() OVER(ORDER BY S.HyperLinkId) AS RowNumber, S.HyperLinkId, S.SectionId, S.SegmentId, S.SegmentStatusId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.LinkTarget, S.LinkText
			,S.LuHyperLinkSourceTypeId, S.CreateDate, @TargetUserID AS CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID
			,SLE_StatusID, S.SLE_LinkNo, S.HyperLinkId AS A_HyperLinkId
		INTO #ProjectHyperLink_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectHyperLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID
		
		SET @TableRows = @@ROWCOUNT

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectHyperLink Staging Loaded', 'ProjectHyperLink Staging Loaded', 1, 20, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 50, 0, '', ''

		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectHyperLink_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			--Move ProjectHyperLink table
			INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
			(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
				,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
			SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId
				,S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId, S.CreateDate, @TargetUserID AS CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID
				,S.SLE_StatusID, S.SLE_LinkNo, S.HyperLinkId AS A_HyperLinkId
			FROM #ProjectHyperLink_Staging S
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			LEFT JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
				AND S.SegmentId = S4.A_SegmentId
			WHERE S.RowNumber BETWEEN @Start AND @End AND S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

			SET @Records += @ProjectHyperLink_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectHyperLink_BatchSize - 1;
		END
		
		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectHyperLink Records Added', 'ProjectHyperLink Records Added', 1, 20, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 50, 0, '', ''

		SELECT H.HyperLinkId, H.A_HyperLinkId, H.CustomerId, H.ProjectId, H.SectionId, H.SegmentStatusId, H.SegmentId
		INTO #tmpProjectHyperLinkSLC FROM [SLCProject].[dbo].[ProjectHyperLink] H WITH (NOLOCK) WHERE H.ProjectId = @New_ProjectID AND H.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectHyperLink_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Temp Table Created from ProjectHyperLink', 'Temp Table Created from ProjectHyperLink', 1, 20, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 50, 0, '', ''


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
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID AND PS.SegmentDescription LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'HyperLink PlaceHolder Updated', 'HyperLink PlaceHolder Updated', 1, 20, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 50, 0, '', ''


		--Insert ProjectNote_Staging table
		SELECT ROW_NUMBER() OVER(ORDER BY S.NoteId) AS RowNumber, S.NoteId, S.SectionId, S.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.Title
			,@TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.NoteId AS A_NoteId
		INTO #ProjectNote_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectNote] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SET @TableRows = @@ROWCOUNT

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectNote Staging Loaded', 'ProjectNote Staging Loaded', 1, 21, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 52, 0, '', ''

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
					,@TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
			FROM #ProjectNote_Staging S
			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
				AND S.SegmentStatusId = S3.A_SegmentStatusId
			WHERE S.RowNumber BETWEEN @Start AND @End AND S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID
			
			SET @Records += @ProjectNote_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectNote_BatchSize - 1;
		END

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectNote Records Inserted', 'ProjectNote Records Inserted', 1, 21, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 52, 0, '', ''

		SELECT P.NoteId, P.SectionId, P.SegmentStatusId, P.NoteText, P.ProjectId, P.CustomerId, P.A_NoteId INTO #tmpProjectNoteSLC
		FROM [SLCProject].[dbo].[ProjectNote] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectNote_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Temp Table created for ProjectNote', 'Temp Table created for ProjectNote', 1, 21, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 52, 0, '', ''


		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table
		UPDATE A
			SET A.NoteText = B.NoteText
		FROM #tmpProjectNoteSLC A WITH (NOLOCK)
		INNER JOIN (
					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentStatusId) AS SegmentStatusId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
					FROM #tmpProjectNoteSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID AND PS.NoteText LIKE '%{HL#%'
					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID AND A.NoteText LIKE '%{HL#%'

		DROP TABLE IF EXISTS #tmpProjectHyperLinkSLC;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'HyperLinkId updated in Temp ProjectNote', 'HyperLinkId updated in Temp ProjectNote', 1, 21, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 52, 0, '', ''

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNoteSLC PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectNote created', 'ProjectNote created', 1, 21, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 52, 0, '', ''


		--Insert ProjectSegmentReferenceStandard_Staging table
		SELECT S.SegmentRefStandardId, S.SectionId, S.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, @TargetUserID AS CreatedBy
			,S.ModifiedDate, @TargetUserID AS ModifiedBy, S.mSegmentId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.RefStdCode, S.IsDeleted
		INTO #ProjectSegmentReferenceStandard_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move ProjectSegmentReferenceStandard table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentReferenceStandard]
		(SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, mSegmentId, ProjectId, CustomerId
			,RefStdCode, IsDeleted)
		SELECT S2.SectionId, S3.SegmentId
			--,CASE WHEN S.RefStandardSource = 'M' THEN S.RefStandardId ELSE S4.RefStdId END AS RefStandardId
			,CASE WHEN S.RefStandardSource = 'M' THEN S.RefStandardId ELSE IIF(S4A.RefStdId IS NULL, S4B.RefStdId, S4A.RefStdId) END AS RefStandardId
			,S.RefStandardSource
			,S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
			,S.ProjectId, S.CustomerId
			--,CASE WHEN S.RefStandardSource = 'M' THEN S.RefStdCode ELSE S4.RefStdCode END AS RefStdCode
			,CASE WHEN S.RefStandardSource = 'M' THEN S.RefStdCode ELSE IIF(S4A.RefStdId IS NULL, S4B.RefStdCode, S4A.RefStdCode) END AS RefStdCode
			,S.IsDeleted
		FROM #ProjectSegmentReferenceStandard_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		--LEFT JOIN [SLCProject].[dbo].[ReferenceStandard] S4 WITH (NOLOCK) ON S.CustomerId = S4.CustomerId AND S.RefStandardId = S4.A_RefStdId
		LEFT JOIN #AlreadyExReferenceStandard S4A ON S.CustomerId = S4A.CustomerId AND S.RefStandardId = S4A.A_RefStdId
		LEFT JOIN #TmpNewlyAddedRefStds S4B ON S.CustomerId = S4B.CustomerId AND S.RefStandardId = S4B.A_RefStdId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		--Load #tmpProjectSegmentReferenceStandardSLC
		SELECT S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.RefStandardId, S.RefStandardSource, S.RefStdCode
			,CASE WHEN S1.RefStdCode IS NULL THEN S2.SourceRefStdCode ELSE S1.SourceRefStdCode END AS SourceRefStdCode
		INTO #tmpProjectSegmentReferenceStandardSLC
		FROM [SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
		LEFT JOIN #AlreadyExReferenceStandard S1 ON S.CustomerId = S1.CustomerId AND S.RefStdCode = S1.RefStdCode
		LEFT JOIN #TmpNewlyAddedRefStds S2 ON S.CustomerId = S2.CustomerId AND S.RefStdCode = S2.RefStdCode
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID AND RefStandardSource = 'U'

		--Update RS placeholders with new RefStdCode in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT S3.CustomerId, S3.ProjectId, MAX(S3.SectionId) AS SectionId, MAX(S3.SegmentId) AS SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{RS#'+CAST(S3.SourceRefStdCode AS VARCHAR(32))+'}', '{RS#'+CAST(S3.RefStdCode AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentReferenceStandardSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
						AND PS.SegmentId = S3.SegmentId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID AND S3.RefStandardSource = 'U'
					GROUP BY S3.CustomerId, S3.ProjectId, S3.SectionId, S3.SegmentId
		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentReferenceStandard created', 'ProjectSegmentReferenceStandard created', 1, 22, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 55, 0, '', ''


		--Insert ProjectSegmentTab_Staging table
		SELECT S.SegmentTabId, @TargetCustomerID AS CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.TabTypeId, S.TabPosition
			,S.CreateDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy
		INTO #ProjectSegmentTab_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentTab] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move ProjectSegmentTab table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTab]
		(CustomerId, ProjectId, SectionId, SegmentStatusId, TabTypeId, TabPosition, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy
		FROM #ProjectSegmentTab_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentTab created', 'ProjectSegmentTab created', 1, 23, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 57, 0, '', ''


		--Move ProjectSegmentRequirementTag_Staging table
		SELECT S.SegmentRequirementTagId, S.SectionId, S.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId
			,@TargetCustomerID AS CustomerId, @TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
		INTO #ProjectSegmentRequirementTag_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentRequirementTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

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
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentRequirementTag created', 'ProjectSegmentRequirementTag created', 1, 24, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 60, 0, '', ''


		--Insert ProjectSegmentUserTag_Staging table
		SELECT S.SegmentUserTagId, @TargetCustomerID AS CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.UserTagId
			,S.CreateDate, @TargetUserID AS CreatedBy, S.ModifiedDate, @TargetUserID AS ModifiedBy, S.IsDeleted
		INTO #ProjectSegmentUserTag_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentUserTag] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move ProjectSegmentUserTag table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentUserTag]
		(CustomerId, ProjectId, SectionId, SegmentStatusId, UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted)
		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, CASE WHEN S4A.UserTagId IS NULL THEN S4B.UserTagId ELSE S4A.UserTagId END AS UserTagId
			,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
		FROM #ProjectSegmentUserTag_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentStatusId = S3.A_SegmentStatusId
		--LEFT JOIN [SLCProject].[dbo].[ProjectUserTag] S4 WITH (NOLOCK) ON S.CustomerId = S4.CustomerId AND S.UserTagId = S4.A_UserTagId
		LEFT JOIN #TmpNewlyProjectUserTag S4A ON S.CustomerId = S4A.CustomerId AND S.UserTagId = S4A.A_UserTagId
		LEFT JOIN #AlreadyExProjectUserTag S4B ON S.CustomerId = S4B.CustomerId AND S.UserTagId = S4B.A_UserTagId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentUserTag created', 'ProjectSegmentUserTag created', 1, 25, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 62, 0, '', ''


		--Insert ProjectSegmentImage_Staging table
		SELECT S.SegmentImageId, S.SegmentId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.ImageStyle
		INTO #ProjectSegmentImage_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move ProjectSegmentImage table
		INSERT INTO [SLCProject].[dbo].[ProjectSegmentImage]
		(SegmentId, SectionId, ImageId, ProjectId, CustomerId, ImageStyle)
		SELECT CASE WHEN S3.SegmentId IS NULL THEN 0 ELSE S3.SegmentId END AS SegmentId, S2.SectionId, S4.ImageId, S.ProjectId, S.CustomerId, S.ImageStyle
		FROM #ProjectSegmentImage_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectImageSLC S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.SegmentId = S3.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		SELECT S.SegmentImageId, S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.ImageId INTO #tmpProjectSegmentImage
		FROM [SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK) WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		--Update Image plaholders with new ImageId in ProjectSegment table
		UPDATE A
			SET A.SegmentDescription = B.NewSegmentDescription
		FROM #tmpProjectSegmentSLC A
		INNER JOIN (
					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentId
						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
					FROM #tmpProjectSegmentSLC PS
					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
						AND PS.SegmentStatusId = S3.SegmentStatusId
					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
						--AND PS.SegmentId = S5.SegmentId
					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID AND PS.SegmentDescription LIKE '%{IMG#%'
					GROUP BY PS.ProjectId, PS.CustomerId, PS.SectionId, PS.SegmentId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentImage created', 'ProjectSegmentImage created', 1, 26, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 65, 0, '', ''


		--Insert ProjectNoteImage_Staging table
		SELECT S.NoteImageId, S.NoteId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId
		INTO #ProjectNoteImage_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectNoteImage] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move ProjectNoteImage table
		INSERT INTO [SLCProject].[dbo].[ProjectNoteImage]
		(NoteId, SectionId, ImageId, ProjectId, CustomerId)
		SELECT S3.NoteId, S2.SectionId, S4.ImageId, S.ProjectId, S.CustomerId
		FROM #ProjectNoteImage_Staging S
		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
		INNER JOIN #tmpProjectNoteSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
			AND S.NoteId = S3.A_NoteId
		INNER JOIN #tmpProjectImageSLC S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		SELECT P.NoteImageId, P.ProjectId, P.CustomerId, P.SectionId, P.NoteId, P.ImageId INTO #tmpProjectNoteImageSLC
		FROM [SLCProject].[dbo].[ProjectNoteImage] P WITH (NOLOCK)
		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @TargetCustomerID

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
					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @TargetCustomerID AND PS.NoteText LIKE '%{IMG#%'
					GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId--, S5.NoteId, S5.ImageId
		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @TargetCustomerID AND A.NoteText LIKE '%{IMG#%'

		--UPDATE SegmentDescription in original table
		UPDATE PSS
		SET PSS.NoteText = PSS_TMP.NoteText
		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
		INNER JOIN #tmpProjectNoteSLC PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
			AND PSS.ProjectId = PSS_TMP.ProjectId
		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @TargetCustomerID;

		DROP TABLE IF EXISTS #tmpProjectImageSLC;
		DROP TABLE IF EXISTS #tmpProjectNoteSLC;
		DROP TABLE IF EXISTS #tmpProjectNoteImageSLC;
		DROP TABLE IF EXISTS #ProjectNoteImage_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectNoteImage created', 'ProjectNoteImage created', 1, 27, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 67, 0, '', ''

		--Move ProjectSegmentLink table
		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentLinkId) AS RowNumber, S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
			,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
			,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, @TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.ModifiedDate
			,@New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.SegmentLinkCode, S.SegmentLinkSourceTypeId
		INTO #ProjectSegmentLink_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentLink] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		SET @TableRows = @@ROWCOUNT

		SET @Records = 1
		SET @Start = 1
		SET @End = @Start + @ProjectSegmentLink_BatchSize - 1

		WHILE @Records <= @TableRows
		BEGIN
			INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
			(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode
				,TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, IsDeleted
				,CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
			SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
				,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
				,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, @TargetUserID AS CreatedBy, @TargetUserID AS ModifiedBy, S.ModifiedDate
				,@New_ProjectID AS ProjectId, @TargetCustomerID AS CustomerId, S.SegmentLinkCode, S.SegmentLinkSourceTypeId
			FROM #ProjectSegmentLink_Staging S
			WHERE S.RowNumber BETWEEN @Start AND @End

			SET @Records += @ProjectSegmentLink_BatchSize;
			SET @Start = @End + 1 ;
			SET @End = @Start + @ProjectSegmentLink_BatchSize - 1;
		END
		
		DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentLink created', 'ProjectSegmentLink created', 1, 28, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 70, 0, '', ''


		--Move ProjectSegmentTracking table
		SELECT S.[SegmentId], @New_ProjectID AS [ProjectId], @TargetCustomerID AS [CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		INTO #ProjectSegmentTracking_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectSegmentTracking] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTracking]
		([SegmentId], [ProjectId], [CustomerId], [UserId], [SegmentDescription], [CreatedBy], [CreateDate], [VersionNumber])
		SELECT S1.[SegmentId], S.[ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
		FROM #ProjectSegmentTracking_Staging S
		INNER JOIN #tmpProjectSegmentSLC S1 ON S.CustomerId = S1.CustomerId AND S.SegmentId = S1.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectSegmentTracking created', 'ProjectSegmentTracking created', 1, 29, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 72, 0, '', ''


		--Move ProjectDisciplineSection table
		SELECT S.[SectionId], S.[Disciplineld], @New_ProjectID AS [ProjectId], @TargetCustomerID AS [CustomerId], S.[IsActive]
		INTO #ProjectDisciplineSection_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectDisciplineSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		INSERT INTO [SLCProject].[dbo].[ProjectDisciplineSection]
		([SectionId], [Disciplineld], [ProjectId], [CustomerId], [IsActive])
		SELECT S1.[SectionId], S.[Disciplineld], S.[ProjectId], S.[CustomerId], S.[IsActive]
		FROM #ProjectDisciplineSection_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectDisciplineSection created', 'ProjectDisciplineSection created', 1, 30, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 75, 0, '', ''


		--Move ProjectDateFormat table
		INSERT INTO [SLCProject].[dbo].[ProjectDateFormat]
		([MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate])
		SELECT S.[MasterDataTypeId], @New_ProjectID AS [ProjectId], @TargetCustomerID AS [CustomerId], S.[UserId], S.[ClockFormat], S.[DateFormat], S.[CreateDate]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectDateFormat] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectDateFormat created', 'ProjectDateFormat created', 1, 31, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 77, 0, '', ''


		----Move MaterialSection table
		--SELECT @New_ProjectID AS [ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], @TargetCustomerID AS [CustomerId]
		--INTO #MaterialSection_Staging
		--FROM [SLCSERVER03].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
		--WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--INSERT INTO [SLCProject].[dbo].[MaterialSection]
		--([ProjectId], [VimId], [MaterialId], [SectionId], [CustomerId])
		--SELECT S.[ProjectId], S.[VimId], S.[MaterialId], S1.[SectionId], S.[CustomerId]
		--FROM #MaterialSection_Staging S
		--INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		--DROP TABLE IF EXISTS #MaterialSection_Staging;

		--EXECUTE [SLCProject].[dbo].[sp_PTransferStepProgress] @RequestId, 'MaterialSection created', 'MaterialSection created', '32', 80, @OldCount, @NewCount


		----Move LinkedSections table
		--SELECT @New_ProjectID AS [ProjectId], S.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], @TargetCustomerID AS [customerId]
		--INTO #LinkedSections_Staging
		--FROM [SLCSERVER03].[SLCProject].[dbo].[LinkedSections] S WITH (NOLOCK)
		--WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--INSERT INTO [SLCProject].[dbo].[LinkedSections]
		--([ProjectId], [SectionId], [VimId], [MaterialId], [Linkedby], [LinkedDate], [customerId])
		--SELECT S.[ProjectId], S1.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
		--FROM #LinkedSections_Staging S
		--INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		--DROP TABLE IF EXISTS #LinkedSections_Staging;

		--EXECUTE [SLCProject].[dbo].[sp_PTransferStepProgress] @RequestId, 'LinkedSections created', 'LinkedSections created', '33', 82, @OldCount, @NewCount


		--Move ApplyMasterUpdateLog table
		INSERT INTO [SLCProject].[dbo].[ApplyMasterUpdateLog]
		([ProjectId], [LastUpdateDate])
		SELECT @New_ProjectID AS [ProjectId], S.[LastUpdateDate]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ApplyMasterUpdateLog] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ApplyMasterUpdateLog created', 'ApplyMasterUpdateLog created', 1, 34, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 85, 0, '', ''

		--Move ProjectExport table
		INSERT INTO [SLCProject].[dbo].[ProjectExport]
		([FileName],[ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy],[CreatedByFullName]
			,[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId],[ProjectName],[FileStatus],[PrintFailureReason])
		SELECT [FileName], @New_ProjectID AS [ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy]
			,[CreatedByFullName],[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],@TargetCustomerID AS [CustomerId],[ProjectName],[FileStatus],[PrintFailureReason]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectExport] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectExport created', 'ProjectExport created', 1, 35, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 87, 0, '', ''

		--Move SegmentComment_Staging table
		SELECT @New_ProjectID AS [ProjectId],[SectionId],[SegmentStatusId],[ParentCommentId],[CommentDescription],@TargetCustomerID AS [CustomerId]
			,[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[CommentStatusId],[IsDeleted],[userFullName],[SegmentCommentId] AS [A_SegmentCommentId]
		INTO #SegmentComment_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[SegmentComment] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

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
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		--Update ParentCommentId
		UPDATE CST
			SET CST.ParentCommentId = PST.SegmentCommentId
		FROM [SLCProject].[dbo].[SegmentComment] CST WITH (NOLOCK)
		INNER JOIN [SLCProject].[dbo].[SegmentComment] PST WITH (NOLOCK) ON CST.ProjectId = PST.ProjectId AND CST.CustomerId = PST.CustomerId
			AND CST.SectionId = PST.SectionId AND PST.A_SegmentCommentId = CST.ParentCommentId AND CST.ParentCommentId <> 0
		WHERE CST.ProjectId = @New_ProjectID AND CST.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #SegmentComment_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'SegmentComment created', 'SegmentComment created', 1, 36, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 90, 0, '', ''


		--Move TrackAcceptRejectProjectSegmentHistory table
		SELECT [SectionId],[SegmentId], @New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note]
		INTO #TrackAcceptRejectProjectSegmentHistory_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory]
		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note])
		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[TrackActionId],S.[Note]
		FROM #TrackAcceptRejectProjectSegmentHistory_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentId = S2.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #TrackAcceptRejectProjectSegmentHistory_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'TrackAcceptRejectProjectSegmentHistory created', 'TrackAcceptRejectProjectSegmentHistory created', 1, 37, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 92, 0, '', ''


		--Insert TrackProjectSegment_Staging table
		SELECT [SectionId],[SegmentId],@New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],[BeforEdit],[AfterEdit],[CreateDate]
			,[ChangedDate],[ChangedById],[IsDeleted]
		INTO #TrackProjectSegment_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[TrackProjectSegment] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		--Move TrackProjectSegment table
		INSERT INTO [SLCProject].[dbo].[TrackProjectSegment]
		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate],[ChangedDate],[ChangedById],[IsDeleted])
		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[CreateDate],S.[ChangedDate],S.[ChangedById]
			,S.[IsDeleted]
		FROM #TrackProjectSegment_Staging S
		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		LEFT JOIN #tmpProjectSegmentSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
			AND S.SegmentId = S2.A_SegmentId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		DROP TABLE IF EXISTS #TrackProjectSegment_Staging;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'TrackProjectSegment created', 'TrackProjectSegment created', 1, 38, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 93, 0, '', ''


		--Move UserProjectAccessMapping table
		INSERT INTO [SLCProject].[dbo].[UserProjectAccessMapping]
		([ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive])
		SELECT @New_ProjectID AS [ProjectId],[UserId],@TargetCustomerID AS [CustomerId],@TargetUserID AS [CreatedBy],[CreateDate]
			,@TargetUserID AS [ModifiedBy],[ModifiedDate],[IsActive]
		FROM [SLCSERVER03].[SLCProject].[dbo].[UserProjectAccessMapping] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'UserProjectAccessMapping created', 'UserProjectAccessMapping created', 1, 39, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 94, 0, '', ''


		--Move ProjectActivity table
		INSERT INTO [SLCProject].[dbo].[ProjectActivity]
		([ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate])
		SELECT @New_ProjectID AS [ProjectId],[UserId],@TargetCustomerID AS [CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectActivity] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectActivity created', 'ProjectActivity created', 1, 40, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 95, 0, '', ''


		--Move ProjectLevelTrackChangesLogging table
		INSERT INTO [SLCProject].[dbo].[ProjectLevelTrackChangesLogging]
		([UserId],[ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate])
		SELECT [UserId],@New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate]
		FROM [SLCSERVER03].[SLCProject].[dbo].[ProjectLevelTrackChangesLogging] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'ProjectLevelTrackChangesLogging created', 'ProjectLevelTrackChangesLogging created', 1, 41, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 96, 0, '', ''


		--Move SectionLevelTrackChangesLogging table
		SELECT [UserId],@New_ProjectID AS [ProjectId],[SectionId],@TargetCustomerID AS [CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate]
		INTO #tmpSectionLevelTrackChangesLoggingSLC
		FROM [SLCSERVER03].[SLCProject].[dbo].[SectionLevelTrackChangesLogging] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		INSERT INTO [SLCProject].[dbo].[SectionLevelTrackChangesLogging]
		([UserId],[ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate])
		SELECT S.[UserId],S.[ProjectId],S1.[SectionId],S.[CustomerId],S.[UserEmail],S.[IsTrackChanges],S.[IsTrackChangeLock],S.[CreatedDate]
		FROM #tmpSectionLevelTrackChangesLoggingSLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'SectionLevelTrackChangesLogging created', 'SectionLevelTrackChangesLogging created', 1, 42, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 97, 0, '', ''

		--Move TrackAcceptRejectHistory table
		SELECT [SectionId],@New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],[UserId],[TrackActionId],[CreateDate]
		INTO #tmpTrackAcceptRejectHistorySLC
		FROM [SLCSERVER03].[SLCProject].[dbo].[TrackAcceptRejectHistory] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID

		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectHistory]
		([SectionId],[ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate])
		SELECT S1.[SectionId],S.[ProjectId],S.[CustomerId],S.[UserId],S.[TrackActionId],S.[CreateDate]
		FROM #tmpTrackAcceptRejectHistorySLC S WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'TrackAcceptRejectHistory created', 'TrackAcceptRejectHistory created', 1, 43, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 98, 0, '', ''


		--Move TrackSegmentStatusType table
		SELECT @New_ProjectID AS [ProjectId],[SectionId],@TargetCustomerID AS [CustomerId],[SegmentStatusId],[SegmentStatusTypeId],[PrevStatusSegmentStatusTypeId],[InitialStatusSegmentStatusTypeId],[IsAccepted],[UserId]
			,[UserFullName],[CreatedDate],[ModifiedById],[ModifiedByUserFullName],[ModifiedDate],[TenantId],[InitialStatus],[IsSegmentStatusChangeBySelection],[CurrentStatus]
			,[SegmentStatusTypeIdBeforeSelection]
		INTO #TrackSegmentStatusType_Staging
		FROM [SLCSERVER03].[SLCProject].[dbo].[TrackSegmentStatusType] S WITH (NOLOCK)
		WHERE S.ProjectId = @SourceProjectID AND S.CustomerId = @SourceCustomerID


		--Move TrackSegmentStatusType table
		INSERT INTO [SLCProject].[dbo].[TrackSegmentStatusType]
		([ProjectId],[SectionId],[CustomerId],[SegmentStatusId],[SegmentStatusTypeId],[PrevStatusSegmentStatusTypeId],[InitialStatusSegmentStatusTypeId],[IsAccepted],[UserId],[UserFullName]
			,[CreatedDate],[ModifiedById],[ModifiedByUserFullName],[ModifiedDate],[TenantId],[InitialStatus],[IsSegmentStatusChangeBySelection],[CurrentStatus]
			,[SegmentStatusTypeIdBeforeSelection])
		SELECT S.[ProjectId],S1.[SectionId],S.[CustomerId],S2.[SegmentStatusId],S.[SegmentStatusTypeId],S.[PrevStatusSegmentStatusTypeId],S.[InitialStatusSegmentStatusTypeId],S.[IsAccepted],S.[UserId]
			,S.[UserFullName],S.[CreatedDate],S.[ModifiedById],S.[ModifiedByUserFullName],S.[ModifiedDate],S.[TenantId],S.[InitialStatus],S.[IsSegmentStatusChangeBySelection],S.[CurrentStatus]
			,S.[SegmentStatusTypeIdBeforeSelection]
		FROM #TrackSegmentStatusType_Staging S WITH (NOLOCK)
		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
		INNER JOIN #tmpProjectSegmentStatusSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
						AND S.SegmentStatusId = S2.A_SegmentStatusId
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID


		--Move FileNameFormatSetting table
		INSERT INTO [dbo].[FileNameFormatSetting]
		([FileFormatCategoryId],[IncludeAutherSectionId],[Separator],[FormatJsonWithPlaceHolder],[ProjectId],[CustomerId],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
		SELECT [FileFormatCategoryId],[IncludeAutherSectionId],[Separator],[FormatJsonWithPlaceHolder],@New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate]
		FROM [SLCSERVER03].[SLCProject].[dbo].[FileNameFormatSetting]
		WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID


		--Move SheetSpecsPageSettings table
		INSERT INTO [dbo].[SheetSpecsPageSettings]
		([PaperSettingKey],[ProjectId],[CustomerId],[Name],[Value],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[IsActive],[IsDeleted])
		SELECT [PaperSettingKey],@New_ProjectID AS [ProjectId],@TargetCustomerID AS [CustomerId],[Name],[Value],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[IsActive],[IsDeleted]
		FROM [SLCSERVER03].[SLCProject].[dbo].[SheetSpecsPageSettings]
		WHERE ProjectId = @SourceProjectID AND CustomerId = @SourceCustomerID


		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'TrackSegmentStatusType created', 'TrackSegmentStatusType created', 1, 43, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 2, 99, 0, '', ''

		----Insert data into SectionDocument related Alternate Document  
		INSERT INTO [SLCProject].[dbo].[SectionDocument] (ProjectId, SectionId, SectionDocumentTypeId, DocumentPath, OriginalFileName, CreateDate, CreatedBy)      
		SELECT @New_ProjectID,tgtSect.SectionId ,SD.SectionDocumentTypeId, 
		        REPLACE(REPLACE(SD.DocumentPath,@SourceProjectID,@New_ProjectID),@SourceCustomerID,@TargetCustomerID)  
			    ,SD.OriginalFileName, GETUTCDATE(), @TargetUserID 
				FROM [SLCSERVER03].[SLCProject].[dbo].[SectionDocument] SD WITH (NOLOCK)  
		INNER JOIN #tmpProjectSectionSLC tgtSect WITH(NOLOCK)  
		ON  SD.ProjectId = @SourceProjectID  
		AND SD.SectionId = tgtSect.A_SectionId   
		--WHERE tgtSect.SectionSource = 8  


		----Move SheetSpecsPrintSettings related Alternate Document  
		INSERT INTO [dbo].[SheetSpecsPrintSettings] 
		(CustomerId, ProjectId, UserId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, SheetSpecsPrintPreviewLevel)      
		SELECT @TargetCustomerID AS CustomerId, @New_ProjectID AS ProjectId, @TargetUserID AS UserId, CreatedDate, @TargetUserID AS CreatedBy, ModifiedDate, @TargetUserID AS ModifiedBy
			,IsDeleted, SheetSpecsPrintPreviewLevel
		FROM [SLCSERVER03].[SLCProject].[dbo].[SheetSpecsPrintSettings] SD WITH (NOLOCK)  
		WHERE SD.ProjectId = @SourceProjectID

		DECLARE @IsSupplementalDocsEnable BIT = 0;
		SELECT @IsSupplementalDocsEnable = ISNULL(IsSupplementalDocsEnable, 0) 
			FROM [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferQueue]  WITH (NOLOCK) WHERE TransferRequestId = @TransferRequestId;

		IF (@IsSupplementalDocsEnable = 1)
		BEGIN
			---Move supplemental documents related data
			DROP TABLE IF EXISTS #TempDocLibraryIds;
			DROP TABLE IF EXISTS #TargetResultImportDocLibrary;
			DROP TABLE IF EXISTS #TargetResultDocLibraryMapping;

			-- Get DocLibraryId which needs to sent in Target customer
			SELECT DISTINCT DLM.DocLibraryId 
			INTO #TempDocLibraryIds
			FROM [SLCSERVER03].[SLCProject].[dbo].[DocLibraryMapping] DLM WITH(NOLOCK) 
			INNER JOIN [SLCSERVER03].[SLCProject].[dbo].[ImportDocLibrary] IDL WITH(NOLOCK) ON IDL.DocLibraryId = DLM.DocLibraryId 
			WHERE DLM.CustomerId = @SourceCustomerId AND DLM.ProjectId = @SourceProjectId AND ISNULL(DLM.IsDeleted, 0) = 0;

			SELECT @TargetCustomerId AS CustomerId, DocumentTypeId,
			CONCAT(@TargetCustomerId, '/Documents/Received Documents/', @New_ProjectID, '/', OriginalFileName) AS  DocumentPath,
			OriginalFileName, FileSize, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy,
			IDL.DocLibraryId AS A_DocLibraryId
			INTO #TargetResultImportDocLibrary
			FROM [SLCSERVER03].[SLCProject].[dbo].[ImportDocLibrary] IDL WITH(NOLOCK) 
			INNER JOIN #TempDocLibraryIds T ON T.DocLibraryId = IDL.DocLibraryId;

			INSERT INTO [SLCProject].[dbo].[ImportDocLibrary] (CustomerId, DocumentTypeId, DocumentPath, OriginalFileName,  
						FileSize, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, A_DocLibraryId)
			SELECT CustomerId, DocumentTypeId, DocumentPath, OriginalFileName,
					FileSize, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, A_DocLibraryId
			FROM #TargetResultImportDocLibrary;

			INSERT INTO [SLCProject].[dbo].DocLibraryMapping (CustomerId, ProjectId, SectionId, SegmentId, DocLibraryId, SortOrder, IsActive,
				IsAttachedToFolder, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, AttachedByFullName)
			SELECT @TargetCustomerId AS CustomerId, @New_ProjectID AS ProjectId,
				PST.SectionId AS SectionId, SegmentId, IDLT.DocLibraryId AS DocLibraryId,
				DLM.SortOrder, DLM.IsActive, DLM.IsAttachedToFolder, DLM.IsDeleted, DLM.CreatedDate, DLM.CreatedBy,
				DLM.ModifiedDate, DLM.ModifiedBy, DLM.AttachedByFullName
			FROM [SLCSERVER03].[SLCProject].[dbo].[DocLibraryMapping] DLM WITH(NOLOCK) 
			INNER JOIN [SLCSERVER03].[SLCProject].[dbo].[ImportDocLibrary] IDL ON IDL.DocLibraryId = DLM.DocLibraryId 
			INNER JOIN [SLCProject].[dbo].[ProjectSection] PST ON PST.CustomerId = @TargetCustomerId AND PST.ProjectId = @New_ProjectID AND PST.A_SectionId = DLM.SectionId 
			INNER JOIN [SLCProject].[dbo].[ImportDocLibrary] IDLT ON IDLT.CustomerId = @TargetCustomerId AND IDLT.A_DocLibraryId = IDL.DocLibraryId AND IDLT.DocumentPath LIKE '%/Documents/Received Documents/' + CAST(@New_ProjectID AS NVARCHAR(50)) +'/%'
			WHERE DLM.CustomerId = @SourceCustomerId AND DLM.ProjectId = @SourceProjectId AND ISNULL(DLM.IsDeleted, 0) = 0;
		END

		--Load Project Migration Exception table
		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Choice' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID AND SegmentDescription LIKE '%\ch\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'ReferenceStandard' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID AND SegmentDescription LIKE '%\rs\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'HyperLink' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID AND SegmentDescription LIKE '%\hl\#%'

		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Image' AS BrokenPlaceHolderType
			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
		FROM #tmpProjectSegmentSLC S
		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @TargetCustomerID AND SegmentDescription LIKE '%\img\#%'

		DROP TABLE IF EXISTS #tmpProjectSegmentSLC;

		--Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is transferred successfully to production server
		UPDATE P 
		SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0, P.IsPermanentDeleted = 0, P.ModifiedDate = GETUTCDATE(), P.CreatedBy = @TargetUserID, P.ModifiedBy = @TargetUserID
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.CustomerId = @TargetCustomerID AND P.ProjectId = @New_ProjectID

		----Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
		--UPDATE P
		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedDate = GETUTCDATE()
		--FROM [SLCSERVER03].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
		--WHERE P.CustomerId = @SourceCustomerID AND P.ProjectId = @SourceProjectID;

		--Update Status to Completed on Central server
		UPDATE P
			SET P.StatusId = 3, P.EndTime = GETUTCDATE()
		FROM [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferQueue] P WITH (NOLOCK)
		WHERE TransferRequestId = @TransferRequestId

		--Update TargetProjectId in ProjectTransferConflictLog
		UPDATE P SET TargetProjectID = @New_ProjectID
		FROM [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferConflictLog] P WITH (NOLOCK)
		WHERE TransferRequestId = @TransferRequestId AND SourceCustomerID = @SourceCustomerID AND SourceProjectID = @SourceProjectID AND SourceServerID = @SourceServerID

		--Update TargetProjectId in ProjectTransferGlobalDataAuditLog
		UPDATE P SET TargetProjectID = @New_ProjectID
		FROM [SLCProject].[dbo].[ProjectTransferGlobalDataAuditLog] P WITH (NOLOCK)
		WHERE RequestId = @TransferRequestId AND SourceCustomerID = @SourceCustomerID AND SourceProjectID = @SourceProjectID AND SourceServerID = @SourceServerID

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Project Transferred', 'Project Transferred', 1, 44, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 3, 100, 0, '', ''

		SET @TargetProjectID = @New_ProjectID

	END TRY

	BEGIN CATCH
		/*************************************
		*  Get the Error Message for @@Error
		*************************************/
		--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
		UPDATE P
		SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @TargetUserID, P.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
		WHERE P.CustomerId = @TargetCustomerID AND P.ProjectId = @New_ProjectID;

		EXECUTE [dbo].[usp_MaintainCopyProjectHistory] @New_ProjectID, 'Project Transfer Failed', 'Project Transfer Failed', 1, 45, @RequestId
		EXECUTE [dbo].[usp_MaintainCopyProjectProgress] 0, @New_ProjectID, @TargetUserID, @TargetCustomerID, 4, 100, 0, '', ''

		--Update Status to Failed on Central server
		UPDATE P
			SET P.StatusId = 4, P.EndTime = GETUTCDATE()
		FROM [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferQueue] P WITH (NOLOCK)
		WHERE TransferRequestId = @TransferRequestId

		--Cancel Archive if the failed project is also marked for archive
		UPDATE A
			SET A.InProgressStatusId = 5
		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
		WHERE A.SLC_ServerId = @SourceServerID AND A.SLC_CustomerId = @SourceCustomerID AND A.SLC_ProdProjectId = @SourceProjectID AND A.InProgressStatusId = 1

		SET @ErrorStep = 'ProjectTransfer'

		SELECT @ErrorCode = ERROR_NUMBER()
			, @Return_Message = @ErrorStep + ' '
			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
			+ ERROR_MESSAGE() + ' > ' 
			+ ERROR_PROCEDURE()

		EXEC [SLCProject].[dbo].[spb_LogErrors] @TargetCustomerID, @ErrorCode, @ErrorStep, @Return_Message

    
	END CATCH


END

GO