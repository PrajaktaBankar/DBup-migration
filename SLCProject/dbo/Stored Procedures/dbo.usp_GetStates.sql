CREATE PROCEDURE [dbo].[usp_GetStates]
AS
BEGIN

SELECT DISTINCT
	t1.StateProvinceID
   ,t1.CountryID
   ,t1.StateProvinceAbbreviation
   ,t1.StateProvinceName
FROM LuStateProvince t1 WITH (NOLOCK)
INNER JOIN LuCity t2 WITH (NOLOCK)
	ON t2.StateProvinceId = t1.StateProvinceID
ORDER BY t1.StateProvinceName

END

GO
