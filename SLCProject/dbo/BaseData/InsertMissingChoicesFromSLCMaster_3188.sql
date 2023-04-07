
--Scenario : Data is Missing For Master Segment
--Customer Support 30056: SLC - [CH#] Errors Issue - PPL 41812

--Execute it on Server 2


DECLARE @ProjectId INT = 3188;
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Get segment description which having choice code
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,
PSSV.SegmentOrigin,PSSV.CustomerId, 
ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK)
WHERE PSSV.ProjectId = @ProjectId AND
ISNULL(PSSV.IsDeleted,0)=0 AND PSSV.SegmentOrigin='M' 
AND PSSV.SegmentDescription LIKE '%{CH#%'


DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption;
SELECT * INTO #TempProjectSelectedChoiceOption FROM SelectedChoiceOption SCO WITH(NOLOCK)
WHERE SCO.ProjectId = @ProjectId

--Declare loopCount
DECLARE @LoopCount INT = (SELECT COUNT(1) AS TotalRows FROM #TempProjectSegmentStatusView)

DECLARE @SegmentDescription NVARCHAR(MAX) = '';
DECLARE @SectionId INT = 0;
DECLARE @CustomerId INT = 0;

--Iterate while loop to gettig choice code from segmentdescription and insert to #ChoiceCodesInSegmnetDesc 
WHILE @LoopCount > 0
BEGIN
	SELECT @SegmentDescription = TPSSV.SegmentDescription, @SectionId = TPSSV.SectionId ,
	@CustomerId =TPSSV.CustomerId
	
	FROM #TempProjectSegmentStatusView TPSSV WHERE RowId = @LoopCount;

	INSERT INTO #ChoiceCodesInSegmnetDesc(ProjectId,SectionId,CustomerId,ChoiceCode)
	SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids
	FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'{CH#')

    SET @LoopCount = @LoopCount - 1;
END;

drop table if exists #TempProjectSelectedChoiceOption1

--find out missing choicescode in SLCProject db
SELECT CCIS.ProjectId,CCIS.SectionId,CCIS.ChoiceCode ,CCIS.CustomerId 
into #TempProjectSelectedChoiceOption1
FROM #ChoiceCodesInSegmnetDesc CCIS 
LEFT OUTER JOIN #TempProjectSelectedChoiceOption TPSCO ON 
TPSCO.SegmentChoiceCode = CCIS.ChoiceCode and TPSCO.ProjectId=CCIS.ProjectId
and CCIS.SectionId=TPSCO.SectionId
WHERE TPSCO.SegmentChoiceCode IS NULL
 
 --(631 rows affected)
 --select * from #TempProjectSelectedChoiceOption1

 --Inserted Missing choices from SLCMaster to SLCProject
  if((select count(1) #TempProjectSelectedChoiceOption1)>0)
 begin
 INSERT INTO SelectedChoiceOption
 SELECT  
 tblins.ChoiceCode, SCO.ChoiceOptionCode, SCO.ChoiceOptionSource,
 SCO.IsSelected, tblins.SectionId, tblins.ProjectId,
 tblins.CustomerId AS CustomerId,NULL AS OptionJson,0 AS IsDeleted
 FROM SLCMaster..SelectedChoiceOption SCO WITH (NOLOCK) inner join 
 #TempProjectSelectedChoiceOption1 tblins on  
 tblins.ChoiceCode=SCO.SegmentChoiceCode
  WHERE tblins.ChoiceCode=SCO.SegmentChoiceCode
  end
