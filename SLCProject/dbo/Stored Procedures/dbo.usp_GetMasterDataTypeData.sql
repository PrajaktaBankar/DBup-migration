CREATE PROCEDURE [dbo].[usp_GetMasterDataTypeData]  
AS   
BEGIN
SELECT
	MasterDataTypeId
   ,Name
   ,Description
   ,LanguageCode
   ,LanguageName
FROM LuMasterDataType  WITH(NOLOCK)
END

GO
