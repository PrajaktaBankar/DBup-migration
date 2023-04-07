/*
Customer Support 31209: Deadline Dec. 3! {CH#} Issue in Project "302014 RMLEI Renovation" ( CID = 33307 / Admin ID = 1596 / SERVER 3 )
Run commonscriptForAllDataBase.sql script before executing below script
31209_1.sql
31209_2.sql
31209_3.sql
31209_4.sql

*/ 

 CREATE table #tempCustomerId (CustomerId Int,RowNo Int)

 INSERT INTO #tempCustomerId (CustomerId  ,RowNo  )

 SELECT A.CustomerId,ROW_NUMBER() over(ORDER by	CustomerId)as row_no FROM(
 SELECT DISTINCT CustomerId
  FROM Project  
  )as A

DECLARE @ProjectRowCount int=(select COUNT(CustomerId) from #tempCustomerId)

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @CustomerId INT = (select  CustomerId from #tempCustomerId WHERE RowNo=@ProjectRowCount);

 UPDATE psc SET   psc.SegmentStatusId=pss.SegmentStatusId
  FROM
  ProjectSegmentChoice psc WITH(NOLOCK)
  INNER JOIN ProjectSegment pss WITH(NOLOCK) ON pss.SegmentId=psc.SegmentId AND psc.ProjectId=pss.ProjectId 
  AND psc.SectionId=pss.SectionId AND psc.CustomerId=pss.CustomerId
  WHERE psc.SegmentStatusId IS NULL and psc.CustomerId=@CustomerId

  SET @ProjectRowCount =@ProjectRowCount-1

END


DROP TABLE #tempCustomerId
 