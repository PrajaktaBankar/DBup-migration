CREATE PROCEDURE [dbo].[usp_getUserIncludeGlobalSetting]    
	@CustomerId INT,
	@UserId INT
AS    
BEGIN
   
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PUserId INT = @UserId;
SET NOCOUNT ON;

SELECT
	CustomerGlobalSettingId
   ,CustomerId
   ,UserId
   ,IsAutoSelectParagraph
   ,IsAutoSelectForImport
   ,ISIncludeSubparagraph
FROM [CustomerGlobalSetting](NOLOCK)
WHERE UserId = @PUserId
END

GO
