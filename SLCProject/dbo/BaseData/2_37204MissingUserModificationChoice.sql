/*
Customer Support 37204: SLC CH# issue
server :2

*/

DECLARE @CustomerId int =216
DECLARE @ProjectId int =5771

DROP TABLE IF EXISTS #tempInsertMissingUserModificationMissingChoices
 CREATE table #tempInsertMissingUserModificationMissingChoices(ProjectId Int,RowNo Int)

INSERT INTO #tempInsertMissingUserModificationMissingChoices (ProjectId, RowNo)
	SELECT  
		ProjectId
	   ,ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS RowNo
	FROM Project WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND ISNULL(IsPermanentDeleted, 0) = 0
	

DECLARE @ProjectRowCount int=( SELECT
		COUNT(ProjectId)
	FROM #tempInsertMissingUserModificationMissingChoices)

	SELECT *	FROM #tempInsertMissingUserModificationMissingChoices

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId1 INT =( SELECT
		ProjectId
	FROM #tempInsertMissingUserModificationMissingChoices
	WHERE RowNo = @ProjectRowCount);

IF (@ProjectId != 0)
BEGIN
SET @ProjectRowCount = 1
SET @ProjectId1 = @ProjectId
	end
	print cast(@ProjectId1 as nvarchar(50))+' Begin'
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
	PS.SectionId
   ,PS.SegmentDescription
   ,PS.ProjectId
   ,PS.SegmentSource
   ,PS.CustomerId
   ,PS.SegmentStatusId
   ,PS.SegmentId
   ,PS.ModifiedBy
   ,ROW_NUMBER() OVER (ORDER BY PS.SegmentStatusId ASC) AS RowId INTO #TempProjectSegmentStatusView
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.ProjectId = @ProjectId1
AND ISNULL(PS.IsDeleted, 0) = 0
AND PS.SegmentDescription LIKE '%{CH#%'
AND PS.SegmentDescription NOT LIKE '%{CH#{CH#%'
AND PS.SegmentStatusId IS NOT NULL


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
   ,@ModifiedBy = TPSSV.ModifiedBy

FROM #TempProjectSegmentStatusView TPSSV
WHERE RowId = @LoopCount;

INSERT INTO #ChoiceCodesInSegmnetDesc (ProjectId, SectionId, CustomerId, ChoiceCode, 
SegmentStatusId, SegmentId, ModifiedBy)
	SELECT
		@ProjectId1 AS ProjectId
	   ,@SectionId AS SectionId
	   ,@CustomerId AS CustomerId
	   ,Ids
	   ,@SegmentStatusId AS SegmentStatusId
	   ,@SegmentId AS SegmentId
	   ,@ModifiedBy AS ModifiedBy
	FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription, '{CH#')

SET @LoopCount = @LoopCount - 1;
END;

--Filter missing choices data from #TempProjectSegmentChoice
DROP TABLE IF EXISTS #TempProjectSegmentChoice1

SELECT DISTINCT
	CCIS.* INTO #TempProjectSegmentChoice1
FROM #ChoiceCodesInSegmnetDesc CCIS
LEFT OUTER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
	ON PSC.SegmentChoiceCode = CCIS.ChoiceCode
		AND PSC.ProjectId = CCIS.ProjectId
		AND CCIS.SectionId = PSC.SectionId
		AND CCIS.SegmentId = PSC.SegmentId
		AND CCIS.SegmentStatusId = PSC.SegmentStatusId
WHERE PSC.SegmentChoiceCode IS NULL

--Filter missing choices data from #TempProjectChoiceOption1

DROP TABLE IF EXISTS #TempProjectChoiceOption1

SELECT DISTINCT
	SortOrder
   ,OptionJson
   ,ChoiceOptionCode
   ,SC.CreateDate
   ,SC.ModifiedDate
   ,tblins.ProjectId
   ,tblins.SectionId
   ,tblins.CustomerId
   ,tblins.ChoiceCode
   ,tblins.SegmentStatusId
   ,tblins.SegmentId
   ,tblins.ModifiedBy INTO #TempProjectChoiceOption1
FROM #TempProjectSegmentChoice1 tblins
INNER JOIN SLCMaster..SegmentChoice SC WITH (NOLOCK)
	ON SC.SegmentChoiceCode = tblins.ChoiceCode
INNER JOIN SLCMaster..ChoiceOption SLCMCO WITH (NOLOCK)
	ON SC.SegmentChoiceId = SLCMCO.SegmentChoiceId

--Filter missing choices data from ##TempProjectSelectedChoiceOption

DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption1
SELECT DISTINCT
	CCIS.*
   ,SLCMSCO.ChoiceOptionCode
   ,SLCMSCO.IsSelected INTO #TempProjectSelectedChoiceOption1
FROM #TempProjectSegmentChoice1 CCIS
INNER JOIN SLCMaster..SegmentChoice SC WITH (NOLOCK)
	ON SC.SegmentChoiceCode = CCIS.ChoiceCode
INNER JOIN SLCMaster..ChoiceOption SLCMCO WITH (NOLOCK)
	ON SC.SegmentChoiceId = SLCMCO.SegmentChoiceId
INNER JOIN SLCMaster..SelectedChoiceOption SLCMSCO WITH (NOLOCK)
	ON SLCMSCO.SegmentChoiceCode = CCIS.ChoiceCode
		AND SLCMCO.ChoiceOptionCode = SLCMSCO.ChoiceOptionCode

--if missing data is present in filtered table then insert into original table from SLCMaster


IF ((SELECT
			COUNT(1) #TempProjectSegmentChoice1)
	> 0)
BEGIN
INSERT INTO ProjectSegmentChoice
	SELECT DISTINCT
		tblins.SectionId
	   ,tblins.SegmentStatusId
	   ,tblins.SegmentId
	   ,SMSC.ChoiceTypeId
	   ,tblins.ProjectId
	   ,tblins.CustomerId
	   ,'U' AS SegmentChoiceSource
	   ,tblins.ChoiceCode
	   ,tblins.ModifiedBy
	   ,GETUTCDATE() AS CreateDate
	   ,NULL AS ModifiedBy
	   ,NULL AS ModifiedDate
	   ,NULL AS SLE_DocID
	   ,NULL AS SLE_SegmentID
	   ,NULL AS SLE_StatusID
	   ,NULL AS SLE_ChoiceNo
	   ,SMSC.ChoiceTypeId
	   ,NULL AS A_SegmentChoiceId
	   ,0 AS IsDeleted

	FROM SLCMaster..SegmentChoice SMSC WITH (NOLOCK)
	INNER JOIN #TempProjectSegmentChoice1 tblins
		ON tblins.ChoiceCode = SMSC.SegmentChoiceCode
	WHERE tblins.ChoiceCode = SMSC.SegmentChoiceCode
END

--if missing data is present in filtered table then insert into original table from SLCMaster


IF ((SELECT
			COUNT(1)
		FROM #TempProjectChoiceOption1)
	> 0)
BEGIN
INSERT INTO ProjectChoiceOption
	SELECT DISTINCT
		PSC.SegmentChoiceId
	   ,tblins.SortOrder
	   ,'U' AS ChoiceOptionSource
	   ,tblins.OptionJson
	   ,PSC.ProjectId
	   ,PSC.SectionId
	   ,PSC.CustomerId
	   ,tblins.ChoiceOptionCode
	   ,PSC.CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,PSC.CreatedBy
	   ,NULL AS ModifiedDate
	   ,NULL AS A_ChoiceOptionId
	   ,0 AS IsDeleted
	FROM ProjectSegmentChoice PSC WITH (NOLOCK)
	INNER JOIN #TempProjectChoiceOption1 tblins WITH (NOLOCK)
		ON tblins.ChoiceCode = PSC.SegmentChoiceCode
			AND PSC.ProjectId = tblins.ProjectId
			AND PSC.SectionId = tblins.SectionId
			AND PSC.SegmentStatusId = tblins.SegmentStatusId
			AND PSC.SegmentId = tblins.SegmentId

END

--if missing data is present in filtered table then insert into original table from SLCMaster

IF ((SELECT
			COUNT(1) #TempProjectSelectedChoiceOption1)
	> 0)
BEGIN
INSERT INTO SelectedChoiceOption
	SELECT DISTINCT
		tblins.ChoiceCode
	   ,SCO.ChoiceOptionCode
	   ,'U' AS ChoiceOptionSource
	   ,SCO.IsSelected
	   ,tblins.SectionId
	   ,tblins.ProjectId
	   ,tblins.CustomerId AS CustomerId
	   ,NULL AS OptionJson
	   ,0 AS IsDeleted
	FROM SLCMaster..SelectedChoiceOption SCO WITH (NOLOCK)
	INNER JOIN #TempProjectSelectedChoiceOption1 tblins
		ON tblins.ChoiceCode = SCO.SegmentChoiceCode
	INNER JOIN #TempProjectChoiceOption1 tpco
		ON tpco.ChoiceOptionCode = SCO.ChoiceOptionCode
	WHERE tblins.ChoiceCode = SCO.SegmentChoiceCode
END


SET @ProjectRowCount = @ProjectRowCount - 1;

print @ProjectRowCount

print cast(@ProjectId1 as nvarchar(50))+' End'

 END