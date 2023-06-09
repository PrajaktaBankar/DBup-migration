CREATE Proc [dbo].[usp_IsProjectNameExist]    
(     
@ProjectName NVARCHAR(MAX),    
@CustomerId INT=0   
)    
AS    
BEGIN
    
DECLARE @PProjectName NVARCHAR(MAX) = @ProjectName;
DECLARE @PCustomerId INT = @CustomerId;

SELECT TOP 1
	COUNT(1) AS IsExists
FROM Project P WITH (NOLOCK)
WHERE ISNULL(P.IsPermanentDeleted, 0) = 0
AND P.CustomerId = @PCustomerId
AND P.[Name] = @PProjectName;
END

GO
