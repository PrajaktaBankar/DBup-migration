CREATE PROCEDURE [dbo].[usp_GetspecificationView]  
AS  
BEGIN

SELECT
	SpecViewModeId
   ,Name
   ,SpecViewCode
   ,Description
   ,SortOrder
   ,IsActive
FROM LuSpecificationViewMode WITH (NOLOCK)

END

GO
