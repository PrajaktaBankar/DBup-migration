USE SLCProject
  GO
  --Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275
--execute on server 02 

DECLARE @ProjectId INT =5026
DECLARE @CustomerId INT=383

--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT PS.SectionId, PS.SegmentDescription,PS.ProjectId,PS.SegmentSource,
PS.CustomerId,PS.SegmentStatusId,PS.SegmentId ,PS.ModifiedBy, ROW_NUMBER() OVER(ORDER BY PS.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM  ProjectSegment PS WITH(NOLOCK) 
WHERE PS.ProjectId = @ProjectId and ISNULL(PS.IsDeleted,0)=0    
AND  PS.SegmentDescription LIKE '%{CH#%' 
AND  PS.SegmentDescription NOT LIKE '%{CH#{CH#%'
AND PS.SegmentStatusId IS NOT NULL


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
@CustomerId =TPSSV.CustomerId,@SegmentStatusId=TPSSV.SegmentStatusId ,@SegmentId=TPSSV.SegmentId,
@ModifiedBy =TPSSV.ModifiedBy

FROM #TempProjectSegmentStatusView TPSSV WHERE RowId = @LoopCount;

INSERT INTO #ChoiceCodesInSegmnetDesc(ProjectId,SectionId,CustomerId,ChoiceCode,SegmentStatusId,SegmentId,ModifiedBy)
SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids,@SegmentStatusId AS SegmentStatusId,@SegmentId AS SegmentId ,@ModifiedBy as ModifiedBy
FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'{CH#')

SET @LoopCount = @LoopCount - 1;
END;

--Filter missing choices data from #TempProjectSegmentChoice
drop table if exists #TempProjectSegmentChoice1,#TempUnsedChoice

SELECT DISTINCT PSC.SegmentChoiceId,PSC.SectionId,PSC.ProjectId,PSC.CustomerId,PSC.SegmentChoiceCode   
into #TempUnsedChoice
FROM  ProjectSegmentChoice PSC WITH(NOLOCK)
LEFT OUTER JOIN  #ChoiceCodesInSegmnetDesc CCIS 
ON PSC.SegmentChoiceCode = CCIS.ChoiceCode and PSC.ProjectId=CCIS.ProjectId
AND CCIS.SectionId=PSC.SectionId AND  CCIS.SegmentId=PSC.SegmentId and CCIS.SegmentStatusId =PSC.SegmentStatusId
WHERE CCIS.ChoiceCode IS NULL and PSC.ProjectId=5026
 

 DELETE  sco  FROM ProjectSegmentChoice psc INNER JOIN #TempUnsedChoice tuc
 ON psc.SegmentChoiceId=tuc.SegmentChoiceId AND psc.SectionId=tuc.SectionId
 AND psc.ProjectId=tuc.ProjectId and psc.CustomerId=tuc.CustomerId 
 INNER JOIN SelectedChoiceOption sco ON psc.ProjectId=sco.ProjectId and sco.SegmentChoiceCode=psc.SegmentChoiceCode
 AND psc.SectionId=sco.SectionId and psc.CustomerId=sco.CustomerId
 INNER JOIN ProjectChoiceOption pco	ON pco.SegmentChoiceId=psc.SegmentChoiceId 
 AND pco.SectionId=psc.SectionId and pco.ProjectId=psc.ProjectId and pco.CustomerId=psc.CustomerId
 AND pco.ChoiceOptionCode=sco.ChoiceOptionCode
 AND sco.ChoiceOptionSource='U'
 

 DELETE pco  FROM ProjectSegmentChoice psc INNER JOIN #TempUnsedChoice tuc
 ON psc.SegmentChoiceId=tuc.SegmentChoiceId AND psc.SectionId=tuc.SectionId
 AND psc.ProjectId=tuc.ProjectId and psc.CustomerId=tuc.CustomerId
 INNER JOIN ProjectChoiceOption pco	ON pco.SegmentChoiceId=psc.SegmentChoiceId 
 AND pco.SectionId=psc.SectionId and pco.ProjectId=psc.ProjectId and pco.CustomerId=psc.CustomerId
 

 DELETE psc  FROM ProjectSegmentChoice psc INNER JOIN #TempUnsedChoice tuc
 ON psc.SegmentChoiceId=tuc.SegmentChoiceId AND psc.SectionId=tuc.SectionId
 AND psc.ProjectId=tuc.ProjectId and psc.CustomerId=tuc.CustomerId