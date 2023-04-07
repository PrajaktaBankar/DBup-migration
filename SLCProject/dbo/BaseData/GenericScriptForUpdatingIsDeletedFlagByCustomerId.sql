--Execute this on Server 3
--Customer Support 30217: Customer Omniplan continuing to have issues

DECLARE @CustomerId INT=1431;

 CREATE TABLE #tempProjectId (ProjectId INT,RowNo INT)
 ---insert customer projectId in #tempProjectId table
INSERT INTO #tempProjectId (ProjectId, RowNo)
	SELECT
		ProjectId
	   ,ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS RowNo
	FROM project WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND ISNULL(IsPermanentDeleted, 0) = 0

DECLARE @ProjectRowCount INT=( SELECT
		COUNT(ProjectId)
	FROM #tempProjectId)

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId_1 INT = ( SELECT
		ProjectId
	FROM #tempProjectId
	WHERE RowNo = @ProjectRowCount);

--insert into temp table from selectedChoiceOption 
SELECT
	* INTO #temp
FROM SelectedChoiceOption WITH (NOLOCK)
WHERE ProjectId IN (@ProjectId_1)
AND isdeleted = 1

--SELECT * from #temp

--select data from ProjectChoiceOption and ProjectSegmentChoice where isdeleted=0 and insert into #selectedchoicetemp
SELECT
	t.* INTO #selectedchoicetemp
FROM ProjectChoiceOption pco WITH (NOLOCK)
INNER JOIN #temp t
	ON t.ProjectId = pco.ProjectId
		AND t.CustomerId = pco.CustomerId
		AND t.SectionId = pco.SectionId
		AND t.ChoiceOptionCode = pco.ChoiceOptionCode
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
	ON pco.ProjectId = psc.ProjectId
		AND pco.CustomerId = psc.CustomerId
		AND pco.SectionId = psc.SectionId
		AND pco.SegmentChoiceId = psc.SegmentChoiceId
WHERE pco.IsDeleted = 0
AND psc.IsDeleted = 0
AND psc.ProjectId IN (@ProjectId_1)
ORDER BY t.ProjectId

--select * FROM #selectedchoicetemp

--(62 rows should affected) 
UPDATE B
SET IsDeleted = 0
FROM (SELECT
		SCO.*
	FROM SelectedChoiceOption SCO WITH (NOLOCK)
	INNER JOIN #selectedchoicetemp SCT
		ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId
	WHERE SCT.ProjectId IN (@ProjectId_1)) B

DROP TABLE IF EXISTS #temp
DROP TABLE IF EXISTS #selectedchoicetemp

SET @ProjectRowCount = @ProjectRowCount - 1;

END

DROP TABLE IF EXISTS #tempProjectId
