CREATE PROCEDURE [dbo].[usp_GetReferenceStandardsOfChoices]    
  @RsCode INT NULL ,
  @CustomerId INT NULL = NULL
AS    
BEGIN
  
  DECLARE @PRsCode INT = @RsCode;
  DECLARE @PCustomerId INT = @CustomerId;
SET NOCOUNT ON;
SET NOCOUNT ON;
SELECT
	RS.RefStdId
   ,RS.RefStdName
   ,RS.ReplaceRefStdId
   ,RS.IsObsolete
   ,RS.RefStdCode

FROM [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK)
WHERE RS.RefStdCode = @PRsCode
UNION
SELECT
	RS.RefStdId
   ,RS.RefStdName
   ,RS.ReplaceRefStdId
   ,RS.IsObsolete
   ,RS.RefStdCode

FROM ReferenceStandard AS RS WITH (NOLOCK)
WHERE RS.RefStdCode = @PRsCode
AND RS.CustomerId = @PCustomerId
END

GO
