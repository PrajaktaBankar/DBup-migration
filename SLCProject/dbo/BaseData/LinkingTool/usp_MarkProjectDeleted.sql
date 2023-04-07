
CREATE PROCEDURE [dbo].[usp_MarkProjectDeleted]
AS
BEGIN

--Mark more than 7 days old projects as deleted so it can be removed permanently from the database with the help of Delete Project job

DECLARE @CustomerId AS INT
SELECT @CustomerId = CustomerId FROM [SpecData].[dbo].[CustomerAccessKey] WITH (NOLOCK) WHERE CustomerName = 'USG Corporation'

UPDATE SLCProject.dbo.Project SET IsDeleted = 1, IsPermanentDeleted = 1 WHERE CustomerId = @CustomerId AND CreateDate < GETDATE()-7

END