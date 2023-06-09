CREATE PROCEDURE [dbo].[usp_UpdateProjectGlobalTerm]      
(     
 @GlobalTermId INT,      
 @GlobalTermsvalue NVARCHAR(255),      
 @GlobalTermsName NVARCHAR(255),      
 @ModifiedBy INT  ,    
 @ProjectId  INT ,    
 @GlobalTermFieldTypeId smallint    
)    
AS      
BEGIN
    
     
 DECLARE @PGlobalTermId INT = @GlobalTermId;
    
 DECLARE @PGlobalTermsvalue NVARCHAR(255) = @GlobalTermsvalue;
    
 DECLARE @PGlobalTermsName NVARCHAR(255) = @GlobalTermsName;
    
 DECLARE @PModifiedBy INT = @ModifiedBy;
    
 DECLARE @PProjectId  INT = @ProjectId;
    
 DECLARE @PGlobalTermFieldTypeId smallint = @GlobalTermFieldTypeId;
    
  
DECLARE @DateFormat NVARCHAR(10) = NULL;
DECLARE @OldGlobalTermValue NVARCHAR(255) = NULL;
SELECT
	@OldGlobalTermValue = [Value]
FROM ProjectGlobalTerm
WHERE GlobalTermId = @PGlobalTermId

UPDATE PGT
SET PGT.[Value] = @PGlobalTermsvalue
   ,PGT.OldValue = @OldGlobalTermValue
   ,PGT.[Name] = @PGlobalTermsName
   ,PGT.ModifiedBy = @PModifiedBy
   ,PGT.ModifiedDate = GETUTCDATE()
   ,PGT.GlobalTermFieldTypeId = @PGlobalTermFieldTypeId
FROM ProjectGlobalTerm PGT WITH (NOLOCK)
WHERE PGT.GlobalTermId = @PGlobalTermId

DECLARE @OutputTable TABLE (
	IsMigrated BIT
   ,IsOldProject BIT
   ,[DateFormat] NVARCHAR(50)
   ,TimeFormat NVARCHAR(50)
   ,OldGlobalTermValue NVARCHAR(500) NULL
   ,ModifiedDate DATETIME2
   ,ModifiedBy INT
)

INSERT INTO @OutputTable (IsMigrated, IsOldProject, [DateFormat], TimeFormat)
EXEC usp_getGTDateFormat @PProjectId

UPDATE @OutputTable
SET OldGlobalTermValue = @OldGlobalTermValue

UPDATE @OutputTable
SET ModifiedDate = (SELECT TOP 1
		ModifiedDate
	FROM ProjectGlobalTerm WITH (NOLOCK)
	WHERE GlobalTermId = @PGlobalTermId)

UPDATE @OutputTable
SET ModifiedBy = (SELECT TOP 1
		ModifiedBy
	FROM ProjectGlobalTerm WITH (NOLOCK)
	WHERE GlobalTermId = @PGlobalTermId)

SELECT
	*
FROM @OutputTable;


END

GO