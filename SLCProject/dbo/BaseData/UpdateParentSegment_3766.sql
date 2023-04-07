--Execute it On server 3

select ROW_NUMBER() over(order by mSegmentId) as RowId,mSegmentId,COUNT(SegmentStatusId) AS StatusCount into #duplicateSegments from [dbo].[ProjectSegmentStatus] ps 
where ps.ProjectId=3766 and ps.SectionId=2931821 --and mSegmentId=711384
GROUP BY mSegmentId
HAVING COUNT(SegmentStatusId)=4

select distinct ps.* into #dProjectSegmentStatus from [dbo].[ProjectSegmentStatus] ps 
inner join #duplicateSegments ds
ON ps.mSegmentId=ds.mSegmentId
where ps.ProjectId=3766 and ps.SectionId=2931821
order by ps.IndentLevel,ps.mSegmentId

select * from #dProjectSegmentStatus

declare @i int=1, @count int=(select count(1) from #duplicateSegments)
declare @mSegmentId int=0
while(@i<=@count)
begin
	set @mSegmentId=(select mSegmentId from #duplicateSegments where RowId=@i)
	if((select count(distinct ParentSegmentStatusId) from #dProjectSegmentStatus where mSegmentId=@mSegmentId)>1)
	begin
		update #dProjectSegmentStatus 
		set IsDeleted=1
		where mSegmentId=@mSegmentId

		update t
		set t.IsDeleted=null
		--select * 
		from #dProjectSegmentStatus t
		where t.ParentSegmentStatusId=(select x.SegmentStatusId from #dProjectSegmentStatus x where x.SegmentStatusId in(t.ParentSegmentStatusId) and isnull(x.IsDeleted,0)=0)
		and t.mSegmentId=@mSegmentId
	end
	set @i=@i+1
	print @i
end


--BackUP
update ps
set ps.FormattingJson=isnull(ps.isdeleted,0)
from ProjectSegmentStatus ps inner join #dProjectSegmentStatus d
on ps.SegmentStatusId=d.SegmentStatusId
where isnull(ps.IsDeleted,0)!=isnull(d.IsDeleted,0)
and ps.SegmentSource='M'

update ps
set ps.IsDeleted=d.IsDeleted
from ProjectSegmentStatus ps inner join #dProjectSegmentStatus d
on ps.SegmentStatusId=d.SegmentStatusId
where isnull(ps.IsDeleted,0)!=isnull(d.IsDeleted,0)
and ps.SegmentSource='M'