CREATE PROCEDURE usp_GetMigratedProjectDefaultPrivacySetting        
@CustomerId int,        
@UserId int,      
@IsOfficeMaster bit,      
@ProjectAccessTypeId int OUTPUT,      
@ProjectOwnerId int OUTPUT      
AS        
BEGIN    
        
DECLARE @PCustomerId int = @CustomerId;    

DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;  
  
SET @ProjectOwnerId = NULL;      
   
DECLARE @ProjectOrigineType int = (SELECT ProjectOriginTypeId FROM LuProjectOriginType WITH (NOLOCK)    
        WHERE [Name] = 'Migrated Project');    
  
DECLARE @ProjectOwnerTypeId INT = NULL;    
SELECT    
 CustomerId    
   ,ProjectAccessTypeId    
   ,ProjectOwnerTypeId    
   ,ProjectOriginTypeId    
   ,IsOfficeMaster INTO #ProjDefaultPrivacySetting    
FROM ProjectDefaultPrivacySetting WITH(NOLOCK)    
WHERE CustomerId = 0    
AND ProjectOriginTypeId = @ProjectOrigineType    
AND IsOfficeMaster = @PIsOfficeMaster;    
    
UPDATE t    
SET t.ProjectAccessTypeId = pdps.ProjectAccessTypeId    
   ,t.ProjectOwnerTypeId = pdps.ProjectOwnerTypeId    
FROM #ProjDefaultPrivacySetting t    
JOIN ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
 ON t.IsOfficeMaster = pdps.IsOfficeMaster    
 AND t.ProjectOriginTypeId = pdps.ProjectOriginTypeId    
 AND pdps.CustomerId = @PCustomerId;    
    
    
SELECT TOP 1    
 @ProjectAccessTypeId = ProjectAccessTypeId    
   ,@ProjectOwnerTypeId = ProjectOwnerTypeId    
FROM #ProjDefaultPrivacySetting;    
    
IF (@ProjectOwnerTypeId = 3)    
 SET @ProjectOwnerId = @UserId;    
END