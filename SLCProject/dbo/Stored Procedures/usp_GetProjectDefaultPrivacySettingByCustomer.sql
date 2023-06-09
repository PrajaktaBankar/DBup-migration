CREATE PROCEDURE usp_GetProjectDefaultPrivacySettingByCustomer      
(      
@CustomerId int      
)      
AS      
BEGIN  
      
DECLARE @PCustomerId int = @CustomerId;  
  
DROP TABLE IF EXISTS #projectPrivacySettings;  
  
SELECT  
 CustomerId  
   ,ProjectAccessTypeId  
   ,ProjectOwnerTypeId  
   ,ProjectOriginTypeId  
   ,IsOfficeMaster INTO #projectPrivacySettings  
FROM ProjectDefaultPrivacySetting WITH (NOLOCK)  
WHERE CustomerId = 0;  
  
--select * from #projectPrivacySettings  
UPDATE t  
SET t.ProjectAccessTypeId = pps.ProjectAccessTypeId  
   ,t.ProjectOwnerTypeId = pps.ProjectOwnerTypeId  
FROM #projectPrivacySettings t  
JOIN ProjectDefaultPrivacySetting pps WITH (NOLOCK)  
 ON   
 t.ProjectOriginTypeId = pps.ProjectOriginTypeId  
 AND t.IsOfficeMaster = pps.IsOfficeMaster  
 where pps.CustomerId = @PCustomerId;  
  
select * from #projectPrivacySettings;  
END;