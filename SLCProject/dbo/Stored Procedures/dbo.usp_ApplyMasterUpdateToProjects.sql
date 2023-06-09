CREATE PROCEDURE [dbo].[usp_ApplyMasterUpdateToProjects]         
 @projectId INT NULL, @customerId INT NULL        
AS        
BEGIN      
DECLARE @PprojectId INT = @projectId;      
DECLARE @PcustomerId INT = @customerId;      
SET NOCOUNT ON      
        
--TODO : CREATE COMMON SP TO CALL ALL UPDATES SPs : START        
         
 DECLARE @LastUpdateDate DateTime2      
         
 DECLARE @isProjectExists bit=0      
        
 IF( EXISTS (SELECT top 1 1 FROM ApplyMasterUpdateLog AS al WITH (NOLOCK)      
 WHERE al.ProjectId = @PprojectId)      
)      
BEGIN      
SET @LastUpdateDate = (SELECT      
 TOP 1      
  LastUpdateDate      
 FROM ApplyMasterUpdateLog AS al WITH (NOLOCK)      
 WHERE al.ProjectId = @PprojectId      
 ORDER BY LastUpdateDate DESC);      
SET @isProjectExists = 1;      
        
        
        
 END        
 ELSE      
SET @isProjectExists = 0;      
      
IF (EXISTS (SELECT top 1 1      
  FROM SLCMaster..SLCUpdateServiceLog AS l WITH (NOLOCK)      
  WHERE ((l.LastUpdateDate >= @LastUpdateDate      
  AND @isProjectExists = 1)      
  OR @isProjectExists = 0)      
  AND l.TableName = 'SECTION'      
  AND l.RecordCount > 0      
  AND l.ActionType = 'Insert')      
 )      
BEGIN      
      
PRINT 'sp_LoadUnMappedMasterSectionsToExistingProjectUpdates'      
      
--CALL SP FOR EXISTING PROJECT TO SECTION NEWLLY ADDED SECTION          
EXECUTE [sp_LoadUnMappedMasterSectionsToExistingProjectUpdates] @projectId = @PprojectId      
END      
      
IF (EXISTS (SELECT top 1 1      
  FROM SLCMaster..SLCUpdateServiceLog AS l WITH (NOLOCK)      
  WHERE ((l.LastUpdateDate >= @LastUpdateDate      
  AND @isProjectExists = 1)      
  OR @isProjectExists = 0)      
  AND l.TableName = 'SegmentStatus'      
  AND l.RecordCount > 0      
  AND l.ActionType = 'Update')      
 )      
BEGIN      
PRINT 'SPECTYPE'      
--UPDATE SLCPROJECT FOR SPECTYPE TAG        
UPDATE PSS      
SET   
PSS.SpecTypeTagId = SS.SpecTypeTagId,  
PSS.ModifiedDate = GETUTCDATE()  
FROM ProjectSegmentStatus PSS WITH (NOLOCK)      
INNER JOIN SLCMaster..SegmentStatus SS WITH (NOLOCK)      
 ON PSS.mSegmentStatusId = SS.SegmentStatusId      
WHERE PSS.SegmentSource = 'M'      
AND PSS.SegmentOrigin = 'M'      
AND PSS.SpecTypeTagId IS NULL      
AND SS.SpecTypeTagId IS NOT NULL      
AND PSS.ProjectId = @PprojectId      
AND PSS.CustomerId = @PcustomerId    
AND ISNULL(SS.IsDeleted,0) = 0      
END      
      
-- Start : Commented to implement User Story 30400: Updates: Tags (revised implementation of 10642)
--IF (EXISTS (SELECT top 1 1      
--  FROM SLCMaster..SLCUpdateServiceLog  AS l WITH (NOLOCK)      
--  WHERE ((l.LastUpdateDate >= @LastUpdateDate      
--  AND @isProjectExists = 1)      
--  OR @isProjectExists = 0)      
--  AND l.TableName = 'RequirementTag'      
--  AND l.RecordCount > 0      
--  AND l.ActionType = 'Delete')      
-- )      
--BEGIN      
      
---- DELETE RECORDS FROM SLCProject        
----DELETE PSRT    
---- FROM dbo.ProjectSegmentRequirementTag PSRT WITH (NOLOCK)    
---- LEFT JOIN SLCMaster..SegmentRequirementTag SRT WITH (NOLOCK)    
----  ON SRT.SegmentRequirementTagId = PSRT.mSegmentRequirementTagId    
----WHERE SRT.SegmentRequirementTagId IS NULL    
---- AND PSRT.mSegmentRequirementTagId IS NOT NULL    
---- AND PSRT.ProjectId = @PprojectId    
---- AND PSRT.CustomerId = @PcustomerId;    
    
----update PSRT      
----set PSRT.IsDeleted=1      
--DELETE PSRT      
-- FROM dbo.ProjectSegmentRequirementTag PSRT WITH (NOLOCK)      
-- INNER JOIN dbo.ProjectSegmentStatus PSS WITH (NOLOCK)      
-- ON PSS.SegmentStatusId = PSRT.SegmentStatusId    
-- LEFT JOIN SLCMaster..SegmentStatus MSS WITH (NOLOCK)      
-- ON MSS.SegmentId = PSS.mSegmentId      
-- LEFT JOIN SLCMaster..SegmentRequirementTag SRT WITH (NOLOCK)      
--  ON SRT.SegmentRequirementTagId = PSRT.mSegmentRequirementTagId      
--WHERE SRT.SegmentRequirementTagId IS NULL      
-- AND PSRT.mSegmentRequirementTagId IS NOT NULL      
-- AND PSRT.ProjectId = @PprojectId      
-- AND PSRT.CustomerId = @PcustomerId    
-- AND ISNULL(MSS.IsDeleted,0) = 0
      
--END; 

-- End : Commented to implement User Story 30400: Updates: Tags (revised implementation of 10642)

    
     
IF (EXISTS (SELECT top 1 1        FROM SLCMaster..SLCUpdateServiceLog AS l WITH (NOLOCK)      
  WHERE ((l.LastUpdateDate >= @LastUpdateDate      
  AND @isProjectExists = 1)      
  OR @isProjectExists = 0)      
  AND l.TableName = 'SECTION'      
  AND l.RecordCount > 0      
  AND l.ActionType = 'Update')      
)      
BEGIN      
PRINT 'usp_updateSectionNameAndID'      
      
/* SP CALL TO MODIFIY SECTION NAME AND ID */      
EXEC usp_updateSectionNameAndID @projectId = @PprojectId      
END      
/* CHECK DELETED MASTER SECTION IN A PROJECT */      
/* NOTE: Commented below due to performance [Delete Section Scenario - 1] */      
      
IF (EXISTS (SELECT top 1       
   1      
  FROM SLCMaster..SLCUpdateServiceLog AS l WITH (NOLOCK)      
  WHERE ((l.LastUpdateDate >= @LastUpdateDate      
  AND @isProjectExists = 1)      
  OR @isProjectExists = 0)      
  AND l.TableName = 'SECTION'      
  AND l.RecordCount > 0      
  AND l.ActionType = 'Delete')      
 )      
BEGIN      
PRINT 'usp_deletedMasterSectionsFromProject'      
      
EXEC usp_deletedMasterSectionsFromProject @projectId = @PprojectId      
            ,@customerId = @PcustomerId      
END      
-- : END        
--TODO Entry in ApplyMasterUpdateLog        
IF ((SELECT      
   COUNT(*)      
  FROM ApplyMasterUpdateLog AS al WITH (NOLOCK)      
  WHERE al.ProjectId = @PprojectId)      
 = 0)      
BEGIN      
INSERT INTO ApplyMasterUpdateLog (ProjectId, LastUpdateDate)      
 VALUES (@PprojectId, GETUTCDATE())      
END      
ELSE      
IF (@isProjectExists = 1)      
BEGIN      
UPDATE amd      
SET amd.LastUpdateDate = GETUTCDATE()      
from ApplyMasterUpdateLog amd WITH (NOLOCK)      
WHERE ProjectId = @PprojectId      
END      
      
END