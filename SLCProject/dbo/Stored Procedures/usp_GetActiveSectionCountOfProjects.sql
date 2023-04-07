CREATE PROC usp_GetActiveSectionCountOfProjects
(
	@ProjectIdList NVARCHAR(500)='',
	@CustomerId INT
)
AS
BEGIN
	
DROP TABLE IF EXISTS #ProjectList;
DROP TABLE IF EXISTS #CTE_ActiveSection;
create table #ProjectList(ProjectId int --NOT NULL PRIMARY KEY
)
Insert into #ProjectList
SELECT * from STRING_SPLIT(@ProjectIdList, ',')  
	;WITH CTE_ActiveSection (ProjectId, TotalActiveSection)                                         
	AS                                              
	  (
Select PSS.ProjectId, count(PSS.SectionId) as TotalActiveSections
	from #ProjectList pl with (nolock)                                                
		INNER JOIN ProjectSection PS with (nolock) ON pl.ProjectId = PS.ProjectId AND PS.IsDeleted = 0 AND ps.IsLastLevel = 1                         
		INNER JOIN Projectsegmentstatus PSS with (nolock) 
		ON PSS.SectionId = PS.SectionId AND PSS.ProjectId = pl.ProjectId and PSS.SequenceNumber = 0 and ( PSS.SegmentStatusTypeId between 1 AND  5)                                  
	where PSS.CustomerId = @CustomerId                                                 
	GROUP by PSS.ProjectId,PSS.CustomerId
)

select * from CTE_ActiveSection  

END
GO