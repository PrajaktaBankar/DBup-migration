
drop table if exists #ProjectDetails

CREATE Table #ProjectDetails(RowId int,ProjectId INT, CustomerId INT,[Name] nvarchar(500))

insert into #ProjectDetails
select DISTINCT ROW_NUMBER() OVER(Order by p.ProjectId) as RowId,p.ProjectId,p.CustomerId,[Name]
from Project p with(NOLOCK) inner join UserFolder uf with(nolock)
ON p.ProjectId=uf.ProjectId
WHERE ISNULL(p.IsPermanentDeleted,0)=0
and uf.LastAccessed>DATEADD(MONTH,-3,GETUTCDATE())

--select * from #ProjectDetails

DECLARE @CustomerId int=0--1598
DECLARE @ProjectId INT,@ProjectName nvarchar(500)

DECLARE @i int=1,@cnt int=(select count(1) from #ProjectDetails)
SET NOCOUNT ON
WHILE(@i<=@cnt)
BEGIN
	select @ProjectId=ProjectId,@ProjectName=[Name],@CustomerId=CustomerId from #ProjectDetails where RowId=@i
	exec usp_CorrectProjectSectionSortO1rder_df @ProjectId,@CustomerId,1	
	print CONCAT(@i,':- data corrected for project ',@ProjectId,'-',@ProjectName)
	set @i=@i+1
END

SET NOCOUNT OFF