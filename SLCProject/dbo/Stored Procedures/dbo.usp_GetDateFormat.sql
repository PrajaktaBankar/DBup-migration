CREATE PROCEDURE [dbo].[usp_GetDateFormat]  
AS  
BEGIN
SELECT
	DateFormatId,DateFormat,SortOrder,IsActive,IsDeleted,DisplayName
FROM [LuDateFormat] WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY SortOrder
END

GO
