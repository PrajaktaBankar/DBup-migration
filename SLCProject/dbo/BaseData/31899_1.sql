USE SLCProject
GO
--Customer Support 31899: Missing choices in print - - 29449 Steve Oliver with Powers Brown Architecture Holdings, Inc. - 29449
--EXECUTE On server 2


--NOTE:Please Read Below note before execute this script
--Update isDeleted flag all project for one customer 
--NOTE :If you want to run this script for selected project then assign Project Id to below ProjectId Parameter,
		--If you want to run this scripts for all project of selected customer then make ProjectId Property as 0

DECLARE @CustomerId int =1663
DECLARE @ProjectId int =5055

DROP TABLE IF EXISTS #tempUpdateIsDeletedProjectId

 CREATE  TABLE #tempUpdateIsDeletedProjectId (ProjectId INT,RowNo INT)
---insert customer projectId in #tempProjectId table
INSERT INTO #tempUpdateIsDeletedProjectId (ProjectId, RowNo)
	SELECT
		ProjectId
	   ,ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS RowNo
	FROM project WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND ISNULL(IsPermanentDeleted, 0) = 0

DECLARE @ProjectRowCount INT=( SELECT
		COUNT(ProjectId)
	FROM #tempUpdateIsDeletedProjectId)


WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId_1 INT = ( SELECT
		ProjectId
	FROM #tempUpdateIsDeletedProjectId
	WHERE RowNo = @ProjectRowCount);

--insert into temp table from selectedChoiceOption 

IF(@ProjectId !=0)
	begin
	set @ProjectRowCount=1
	set @ProjectId_1= @ProjectId1
	end

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
	ON t.SectionId = pco.SectionId
		AND t.CustomerId = pco.CustomerId
		AND t.ProjectId = pco.ProjectId
		AND t.ChoiceOptionCode = pco.ChoiceOptionCode
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
	ON  pco.SegmentChoiceId = psc.SegmentChoiceId
		AND pco.SectionId = psc.SectionId
		AND pco.CustomerId = psc.CustomerId
		AND pco.ProjectId = psc.ProjectId
		AND psc.SegmentChoiceSource = pco.ChoiceOptionSource
WHERE psc.ProjectId IN (@ProjectId_1)
AND psc.IsDeleted = 0
AND pco.IsDeleted = 0
AND psc.SegmentChoiceSource = 'U'
ORDER BY t.ProjectId

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

END



DROP TABLE IF EXISTS #tempProjectId

