CREATE procedure usp_GetTransferredProjectDefaultPrivacySetting  
@CustomerId int,  
@IsOfficeMaster bit  
AS  
BEGIN  
DECLARE @PCustomerId int = @CustomerId;  
DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;  
DECLARE @ProjectOrigineType int = 3; -- Transferred Project  
  
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
  
SELECT  
 ProjectAccessTypeId  
   ,ProjectOwnerTypeId  
FROM #ProjDefaultPrivacySetting;  
END