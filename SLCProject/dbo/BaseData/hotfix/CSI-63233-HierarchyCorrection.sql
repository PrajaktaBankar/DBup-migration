use SLCProject
/*
Server - Execute on server 004
Customer Support 63233: Paragraphs not turning on in one section in Office Master - 21628
*/
GO


DECLARE @SectionId INT = 14110112;

DROP TABLE IF EXISTS #IndentLevelWiseParentIds;
CREATE TABLE #IndentLevelWiseParentIds(
 IndentLevel INT,
 ParentSegmentStatusId BIGINT);

INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (1,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (2,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (3,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (4,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (5,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (6,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (7,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (8,-1);

DROP TABLE IF EXISTS #tempSectionPSS;

SELECT ROW_NUMBER() over(ORDER BY PSS.SequenceNumber) AS RowId, PSS.SegmentStatusId , PSS.ParentSegmentStatusId,
 PSS.IndentLevel, PSS.SequenceNumber, -1 AS NewPSegmentStatusId INTO #tempSectionPSS
FROM ProjectSegmentStatus PSS WITH(NOLOCK) where PSS.SectionId = @SectionId and ISNULL(PSS.IsDeleted,0) =0 order by SequenceNumber;


DECLARE @Cntr INT = 2;
DECLARE @RowCnt INT = (SELECT COUNT(*)-1 FROM #tempSectionPSS);
DECLARE @tPSegStatusId INT = (SELECT SegmentStatusId FROM #tempSectionPSS WHERE SequenceNumber = 0)
UPDATE #IndentLevelWiseParentIds SET ParentSegmentStatusId = @tPSegStatusId WHERE IndentLevel = 1;

DECLARE @CurrIndtLevel INT, @CurrSSId BIGINT, @CurrPrntSSId BIGINT, @expctPrntSSId BIGINT;

WHILE(@Cntr <= @RowCnt)
BEGIN
	SELECT @CurrIndtLevel = IndentLevel, @CurrSSId = SegmentStatusId, @CurrPrntSSId = ParentSegmentStatusId FROM #tempSectionPSS WHERE RowId = @Cntr;
	SELECT @expctPrntSSId = ParentSegmentStatusId FROM #IndentLevelWiseParentIds WHERE IndentLevel = @CurrIndtLevel;
	IF(@CurrPrntSSId <> @expctPrntSSId)
		UPDATE #tempSectionPSS SET NewPSegmentStatusId = @expctPrntSSId WHERE RowId = @Cntr;
	IF(@CurrIndtLevel <=8)
		UPDATE #IndentLevelWiseParentIds SET ParentSegmentStatusId = @CurrSSId WHERE IndentLevel = (@CurrIndtLevel+1);

	SET @Cntr = @Cntr+1;
END;

-- CHECK IF INDENT LEVELS NEED TO BE CORRECTED
SET @Cntr = (SELECT COUNT(1) FROM #tempSectionPSS WHERE NewPSegmentStatusId >-1);
IF(@Cntr > 0)
BEGIN
	SELECT 'Updating ParentSegmentStatusId of ' + CAST(@Cntr AS NVARCHAR(20)) + ' segments...' AS [Action];

	UPDATE PSS SET PSS.ParentSegmentStatusId = tPSS.NewPSegmentStatusId FROM ProjectSegmentStatus PSS WITH(NOLOCK) INNER JOIN #tempSectionPSS tPSS
	ON PSS.SegmentStatusId = tPSS.SegmentStatusId WHERE PSS.SectionId = @SectionId AND tPSS.NewPSegmentStatusId <> -1;
 
	SELECT SegmentStatusId, ParentSegmentStatusId AS OldParentSSId, NewPSegmentStatusId AS NewParentSSIT from #tempSectionPSS WHERE NewPSegmentStatusId <> -1 ORDER BY RowId;
END
ELSE
	SELECT 'Parent-Child relationship for this section (SectionId - '+ CAST(@SectionId AS NVARCHAR(15)) +') is correct' AS Result;

-------------------------------------------------------------------------
GO
-------------------------------------------------------------------------

DECLARE @SectionId INT = 25991400;

DROP TABLE IF EXISTS #IndentLevelWiseParentIds;
CREATE TABLE #IndentLevelWiseParentIds(
 IndentLevel INT,
 ParentSegmentStatusId BIGINT);

INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (1,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (2,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (3,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (4,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (5,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (6,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (7,-1);
INSERT INTO #IndentLevelWiseParentIds(IndentLevel,ParentSegmentStatusId) VALUES (8,-1);

DROP TABLE IF EXISTS #tempSectionPSS;

SELECT ROW_NUMBER() over(ORDER BY PSS.SequenceNumber) AS RowId, PSS.SegmentStatusId , PSS.ParentSegmentStatusId,
 PSS.IndentLevel, PSS.SequenceNumber, -1 AS NewPSegmentStatusId INTO #tempSectionPSS
FROM ProjectSegmentStatus PSS WITH(NOLOCK) where PSS.SectionId = @SectionId and ISNULL(PSS.IsDeleted,0) =0 order by SequenceNumber;


DECLARE @Cntr INT = 2;
DECLARE @RowCnt INT = (SELECT COUNT(*)-1 FROM #tempSectionPSS);
DECLARE @tPSegStatusId INT = (SELECT SegmentStatusId FROM #tempSectionPSS WHERE SequenceNumber = 0)
UPDATE #IndentLevelWiseParentIds SET ParentSegmentStatusId = @tPSegStatusId WHERE IndentLevel = 1;

DECLARE @CurrIndtLevel INT, @CurrSSId BIGINT, @CurrPrntSSId BIGINT, @expctPrntSSId BIGINT;

WHILE(@Cntr <= @RowCnt)
BEGIN
	SELECT @CurrIndtLevel = IndentLevel, @CurrSSId = SegmentStatusId, @CurrPrntSSId = ParentSegmentStatusId FROM #tempSectionPSS WHERE RowId = @Cntr;
	SELECT @expctPrntSSId = ParentSegmentStatusId FROM #IndentLevelWiseParentIds WHERE IndentLevel = @CurrIndtLevel;
	IF(@CurrPrntSSId <> @expctPrntSSId)
		UPDATE #tempSectionPSS SET NewPSegmentStatusId = @expctPrntSSId WHERE RowId = @Cntr;
	IF(@CurrIndtLevel <=8)
		UPDATE #IndentLevelWiseParentIds SET ParentSegmentStatusId = @CurrSSId WHERE IndentLevel = (@CurrIndtLevel+1);

	SET @Cntr = @Cntr+1;
END;

-- CHECK IF INDENT LEVELS NEED TO BE CORRECTED
SET @Cntr = (SELECT COUNT(1) FROM #tempSectionPSS WHERE NewPSegmentStatusId >-1);
IF(@Cntr > 0)
BEGIN
	SELECT 'Updating ParentSegmentStatusId of ' + CAST(@Cntr AS NVARCHAR(20)) + ' segments...' AS [Action];

	UPDATE PSS SET PSS.ParentSegmentStatusId = tPSS.NewPSegmentStatusId FROM ProjectSegmentStatus PSS WITH(NOLOCK) INNER JOIN #tempSectionPSS tPSS
	ON PSS.SegmentStatusId = tPSS.SegmentStatusId WHERE PSS.SectionId = @SectionId AND tPSS.NewPSegmentStatusId <> -1;
 
	SELECT SegmentStatusId, ParentSegmentStatusId AS OldParentSSId, NewPSegmentStatusId AS NewParentSSIT from #tempSectionPSS WHERE NewPSegmentStatusId <> -1 ORDER BY RowId;
END
ELSE
	SELECT 'Parent-Child relationship for this section (SectionId - '+ CAST(@SectionId AS NVARCHAR(15)) +') is correct' AS Result;

