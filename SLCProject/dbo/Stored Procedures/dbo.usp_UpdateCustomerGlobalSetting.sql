CREATE PROCEDURE [dbo].[usp_UpdateCustomerGlobalSetting]
  @CustomerGlobalSettingJson NVARCHAR(MAX)
AS
BEGIN
 DECLARE @PCustomerGlobalSettingJson NVARCHAR(MAX) =  @CustomerGlobalSettingJson;
	--Declare @CustomerGlobalSetting table
	DECLARE @CustomerGlobalSetting TABLE (
		CustomerId INT NULL,
		UserId INT NULL,
		IsAutoSelectParagraph BIT NULL,
		IsAutoSelectForImport BIT NULL
	);

--Fill @CustomerGlobalSetting table
INSERT INTO @CustomerGlobalSetting (CustomerId, UserId, IsAutoSelectParagraph, IsAutoSelectForImport)
	SELECT
		CustomerId
	   ,UserId
	   ,IsAutoSelectParagraph
	   ,IsAutoSelectForImport
	FROM OPENJSON(@PCustomerGlobalSettingJson)
	WITH (
	CustomerId INT '$.CustomerId',
	UserId INT '$.UserId',
	IsAutoSelectParagraph BIT '$.IsAutoSelectParagraph',
	IsAutoSelectForImport BIT '$.IsAutoSelectForImport'
	);

IF NOT EXISTS (SELECT TOP 1
			CustomerGlobalSettingId
		FROM CustomerGlobalSetting CGS WITH (NOLOCK)
		INNER JOIN @CustomerGlobalSetting CGST
			ON CGS.CustomerId = CGST.CustomerId
			AND CGS.UserId = CGST.UserId)
BEGIN
--Create New Entry
INSERT INTO CustomerGlobalSetting (CustomerId, UserId, IsAutoSelectParagraph, IsAutoSelectForImport)
	SELECT
		CustomerId
	   ,UserId
	   ,IsAutoSelectParagraph
	   ,IsAutoSelectForImport
	FROM @CustomerGlobalSetting
END
ELSE
BEGIN
-- Update Existing
UPDATE CGS
SET CGS.IsAutoSelectForImport = CGST.IsAutoSelectForImport
   ,CGS.IsAutoSelectParagraph = CGST.IsAutoSelectParagraph
FROM CustomerGlobalSetting AS CGS WITH (NOLOCK)
INNER JOIN @CustomerGlobalSetting AS CGST
	ON CGS.CustomerId = CGST.CustomerId
	AND CGS.UserId = CGST.UserId
END

END

GO
