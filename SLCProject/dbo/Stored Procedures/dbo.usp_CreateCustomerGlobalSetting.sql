CREATE PROCEDURE [dbo].[usp_CreateCustomerGlobalSetting]        -- usp_CreateCustomerGlobalSetting  @CustomerID = 1, @UserID = 2, @IsAutoSelectForImport = 1, @IsAutoSelectParagraph = NULL   
 @CustomerId INT,     
 @UserId INT ,     
 @IsAutoSelectParagraph BIT = NULL,  
 @IsAutoSelectForImport BIT = NULL  
AS        
BEGIN
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PIsAutoSelectParagraph BIT = @IsAutoSelectParagraph;
 DECLARE @PIsAutoSelectForImport BIT = @IsAutoSelectForImport;
  IF NOT EXISTS (SELECT TOP 1
		1
	FROM CustomerGlobalSetting WITH (NOLOCK)
	WHERE CustomerId = @PCustomerId
	AND UserId = @PUserId)
BEGIN
IF (@PIsAutoSelectParagraph IS NOT NULL)
BEGIN
INSERT INTO CustomerGlobalSetting (CustomerId, UserId, IsAutoSelectParagraph)
	VALUES (@PCustomerId, @PUserId, @PIsAutoSelectParagraph)
END
IF (@PIsAutoSelectForImport IS NOT NULL)
BEGIN
INSERT INTO CustomerGlobalSetting (CustomerId, UserId, IsAutoSelectForImport)
	VALUES (@PCustomerId, @PUserId, @PIsAutoSelectForImport)
END
END
ELSE
BEGIN
IF (@PIsAutoSelectParagraph IS NOT NULL)
BEGIN
UPDATE CGS
SET CGS.IsAutoSelectParagraph = @PIsAutoSelectParagraph
FROM CustomerGlobalSetting CGS WITH(NOLOCK)
WHERE CGS.CustomerId = @PCustomerId
AND CGS.UserId = @PUserId
END

IF (@PIsAutoSelectForImport IS NOT NULL)
BEGIN
UPDATE CGS
SET CGS.IsAutoSelectForImport = @PIsAutoSelectForImport
FROM CustomerGlobalSetting CGS WITH(NOLOCK)
WHERE CGS.CustomerId = @PCustomerId
AND CGS.UserId = @PUserId
END
END
END

GO
