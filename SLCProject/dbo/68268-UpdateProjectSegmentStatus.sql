/*
Customer Support 68268: Duplicate sections and paragraphs (BC Group) (Admin ID: 1319)

server:3

description:
2 times entry happen in projectsegmentstatus

*/

DECLARE @ProjectId INT = 10939;
DECLARE @CustomerId INT = 1319;


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

--inserted duplicate records in Temp  table which count is greater than 1

INSERT INTO #MaxSegmentStatus 
(ProjectId, CustomerId, SectionId, SequenceNumber, IndentLevel, DuplicateCount, MaxSegmentStatusId)
	SELECT
		PS.ProjectId
	   ,PS.CustomerId
	   ,PS.SectionId
	   ,PSST.SequenceNumber
	   ,PSST.IndentLevel
	   ,COUNT(*) AS DuplicateCount
	   ,MIN(PSST.SegmentStatusId) AS MaxSegmentStatusId
	FROM ProjectSection PS WITH (NOLOCK) 
	INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK) 
		ON PS.SectionId = PSST.SectionId
	WHERE PS.CustomerId = @CustomerId
	AND PS.ProjectId = @ProjectId
	AND PS.SectionId in(11481588,11481587)
	AND PS.IsDeleted = 0
	GROUP BY PS.ProjectId
			,PS.CustomerId
			,PS.SectionId
			,PSST.SequenceNumber
			,PSST.IndentLevel
	HAVING COUNT(*) > 1
	ORDER BY PS.ProjectId, PS.CustomerId, PS.SectionId, PSST.SequenceNumber, PSST.IndentLevel




	--update ProjectSegmentStatus isdeleted =1 for duplicates
UPDATE PSST
SET PSST.IsDeleted = 1
FROM ProjectSegmentStatus PSST WITH (NOLOCK) 
INNER JOIN #MaxSegmentStatus MSS WITH (NOLOCK) 
	ON PSST.ProjectId = MSS.ProjectId
	AND PSST.CustomerId = MSS.CustomerId
	AND PSST.SectionId = MSS.SectionId
	AND PSST.SequenceNumber = MSS.SequenceNumber
	AND PSST.IndentLevel = MSS.IndentLevel
LEFT JOIN #MaxSegmentStatus MSS_MAX WITH (NOLOCK) 
	ON PSST.ProjectId = MSS_MAX.ProjectId
	AND PSST.CustomerId = MSS_MAX.CustomerId
	AND PSST.SectionId = MSS_MAX.SectionId
	AND PSST.SequenceNumber = MSS_MAX.SequenceNumber
	AND PSST.IndentLevel = MSS_MAX.IndentLevel
	AND PSST.SegmentStatusId = MSS_MAX.MaxSegmentStatusId
WHERE MSS_MAX.MaxSegmentStatusId IS NULL



