/*
Data fix for Customer Support 53943: Edits to User section after exiting and reopening messed up format - 67273
SLC does not allow promote and demote in the RS title area.

RequirementTagId=23 --RT
RequirementTagId=22 --RS

Assumptions:
1. There can be only one RT paragraph. If there two more it takes the top 1.
2. The RS paragraph indent level is always set to 3
3. The RT paragraph is assumed to be at level 2 (queried and it was all in indentlevel 2)

*/

/*
--- Check RT paragraph at indent level more than 2
select pst.customerid, Pst.projectid, pst.sectionid, psec.sourcetag, psec.author, pst.SegmentStatusId, pst.segmentid, pst.parentsegmentstatusid, pst.SequenceNumber
		, pst.IsRefStdParagraph, pst.IndentLevel , 	dbo.[fnGetSegmentDescriptionTextForRSAndGT](1575, 2439, pseg.[segmentdescription])	as RTParagraphDesc		
from dbo.ProjectSegmentStatus pst
	inner join dbo.ProjectSegment pseg on pseg.SegmentId=pst.SegmentId
	inner join dbo.ProjectSegmentRequirementTag psr on psr.SegmentStatusId = pst.SegmentStatusId
	inner join dbo.ProjectSection psec on psec.SectionId=pst.SectionId
where pst.ProjectId=1575 
			and isnull(pst.IsDeleted,0)=0
			and RequirementTagId=23
			and pst.IndentLevel>2
			--and pst.IndentLevel=2
			and mSectionId is null
order by SourceTag, Author

*/

/*

--RS paragraph that has indent level > 3
select pst.customerid, Pst.projectid, pst.sectionid, psec.sourcetag, psec.author, pst.SegmentStatusId, pst.segmentid, pst.parentsegmentstatusid, pst.SequenceNumber
		, pst.IsRefStdParagraph, pst.IndentLevel , 	dbo.[fnGetSegmentDescriptionTextForRSAndGT](1575, 2439, pseg.[segmentdescription])	as RSParagraphDesc		
from dbo.ProjectSegmentStatus pst
	inner join dbo.ProjectSegment pseg on pseg.SegmentId=pst.SegmentId
	inner join dbo.ProjectSegmentRequirementTag psr on psr.SegmentStatusId = pst.SegmentStatusId
	inner join dbo.ProjectSection psec on psec.SectionId=pst.SectionId
where pst.ProjectId=1575 
			and (pst.IsDeleted=0 or pst.IsDeleted is null)
			and IsRefStdParagraph=1 
			and RequirementTagId=22
			and pst.IndentLevel>3
			and mSectionId is null
			--and pst.SectionId=2687551 
order by SourceTag, Author
*/

declare @CustomerID int = 2439
declare @ProjectID int = 3047

declare @RTRequirementTagID int = 23
declare @RSRequirementTagID int = 22

declare @ParentRTSegmentStatusID int
declare @CurrentSectionID int


drop table if exists ##FixedRSParagraphs

create table ##FixedRSParagraphs (customerID int
									, ProjectID int
									, SectionID int
									, SourceTag nvarchar(20)
									, author nvarchar(20)
									, segmentstatusid int
									, segmentid int
									, ParentSegmentStatusID bigint
									, Sequencenumber	 decimal(18,4)
									, IsRefStdParagraph bit
									, IndentLevel tinyint
									, RSParaDesc nvarchar(max)
									)

drop table if exists #tmpSections

select sec.sectionid, sec.SourceTag, sec.Author, RTParaCount, 0 as IsProcessed
into #tmpSections
from dbo.ProjectSection sec
inner join (
	select pst.sectionid, count(*) as RTParaCount from dbo.ProjectSegmentStatus pst
		inner join dbo.ProjectSegmentRequirementTag psr on psr.SegmentStatusId = pst.SegmentStatusId
	where pst.ProjectId=@ProjectID 
			and RequirementTagId=@RTRequirementTagID --23
			and isnull(pst.IsDeleted,0)=0 
			and IndentLevel=2
	group by pst.SectionId		
	--having count(*)=1
	) sec2 on sec.SectionId=sec2.SectionId
where sec.mSectionId is null and isnull(sec.IsDeleted,0)=0 

while (select count(*) from #tmpSections where IsProcessed=0)>0
begin

	select top 1 @CurrentSectionID=SectionID from #tmpSections where IsProcessed=0	

	select top 1 @ParentRTSegmentStatusID=pst.SegmentStatusId from dbo.ProjectSegmentStatus pst		
		inner join dbo.ProjectSegmentRequirementTag psr on psr.SegmentStatusId = pst.SegmentStatusId
	where pst.ProjectId=@ProjectID
			and isnull(pst.IsDeleted,0)=0
			and RequirementTagId=@RTRequirementTagID --23
			and pst.SectionId=@CurrentSectionID 
	order by SequenceNumber

	Insert into ##FixedRSParagraphs
	select pst.customerid, Pst.projectid, pst.sectionid, psec.sourcetag, psec.author, pst.SegmentStatusId, pst.segmentid, pst.parentsegmentstatusid, pst.SequenceNumber
			, pst.IsRefStdParagraph, pst.IndentLevel, 	pseg.[segmentdescription] as RSParagraphDesc		
	from dbo.ProjectSegmentStatus pst
		inner join dbo.ProjectSegment pseg on pseg.SegmentId=pst.SegmentId
		inner join dbo.ProjectSegmentRequirementTag psr on psr.SegmentStatusId = pst.SegmentStatusId
		inner join dbo.ProjectSection psec on psec.SectionId=pst.SectionId
	where pst.ProjectId=@ProjectID
				and isnull(pst.IsDeleted,0)=0 
				and IsRefStdParagraph=1 
				and RequirementTagId=@RSRequirementTagID --22
				and pst.IndentLevel>3				
				and pst.SectionId=@CurrentSectionID

	Update pst set pst.IndentLevel=3, pst.ParentSegmentStatusId=@ParentRTSegmentStatusID
	from dbo.ProjectSegmentStatus pst
	inner join dbo.ProjectSegmentRequirementTag psr on psr.SegmentStatusId = pst.SegmentStatusId
	where pst.ProjectId=@ProjectID
				and isnull(pst.IsDeleted,0)=0 
				and IsRefStdParagraph=1 
				and RequirementTagId=22
				and pst.IndentLevel>3				
				and pst.SectionId=@CurrentSectionID
	
	Update #tmpSections set IsProcessed=1 where SectionId=@CurrentSectionID

	if (select count(*) from #tmpSections where IsProcessed=0)=0
		break
	else
		continue
end 

select * from #tmpSections
select * from ##FixedRSParagraphs order by SourceTag, Sequencenumber

