CREATE PROCEDURE [dbo].[usp_DeleteProjectGlobalTerms]  
@UserGlobalTermId INT NULL,
@CustomerId INT NULL 
AS       
BEGIN
DECLARE @PUserGlobalTermId INT = @UserGlobalTermId;
DECLARE @PCustomerId INT = @CustomerId;
--Set Nocount On
SET NOCOUNT ON;

SET NOCOUNT ON;
UPDATE UT
SET UT.IsDeleted = 1
from UserGlobalTerm UT WITH(NOLOCK)
WHERE UT.UserGlobalTermId = @PUserGlobalTermId
AND UT.CustomerId = @PCustomerId

UPDATE PGT
SET PGT.IsDeleted = 1
from ProjectGlobalTerm PGT  WITH(NOLOCK)
WHERE PGT.UserGlobalTermId = @PUserGlobalTermId
AND PGT.CustomerId = @PCustomerId
AND PGT.GlobalTermSource = 'U'

END
GO
