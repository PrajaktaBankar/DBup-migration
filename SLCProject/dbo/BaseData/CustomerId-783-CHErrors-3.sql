use SLCProject
go

--Customer: 783 CH# Errors
--EXECUTE On server 3

DECLARE @CustomerId int =783
DECLARE @ProjectId int =0

DROP TABLE IF EXISTS #tempInsertMissingMasterChoices

  CREATE table #tempInsertMissingMasterChoices (ProjectId Int,RowNo Int)

INSERT INTO #tempInsertMissingMasterChoices (ProjectId, RowNo)
	SELECT  
		ProjectId
	   ,ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS RowNo
	FROM Project WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND ISNULL(IsPermanentDeleted, 0) = 0

DECLARE @ProjectRowCount int=( SELECT
		COUNT(ProjectId)
	FROM #tempInsertMissingMasterChoices)

SELECT  * 	FROM #tempInsertMissingMasterChoices	

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId1 INT = ( SELECT
		ProjectId
	FROM #tempInsertMissingMasterChoices
	WHERE RowNo = @ProjectRowCount);


IF (@ProjectId1 != 0)
BEGIN
SET @ProjectRowCount = 1
SET @ProjectId = @ProjectId1
	end

	print cast(@ProjectId as nvarchar(50))+' Begin'

--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (
	ProjectId INT
   ,SectionId INT
   ,CustomerId INT
   ,ChoiceCode INT
   ,SegmentStatusId INT
   ,SegmentId INT
   ,ModifiedBy INT
);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT
	PSSV.SectionId
   ,PSSV.SegmentDescription
   ,PSSV.ProjectId
   ,PSSV.SegmentOrigin
   ,PSSV.CustomerId
   ,PSSV.SegmentStatusId
   ,PSSV.SegmentId
   ,ROW_NUMBER() OVER (ORDER BY PSSV.SegmentStatusId ASC) AS RowId INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH (NOLOCK)
WHERE PSSV.ProjectId = @ProjectId
AND ISNULL(PSSV.IsDeleted, 0) = 0
AND PSSV.SegmentSource = 'M'
AND PSSV.SegmentDescription LIKE '%{CH#%'

--Insert choices data in SelectedChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption;
SELECT
	SegmentChoiceCode
   ,ProjectId
   ,CustomerId
   ,SectionId INTO #TempProjectSelectedChoiceOption
FROM SelectedChoiceOption SCO WITH (NOLOCK)
WHERE SCO.ProjectId = @ProjectId
AND SCO.ChoiceOptionSource = 'M'

--Fetch choice code from SegmentDescription
DECLARE @LoopCount INT = (SELECT
		COUNT(1) AS TotalRows
	FROM #TempProjectSegmentStatusView)

DECLARE @SegmentDescription NVARCHAR(MAX) = '';
DECLARE @SectionId INT = 0;
DECLARE @SegmentStatusId INT = 0;
DECLARE @SegmentId INT = 0;
DECLARE @ModifiedBy INT = 0;
WHILE @LoopCount > 0
BEGIN
SELECT
	@SegmentDescription = TPSSV.SegmentDescription
   ,@SectionId = TPSSV.SectionId
   ,@CustomerId = TPSSV.CustomerId
   ,@SegmentStatusId = TPSSV.SegmentStatusId
   ,@SegmentId = TPSSV.SegmentId

FROM #TempProjectSegmentStatusView TPSSV
WHERE RowId = @LoopCount;

INSERT INTO #ChoiceCodesInSegmnetDesc (ProjectId, SectionId, CustomerId, ChoiceCode,
 SegmentStatusId, SegmentId)
	SELECT
		@ProjectId AS ProjectId
	   ,@SectionId AS SectionId
	   ,@CustomerId AS CustomerId
	   ,Ids
	   ,@SegmentStatusId AS SegmentStatusId
	   ,@SegmentId AS SegmentId
	FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription, '{CH#')

SET @LoopCount = @LoopCount - 1;
END;


--Filter missing choices data from ##TempProjectSelectedChoiceOption
DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption1
SELECT
	CCIS.* INTO #TempProjectSelectedChoiceOption1
FROM #ChoiceCodesInSegmnetDesc CCIS
LEFT OUTER JOIN #TempProjectSelectedChoiceOption TPSCO
	ON CCIS.SectionId = TPSCO.SectionId
		AND TPSCO.ProjectId = CCIS.ProjectId
		AND CCIS.CustomerId = TPSCO.CustomerId
		AND TPSCO.SegmentChoiceCode = CCIS.ChoiceCode
WHERE TPSCO.SegmentChoiceCode IS NULL


--if missing data is present in filtered table then insert into original table from SLCMaster

IF ((SELECT
			COUNT(1) #TempProjectSelectedChoiceOption1)
	> 0)
BEGIN
INSERT INTO SelectedChoiceOption
	SELECT
		tblins.ChoiceCode
	   ,SCO.ChoiceOptionCode
	   ,'M' AS ChoiceOptionSource
	   ,SCO.IsSelected
	   ,tblins.SectionId
	   ,tblins.ProjectId
	   ,tblins.CustomerId AS CustomerId
	   ,NULL AS OptionJson
	   ,0 AS IsDeleted
	FROM SLCMaster..SegmentChoice sc WITH (NOLOCK)
	INNER JOIN SLCMaster..SelectedChoiceOption SCO WITH (NOLOCK)
		ON sco.Sectionid = sc.SectionId
			AND sc.SegmentChoiceCode = SCO.SegmentChoiceCode
	INNER JOIN SLCMaster.dbo.ChoiceOption co WITH (NOLOCK)
		ON co.ChoiceOptionCode = SCO.ChoiceOptionCode
			AND SCO.SegmentChoiceCode = sc.SegmentChoiceCode
			AND sc.SegmentChoiceId = co.SegmentChoiceId
	INNER JOIN #TempProjectSelectedChoiceOption1 tblins
		ON tblins.ChoiceCode = SCO.SegmentChoiceCode
	WHERE tblins.ChoiceCode = sc.SegmentChoiceCode

END

SET @ProjectRowCount = @ProjectRowCount - 1;
print @ProjectRowCount

print cast(@ProjectId as nvarchar(50))+' End'

 END

