CREATE PROCEDURE [dbo].[usp_CreateLookupTables]
(
 @DbName NVARCHAR(MAX) = 0
)
AS
BEGIN
    
DECLARE @PDbName NVARCHAR(MAX)= @DbName;
EXEC ('USE ' + @PDbName)
SELECT
	10
END

GO
