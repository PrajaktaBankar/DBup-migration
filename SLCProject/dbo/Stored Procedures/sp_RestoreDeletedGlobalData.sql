CREATE PROCEDURE [dbo].[sp_RestoreDeletedGlobalData]
(
	@PSLC_CustomerId		INT
	,@PProjectID			INT
	,@IsRestoreDeleteFailed	INT OUTPUT
)
AS
BEGIN
	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message VARCHAR(1024)
	DECLARE @ErrorStep VARCHAR(50)
	SET @IsRestoreDeleteFailed = 0

	--Handled Parameter Sniffing here
	DECLARE @SLC_CustomerId INT
	SET @SLC_CustomerId = @PSLC_CustomerId
	DECLARE @ProjectID INT
	SET @ProjectID = @PProjectID

	--Drop all Temp tables
	DROP TABLE IF EXISTS #TMPREFSTDID;
	DROP TABLE IF EXISTS #tmpRefStdIdInProjRefStandard;
	DROP TABLE IF EXISTS #tmpRefStdIdInProjSegmentRefStandard;
	DROP TABLE IF EXISTS #TMPTemplateIdInProject;
	DROP TABLE IF EXISTS #TMPTemplateIdInProjectSection;
	DROP TABLE IF EXISTS #TMPTemplateId;
	DROP TABLE IF EXISTS #DeletedTemplate;
	DROP TABLE IF EXISTS #tmpUserGlobalTermIdInProSegGlobalTerm;
	DROP TABLE IF EXISTS #tmpUserGlobalTermIdInHeaderFooter;
	DROP TABLE IF EXISTS #TMPUserGlobalTermId;


	BEGIN TRY

		--Get all global data used in UnArchived project

		--ReferenceStandard
		IF OBJECT_ID('tempdb..#TMPREFSTDID') IS NOT NULL DROP TABLE #TMPREFSTDID
		CREATE TABLE #TMPREFSTDID (RefStandardId	INT)

		SELECT DISTINCT RefStandardId
		INTO #tmpRefStdIdInProjRefStandard
		FROM [SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND RefStdSource = 'U'

		SELECT DISTINCT RefStandardId
		INTO #tmpRefStdIdInProjSegmentRefStandard
		FROM [SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND RefStandardSource = 'U'

		INSERT INTO #TMPREFSTDID SELECT RefStandardId FROM #tmpRefStdIdInProjRefStandard;
		INSERT INTO #TMPREFSTDID SELECT RefStandardId FROM #tmpRefStdIdInProjSegmentRefStandard;

		--Restore Deleted ReferenceStandard
		UPDATE S SET S.IsDeleted = 0
		FROM [SLCProject].[dbo].[ReferenceStandard] S WITH (NOLOCK)
		WHERE S.CustomerId = @SLC_CustomerId AND S.RefStdId IN (SELECT RefStandardId FROM #TMPREFSTDID) AND IsDeleted = 1;


		--Template
		SELECT DISTINCT TemplateId INTO #TMPTemplateIdInProject
		FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND ISNULL(TemplateId, 0) > 0

		SELECT DISTINCT TemplateId INTO #TMPTemplateIdInProjectSection
		FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND ISNULL(TemplateId, 0) > 0

		IF OBJECT_ID('tempdb..#TMPTemplateId') IS NOT NULL DROP TABLE #TMPTemplateId
		CREATE TABLE #TMPTemplateId (TemplateId	INT)

		INSERT INTO #TMPTemplateId SELECT TemplateId FROM #TMPTemplateIdInProject
		INSERT INTO #TMPTemplateId SELECT TemplateId FROM #TMPTemplateIdInProjectSection

		--Get Deleted template that is used in the UnArchived project
		SELECT TemplateId INTO #DeletedTemplate FROM [SLCProject].[dbo].[Template] S WITH (NOLOCK)
		WHERE S.CustomerId = @SLC_CustomerId AND S.TemplateId IN (SELECT TemplateId FROM #TMPTemplateId) AND S.IsDeleted = 1;

		--Restore Deleted Template
		UPDATE S SET S.IsDeleted = 0
		FROM [SLCProject].[dbo].[Template] S WITH (NOLOCK)
		WHERE S.CustomerId = @SLC_CustomerId AND S.TemplateId IN (SELECT TemplateId FROM #TMPTemplateId) AND S.IsDeleted = 1;

		--Restore Deleted Style
		UPDATE S SET S.IsDeleted = 0
		FROM [SLCProject].[dbo].[Style] S WITH (NOLOCK)
		INNER JOIN [SLCProject].[dbo].[TemplateStyle] S1 WITH (NOLOCK) ON S.CustomerId = S1.CustomerId AND S.StyleId = S1.StyleId AND S1.TemplateId IN (SELECT TemplateId FROM #DeletedTemplate)
		WHERE S.CustomerId = @SLC_CustomerId AND S1.TemplateId IN (SELECT TemplateId FROM #DeletedTemplate) AND S.IsDeleted = 1;
		


		--UserGlobalTerm
		
		IF OBJECT_ID('tempdb..#tmpUserGlobalTermIdInProSegGlobalTerm') IS NOT NULL DROP TABLE #tmpUserGlobalTermIdInProSegGlobalTerm
		CREATE TABLE #tmpUserGlobalTermIdInProSegGlobalTerm (UserGlobalTermId	INT)

		IF OBJECT_ID('tempdb..#tmpGlobalTermCode') IS NOT NULL DROP TABLE #tmpGlobalTermCode
		CREATE TABLE #tmpGlobalTermCode (GlobalTermCode	INT)
			

		IF EXISTS (SELECT S.UserGlobalTermId FROM [SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK) WHERE S.ProjectId = @ProjectID
						AND S.CustomerId = @SLC_CustomerId AND S.UserGlobalTermId IS NULL AND IsDeleted = 0)
		BEGIN
			
			IF OBJECT_ID('tempdb..#tmpProjectSegment') IS NOT NULL DROP TABLE #tmpProjectSegment
			CREATE TABLE #tmpProjectSegment
			(
				RowID					INT IDENTITY(1, 1), 
				ProjectId				INT NOT NULL,
				CustomerId				INT NOT NULL,
				SectionId				INT NOT NULL,
				SegmentId				BIGINT NULL,
				SegmentDescription		NVARCHAR(MAX) NULL,
				NewGlobalTermCode		INT NULL,
				IsProcessed				BIT NULL DEFAULT((0))
			)

			DECLARE @stringTAG NVARCHAR(10) = '{GT#'
			DECLARE @NumberRecords AS INT, @RowCount AS INT

			INSERT INTO #tmpProjectSegment
			(ProjectId, CustomerId, SectionId, SegmentId, SegmentDescription, NewGlobalTermCode, IsProcessed)
			SELECT S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.SegmentDescription, NULL AS NewGlobalTermCode, 0 AS IsProcessed
			FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
			INNER JOIN [SLCProject].[dbo].[ProjectSegmentGlobalTerm] S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
				AND S.SectionId = S1.SectionId AND S.SegmentId = S1.SegmentId
			WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND S1.IsDeleted = 0

			-- Get the number of records in the temporary table
			SET @NumberRecords = @@ROWCOUNT
			SET @RowCount = 1

			--Delete Duplicate records from #tmpProjectSegment table
			;WITH CTE_Segments AS(
				SELECT [ProjectId],[CustomerID],[SegmentId],
					RN = ROW_NUMBER()OVER(PARTITION BY [ProjectId],[CustomerID],[SegmentId] ORDER BY [SegmentId] DESC)
				FROM #tmpProjectSegment WITH (NOLOCK)
			)
			DELETE CTE_Segments WHERE [RN] > 1;

			-- loop through all records in the temporary table using the WHILE loop construct
			WHILE @RowCount <= @NumberRecords
			BEGIN
				DECLARE @SectionId AS INT, @SegmentId AS BIGINT
				SELECT @SectionId = SectionId, @SegmentId = SegmentId FROM #tmpProjectSegment WHERE RowID = @RowCount
	
				INSERT INTO #tmpGlobalTermCode
				SELECT SLCProject.[dbo].[fn_GetIDFromPlaceHolder](PS.SegmentDescription, @stringTAG)
				FROM #tmpProjectSegment PS WITH (NOLOCK)
				WHERE PS.ProjectId = @ProjectID AND PS.CustomerId = @SLC_CustomerId AND PS.SectionId = @SectionId AND PS.SegmentId = @SegmentId

				UPDATE PS
				SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{GT#'+CAST(SLCProject.[dbo].[fn_GetIDFromPlaceHolder](PS.SegmentDescription, @stringTAG) AS VARCHAR(100))+'}', '{NEWGT#'+CAST(SLCProject.[dbo].[fn_GetIDFromPlaceHolder](PS.SegmentDescription, @stringTAG) AS VARCHAR(100))+'}')
					,NewGlobalTermCode = SLCProject.[dbo].[fn_GetIDFromPlaceHolder](PS.SegmentDescription, @stringTAG)
				FROM #tmpProjectSegment PS WITH (NOLOCK)
				WHERE PS.ProjectId = @ProjectID AND PS.CustomerId = @SLC_CustomerId AND PS.SectionId = @SectionId AND PS.SegmentId = @SegmentId

				SET @RowCount = @RowCount + 1
			END

		END
		ELSE
		BEGIN
			INSERT INTO #tmpUserGlobalTermIdInProSegGlobalTerm
			SELECT DISTINCT UserGlobalTermId
			FROM [SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
			WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND S.IsDeleted = 0
		END

		SELECT DISTINCT UserGlobalTermId INTO #tmpUserGlobalTermIdInHeaderFooter
		FROM [SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		IF EXISTS (SELECT GlobalTermCode FROM #tmpGlobalTermCode)
		BEGIN
			INSERT INTO #tmpUserGlobalTermIdInProSegGlobalTerm
			SELECT UserGlobalTermId FROM [SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
			WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId AND S.IsDeleted = 0
		END

		IF OBJECT_ID('tempdb..#TMPUserGlobalTermId') IS NOT NULL DROP TABLE #TMPUserGlobalTermId
		CREATE TABLE #TMPUserGlobalTermId (UserGlobalTermId	INT)

		INSERT INTO #TMPUserGlobalTermId SELECT DISTINCT UserGlobalTermId FROM #tmpUserGlobalTermIdInProSegGlobalTerm
		INSERT INTO #TMPUserGlobalTermId SELECT DISTINCT UserGlobalTermId FROM #tmpUserGlobalTermIdInHeaderFooter

		--Restore Deleted UserGlobalTerm
		UPDATE S SET S.IsDeleted = 0
		FROM [SLCProject].[dbo].[UserGlobalTerm] S WITH (NOLOCK)
		WHERE S.CustomerId = @SLC_CustomerId AND S.UserGlobalTermId IN (SELECT UserGlobalTermId FROM #TMPUserGlobalTermId) AND S.IsDeleted = 1;

	END TRY

	BEGIN CATCH
		/*************************************
		*  Get the Error Message for @@Error
		*************************************/
		--Set IsProjectMigrationFailed to 1
		SET @IsRestoreDeleteFailed = 1

		SET @ErrorStep = 'RestoreDeletedGlobalData'

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


