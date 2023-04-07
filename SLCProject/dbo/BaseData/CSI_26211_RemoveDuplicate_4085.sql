USE SLCProject
GO


DECLARE @ProjectId INT = 4085;
DECLARE @CustomerId INT = 1922;

DROP TABLE IF EXISTS #MaxSegmentStatus;
CREATE TABLE #MaxSegmentStatus(
ProjectId INT,
CustomerId INT,
SectionId INT,
SequenceNumber DECIMAL(18,4),
IndentLevel INT,
DuplicateCount INT,
MaxSegmentStatusId INT
);

INSERT INTO #MaxSegmentStatus (ProjectId, CustomerId, SectionId, SequenceNumber, IndentLevel, DuplicateCount, MaxSegmentStatusId)
	SELECT
		PS.ProjectId
	   ,PS.CustomerId
	   ,PS.SectionId
	   ,PSST.SequenceNumber
	   ,PSST.IndentLevel
	   ,COUNT(*) AS DuplicateCount
	   ,MAX(PSST.SegmentStatusId) AS MaxSegmentStatusId
	FROM ProjectSection PS
	INNER JOIN ProjectSegmentStatus PSST
		ON PS.SectionId = PSST.SectionId
	WHERE PS.CustomerId = @CustomerId
	AND PS.ProjectId = @ProjectId
	AND PS.IsDeleted = 0
	GROUP BY PS.ProjectId
			,PS.CustomerId
			,PS.SectionId
			,PSST.SequenceNumber
			,PSST.IndentLevel
	HAVING COUNT(*) > 1
	ORDER BY PS.ProjectId, PS.CustomerId, PS.SectionId, PSST.SequenceNumber, PSST.IndentLevel

UPDATE PSST
SET PSST.IsDeleted = 1
FROM ProjectSegmentStatus PSST
INNER JOIN #MaxSegmentStatus MSS
	ON PSST.ProjectId = MSS.ProjectId
	AND PSST.CustomerId = MSS.CustomerId
	AND PSST.SectionId = MSS.SectionId
	AND PSST.SequenceNumber = MSS.SequenceNumber
	AND PSST.IndentLevel = MSS.IndentLevel
LEFT JOIN #MaxSegmentStatus MSS_MAX
	ON PSST.ProjectId = MSS_MAX.ProjectId
	AND PSST.CustomerId = MSS_MAX.CustomerId
	AND PSST.SectionId = MSS_MAX.SectionId
	AND PSST.SequenceNumber = MSS_MAX.SequenceNumber
	AND PSST.IndentLevel = MSS_MAX.IndentLevel
	AND PSST.SegmentStatusId = MSS_MAX.MaxSegmentStatusId
WHERE MSS_MAX.MaxSegmentStatusId IS NULL;