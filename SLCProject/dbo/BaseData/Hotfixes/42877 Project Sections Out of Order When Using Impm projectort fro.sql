use SLCProject_SqlSlcOp004
go

/*

Data fix for Customer Support 43788: SLC Master Spec Update
Ran on server 4

Problem: for many project 078700:BSD occurs under division folder 083000 instead of 078000
1. Update the divisionid to 9 and divisioncode to 07
2. Update the ParentSectionID to SectionID of folder 078000

*/

/*
Pre Checks
select * from dbo.ProjectSection with (nolock) where CustomerId=1429 and SourceTag like '078700' and Author like 'BSD' and DivisionCode='08' order by ProjectId
select * from dbo.ProjectSection with (nolock) where CustomerId=1429 and SourceTag like '078700' and Author like 'BSD' and DivisionCode='08' and divisionid=10 order by ProjectId
select * from dbo.ProjectSection with (nolock) where CustomerId=1429 and SourceTag like '078700' and Author like 'BSD' and ProjectId=4139
select * from dbo.ProjectSection where SectionId=4767116
select * from dbo.ProjectSection with (nolock) 
where CustomerId=1429 
and SourceTag like '078700' 
and Author like 'BSD' 

select * from dbo.ProjectSection where SectionId=2219159
--and DivisionCode='08' and divisionid=10 order by ProjectId
*/


drop table if exists #tmpCurrentParentFolder  

select ps.projectid, ps.SectionId
into #tmpCurrentParentFolder  
from dbo.ProjectSection ps with (nolock) 
inner join dbo.projectsection ps1 on ps1.sectionid=ps.parentsectionid
where ps.CustomerId=1429 
		and ps.SourceTag like '078700' 
		and ps.Author like 'BSD' 
		and ps1.SourceTag = '083000' and ps1.Author is NULL
		--and ps.ProjectId=4139

--078700 SectionID

drop table if exists #tmpSectionID078700

select projectid, sectionid 
into #tmpSectionID078700
from dbo.ProjectSection with (nolock) 
where CustomerId=1429 and SourceTag = '078000' and Author is null

select p.IsDeleted, p.[name], * from dbo.ProjectSection ps
inner join (
	select a.projectid, a.SectionId, b.SectionId as ParentSectionID 
	from #tmpCurrentParentFolder a
	inner join #tmpSectionID078700 b on b.ProjectId=a.ProjectId
) ps1 on ps1.ProjectId=ps.ProjectId and ps1.SectionId=ps.SectionId
inner join dbo.Project p on ps.ProjectId=p.ProjectId
where ps.CustomerId=1429 --and p.IsDeleted=0

Update dbo.ProjectSection set Divisionid=9, DivisionCode='07' where CustomerId=1429 and SourceTag like '078700' and Author like 'BSD' and DivisionCode='08' and divisionid=10 

Update dbo.ProjectSection set ParentSectionId=ps1.ParentSectionID
from dbo.ProjectSection ps
inner join (
	select a.projectid, a.SectionId, b.SectionId as ParentSectionID 
	from #tmpCurrentParentFolder a
	inner join #tmpSectionID078700 b on b.ProjectId=a.ProjectId
) ps1 on ps1.ProjectId=ps.ProjectId and ps1.SectionId=ps.SectionId
where ps.CustomerId=1429


