--Execute it on Server 3

--Get Duplicate Entries in segment status
select * into #duplicate 
from(
select ROW_NUMBER() OVER(PARTITION BY mSegmentId  ORDER BY SequenceNumber) AS RowNumberRank,*
from [dbo].[ProjectSegmentStatus] where ProjectId =2260 and isnull(IsDeleted,0)=0 and SegmentSource='M' 
) as x
where RowNumberRank>1

select * from #duplicate

--Remove duplicate mSegmentIds

delete d
from (
select mSegmentId from #duplicate group by mSegmentId
having count(mSegmentId)>1
) as x right outer join #duplicate d
on x.mSegmentId=d.mSegmentId
where x.mSegmentId is null


--Soft Delete all duplicates
update ps
set ps.IsDeleted=1
from [dbo].[ProjectSegmentStatus] ps inner join #duplicate d
on ps.SegmentStatusId=d.SegmentStatusId