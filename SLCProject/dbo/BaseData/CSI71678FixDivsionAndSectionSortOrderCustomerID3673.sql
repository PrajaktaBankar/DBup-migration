USE SLCProject
GO
/*

RUn on Server 4
CustomerID 3673
Customer Support 71678: SLC: Division Folders Out Of Order

Notes for future use:
If there are userfolder or CustomerDivision data, this fix may not work.
There can be sections which may not be in order and should appear in the folder it was first added.

*/

DECLARE @CustomerId int=3673 --0--1598
DECLARE @ProjectId INT,@ProjectName nvarchar(500)

drop table if exists #ProjectDetails

CREATE Table #ProjectDetails(RowId int,ProjectId INT, CustomerId INT,[Name] nvarchar(500))

insert into #ProjectDetails
select DISTINCT ROW_NUMBER() OVER(Order by p.ProjectId) as RowId,p.ProjectId,p.CustomerId,[Name]
FROM Project p
WHERE ISNULL(p.IsPermanentDeleted,0)=0 
AND customerid=@CustomerId	

--select * from #ProjectDetails

DECLARE @i int=1,@cnt int=(select count(1) from #ProjectDetails)
SET NOCOUNT ON
WHILE(@i<=@cnt)
BEGIN
	select @ProjectId=ProjectId,@ProjectName=[Name],@CustomerId=CustomerId from #ProjectDetails where RowId=@i

	UPDATE dbo.ProjectSection SET SourceTag='02' WHERE ProjectId=@ProjectId AND sourcetag='020' AND mSectionId=105

	DROP TABLE IF EXISTS #TmpNewProjectSection
	SELECT ROW_NUMBER() OVER(ORDER BY sourcetag) AS 'New_SortOrder',* 
	INTO #TmpNewProjectSection
	FROM dbo.ProjectSection ps 
	WHERE ps.ProjectId=@ProjectId  

	--SELECT * FROM #TmpNewProjectSection tnps

	UPDATE dbo.ProjectSection SET SortOrder=tnps.New_SortOrder
	FROM dbo.ProjectSection ps 
	INNER  JOIN #TmpNewProjectSection tnps ON ps.SectionId=tnps.SectionId	

	exec usp_CorrectProjectSectionSortO1rder_df @ProjectId,@CustomerId,1	
	print CONCAT(@i,':- data corrected for project ',@ProjectId,'-',@ProjectName)
	set @i=@i+1
END

SET NOCOUNT OFF