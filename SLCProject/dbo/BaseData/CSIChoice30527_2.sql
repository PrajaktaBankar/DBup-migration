/*
Customer Support 30527: SLC Customer Seeing {CH#} Issue
Server:3
*/


DELETE A FROM (
select *,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceCode,ChoiceOptionCode	,ChoiceOptionSource		,SectionId	,ProjectId	,CustomerId ORDER BY SelectedChoiceOptionId) as RowNo
 from  SLCProject_SqlSlcOp003..SelectedChoiceOption
 where   ProjectId=4698 AND CustomerId=1191 AND ChoiceOptionSource='M'
 )AS A WHERE A.RowNo>1
 
DECLARE @CustomerId int =1191
DECLARE @ProjectId1 int =4698

DROP TABLE IF EXISTS #tempInsertMissingMasterChoices

  CREATE table #tempInsertMissingMasterChoices (ProjectId Int,RowNo Int)

 INSERT INTO #tempInsertMissingMasterChoices (ProjectId  ,RowNo  )
select ProjectId,
ROW_NUMBER () over(PARTITION BY  CustomerId ORDER BY  CustomerId)as RowNo
 from 
Project WITH(NOLOCK) WHERE  CustomerId=@CustomerId and ISNULL( IsPermanentDeleted,0)=0

DECLARE @ProjectRowCount int=(select COUNT(ProjectId) from #tempInsertMissingMasterChoices)

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId INT = (select  ProjectId  from #tempInsertMissingMasterChoices WHERE RowNo=@ProjectRowCount);


IF(@ProjectId1 !=0)
	begin
	set @ProjectRowCount=1
	set @ProjectId= @ProjectId1
	end


--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,PSSV.SegmentOrigin,
PSSV.CustomerId,PSSV.SegmentStatusId,PSSV.SegmentId  , ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK)  
WHERE PSSV.ProjectId = @ProjectId AND
ISNULL(PSSV.IsDeleted,0)=0 AND  PSSV.SegmentSource='M' AND PSSV.SegmentDescription LIKE '%{CH#%'
 
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
--(719 rows affected)
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
  SLCMaster..SegmentChoice sc WITH (NOLOCK) ON sc.SegmentChoiceCode=SCO.SegmentChoiceCode 
 INNER JOIN SLCMaster.dbo.ChoiceOption co WITH (NOLOCK) ON
 co.ChoiceOptionCode=SCO.ChoiceOptionCode AND SCO.SegmentChoiceCode=sc.SegmentChoiceCode AND sc.SegmentChoiceId=co.SegmentChoiceId
 INNER JOIN 
#TempProjectSelectedChoiceOption1 tblins on tblins.ChoiceCode=SCO.SegmentChoiceCode
 WHERE tblins.ChoiceCode=sc.SegmentChoiceCode  
 
 END
  
 SET @ProjectRowCount = @ProjectRowCount-1;

 END