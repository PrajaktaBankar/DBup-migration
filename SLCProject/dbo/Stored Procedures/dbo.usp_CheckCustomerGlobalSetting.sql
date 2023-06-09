CREATE PROCEDURE [dbo].[usp_CheckCustomerGlobalSetting]    
	@customerId INT,
	@userId INT
AS    
BEGIN
   
	DECLARE @PcustomerId INT = @customerId;
	DECLARE @PuserId INT = @userId;
SET NOCOUNT ON;

SELECT
	CustomerId AS CustomerId
   ,UserId AS UserId
   ,IsAutoSelectParagraph AS IsAutoSelectParagraph
FROM [CustomerGlobalSetting] WITH(NoLock)
WHERE CustomerId = @PcustomerId
AND UserId = @PuserId
END

GO
