CREATE PROC [dbo].[getProjectListById]  
(  
 @projectId nvarchar(max)  
)  
AS  
BEGIN
  
DECLARE @PprojectId nvarchar(max) = @projectId;

SELECT
	P.ProjectId
	,P.Name
	,P.Description
FROM Project p WITH (NOLOCK)
INNER JOIN STRING_SPLIT(@PprojectId, ',') i
	ON p.ProjectId = i.value
WHERE ISNULL(P.IsDeleted,0) = 0
		And ISNULL(P.IsArchived,0)=0
END

GO
