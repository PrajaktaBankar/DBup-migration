use SLCProject
go
/*

Run this on server 2
First run with @Fix = 0 and then run with @Fix = 1
*/
--select MasterDataTypeId, * from dbo.Project with (nolock) where CustomerId=@Customerid and IsOfficeMaster=1

declare @CustomerID int = 1211
declare @ProjectID int = 13272
declare @Fix int = 0
declare @RowCount int = 0

drop table if exists #tmpSectionParagraphs
create table #tmpSectionParagraphs (Customerid int, 
									Projectid int,
									sectionid int,
									SegmentStatusId bigint, 
									Parentsegmentstatusid bigint, 
									mSegmentStatusId int, 
									SegmentId int, 
									mSegmentId int, 
									sequencenumber decimal(18,4), 
									IndentLevel int, 
									SegmentDescription nvarchar(max)
									)

drop table if exists #tmpSections

select ps.ProjectId, ps.sectionid, ps.SourceTag, ps.Author, 0 as IsProcessed, 0 as UpdateCount
into #tmpSections
from dbo.ProjectSegmentStatus pss with (nolock) 
inner join dbo.ProjectSection ps (nolock) on ps.SectionId=pss.SectionId and ps.CustomerId=pss.CustomerId and ps.ProjectId=pss.ProjectId
where ps.CustomerId=@CustomerID and pss.SequenceNumber=0 and ps.ProjectId=@ProjectID 
--and SourceTag='010402.04'
order by ProjectId, SourceTag, Author

select * from #tmpSections


declare @UpdateCount int = 0 
declare @FixSectionID int
declare @CurrentIndentLevel int = 8

while (select count(*) from #tmpSections where IsProcessed=0)>0
begin

	select top 1 @FixSectionID=SectionID from #tmpSections where IsProcessed=0

	drop table if exists #tmpProjectSegmentStatusView

	select Customerid, projectid, sectionid, SegmentStatusId, Parentsegmentstatusid, mSegmentStatusId, SegmentId, mSegmentId, sequencenumber, IndentLevel, SegmentDescription 
	into #tmpProjectSegmentStatusView
	from dbo.ProjectSegmentStatusView 
	where CustomerId=@Customerid and SectionId=@FixSectionID and isnull(IsDeleted,0)=0

	set @UpdateCount=0
	set @CurrentIndentLevel = 8
	set @RowCount = 0

	while (@CurrentIndentLevel>0)
	begin
		insert into #tmpSectionParagraphs
		select child.*	
		from #tmpProjectSegmentStatusView child
		cross apply ( select top 1 * from #tmpProjectSegmentStatusView parent
							where parent.ProjectId=child.Projectid
								and parent.SectionId=child.SectionId
								and child.IndentLevel-1=parent.IndentLevel 
								and parent.SequenceNumber < child.SequenceNumber								
							order by parent.SequenceNumber desc
							) as X
		where child.IndentLevel=@CurrentIndentLevel and child.ParentSegmentStatusId != X.SegmentStatusId
	
		if @@ROWCOUNT>0
		begin
			Update child set ParentSegmentStatusId=X.SegmentStatusId
			from #tmpProjectSegmentStatusView child
			cross apply ( select top 1 * from #tmpProjectSegmentStatusView parent
									where parent.ProjectId=child.Projectid
										and parent.SectionId=child.SectionId
										and child.IndentLevel-1=parent.IndentLevel 
										and parent.SequenceNumber < child.SequenceNumber
									order by parent.SequenceNumber desc
									) as X
			where child.IndentLevel=@CurrentIndentLevel and child.ParentSegmentStatusId != X.SegmentStatusId
			
			set @RowCount = @RowCount + @@ROWCOUNT

		end

		set @CurrentIndentLevel = @CurrentIndentLevel - 1

	end 

	if @Fix=1
		Update ps set ps.ParentSegmentStatusId=psv.ParentSegmentStatusId
				from dbo.ProjectSegmentStatus ps
				inner join #tmpProjectSegmentStatusView psv on psv.SegmentStatusId=ps.SegmentStatusId
																and psv.SectionId=ps.SectionId 
																and psv.ProjectId=ps.ProjectId
																and psv.CustomerId=ps.CustomerId


	Update #tmpSections set IsProcessed=1, UpdateCount=@RowCount 
	where SectionId=@FixSectionID

	if (select count(*) from #tmpSections where IsProcessed=0)=0
		break;

end

select s.projectid, p.[name], s.SourceTag, s.Author, UpdateCount
from #tmpSections s
inner join dbo.Project p (nolock) on p.ProjectId=s.ProjectId
where UpdateCount>0
order by Projectid, SourceTag, Author

select sp.Customerid, sp.projectid, p.[name] as projectname, sp.sectionid, psec.sourcetag, psec.author, SegmentStatusId, Parentsegmentstatusid, mSegmentStatusId, SegmentId, mSegmentId, sequencenumber, IndentLevel, SegmentDescription   
from #tmpSectionParagraphs sp
inner join dbo.ProjectSection psec on psec.CustomerId=sp.CustomerId
									and psec.ProjectId=sp.ProjectId
									and psec.SectionId=sp.SectionId
inner join dbo.project p on psec.ProjectId=p.ProjectId
order by sp.ProjectId, psec.SourceTag, psec.Author, sp.SequenceNumber

