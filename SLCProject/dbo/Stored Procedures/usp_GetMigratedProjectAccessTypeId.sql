CREATE PROCEDURE usp_GetMigratedProjectAccessTypeId  
@CustomerId INT,  
@IsOfficeMaster BIT = 0  
AS  
BEGIN  
DECLARE @PCustomerId int = @CustomerId;  
      
DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;  
      
DECLARE @ProjectOrigineType int = (SELECT ProjectOriginTypeId FROM LuProjectOriginType WITH (NOLOCK)  
         WHERE [Name] = 'Migrated Project');  
  
DROP TABLE IF EXISTS #TempProjDefaultPrivacySetting;  
  
SELECT  
    CustomerId  
   ,ProjectAccessTypeId  
   ,ProjectOriginTypeId  
   ,IsOfficeMaster INTO #TempProjDefaultPrivacySetting  
FROM ProjectDefaultPrivacySetting WITH (NOLOCK)  
WHERE CustomerId = 0 -- Here CustomerId = 0 used purposefully to get Default Settings  
AND ProjectOriginTypeId = @ProjectOrigineType  
AND IsOfficeMaster = @PIsOfficeMaster;  
  
UPDATE t  
SET t.ProjectAccessTypeId = pdps.ProjectAccessTypeId  
FROM #TempProjDefaultPrivacySetting t  
JOIN ProjectDefaultPrivacySetting pdps WITH (NOLOCK)  
 ON t.IsOfficeMaster = pdps.IsOfficeMaster  
 AND t.ProjectOriginTypeId = pdps.ProjectOriginTypeId  
 AND pdps.CustomerId = @PCustomerId;  
  
SELECT ProjectAccessTypeId FROM #TempProjDefaultPrivacySetting;  
  
END;