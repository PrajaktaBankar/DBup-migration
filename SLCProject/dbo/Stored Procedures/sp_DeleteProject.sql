
CREATE PROCEDURE [dbo].[sp_DeleteProject]
AS
BEGIN

IF OBJECT_ID('tempdb..#tmpProjects') IS NOT NULL DROP TABLE #tmpProjects
CREATE TABLE #tmpProjects
(
	RowID				INT IDENTITY(1, 1),
	ProjectId			INT NOT NULL,
	IsProcessed			BIT NOT NULL
)

DECLARE @NumberRecords int, @RowCount int
DECLARE @ErrorCode INT = 0
DECLARE @Return_Message VARCHAR(1024)
DECLARE @ErrorStep VARCHAR(50)

INSERT INTO #tmpProjects(ProjectId, IsProcessed)
SELECT ProjectId, 0 AS IsProcessed FROM [dbo].[Project]
WHERE IsDeleted = 1 AND IsPermanentDeleted = 1

-- Get the number of records in the temporary table
SET @NumberRecords = @@ROWCOUNT
SET @RowCount = 1

-- loop through all records in the temporary table using the WHILE loop construct
WHILE @RowCount <= @NumberRecords
BEGIN
	BEGIN TRY
		DECLARE @ProjectID AS INT

		SELECT @ProjectID = ProjectID FROM #tmpProjects WHERE RowID = @RowCount

		DELETE FROM ApplyMasterUpdateLog WHERE ProjectId = @ProjectID
		DELETE FROM ProjectExport WHERE ProjectId = @ProjectID
		DELETE FROM LinkedSections WHERE ProjectId = @ProjectID
		DELETE FROM MaterialSection WHERE ProjectId = @ProjectID
		DELETE FROM TrackAcceptRejectProjectSegmentHistory WHERE ProjectId = @ProjectID
		DELETE FROM TrackProjectSegment WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentTab WHERE ProjectId = @ProjectID
		DELETE FROM MaterialSectionMapping WHERE ProjectId = @ProjectID
		DELETE FROM ProjectRevitFile WHERE ProjectId = @ProjectID
		DELETE FROM ProjectRevitFileMapping WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentTracking WHERE ProjectId = @ProjectID
		DELETE FROM HeaderFooterGlobalTermUsage WHERE ProjectId = @ProjectID
		DELETE FROM HeaderFooterReferenceStandardUsage WHERE ProjectId = @ProjectID
		DELETE FROM ProjectGlobalTerm WHERE ProjectId = @ProjectID
		DELETE FROM ProjectHyperLink WHERE ProjectId = @ProjectID
		DELETE FROM ProjectNoteImage WHERE ProjectId = @ProjectID
		DELETE FROM ProjectNote WHERE ProjectId = @ProjectID
		DELETE FROM ProjectReferenceStandard WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentGlobalTerm WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentImage WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentLink WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentReferenceStandard WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentRequirementTag WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentUserTag WHERE ProjectId = @ProjectID
		DELETE FROM UserGlobalTerm WHERE ProjectId = @ProjectID
		DELETE FROM Header WHERE ProjectId = @ProjectID
		DELETE FROM Footer WHERE ProjectId = @ProjectID
		DELETE FROM SelectedChoiceOption WHERE ProjectId = @ProjectID
		DELETE FROM ProjectChoiceOption WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentChoice WHERE ProjectId = @ProjectID
		DELETE FROM PROJECTSEGMENT WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSegmentStatus WHERE ProjectId = @ProjectID
		DELETE FROM PROJECTSECTION WHERE ProjectId = @ProjectID
		DELETE FROM ProjectSummary WHERE ProjectId = @ProjectID
		DELETE FROM UserFolder WHERE ProjectId = @ProjectID
		DELETE FROM ProjectAddress WHERE ProjectId = @ProjectID
		DELETE FROM UserProjectAccessMapping WHERE ProjectId = @ProjectID
		DELETE FROM LuProjectSectionIdSeparator WHERE ProjectId = @ProjectID
		DELETE FROM ProjectDateFormat WHERE ProjectId = @ProjectID
		DELETE FROM ProjectPageSetting WHERE ProjectId = @ProjectID
		DELETE FROM ProjectPaperSetting WHERE ProjectId = @ProjectID
		DELETE FROM ProjectPrintSetting WHERE ProjectId = @ProjectID
		DELETE FROM ProjectDisciplineSection WHERE ProjectId = @ProjectID
		DELETE FROM ProjectMigrationException WHERE ProjectId = @ProjectID
		DELETE FROM PROJECT WHERE ProjectId = @ProjectID

		INSERT INTO [dbo].[DeletedProjectLog] VALUES(GETDATE(),@ProjectID)

	END TRY
	BEGIN CATCH
			
		SET @ErrorStep = 'DeleteProject'

		SELECT @ErrorCode = ERROR_NUMBER()
			, @Return_Message = @ErrorStep + ' '
			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
			+ ERROR_MESSAGE() + ' > ' 
			+ ERROR_PROCEDURE()

		EXEC [DE_Projects_Staging].[dbo].[spb_LogErrors] @ProjectID, @ErrorCode, @ErrorStep, @Return_Message

    
	END CATCH

	UPDATE #tmpProjects SET IsProcessed = 1 WHERE RowID = @RowCount;

	SET @RowCount = @RowCount + 1
END

DROP TABLE #tmpProjects

END