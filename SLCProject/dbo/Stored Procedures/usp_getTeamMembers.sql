
CREATE PROCEDURE [dbo].[usp_GetTeamMembers] 
(
	@projectId INT,
	@customerId INT
)
AS
BEGIN
	SELECT UPAM.UserId
	FROM UserProjectAccessMapping AS UPAM  WITH(NOLOCK) 
	where UPAM.ProjectId=@projectId 
	AND UPAM.IsActive=1
END




