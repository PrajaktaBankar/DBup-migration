CREATE PROCEDURE [dbo].[usp_CreateDatabase]
(
 @CustomerId INT = 0
)
AS
BEGIN  
  DECLARE @PCustomerId INT = @CustomerId;
  DECLARE @DbName NVARCHAR(MAX);
  SET @DbName='SLCProject_'+ CAST(@PCustomerId as NVARCHAR(10));
 
 EXEC ('CREATE DATABASE '+@DbName)  
 EXEC ('USE '+@DbName)
 --EXEC ('Drop Database '+@DbName)
 EXEC [usp_CreateLookupTables] @DbName
END

GO
