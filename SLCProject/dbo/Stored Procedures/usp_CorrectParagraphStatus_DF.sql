/*

It will update the flag of Column IsParentSegmentStatusActive

Usage :
For view only
exec usp_CorrectParagraphStatus_DF @CustomerId=0,@projectId=0,@sectionId=0,@ViewOnly=1

for data update
exec usp_CorrectParagraphStatus_DF @CustomerId=0,@projectId=0,@sectionId=0,@ViewOnly=0

*/

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