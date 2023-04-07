/*

It will update the flag of Column IsParentSegmentStatusActive

Usage :
For view only
exec usp_CorrectParagraphStatus_DF @CustomerId=0,@projectId=0,@sectionId=0,@ViewOnly=1

for data update
exec usp_CorrectParagraphStatus_DF @CustomerId=0,@projectId=0,@sectionId=0,@ViewOnly=0

*/


USE SLCProject
GO

CREATE PROC usp_CorrectParagraphStatus_DF  
(  
 @CustomerId INT,  
 @projectId INT,  
 @sectionId INT,  
 @ViewOnly BIT=1  
)  
AS  
BEGIN  
 DECLARE @TRUE BIT=1, @FALSE BIT=0  
 DECLARE @Level0SegmentStatusId BIGINT  
 DECLARE @IsSectionActive BIT=0  
 SELECT @IsSectionActive=IIF(pss.SegmentStatusTypeId<6,@TRUE,@FALSE),@Level0SegmentStatusId=SegmentStatusId FROM ProjectSegmentStatus pss WITH(NOLOCK) WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
         and pss.CustomerId=@CustomerId and pss.SequenceNumber=0  and ISNULL(pss.IsDeleted,0)=0
  
 Create Table #Level1(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level2(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level3(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level4(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level5(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level6(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level7(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 Create Table #Level8(SequenceNo Decimal(7,2),SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT,SegmentStatusTypeId int,ParentActualStatus BIT,ParagraphActualStatus BIT,ParentCurrStatus BIT,ParagraphCurrStatus BIT,CurrentIndent INT,ActualIndent INT)  
 ----------------------------------------Level 1-------------------------------------------------------  
 INSERT INTO #Level1(SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)

 SELECT SequenceNumber,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,pss.IsParentSegmentStatusActive,@IsSectionActive,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and @IsSectionActive=@TRUE,@TRUE,@FALSE),pss.IndentLevel,1  
 FROM ProjectSegmentStatus pss WITH(NOLOCK) WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
         and pss.ParentSegmentStatusId=@Level0SegmentStatusId and pss.CustomerId=@CustomerId   and ISNULL(pss.IsDeleted,0)=0

 IF(EXISTS(select top 1 1 from #Level1 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l1.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level1 l1 ON pss.SegmentStatusId=l1.SegmentStatusId  
   WHERE l1.ParentActualStatus<>l1.ParentCurrStatus  
  END  
 END  
  
 ----------------------------------------Level 2-------------------------------------------------------  
 INSERT INTO #Level2(SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
   
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l1.ParagraphActualStatus, 
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l1.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,2  
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level1 l1  
 ON pss.ParentSegmentStatusId=l1.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId  and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level2 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l2.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level2 l2 ON pss.SegmentStatusId=l2.SegmentStatusId  
   WHERE l2.ParentActualStatus<>l2.ParentCurrStatus  
  END  
 END  
  
 ----------------------------------------Level 3-------------------------------------------------------  
 INSERT INTO #Level3(SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l2.ParagraphActualStatus,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l2.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,3  
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level2 l2  
 ON pss.ParentSegmentStatusId=l2.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId   and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level3 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l3.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level3 l3 ON pss.SegmentStatusId=l3.SegmentStatusId  
   WHERE l3.ParentActualStatus<>l3.ParentCurrStatus  
  END  
 END  
  
 ----------------------------------------Level 4-------------------------------------------------------  
 INSERT INTO #Level4 (SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l3.ParagraphActualStatus,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l3.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,4  
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level3 l3  
 ON pss.ParentSegmentStatusId=l3.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId   and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level4 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l4.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level4 l4 ON pss.SegmentStatusId=l4.SegmentStatusId  
   WHERE l4.ParentActualStatus<>l4.ParentCurrStatus  
  END  
 END  
   
 ----------------------------------------Level 5-------------------------------------------------------  
 INSERT INTO #Level5 (SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l4.ParagraphActualStatus,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l4.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,5  
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level4 l4  
 ON pss.ParentSegmentStatusId=l4.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId   and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level5 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l5.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level5 l5 ON pss.SegmentStatusId=l5.SegmentStatusId  
   WHERE l5.ParentActualStatus<>l5.ParentCurrStatus  
  END  
 END  
  
 ----------------------------------------Level 6-------------------------------------------------------  
 INSERT INTO #Level6(SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l5.ParagraphActualStatus,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l5.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,6  
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level5 l5  
 ON pss.ParentSegmentStatusId=l5.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId    and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level6 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l6.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level6 l6 ON pss.SegmentStatusId=l6.SegmentStatusId  
   WHERE l6.ParentActualStatus<>l6.ParentCurrStatus  
  END  
 END  
  
 ----------------------------------------Level 7-------------------------------------------------------  
 INSERT INTO #Level7 (SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l6.ParagraphActualStatus,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l6.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,7 
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level6 l6  
 ON pss.ParentSegmentStatusId=l6.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId     and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level7 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l7.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level7 l7 ON pss.SegmentStatusId=l7.SegmentStatusId  
   WHERE l7.ParentActualStatus<>l7.ParentCurrStatus  
  END  
 END  
  
 ----------------------------------------Level 8-------------------------------------------------------  
 INSERT INTO #Level8(SequenceNo,SegmentStatusId,ParentSegmentStatusId,SegmentStatusTypeId,ParentCurrStatus,ParentActualStatus,
 ParagraphCurrStatus,ParagraphActualStatus,CurrentIndent,ActualIndent)
 SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.ParentSegmentStatusId,pss.SegmentStatusTypeId,pss.IsParentSegmentStatusActive,l7.ParagraphActualStatus,  
 IIF(pss.SegmentStatusTypeId<6 and pss.IsParentSegmentStatusActive=@TRUE,@TRUE,@FALSE),IIF(pss.SegmentStatusTypeId<6 and l7.ParagraphActualStatus=@TRUE,@TRUE,@FALSE),pss.IndentLevel,8 
 FROM ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN #Level7 l7  
 ON pss.ParentSegmentStatusId=l7.SegmentStatusId  
 WHERE pss.ProjectId=@projectId and pss.SectionId=@sectionId  
 and pss.CustomerId=@CustomerId    and ISNULL(pss.IsDeleted,0)=0
   
 IF(EXISTS(select top 1 1 from #Level8 where ParentCurrStatus<>ParentActualStatus))  
 BEGIN  
  if(@ViewOnly=0)  
  BEGIN  
   UPDATE pss  
   set pss.IsParentSegmentStatusActive=l8.ParentActualStatus  
   FROM ProjectSegmentStatus pss WITH(NOLOCK)  
   INNER JOIN #Level8 l8 ON pss.SegmentStatusId=l8.SegmentStatusId  
   WHERE l8.ParentActualStatus<>l8.ParentCurrStatus  
  END  
 END  
  
 IF(@ViewOnly=1)  
 BEGIN  
 select * from(  
  select * from #Level1 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level2 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level3 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level4 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level5 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level6 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level7 where ParentActualStatus<>ParentCurrStatus Union  
  select * from #Level8 where ParentActualStatus<>ParentCurrStatus  
 ) as x Order by SequenceNo  
 END  
  
END

/*

It will update the flag of Column IsParentSegmentStatusActive

Usage :
For view only
exec usp_UpdateParagraphStatusForDeletedLinks_DF 1211,7248,13161715,1  


for data update
exec usp_UpdateParagraphStatusForDeletedLinks_DF 1211,7248,13161715,0  


*/
GO
CREATE PROC usp_UpdateParagraphStatusForDeletedLinks_DF  
(  
 @CustomerId INT=NULL,  
 @ProjectId INT=NULL,  
 @SectionId INT=NULL,
 @IsViewOnly BIT=1  
)  
AS  
BEGIN  
 set @CustomerId=ISNULL(@CustomerId,0)  
 set @ProjectId=ISNULL(@ProjectId,0)  
 set @SectionId=ISNULL(@SectionId,0)  
 IF(@CustomerId=0 and @ProjectId=0 AND @SectionId=0)  
 BEGIN  
  RAISERROR('Please provide atLeast one parameter',1,1)  
 END   
 ELSE  
 BEGIN  
  drop TABLE if EXISTS #sec  
  
  CREATE TABLE #sec(RowId INT,CustomerId INT, ProjectId INT,SectionId INT,SectionCode INT)  
    
  IF(@SectionId>0)  
  BEGIN  
   insert into #sec  
   select ROW_NUMBER() OVER(ORDER BY SectionId) AS rowid,CustomerId,ProjectId,SectionId,SectionCode from ProjectSection ps WITH(NOLOCK)  
   Where SectionId=@SectionId and ISNULL(Isdeleted,0)=0 and isLastLevel=1 --and Isnull(mSectionId,0)=0  
  END  
  ELSE IF(@ProjectId>0)  
  BEGIN  
   insert into #sec  
   select ROW_NUMBER() OVER(ORDER BY SectionId) AS rowid,CustomerId,ProjectId,SectionId,SectionCode from ProjectSection ps WITH(NOLOCK)  
   Where ProjectId=@ProjectId and ISNULL(Isdeleted,0)=0 and isLastLevel=1 --and Isnull(mSectionId,0)=0     
  END  
  ELSE IF(@CustomerId>0)  
  BEGIN  
   insert into #sec  
   select ROW_NUMBER() OVER(ORDER BY SectionId) AS rowid,p.CustomerId,p.ProjectId,ps.SectionId,ps.SectionCode from Project p with(NOLOCK) inner join ProjectSection ps WITH(NOLOCK)  
   ON p.ProjectId=ps.ProjectId  
   Where p.CustomerId=@CustomerId and ISNULL(ps.Isdeleted,0)=0 and ISNULL(p.Isdeleted,0)=0 and isLastLevel=1 --and Isnull(mSectionId,0)=0     
  END  
  
  DROP TABLE IF EXISTS #AvailableLinks  
  SELECT psl.SegmentLinkId, s.*,psl.SourceSegmentStatusCode,psl.TargetSegmentStatusCode INTO #AvailableLinks   
  FROM ProjectSegmentLink psl WITH(NOLOCK) inner join #sec s   
  ON s.projectId=psl.projectId and s.SectionCode in(psl.TargetSectionCode)  
  and psl.isdeleted=0
  DECLARE @i INT=1,@section_Id INT,@cnt INT=(SELECT count(1) FROM #sec)  
  WHILE(@i<=@cnt)  
  BEGIN  
   SET @section_Id=(SELECT TOP 1 SectionId from #sec WHERE RowId=@i)  
   DROP TABLE IF EXISTS #NoLinksParagraph  
  
   SELECT pss.SequenceNumber,pss.SegmentStatusId,pss.SegmentStatusTypeId,0 as ActualSegmentStatusTypeId INTO #NoLinksParagraph   
   FROM ProjectSegmentStatus pss WITH(NOLOCK) LEFT OUTER JOIN #AvailableLinks al  
   ON al.SectionId=pss.sectionId AND pss.segmentStatusCode IN(al.TargetSegmentStatusCode)
   WHERE al.SegmentLinkId IS NULL AND SegmentStatusTypeId NOT IN(2,6,9)  AND ISNULL(pss.IsDeleted,0)=0
   --AND 'U' IN(pss.SegmentOrigin,pss.SegmentOrigin)	
   AND pss.SectionId=@section_Id  
   IF(@IsViewOnly=1)
   BEGIN
		update nlp  
		set ActualSegmentStatusTypeId=2  --Need to update by 2 for the TargetLinks
		from #NoLinksParagraph nlp  
		where nlp.SegmentStatusTypeId<6  
  
		update nlp  
		set ActualSegmentStatusTypeId=6  
		from #NoLinksParagraph nlp  
		where nlp.SegmentStatusTypeId in(7,8)  
  
		update nlp  
		set ActualSegmentStatusTypeId=9  
		from #NoLinksParagraph nlp  
		where nlp.SegmentStatusTypeId in(10,11,12) 

		select * from #NoLinksParagraph
   END
   ELSE IF(exists(select top 1 1 from #NoLinksParagraph))  
   BEGIN  
    update pss  
    set SegmentStatusTypeId=2  --Need to update by 2 for the TargetLinks
    from ProjectSegmentStatus pss WITH(NOLOCK) INNER join #NoLinksParagraph nlp  
    ON nlp.SegmentStatusId=pss.SegmentStatusId  
    where pss.SegmentStatusTypeId<6  
  
    update pss  
    set SegmentStatusTypeId=6  
    from ProjectSegmentStatus pss WITH(NOLOCK) INNER join #NoLinksParagraph nlp  
    ON nlp.SegmentStatusId=pss.SegmentStatusId  
    where pss.SegmentStatusTypeId in(7,8)  
  
    update pss  
    set SegmentStatusTypeId=9  
    from ProjectSegmentStatus pss WITH(NOLOCK) INNER join #NoLinksParagraph nlp  
    ON nlp.SegmentStatusId=pss.SegmentStatusId  
    where pss.SegmentStatusTypeId in(10,11,12)  
   END  
   set @i=@i+1  
  END  
 END  
END

/*
64343
*/
GO
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
  
Select * Into #tempTargetLink FROM ProjectSegmentLink PSL WITh (NOLOCK)  
Where PSL.ProjectId = @SectionCode   
AND PSL.TargetSectionCode = @SectionCode  
AND PSL.TargetSegmentStatusCode = @mSegmentStatusCode  
  
  
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
UPDATE PSL SET PSL.SourceSegmentCode = @NewSegmentCode  
From ProjectSegmentLink PSL WITH(NOLOCK)  
Where PSL.ProjectId = @ProjectId  
AND PSL.SourceSegmentCode = @SegmentCode  
AND ISNULL(PSL.IsDeleted,0) = 0   
  
--6] Update Latest SegmentCode for Non NULL records For Target  
UPDATE PSL SET PSL.TargetSegmentCode = @NewSegmentCode  
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
  
  
UPDATE PSS SET PSS.SegmentStatusTypeId = IIF(PSS.SegmentStatusTypeId = 1 ,2, IIF(PSS.SegmentStatusTypeId = 7,6,IIF(PSS.SegmentStatusTypeId = 8,9,PSS.SegmentStatusTypeId)))  
 From #tempNeedstoUpdateIsDelete t INNER JOIN   
ProjectSegmentStatus PSS With(NOLOCK)  
ON t.SectionId = PSS.SectionId  
AND t.TargetSegmentStatusCode = PSS.SegmentStatusCode  
Where PSS.ProjectId = @ProjectId  
AND PSS.SegmentStatusTypeId NOt IN(2,3,4,5,6)  
  
END


/*

*/
go
ALTER PROC usp_CorrectHierarchyBasedOnIndentLevel_DF
(
	@projectId INT,
	@SectionId INT,
	@viewOnly BIT=1
)
AS
BEGIN
	DROP TABLE IF EXISTS #t

	SELECT ROW_NUMBER() OVER(ORDER BY SequenceNumber) as RowNo,SequenceNumber,IndentLevel,SegmentDescription,SegmentStatusId,ParentSegmentStatusId AS CurrentParentSegmentStatusId, CONVERT(BIGINT,0) AS ActualParentSegmentStatusId INTO #t 
	FROM ProjectSegmentStatusView WITH(NOLOCK) 
	WHERE ProjectId=@projectId and sectionId=@SectionId and IsDeleted=0
	ORDER BY SequenceNumber

	DECLARE @i INT=2,@cnt INT=(SELECT count(1) FROM #t)
	DECLARE @currentIdentLevel INT,@PrevIndentLevel INT,@CurrSegmentStatusId BIGINT,@PrevSegmentStatusId BIGINT
	DECLARE @parentSegmentStatusId BIGINT=0

	DECLARE @indentSequenceMapping AS TABLE(IndentLevel INT,SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(0)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(1)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(2)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(3)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(4)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(5)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(6)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(7)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(8)

	SELECT @CurrSegmentStatusId=SegmentStatusId FROM #t WHERE RowNo=1

	UPDATE @indentSequenceMapping
	SET SegmentStatusId=@CurrSegmentStatusId,
		ParentSegmentStatusId=0
	WHERE IndentLevel=0

	WHILE(@i<=@cnt)
	BEGIN
		SELECT @currentIdentLevel=IndentLevel,@CurrSegmentStatusId=SegmentStatusId FROM #t WHERE RowNo=@i

		SELECT @PrevIndentLevel=IndentLevel,@PrevSegmentStatusId=SegmentStatusId,@parentSegmentStatusId=ParentSegmentStatusId 
		FROM @indentSequenceMapping WHERE IndentLevel=@currentIdentLevel-1

		UPDATE @indentSequenceMapping
		SET SegmentStatusId=@CurrSegmentStatusId,
			ParentSegmentStatusId=@PrevSegmentStatusId
		WHERE IndentLevel=@currentIdentLevel


		IF(@currentIdentLevel>@PrevIndentLevel)
		BEGIN
			UPDATE #t
			SET ActualParentSegmentStatusId=@PrevSegmentStatusId
			WHERE RowNo=@i
		END
		ELSE IF(@currentIdentLevel=@PrevIndentLevel)
		BEGIN
			UPDATE #t
			SET ActualParentSegmentStatusId=@parentSegmentStatusId
			WHERE RowNo=@i
		END
		ELSE IF(@currentIdentLevel<@PrevIndentLevel)
		BEGIN
			SELECT @PrevIndentLevel=IndentLevel,@PrevSegmentStatusId=SegmentStatusId,@parentSegmentStatusId=ParentSegmentStatusId 
			FROM @indentSequenceMapping WHERE IndentLevel=@currentIdentLevel
		
			UPDATE #t
			SET ActualParentSegmentStatusId=@parentSegmentStatusId
			WHERE RowNo=@i
		END

		SET @i=@i+1
END

	IF(@viewOnly=0)
	BEGIN
		UPDATE ps
		SET ps.ParentSegmentStatusId=t.ActualParentSegmentStatusId
		FROM ProjectSegmentStatus ps WITH(NOLOCK) INNER JOIN #t t
		ON ps.SegmentStatusId=t.SegmentStatusId
		WHERE t.ActualParentSegmentStatusId<>t.CurrentParentSegmentStatusId

		SELECT CONCAT(@@ROWCOUNT,' Records affected') as MSG
	END
	IF(@viewOnly=1)
	BEGIN
		SELECT *,IIF(CurrentParentSegmentStatusId<>ActualParentSegmentStatusId,'Y','') AS MisMatch FROM #t ORDER BY RowNo
	END
END

/*

*/
GO
ALTER PROCEDURE [dbo].[usp_ApplyIndividualUpdates]     
@InpSegmentsJson nvarchar(max)      
AS      
BEGIN    
    
SET NOCOUNT ON;    
    
Declare  @tblSegments table    
(    
  RowId int, ProjectId INT , SectionId INT , CustomerId INT , SegmentStatusId BIGINT ,     
  mSectionId INT ,  newVersionSegmentId BIGINT , MSegmentStatusId INT ,MasterStatusIsDelete bit      
);    
    
Insert into @tblSegments    
SELECT   ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId,*    
 FROM OPENJSON(@InpSegmentsJson)    
 WITH (    
 ProjectId INT '$.ProjectId',    
 SectionId INT '$.SectionId', CustomerId INT '$.CustomerId', SegmentStatusId BIGINT '$.PSegmentStatusId',     
  mSectionId INT '$.MSectionId',  newVersionSegmentId BIGINT '$.UpdId', MSegmentStatusId INT '$.MSegmentStatusId',MasterStatusIsDelete bit '$.MasterStatusIsDelete'     
 );    
    
 --SELECT * FROM @tblSegments;    
    
DECLARE @Count INT = (SELECT COUNT(*) FROM @tblSegments),     
@i INT =1, @PprojectId INT , @PsectionId INT,    
@PcustomerId INT ,@PSegmentStatusId BIGINT,@PmSectionId INT ,    
@PnewVersionSegmentId BIGINT ,@PMSegmentStatusId BIGINT,@PMasterStatusIsDelete bit;    
    
WHILE @Count >= @i    
BEGIN    
    
SELECT TOP 1    
 @PprojectId = ProjectId, @PsectionId = SectionId, @PcustomerId = CustomerId,    
 @PSegmentStatusId = SegmentStatusId, @PmSectionId = mSectionId, @PnewVersionSegmentId = newVersionSegmentId,    
 @PMSegmentStatusId = MSegmentStatusId, @PMasterStatusIsDelete = MasterStatusIsDelete    
FROM @tblSegments WHERE RowId = @i;    
    
IF(@PMasterStatusIsDelete=1)    
BEGIN    
      
 ;WITH Parent    
 AS (SELECT c1.SegmentStatusId    
     ,c1.ParentSegmentStatusId    
     ,Level = 1    
  FROM ProjectSegmentStatus c1 WITH (NOLOCK)    
  WHERE c1.SegmentStatusId = @PSegmentStatusId    
  UNION ALL    
  SELECT c2.SegmentStatusId    
     ,c2.ParentSegmentStatusId    
     ,Level = Level + 1    
  FROM ProjectSegmentStatus c2 WITH (NOLOCK)    
  INNER JOIN Parent    
   ON Parent.SegmentStatusId = c2.ParentSegmentStatusId)    
    
 UPDATE PSS    
 SET PSS.IsDeleted = 1    
 FROM ProjectSegmentStatus PSS WITH (NOLOCK)    
 INNER JOIN Parent P WITH (NOLOCK)    
  ON P.SegmentStatusId = PSS.SegmentStatusId    
 WHERE PSS.SectionId=@PSectionId    
 AND PSS.ProjectId = @PprojectId    
 AND PSS.CustomerId = @PcustomerId    
    
END    
ELSE    
BEGIN    
 UPDATE pss     
 SET pss.mSegmentId = @PnewVersionSegmentId    
 FROM dbo.ProjectSegmentStatus pss WITH (NOLOCK)    
 WHERE pss.SegmentStatusId = @PSegmentStatusId    
 AND pss.mSegmentStatusId = @PMSegmentStatusId    
 AND pss.SectionId = @PsectionId    
 AND pss.ProjectId = @PprojectId    
    
--MAP CHOICES    
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, ProjectId, CustomerId, SectionId)    
 SELECT    
  MCH.SegmentChoiceCode    
    ,MCHOP.ChoiceOptionCode    
    ,MSCHOP.ChoiceOptionSource    
    ,MSCHOP.IsSelected    
    ,@PProjectId    
    ,@PCustomerId    
    ,@PSectionId    
 FROM SLCMaster.dbo.SegmentChoice AS MCH WITH (NOLOCK)    
 INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK)    
  ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId    
 INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK)    
  ON MCH.SegmentChoiceCode = MSCHOP.SegmentChoiceCode    
   AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode    
   AND MCH.SectionId=MSCHOP.SectionId    
 WHERE MCH.SectionId = @PmSectionId    
 AND MCH.SegmentId = @PnewVersionSegmentId;    
    
EXEC usp_ApplySegmentLinkUpdates @PSegmentStatusId    
        ,@PsectionId    
        ,@PprojectId    
        ,@PcustomerId    

/*Added for CSI 64343*/
EXEC usp_UpdateSegmentLinkFormSLEUpdates @PprojectId, @PsectionId, @PSegmentStatusId, @PcustomerId    

END    
    
 SET @i = @i + 1;    
END;    
    
END    

GO


