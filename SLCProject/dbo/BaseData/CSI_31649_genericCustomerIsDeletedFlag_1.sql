--Customer Support 31649: CH# Errors
--Execute this on Server 2 

--NOTE:Please Read Below note before execute this script
--Update isDeleted flag all project for one customer 
--NOTE :If you want to run this script for selected project then assign Project Id to below ProjectId Parameter,
		--If you want to run this scripts for all project of selected customer then make ProjectId Property as 0

DECLARE @CustomerId int =1663
DECLARE @ProjectId int =5057

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

IF(@ProjectId !=0)
	begin
	set @ProjectRowCount=1
	set @ProjectId_1= @ProjectId
	end

--insert into temp table from selectedChoiceOption 
DROP TABLE IF EXISTS  #temp
 
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
AND psc.SegmentChoiceSource='U'
AND pco.ChoiceOptionSource='U'
ORDER BY t.ProjectId

--(62 rows should affected) 
UPDATE B
SET IsDeleted = 0
FROM (SELECT
		SCO.*
	FROM SelectedChoiceOption SCO WITH (NOLOCK)
	INNER JOIN #selectedchoicetemp SCT
		ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId and SCO.ChoiceOptionSource='U'
	WHERE SCT.ProjectId IN (@ProjectId_1)) B

DROP TABLE IF EXISTS #temp
DROP TABLE IF EXISTS #selectedchoicetemp

SET @ProjectRowCount = @ProjectRowCount - 1;

END

DROP TABLE IF EXISTS #tempProjectId

