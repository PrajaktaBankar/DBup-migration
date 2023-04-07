CREATE PROCEDURE [dbo].[usp_GetProjectTypes]
AS  
BEGIN
SELECT
	ProjectTypeId,Name,Description,IsActive,SortOrder
FROM LuProjectType WITH (NOLOCK)
ORDER BY NAME

END

GO
