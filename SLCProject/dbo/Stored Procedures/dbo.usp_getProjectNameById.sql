CREATE Procedure [dbo].[usp_getProjectNameById]  
@projectId int  
As  
Begin
  
 DECLARE @PprojectId int = @projectId;
 Declare @v_CustomerId int =0;
SET @v_CustomerId = (SELECT
		CustomerId
	FROM Project WITH (NOLOCK)
	WHERE projectId = @PprojectId);
SET @v_CustomerId = ISNULL(@v_CustomerId, 0);

--Select from Project  
SELECT
	P.ProjectId AS Id
   ,P.Name
   ,P.Description
   ,P.UserId
   ,P.CustomerId
   ,ISNULL(P.CreatedBy, 0) AS CreatedBy
   ,P.CreateDate
   ,ISNULL(P.ModifiedBy, 0) AS ModifiedBy
   ,P.ModifiedDate
   ,ISNULL(PA.CountryId, 0) AS CountryId
FROM Project P WITH (NOLOCK)
LEFT JOIN ProjectAddress PA  WITH(NOLOCK)
	ON P.ProjectId = PA.ProjectId
WHERE P.projectId = @PprojectId

SELECT
	Name
FROM Project WITH (NOLOCK)
WHERE CustomerId = @v_CustomerId

END;

GO
