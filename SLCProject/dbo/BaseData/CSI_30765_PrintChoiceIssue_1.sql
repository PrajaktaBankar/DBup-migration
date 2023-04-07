--Script 1- Execute on Server - 3
--Customer Support 30765: ON DEADLINE: {CH#} showing in sections after making edits again.

USE [SLCProject]

DECLARE @ProjectId INT = 4041;

--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentSstatusView;

--Select Segmentsdescription which having Choices
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,PSSV.SegmentOrigin,
PSSV.CustomerId,PSSV.SegmentStatusId,PSSV.SegmentId , ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK) 
WHERE PSSV.ProjectId = @ProjectId AND
ISNULL(PSSV.IsDeleted,0)=0 AND PSSV.SegmentDescription LIKE '%{CH#%'

--Insert choices data in SelectedChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption;
SELECT * INTO #TempProjectSelectedChoiceOption 
FROM SelectedChoiceOption SCO WITH(NOLOCK)
WHERE SCO.ProjectId = @ProjectId 
 
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

select PSC.* into #tempProjectSegmentChoice from ProjectSegmentChoice PSC WITH (NOLOCK) inner join 
#ChoiceCodesInSegmnetDesc CCID on
CCID.ChoiceCode=PSC.SegmentChoiceCode and CCID.ProjectId=PSC.ProjectId and
CCID.SectionId=PSC.SectionId and CCID.CustomerId=PSC.CustomerId
and CCID.SegmentStatusId=PSC.SegmentStatusId 
where CCID.ProjectId =PSC.ProjectId and isnull(psc.IsDeleted,0)=1

---rows affected 28
update PCO set pco.IsDeleted=0 from ProjectChoiceOption PCO  WITH (NOLOCK) inner join #tempProjectSegmentChoice TPSC on
PCO.SegmentChoiceId=TPSC.SegmentChoiceId and PCO.ProjectId=TPSC.ProjectId and PCO.SectionId=TPSC.SectionId
and PCO.CustomerId=TPSC.CustomerId 
where PCO.IsDeleted=1
-- rows affected 25 
update SCO set sco.IsDeleted=0 from ProjectChoiceOption PCO  WITH (NOLOCK) inner join #tempProjectSegmentChoice TPSC on
PCO.SegmentChoiceId=TPSC.SegmentChoiceId and PCO.ProjectId=TPSC.ProjectId and PCO.SectionId=TPSC.SectionId
and PCO.CustomerId=TPSC.CustomerId
inner join SelectedChoiceOption SCO on
PCO.ChoiceOptionCode =SCO.ChoiceOptionCode and TPSC.SegmentChoiceCode=SCO.SegmentChoiceCode and 
PCO.ProjectId=SCO.ProjectId and PCO.SectionId=SCO.SectionId
and PCO.CustomerId=SCO.CustomerId
where sco.IsDeleted=1

--rows affected 13
update PSC set psc.IsDeleted=0 from ProjectSegmentChoice PSC WITH (NOLOCK) inner join 
#ChoiceCodesInSegmnetDesc CCID on
CCID.ChoiceCode=PSC.SegmentChoiceCode and CCID.ProjectId=PSC.ProjectId and
CCID.SectionId=PSC.SectionId and CCID.CustomerId=PSC.CustomerId
and CCID.SegmentStatusId=PSC.SegmentStatusId 
where CCID.ProjectId =PSC.ProjectId and isnull(psc.IsDeleted,0)=1;

