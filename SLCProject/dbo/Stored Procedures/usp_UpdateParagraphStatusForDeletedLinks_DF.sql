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
