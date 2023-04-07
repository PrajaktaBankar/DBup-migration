CREATE PROC [dbo].[getProjectDetailsById]  
(  
 @projectId int,  
 @customerID int  
)  
AS  
BEGIN
  
 DECLARE @PprojectId int = @projectId;
 --DECLARE @PcustomerID int =  @customerID;

SELECT
	P.Name
   ,P.Description
FROM Project p WITH (NOLOCK)
WHERE p.ProjectId = @PprojectId
AND ISNULL(IsDeleted,0) = 0
END
