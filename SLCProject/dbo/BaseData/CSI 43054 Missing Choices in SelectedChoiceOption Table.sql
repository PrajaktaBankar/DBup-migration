USE SLCProject
 Go
 
--Customer Support 43054: SLC User Still Sees {CH# Issue in Projects
--Note Please Exec this script after exec script from "CSI 43054 Missing Choices.sql"(File location \BaseData\CSI 43054 Missing Choices.sql)
--EXECUTE On server 2


SET NOCOUNT ON
DECLARE @CustomerId INT =1754

DROP TABLE IF EXISTS #tempInsertMissingUserModificationMissingChoices
 CREATE table #tempInsertMissingUserModificationMissingChoices(ProjectId Int,RowNo Int)
 DROP TABLE IF EXISTS #AllMissingsSelectedChoice
 CREATE table #AllMissingsSelectedChoice( ProjectId int, SectionId int,	
 ChoiceCode int, CustomerId int, SegmentStatusId int, SegmentId int, ModifiedBy int, SegmentChoiceCode int)

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

	

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId INT =( SELECT
		ProjectId
	FROM #tempInsertMissingUserModificationMissingChoices
	WHERE RowNo = @ProjectRowCount);
	print cast(@ProjectId as nvarchar(50))+' Begin'

	--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,PSSV.SegmentOrigin,
PSSV.CustomerId,PSSV.SegmentStatusId,PSSV.SegmentId ,PS.ModifiedBy, ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK) 
INNER JOIN ProjectSegment PS WITH(NOLOCK)  ON
 PS.SegmentStatusId=PSSV.SegmentStatusId AND PS.SegmentId=PSSV.SegmentId
 and PS.ProjectId=PSSV.ProjectId
WHERE PSSV.ProjectId = @ProjectId AND
ISNULL(PSSV.IsDeleted,0)=0 AND PSSV.SegmentOrigin='U' 
AND PSSV.SegmentSource='U' AND PSSV.SegmentDescription LIKE '%{CH#%'

--Insert choices data in ProjectSegmentChoice temp table for Project 
DROP TABLE IF EXISTS #TempProjectSegmentChoice;
SELECT * INTO #TempProjectSegmentChoice 
FROM ProjectSegmentChoice PSC WITH(NOLOCK)
WHERE PSC.ProjectId = @ProjectId
AND PSC.SegmentChoiceSource ='U'

--Insert choices data in ProjectChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectChoiceOption;
SELECT * INTO #TempProjectChoiceOption 
FROM ProjectChoiceOption PCO WITH(NOLOCK)
WHERE PCO.ProjectId = @ProjectId
AND PCO.ChoiceOptionSource='U'

--Insert choices data in SelectedChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption;
SELECT * INTO #TempProjectSelectedChoiceOption 
FROM SelectedChoiceOption SCO WITH(NOLOCK)
 WHERE SCO.ProjectId = @ProjectId
 AND SCO.ChoiceOptionSource='U'

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
@SegmentStatusId=TPSSV.SegmentStatusId ,@SegmentId=TPSSV.SegmentId,
@ModifiedBy =TPSSV.ModifiedBy

FROM #TempProjectSegmentStatusView TPSSV WHERE RowId = @LoopCount;

INSERT INTO #ChoiceCodesInSegmnetDesc(ProjectId,SectionId,CustomerId,ChoiceCode,SegmentStatusId,SegmentId,ModifiedBy)
SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids,@SegmentStatusId AS SegmentStatusId,@SegmentId AS SegmentId ,@ModifiedBy as ModifiedBy
FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'{CH#')
INSERT INTO #ChoiceCodesInSegmnetDesc(ProjectId,SectionId,CustomerId,ChoiceCode,SegmentStatusId,SegmentId,ModifiedBy)
SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids,@SegmentStatusId AS SegmentStatusId,@SegmentId AS SegmentId ,@ModifiedBy as ModifiedBy
FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'%{\ch%')

SET @LoopCount = @LoopCount - 1;
END;

--Filter missing choices data from #TempProjectSelectedChoiceOption
drop table if exists #TempSelectedChoiceMissing
SELECT CCIS.ProjectId,CCIS.SectionId,CCIS.ChoiceCode ,CCIS.CustomerId,
CCIS.SegmentStatusId,CCIS.SegmentId,CCIS.ModifiedBy,TPSCO.SegmentChoiceCode into #TempSelectedChoiceMissing
FROM #ChoiceCodesInSegmnetDesc CCIS 
LEFT OUTER JOIN #TempProjectSelectedChoiceOption TPSCO 
ON TPSCO.SegmentChoiceCode = CCIS.ChoiceCode and TPSCO.ProjectId=CCIS.ProjectId
and CCIS.SectionId=TPSCO.SectionId
WHERE TPSCO.SegmentChoiceCode IS NULL 

--Filter existing choices data from #ExistProjectSegmentChoice
drop table if exists #ExistProjectSegmentChoice
select am.*, pco.SegmentChoiceId into #ExistProjectSegmentChoice from #TempSelectedChoiceMissing am 
left join ProjectSegmentChoice pco WITH (NOLOCK)
on am.ChoiceCode=pco.SegmentChoiceCode and am.SectionId=pco.SectionId and am.ProjectId=pco.ProjectId
where pco.SegmentChoiceCode is not null and ISNULL(pco.IsDeleted,0)=0 

--Filter existing ChoiceOptionCode data from #tempSelectedChoiceoptionData
drop table if exists #tempSelectedChoiceoptionData
SELECT eps.ChoiceCode as SegmentChoiceCode, pco.ChoiceOptionCode, pco.ChoiceOptionSource
,0 AS IsSelected, eps.SectionId, eps.ProjectId, pco.CustomerId, NULL AS OptionJson, 0 AS IsDeleted
into #tempSelectedChoiceoptionData FROM #ExistProjectSegmentChoice eps 
INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON eps.SegmentChoiceId = pco.SegmentChoiceId
AND eps.SectionId = pco.SectionId AND eps.ProjectId = pco.ProjectId
WHERE ISNULL(pco.IsDeleted, 0) = 0

insert into SelectedChoiceOption
select SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId,
OptionJson, IsDeleted from #tempSelectedChoiceoptionData

 UPDATE A
SET IsSelected = 1
from(
select SCO.*,
ROW_NUMBER() OVER (PARTITION BY SCO.SegmentChoiceCode
,SCO.ChoiceOptionSource, SCO.SectionId,SCO.ProjectId,SCO.CustomerId 
ORDER BY sco.SelectedChoiceOptionId) AS RowNo
from SelectedChoiceOption SCO WITH (NOLOCK) inner join #tempSelectedChoiceoptionData t
on sco.SegmentChoiceCode=t.SegmentChoiceCode
and sco.ChoiceOptionCode=t.ChoiceOptionCode
and sco.SectionId=t.SectionId
 and sco.ProjectId=t.ProjectId
 and sco.ChoiceOptionSource = 'U'
 and sco.CustomerId=t.CustomerId)AS A where A.RowNo=1 



SET @ProjectRowCount = @ProjectRowCount - 1;
print @ProjectRowCount
print cast(@ProjectId as nvarchar(50))+' End'

 END



 