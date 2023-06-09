CREATE PROCEDURE [dbo].[usp_DeleteUserTemplate]      
(      
 @CustomerId INT,      
 @TemplateId INT      
)      
AS  
      
BEGIN
    
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PTemplateId INT = @TemplateId;

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--BEGIN TRANSACTION

--DECLARE DEFAULT SYSTEM TEMPLATE ID      
DECLARE @BsdTemplateId INT = 1;
DECLARE @NmsEnTemplateId INT = (SELECT
		TemplateId
	FROM Template
	WHERE MasterDataTypeId = 2
	AND IsSystem = 1
	AND IsDeleted = 0);
DECLARE @NmsFrTemplateId INT = (SELECT
		TemplateId
	FROM Template
	WHERE MasterDataTypeId = 3
	AND IsSystem = 1
	AND IsDeleted = 0);

--DELETE STYLES FIRST      
UPDATE S
SET S.IsDeleted = 1
FROM Template T
INNER JOIN TemplateStyle TS WITH (NOLOCK)
	ON T.TemplateId = TS.TemplateId
INNER JOIN Style S WITH (NOLOCK)
	ON TS.StyleId = S.StyleId
WHERE T.TemplateId = @PTemplateId

--DELETE TEMPLATE FIRST      
UPDATE T
SET T.IsDeleted = 1
FROM Template T WITH (NOLOCK)
WHERE T.TemplateId = @PTemplateId

--DELETE SECTION LEVEL THROUGHT CUSTOMER LEVEL      
UPDATE PS
SET PS.TemplateId = NULL
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.CustomerId = @PcustomerId
AND PS.TemplateId = @PTemplateId

--DELETE PROJECT LEVEL THROUGHT CUSTOMER      
UPDATE P
SET P.TemplateId =
(CASE
	WHEN P.MasterDataTypeId = 1 THEN @BsdTemplateId
	WHEN P.MasterDataTypeId = 2 THEN @NmsEnTemplateId
	WHEN P.MasterDataTypeId = 3 THEN @NmsFrTemplateId
END)
FROM Project P WITH (NOLOCK)
WHERE P.CustomerId = @PcustomerId
AND P.TemplateId = @PTemplateId

--COMMIT TRANSACTION

END

GO
