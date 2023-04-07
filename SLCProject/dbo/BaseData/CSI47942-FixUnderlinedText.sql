use SLCProject_SqlSlcOp002
go

/*
Customer Support 47942: SLC Cannot Delete Underlined Text
Run on Server 2
CustomerID: 666
ProjectID = 3455

*/

--backup just in case to temp table
drop table if exists #tmpSection221513

select ps.CustomerId, ps.ProjectId, ps.SectionId, psec.SourceTag, psec.Author, pss.SequenceNumber, ps.SegmentDescription, pss.SegmentStatusId, ps.SegmentId 
into #tmpSection221513
from dbo.ProjectSegment ps with (nolock) 
	inner join dbo.projectsegmentstatus pss (nolock) on pss.sectionid=ps.sectionid and pss.segmentstatusid=ps.segmentstatusid and pss.SegmentId=ps.segmentid
	inner join dbo.projectsection psec (nolock) on psec.SectionId=ps.SectionId
where ps.CustomerId=666 and ps.ProjectId=3455 and CHARINDEX('<ins>', segmentdescription)>0 and isnull(pss.IsDeleted,0)=0
order by SourceTag, SequenceNumber


Update ps set SegmentDescription = replace(ps.segmentdescription, '<ins>', '')
from dbo.ProjectSegment ps
inner join #tmpSection221513 pss (nolock) on pss.sectionid=ps.sectionid and pss.segmentstatusid=ps.segmentstatusid and pss.SegmentId=ps.segmentid
where ps.CustomerId=666 and ps.ProjectId=3455 and ps.SectionId=4200817 

Update ps set SegmentDescription = replace(ps.segmentdescription, '</ins>', '')
from dbo.ProjectSegment ps
inner join #tmpSection221513 pss (nolock) on pss.sectionid=ps.sectionid and pss.segmentstatusid=ps.segmentstatusid and pss.SegmentId=ps.segmentid
where ps.CustomerId=666 and ps.ProjectId=3455 and ps.SectionId=4200817 

