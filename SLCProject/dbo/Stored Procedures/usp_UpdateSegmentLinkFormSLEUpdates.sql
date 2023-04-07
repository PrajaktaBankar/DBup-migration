CREATE PROCEDURE [dbo].[usp_UpdateSegmentLinkFormSLEUpdates]      
(    
@ProjectId INT ,    
@SectionId INT,    
@SegmentStatusId BIGINT,    
@CustomerId INT     
)    
AS    
BEGIN    
    
DECLARe @msectionId INt = (Select mSectionId From ProjectSection WITH(NOLOCK) Where SectionId = @SectionId)    
DECLARe @SectionCode INt = (Select SectionCode FRom SLCMaster..Section WITH(NOLOCK) Where SectionId = @mSectionId)     
DECLARE @tempSegmentCode INt = (Select mSegmentId From ProjectSegmentStatus Where SegmentStatusId = @SegmentStatusId)    
DECLARE  @SegmentCode INT = (Select SegmentId From SLCMaster..Segment Where SectionId = @msectionId AND UpdatedId = @tempSegmentCode )    
Declare @mSegmentStatusCode INT = (Select  SegmentStatusCode From ProjectSegmentStatus WITH(NOLOCK) Where SegmentStatusId = @SegmentStatusId)    
    
    
DROP TABLE If EXISTS #LinksBeforeUpdate    
DROP TABLE IF Exists #tempSourceLink    
DROP TABLE IF EXISTS #tempTargetLink    
DROP TABLE IF EXISTS #tempNeedstoUpdateIsDelete    
    
Select * Into #tempSourceLink FROM ProjectSegmentLink PSL WITh (NOLOCK)    
Where PSL.ProjectId = @ProjectId     
AND PSL.SourceSectionCode = @SectionCode    
AND PSl.SourceSegmentStatusCode = @mSegmentStatusCode    
and ISNULL(psl.isdeleted,0)=0
    
Select * Into #tempTargetLink FROM ProjectSegmentLink PSL WITh (NOLOCK)    
Where PSL.ProjectId = @ProjectId     
AND PSL.TargetSectionCode = @SectionCode    
AND PSL.TargetSegmentStatusCode = @mSegmentStatusCode    
and ISNULL(psl.isdeleted,0)=0    
    
--1] copy links in temp table    
Select * into #LinksBeforeUpdate from ProjectSegmentLink     
Where ProjectId = @ProjectId     
ANd SourceSectionCode = @SectionCode     
AND SourceSegmentCode = @SegmentCode    
    
    
DECLARe @mSegmentId INT = (Select mSegmentId From ProjectSegmentStatus Where SegmentStatusId  = @SegmentStatusId)    
DECLARe @NewSegmentCode INT = (Select SegmentCode From SLCMaster..Segment Where SegmentId  = @mSegmentId)    
    
    
--2] update segment code in temp table    
Update #LinksBeforeUpdate SET SourceSegmentCode = @NewSegmentCode    
Where ProjectId = @ProjectId     
AND SourceSectionCode = @SectionCode       
AND SourceSegmentCode = @SegmentCode    
    
    
--3] join with master link table    
Select t.SegmentLinkId     
,t.TargetSegmentStatusCode    
,t.TargetSectionCode    
,0 as SectionId    
,0 as mSectionId    
INTO #tempNeedstoUpdateIsDelete    
From #LinksBeforeUpdate t FULL OUTER JOIN     
SLCMaster..SegmentLink SL with (nolock) ON    
t.SourceSectionCode = SL.SourceSectionCode    
AND t.SourceSegmentStatusCode = SL.SourceSegmentStatusCode    
AND t.SourceSegmentCode = SL.SourceSegmentCode    
AND t.TargetSectionCode = SL.TargetSectionCode    
AND t.TargetSegmentStatusCode = SL.TargetSegmentStatusCode    
AND t.TargetSegmentCode = SL.TargetSegmentCode    
Where t.ProjectId = @ProjectId AND t.SourceSectionCode = @SectionCode    
AND  t.LinkSource = 'M'    
and t.SourceSegmentChoiceCode IS NULL    
AND SL.SourceSegmentChoiceCode IS NULL    
AND SL.SourceSectionCode IS NULL    
    
--4] set isdeleted =1 for null records    
UPDATE PSL SET PSL.IsDeleted = 1    
From ProjectSegmentLink PSL WITH(NOLOCK)    
INNER JOIN    
#tempNeedstoUpdateIsDelete t     
ON PSL.SegmentLinkId = t.SegmentLinkId     
Where PSL.ProjectId = @ProjectId    
    
    
--5] Update Latest SegmentCode for Non NULL records For Source    
UPDATE PSL   
--SET PSL.SourceSegmentCode = @NewSegmentCode  //Deleting this as we are copying new links at section visit  
SET PSL.IsDeleted=1  
From ProjectSegmentLink PSL WITH(NOLOCK)    
Where PSL.ProjectId = @ProjectId    
AND PSL.SourceSegmentCode = @SegmentCode    
AND ISNULL(PSL.IsDeleted,0) = 0     
    
--6] Update Latest SegmentCode for Non NULL records For Target    
UPDATE PSL   
--SET PSL.TargetSegmentCode = @NewSegmentCode  //Deleting this as we are copying new links at section visit  
SET PSL.IsDeleted=1  
From ProjectSegmentLink PSL WITH(NOLOCK)    
Where PSL.ProjectId = @ProjectId    
AND PSL.TargetSegmentCode = @SegmentCode    
AND ISNULL(PSL.IsDeleted,0) = 0     
    
Update t SET t.mSectionId = s.SectionId    
FROM SLCMaster..Section S Inner JOIN #tempNeedstoUpdateIsDelete t    
ON S.SectionCode = t.TargetSectionCode Where ISNULL(S.IsDeleted,0) = 0    
    
Update t SET t.SectionId = PS.SectionId    
FROM ProjectSection PS Inner JOIN #tempNeedstoUpdateIsDelete t    
ON PS.mSectionId = t.mSectionId     
Where Ps.ProjectId = @ProjectId     
AND PS.IsLastLevel = 1    
AND ISNULL(PS.IsDeleted,0) = 0    
 
update psl
set psl.isdeleted=0,
    psl.SourceSegmentCode=@NewSegmentCode
from ProjectSegmentLink psl WITH(NOLOCK)
inner join #tempSourceLink t
on t.SegmentLinkId=psl.SegmentLinkId
where psl.SegmentLinkSourceTypeId=5


update psl
set psl.isdeleted=0,
    psl.TargetSegmentCode=@NewSegmentCode
from ProjectSegmentLink psl WITH(NOLOCK)
inner join #tempTargetLink t
on t.SegmentLinkId=psl.SegmentLinkId
where psl.SegmentLinkSourceTypeId=5

    
UPDATE PSS SET PSS.SegmentStatusTypeId = IIF(PSS.SegmentStatusTypeId = 1 ,2, IIF(PSS.SegmentStatusTypeId = 7,6,IIF(PSS.SegmentStatusTypeId = 8,9,PSS.SegmentStatusTypeId)))    
 From #tempNeedstoUpdateIsDelete t INNER JOIN     
ProjectSegmentStatus PSS With(NOLOCK)    
ON t.SectionId = PSS.SectionId    
AND t.TargetSegmentStatusCode = PSS.SegmentStatusCode    
Where PSS.ProjectId = @ProjectId    
AND PSS.SegmentStatusTypeId NOt IN(2,3,4,5,6)    
    
END