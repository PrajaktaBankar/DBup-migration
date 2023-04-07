USE SLCProject_SqlSlcOp005
Go

DECLARE @CustomerId INT= 1033 
DECLARE @UserGlobalTermId INT= 140
DECLARE @GlobalTermCode INT = 10000024

UPDATE PGT  SET PGT.GlobalTermCode = @GlobalTermCode 
FROM ProjectGlobalTerm PGT WITH (NOLOCK)
WHERE PGT.UserGlobalTermId=@UserGlobalTermId
 AND PGT.CustomerId = @CustomerId 