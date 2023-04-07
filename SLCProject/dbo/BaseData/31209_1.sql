--Execute it on server 3
--Customer Support 31209: Deadline Dec. 3! {CH#} Issue in Project "302014 RMLEI Renovation" ( CID = 33307 / Admin ID = 1596 / SERVER 3 )


DECLARE @ProjectId INT = 5286

--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,PSSV.SegmentOrigin,
PSSV.CustomerId,PSSV.SegmentStatusId,PSSV.SegmentId , ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK) 
WHERE PSSV.ProjectId = @ProjectId AND
ISNULL(PSSV.IsDeleted,0)=0 AND PSSV.SegmentOrigin='M' 
AND PSSV.SegmentSource='M' AND PSSV.SegmentDescription LIKE '%{CH#%'

--Insert choices data in SelectedChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption;
SELECT * INTO #TempProjectSelectedChoiceOption 
FROM SelectedChoiceOption SCO WITH(NOLOCK)
WHERE SCO.ProjectId = @ProjectId
AND SCO.ChoiceOptionSource='M'

--Fetch choice code from SegmentDescription
DECLARE @LoopCount INT = (SELECT COUNT(1) AS TotalRows FROM #TempProjectSegmentStatusView)

DECLARE @SegmentDescription NVARCHAR(MAX) = '';
DECLARE @SectionId INT = 0;
DECLARE @CustomerId INT = 0;
DECLARE @SegmentStatusId INT = 0;
DECLARE @SegmentId INT = 0;
DECLARE @ModifiedBy INT = 0;
WHILE @LoopCount > 0
BEGIN
SELECT @SegmentDescription = TPSSV.SegmentDescription, @SectionId = TPSSV.SectionId ,
@CustomerId =TPSSV.CustomerId,@SegmentStatusId=TPSSV.SegmentStatusId ,@SegmentId=TPSSV.SegmentId 

FROM #TempProjectSegmentStatusView TPSSV WHERE RowId = @LoopCount;

INSERT INTO #ChoiceCodesInSegmnetDesc(ProjectId,SectionId,CustomerId,ChoiceCode,SegmentStatusId,SegmentId)
SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids,@SegmentStatusId AS SegmentStatusId,@SegmentId AS SegmentId 
FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'{CH#')

SET @LoopCount = @LoopCount - 1;
END;


--Filter missing choices data from ##TempProjectSelectedChoiceOption
drop table if exists #TempProjectSelectedChoiceOption1
SELECT CCIS.ProjectId,CCIS.SectionId,CCIS.ChoiceCode ,CCIS.CustomerId,
CCIS.SegmentStatusId,CCIS.SegmentId,CCIS.ModifiedBy into #TempProjectSelectedChoiceOption1
FROM #ChoiceCodesInSegmnetDesc CCIS 
LEFT OUTER JOIN #TempProjectSelectedChoiceOption TPSCO 
ON TPSCO.SegmentChoiceCode = CCIS.ChoiceCode and TPSCO.ProjectId=CCIS.ProjectId
and CCIS.SectionId=TPSCO.SectionId and CCIS.CustomerId=TPSCO.CustomerId
WHERE TPSCO.SegmentChoiceCode IS NULL


--if missing data is present in filtered table then insert into original table from SLCMaster
--(463 rows affected)
IF((select count(1) #TempProjectSelectedChoiceOption1)>0)
BEGIN
INSERT INTO SelectedChoiceOption
SELECT 
tblins.ChoiceCode, 
SCO.ChoiceOptionCode, 
'M' AS ChoiceOptionSource,
SCO.IsSelected, 
tblins.SectionId, 
tblins.ProjectId,
tblins.CustomerId AS CustomerId,NULL AS OptionJson,0 AS IsDeleted
FROM SLCMaster..SelectedChoiceOption SCO WITH (NOLOCK) INNER JOIN
#TempProjectSelectedChoiceOption1 tblins on tblins.ChoiceCode=SCO.SegmentChoiceCode
WHERE tblins.ChoiceCode=SCO.SegmentChoiceCode 

END