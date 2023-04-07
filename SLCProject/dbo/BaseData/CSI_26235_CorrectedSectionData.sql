USE SLCProject
GO

--NOTE: Script to correct wrong sequence numbers of section to correct one

DECLARE @CustomerId INT = 509;

DROP TABLE IF EXISTS #tmp_SegmentStatus;
CREATE TABLE #tmp_SegmentStatus(
	ProjectId INT,
	CustomerId INT,
	SectionId INT,
	SegmentStatusId INT,
	ParentSegmentStatusId INT,
	SequenceNumber DECIMAL(18,4),
	IndentLevel TINYINT
);

DROP TABLE IF EXISTS #tmp_SeqCorruptSections;
CREATE TABLE #tmp_SeqCorruptSections(
	RowId INT,
	ProjectId INT,
	CustomerId INT,
	SectionId INT,
	SourceTag NVARCHAR(100)
);

DROP TABLE IF EXISTS #tmp_InCorrectSegmentStatus;
CREATE TABLE #tmp_InCorrectSegmentStatus(
	RowId INT,
	ProjectId INT,
	CustomerId INT,
	SectionId INT,
	SegmentStatusId INT,
	ParentSegmentStatusId INT,
	SequenceNumber DECIMAL(18,4)
);

--GET TEMP SEGMENT STATUS OF CUSTOMER TO USE IN SUB SEQUENT JOINS
DELETE FROM #tmp_SegmentStatus;
INSERT INTO #tmp_SegmentStatus (ProjectId, CustomerId, SectionId)
	SELECT
		PSST.ProjectId
	   ,PSST.CustomerId
	   ,PSST.SectionId
	FROM ProjectSegmentStatus PSST
	WHERE PSST.CustomerId = @CustomerId
	AND PSST.IndentLevel = 0
	AND PSST.ParentSegmentStatusId = 0
	AND PSST.SequenceNumber >= 1;

--FIND CORRUPTED SECTIONS TO CORRECT THEIR DATA
INSERT INTO #tmp_SeqCorruptSections (RowId, ProjectId, CustomerId, SectionId, SourceTag)
	SELECT DISTINCT
		ROW_NUMBER() OVER (ORDER BY PS.SectionId) AS RowId
	   ,P.ProjectId
	   ,P.CustomerId
	   ,PS.SectionId
	   ,PS.SourceTag
	FROM Project P
	INNER JOIN ProjectSection PS
		ON P.ProjectId = PS.ProjectId
			AND PS.IsLastLevel = 1
			AND PS.IsDeleted = 0
	INNER JOIN #tmp_SegmentStatus PSST
		ON PS.SectionId = PSST.SectionId
	WHERE P.CustomerId = @CustomerId
	--AND P.ProjectId = 0
	AND P.IsDeleted = 0;

--LOOP CORRUPTED SECTIONS ONE BY ONE
DECLARE @SectionLoopCnt INT = 1;
WHILE(@SectionLoopCnt <= ( SELECT
		COUNT(*)
	FROM #tmp_SeqCorruptSections)
)
BEGIN
DECLARE @LoopedSectionId INT = (SELECT
		SectionId
	FROM #tmp_SeqCorruptSections
	WHERE RowId = @SectionLoopCnt);

--GET TEMP SEGMENT STATUS OF CUSTOMER TO USE IN SUB SEQUENT JOINS
DELETE FROM #tmp_SegmentStatus;
INSERT INTO #tmp_SegmentStatus (ProjectId, CustomerId, SectionId, SegmentStatusId, ParentSegmentStatusId, SequenceNumber, IndentLevel)
	SELECT
		PSST.ProjectId
	   ,PSST.CustomerId
	   ,PSST.SectionId
	   ,PSST.SegmentStatusId
	   ,PSST.ParentSegmentStatusId
	   ,PSST.SequenceNumber
	   ,PSST.IndentLevel
	FROM ProjectSegmentStatus PSST
	WHERE PSST.SectionId = @LoopedSectionId;

--FIND BASE SEGMENT STATUS SEQ NUMBER
DECLARE @BaseSegStatusSeqNumber DECIMAL(18, 4) = (SELECT TOP 1
		SequenceNumber
	FROM #tmp_SegmentStatus
	WHERE SectionId = @LoopedSectionId
	AND ParentSegmentStatusId = 0
	AND IndentLevel = 0);

--INSERT CORRUPTED SEGMENT STATUS OF LOOPED SECTION NOW
TRUNCATE TABLE #tmp_InCorrectSegmentStatus;
INSERT INTO #tmp_InCorrectSegmentStatus (RowId, ProjectId, CustomerId, SectionId, SegmentStatusId, ParentSegmentStatusId, SequenceNumber)
	SELECT
		ROW_NUMBER() OVER (ORDER BY PSST.SequenceNumber) AS RowId
	   ,PSST.ProjectId
	   ,PSST.CustomerId
	   ,PSST.SectionId
	   ,PSST.SegmentStatusId
	   ,PSST.ParentSegmentStatusId
	   ,PSST.SequenceNumber
	FROM #tmp_SegmentStatus PSST
	WHERE PSST.SectionId = @LoopedSectionId
	AND PSST.SequenceNumber < @BaseSegStatusSeqNumber
	ORDER BY PSST.SequenceNumber ASC;

--LOOP CORRUPTED SEGMENT STATUS ONE BY ONE TO CORRECT THEM
DECLARE @SegmentStatusLoopCnt INT = 1;
WHILE (@SegmentStatusLoopCnt <= (SELECT
		COUNT(*)
	FROM #tmp_InCorrectSegmentStatus)
)
BEGIN
DECLARE @LoopedSegmentStatusId INT = NULL;
DECLARE @LoopedParentSegmentStatusId INT = NULL;

SELECT
	@LoopedSegmentStatusId = SegmentStatusId
   ,@LoopedParentSegmentStatusId = ParentSegmentStatusId
FROM #tmp_InCorrectSegmentStatus
WHERE RowId = @SegmentStatusLoopCnt;

/* BLOCK TO FIND NEAREST SEQUENCE NUMBER */
BEGIN
DECLARE @NearSeqNumber DECIMAL(18, 4) = NULL;
DECLARE @NearSegStatus INT = NULL;
SELECT
	@NearSegStatus = PSST.SegmentStatusId
   ,@NearSeqNumber = PSST.SequenceNumber
FROM #tmp_SegmentStatus PSST
WHERE PSST.SegmentStatusId = @LoopedParentSegmentStatusId;

WHILE ((SELECT TOP 1
		PSST.SegmentStatusId
	FROM #tmp_SegmentStatus PSST
	WHERE PSST.ParentSegmentStatusId = @NearSegStatus
	AND PSST.SequenceNumber > @BaseSegStatusSeqNumber)
IS NOT NULL)
BEGIN
SELECT TOP 1
	@NearSegStatus = PSST.SegmentStatusId
   ,@NearSeqNumber = PSST.SequenceNumber
FROM #tmp_SegmentStatus PSST
WHERE PSST.ParentSegmentStatusId = @NearSegStatus
AND PSST.SequenceNumber > @BaseSegStatusSeqNumber
ORDER BY PSST.SequenceNumber DESC
END
END

--UPDATE NEW SEQUENCE NUMBER IN TEMP TABLE FOR SEGMENT STATUS
UPDATE #tmp_SegmentStatus
SET SequenceNumber = @NearSeqNumber + 0.1
WHERE SegmentStatusId = @LoopedSegmentStatusId;

SET @SegmentStatusLoopCnt = @SegmentStatusLoopCnt + 1;
END

--UPDATE CORRECT SEQUENCE NUMBER'S TO ALL SEGMENT STATUS OF THIS SECTION STARTING FROM 0
UPDATE TMP
SET TMP.SequenceNumber = X.NewSequenceNumber - 1
FROM #tmp_SegmentStatus TMP
INNER JOIN (SELECT
		TMP.SegmentStatusId
	   ,ROW_NUMBER() OVER (ORDER BY TMP.SequenceNumber ASC) AS NewSequenceNumber
	FROM #tmp_SegmentStatus TMP) AS X
	ON TMP.SegmentStatusId = X.SegmentStatusId

--UPDATE IN ORIGINAL TABLE
UPDATE PSST
SET PSST.SequenceNumber = TMP.SequenceNumber
FROM #tmp_SegmentStatus TMP
INNER JOIN ProjectSegmentStatus PSST
	ON TMP.SegmentStatusId = PSST.SegmentStatusId;

SET @SectionLoopCnt = @SectionLoopCnt + 1;
END