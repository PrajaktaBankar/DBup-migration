use SLCProject_SqlSlcOp003
go

--Customer Support 32911: SLC Choice Code {CH#} Issue
--EXECUTE On server 3

DECLARE @CustomerId int =554
DECLARE @ProjectId int =1825

DROP TABLE IF EXISTS #tempUpdateIsDeletedProjectId

 CREATE  TABLE #tempUpdateIsDeletedProjectId (ProjectId INT,RowNo INT)
---insert customer projectId in #tempProjectId table
INSERT INTO #tempUpdateIsDeletedProjectId (ProjectId, RowNo)
SELECT  
		ProjectId
	   ,ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS RowNo
	FROM Project WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND ISNULL(IsPermanentDeleted, 0) = 0

DECLARE @ProjectRowCount INT=( SELECT
		COUNT(ProjectId)
	FROM #tempUpdateIsDeletedProjectId)

	SELECT * FROM #tempUpdateIsDeletedProjectId ORDER BY RowNo DESC

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId_1 INT = ( SELECT
		ProjectId
	FROM #tempUpdateIsDeletedProjectId
	WHERE RowNo = @ProjectRowCount);

IF (@ProjectId != 0)
BEGIN
SET @ProjectId_1 = @ProjectId
SET @ProjectRowCount = 1
	END

	print cast(@ProjectId_1 as nvarchar(50))+' Begin'
--insert into temp table from selectedChoiceOption 
drop TABLE IF EXISTS #temp
SELECT
	* INTO #temp
FROM SelectedChoiceOption WITH (NOLOCK)
WHERE ProjectId IN (@ProjectId_1)
AND isdeleted = 1

--SELECT * from #temp

--select data from ProjectChoiceOption and ProjectSegmentChoice 
--where isdeleted=0 and insert into #selectedchoicetemp
DROP TABLE IF EXISTS #selectedchoicetemp
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
AND psc.SegmentChoiceSource = 'U'
AND pco.ChoiceOptionSource = 'U'
ORDER BY t.ProjectId

---Delete Dupicate records
DELETE A
	FROM (SELECT
			*
		   ,ROW_NUMBER() OVER (PARTITION BY SegmentChoiceCode, ChoiceOptionCode
			, ChoiceOptionSource, SectionId, ProjectId, CustomerId 
			ORDER BY SelectedChoiceOptionId) AS RowNo
		FROM SelectedChoiceOption WITH (NOLOCK)
		WHERE CustomerId = @CustomerId
		AND ChoiceOptionSource = 'U'
		AND ProjectId = @ProjectId_1) AS A
WHERE A.RowNo > 1

--Insert choice data which is not in SelectedChoiceOption 
--but available in ProjectSegmentChoice and ProjectChoiceOption and which that IsDeleted flag is false.
INSERT INTO SelectedChoiceOption
	SELECT
		psc.SegmentChoiceCode
	   ,pco.ChoiceOptionCode
	   ,pco.ChoiceOptionSource
	   ,slcmsco.IsSelected
	   ,psc.SectionId
	   ,psc.ProjectId
	   ,pco.CustomerId
	   ,NULL AS OptionJson
	   ,0 AS IsDeleted
	FROM ProjectSegmentChoice psc WITH (NOLOCK)
	INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
		ON pco.SegmentChoiceId = psc.SegmentChoiceId
			AND pco.SectionId = psc.SectionId
			AND pco.ProjectId = psc.ProjectId
			AND pco.CustomerId = psc.CustomerId
	LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK)
		ON pco.ChoiceOptionCode = sco.ChoiceOptionCode
			AND pco.SectionId = sco.SectionId
			AND pco.ProjectId = sco.ProjectId
			AND pco.CustomerId = sco.CustomerId
			AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
	INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK)
		ON slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode
	WHERE sco.SelectedChoiceOptionId IS NULL
	AND pco.CustomerId = @CustomerId
	AND pco.ProjectId = @ProjectId_1
	AND ISNULL(pco.IsDeleted, 0) = 0
	AND ISNULL(psc.IsDeleted, 0) = 0



UPDATE B
SET IsDeleted = 0
FROM (SELECT
		SCO.*
	FROM SelectedChoiceOption SCO WITH (NOLOCK)
	INNER JOIN #selectedchoicetemp SCT
		ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId
		AND SCO.ChoiceOptionSource = 'U'
	WHERE SCT.ProjectId IN (@ProjectId_1)) B

DROP TABLE IF EXISTS #temp
DROP TABLE IF EXISTS #selectedchoicetemp

SET @ProjectRowCount = @ProjectRowCount - 1;

print @ProjectRowCount

print cast(@ProjectId_1 as nvarchar(50))+' End'

END

DROP TABLE IF EXISTS #tempProjectId

