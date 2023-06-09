CREATE PROCEDURE [dbo].[usp_getSectionIdSeparators]  
(  
 @ProjectId INT  
)  
AS  
BEGIN
  
DECLARE @PProjectId INT  = @ProjectId;
SELECT
	Id
   ,COALESCE(ProjectId, 0) AS ProjectId
   ,COALESCE(CustomerId, 0) AS CustomerId
   ,COALESCE(UserId, 0) AS UserId
   ,COALESCE(Separator, '') AS Separator
FROM LuProjectSectionIdSeparator WITH (NOLOCK)
WHERE ProjectId = @PProjectId
OR ProjectId IS NULL
END

GO
