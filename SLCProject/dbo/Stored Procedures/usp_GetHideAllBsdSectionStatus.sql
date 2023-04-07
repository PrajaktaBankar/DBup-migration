CREATE PROCEDURE [dbo].[usp_GetHideAllBsdSectionStatus]              
(                  
 @ProjectId int                  
,@CustomerId int                  
)                  
AS                  
BEGIN                  
SET NOCOUNT ON;                  
Declare @PProjectId int = @ProjectId;                  
Declare @PCustomerId int = @CustomerId;                  
Declare @IsAnySectionIsLocked bit = 0;                    
DECLARE @IsAllowHideMasterFolder bit = 0;          
DECLARE @IsHiddenAllBsdFolders bit = 0;  
          
SELECT TOP 1                     
   @IsAnySectionIsLocked = 1                    
   FROM ProjectSection PS WITH (NOLOCK)                    
   WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND PS.IsLastLevel = 1                  
   AND ISNULL(IsLocked,0) = 1                    
   AND ISNULL(PS.mSectionId,0) > 0                    
      
DROP TABLE IF EXISTS #TempProjectSection;      
 DROP TABLE IF EXISTS #TempProjectSection;                      
 SELECT PS.SectionId , PS.ParentSectionId, PS.mSectionId, PS.IsLocked, PS.IsLastLevel, PS.LevelId                     
 INTO #TempProjectSection                      
 FROM ProjectSection PS WITH (NOLOCK)                                  
 WHERE PS.CustomerId = @PCustomerId                      
  AND PS.ProjectId = @PProjectId                                               
  AND ISNULL(PS.IsDeleted,0) = 0;        
         
SELECT TOP 1 @IsAllowHideMasterFolder = 1 -- userPS.*          
 FROM #TempProjectSection userPS WITH(NOLOCK) INNER JOIN #TempProjectSection PS WITH(NOLOCK)          
 ON userPS.ParentSectionId = PS.SectionId           
 WHERE userPS.LevelId <> 2              
 AND ISNULL(userPS.mSectionId,0) = 0          
 AND ISNULL(PS.mSectionId,0) > 0;          
  
SET @IsHiddenAllBsdFolders = CAST(ISNULL(dbo.fn_GetProjectSettingValue(@ProjectId, @CustomerId, 'IsHiddenAllBsdFolders'),0) AS BIT);  
            
SELECT                   
ISNULL(PS.IsHiddenAllBsdSections,0) AS IsHiddenAllBsdSections,            
@IsHiddenAllBsdFolders AS IsHiddenAllBsdFolders,                  
 CASE WHEN @IsAnySectionIsLocked = 1                    
      THEN 1  --'All Master sections must be unlocked before hiding them.'                    
      ELSE 0                    
      END  AS ResponseId,          
CASE WHEN @IsAllowHideMasterFolder = 1                    
      THEN CAST(0 AS BIT)  --'All Master sections must be unlocked before hiding them.'                    
      ELSE CAST(1 AS BIT)                    
      END  AS IsAllowHideMasterFolder          
FROM ProjectSummary PS WITH (NOLOCK)                  
WHERE PS.ProjectId = @PProjectId                  
AND PS.CustomerId = @PCustomerId                  
                   
END;   