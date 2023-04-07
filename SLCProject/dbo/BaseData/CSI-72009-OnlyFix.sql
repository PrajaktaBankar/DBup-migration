use SLCProject_SqlSlcOp002
go

/*
Customer Support 72009: TOC Report shows sections under the wrong Divisions
Run on server 2
*/


select * 
into bpmcore_staging_slc.dbo.ProjectSection_260
from dbo.ProjectSection where CustomerId=260 

--SELECT * FROM dbo.ProjectSection WHERE CustomerId=260 and SourceTag like '05%' and IsLastLevel=1 and (DivisionCode is null or DivisionId <> 7)

Update dbo.ProjectSection set DivisionId=7
							, DivisionCode='05'
WHERE CustomerId=260 
		and SourceTag like '05%' 
		and IsLastLevel=1 
		and (DivisionCode is null 
				or DivisionId <> 7)	

--SELECT * FROM dbo.ProjectSection WHERE CustomerId=260 and SourceTag like '05%' and IsLastLevel=1 and DivisionId is null
--SELECT * FROM dbo.ProjectSection WHERE CustomerId=260 and SourceTag like '09%' and IsLastLevel=1 and (DivisionCode is null or DivisionId !=11)

Update dbo.ProjectSection set DivisionId=11
							, DivisionCode='09'
WHERE CustomerId=260 
	and SourceTag like '09%' 
	and IsLastLevel=1 
	and (DivisionCode is null 
			or DivisionId !=11)

--SELECT * FROM dbo.ProjectSection WHERE CustomerId=260 and SourceTag like '02%' and IsLastLevel=1 and DivisionId is null
--SELECT * FROM dbo.ProjectSection WHERE CustomerId=260 and SourceTag like '02%' and IsLastLevel=1 and (DivisionCode is null or DivisionId !=4)

Update dbo.ProjectSection set DivisionId=4
							, DivisionCode='02'
WHERE CustomerId=260 
	and SourceTag like '02%' 
	and IsLastLevel=1 
	and (DivisionCode is null 
			or DivisionId !=4)

