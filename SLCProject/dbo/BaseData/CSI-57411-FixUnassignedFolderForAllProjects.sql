use SLCProject_SqlSlcOp004

go

/*

select ps.projectid, SourceTag, author, ps.DivisionCode, ps.DivisionId  from dbo.ProjectSection ps with (nolock) 
inner join dbo.project p on p.projectid=ps.projectid
where p.CustomerId=1794 and SourceTag like '000130' and ps.IsDeleted=0 and DivisionId is null and p.IsDeleted=0

CSI-57411 -- Sections imported from unassigned folder has divisionid and divisioncode  NULL

*/


Update dbo.ProjectSection set DivisionId=1, DivisionCode='00'
where CustomerId=1794 and SourceTag like '000130' and author='BKBM' and IsDeleted=0 and DivisionId is null 
