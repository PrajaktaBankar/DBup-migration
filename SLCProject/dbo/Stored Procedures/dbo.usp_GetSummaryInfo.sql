CREATE PROCEDURE [dbo].[usp_GetSummaryInfo]                          
(                
 @ProjectId int,                 
 @CustomerId int,                 
 @IsSummaryInfoPage bit = 0                
)                
AS                
BEGIN                                    
                                     
 DECLARE @PProjectId int = @ProjectId;                                    
 DECLARE @PCustomerId int = @CustomerId;                                    
 DECLARE @ActiveSectionsCount INT = 0;                          
 DECLARE @TotalSectionsCount INT = 0;                         
 Declare @IsAnySectionIsLocked INT = 0;            
 DECLARE @IsAllowHideMasterFolder INT = 0;                    
                         
 -- Only fetch total and active sections count if @IsSummaryInfoPage is true                          
 IF(@IsSummaryInfoPage = 1)                          
 BEGIN                        
                         
 DROP TABLE IF EXISTS #TempProjectSection;                        
 SELECT PS.SectionId , PS.ParentSectionId, PS.mSectionId, PS.IsLocked, PS.IsLastLevel, PS.LevelId                       
 INTO #TempProjectSection                        
 FROM ProjectSection PS WITH (NOLOCK)                                    
 WHERE PS.CustomerId = @PCustomerId                        
  AND PS.ProjectId = @PProjectId                                                 
  AND ISNULL(PS.IsDeleted,0) = 0;                        
                        
  SET @TotalSectionsCount = (SELECT COUNT(1) FROM #TempProjectSection WHERE IsLastLevel = 1);                        
                        
  SET @ActiveSectionsCount = (SELECT                                    
    COUNT(1)                                    
   FROM #TempProjectSection PS WITH (NOLOCK)                                    
   INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)                                    
    ON PS.SectionId = PSST.SectionId                    
   WHERE PS.IsLastLevel = 1 AND PSST.ProjectId = @PProjectId                                    
   AND PSST.CustomerId = @PCustomerId                        
   AND PSST.ParentSegmentStatusId = 0                                    
   AND PSST.SegmentStatusTypeId > 0                                    
   AND PSST.SegmentStatusTypeId < 6);                         
                       
   SELECT TOP 1                     
   @IsAnySectionIsLocked = 1                    
   FROM #TempProjectSection PS WITH (NOLOCK)                    
   WHERE ISNULL(IsLocked,0) = 1          
   AND PS.IsLastLevel =1                    
   AND ISNULL(PS.mSectionId,0) > 0                    
               
   SELECT TOP 1 @IsAllowHideMasterFolder = 1             
   FROM #TempProjectSection userPS WITH(NOLOCK) INNER JOIN #TempProjectSection PS WITH(NOLOCK)              
   ON userPS.ParentSectionId = PS.SectionId               
   WHERE userPS.LevelId <> 2                   
   AND ISNULL(userPS.mSectionId,0) = 0              
   AND ISNULL(PS.mSectionId,0) > 0;             
                         
   DROP TABLE IF EXISTS #TempProjectSection;                                   
 END                         
                         
  --Used to get Global Term For GT with name ProjectId in Master                                  
 --DECLARE @ProjectIdGlobalTermCode INT = 2;                                   
 DECLARE @ProjectIdGlobalTermName NVARCHAR(50) = 'Project ID', @GTValue NVARCHAR(100) = '';                        
 SELECT TOP 1 @GTValue = PG.[value] FROM ProjectGlobalTerm PG WHERE PG.ProjectId = @PProjectId AND PG.[Name] = @ProjectIdGlobalTermName;                         
                        
  SELECT                                    
   P.ProjectId                        
  ,@GTValue AS GlobalTermProjectIdValue                                    
  ,P.[Name] AS ProjectName                                  
  ,P.CreatedBy                                    
  ,UF.UserId AS ModifiedBy                                    
  ,@ActiveSectionsCount AS ActiveSectionsCount                                    
  ,@TotalSectionsCount AS TotalSectionsCount                                    
  ,PSMRY.SpecViewModeId                          
  ,PSMRY.TrackChangesModeId                          
  ,P.IsMigrated AS IsMigratedProject               
  ,PAdress.CountryId                                    
  ,LC.CountryName                                    
  ,ISNULL(PAdress.StateProvinceId, 0) AS StateProvinceId                                    
  ,ISNULL(LS.StateProvinceName, PAdress.StateProvinceName) AS StateProvinceName                                    
,ISNULL(PAdress.CityId, 0) AS CityId                                    
  ,ISNULL(LCity.City, PAdress.CityName) AS City                                    
  ,PSMRY.ProjectTypeId                                    
  ,PSMRY.FacilityTypeId                                    
  ,PSMRY.ActualSizeId AS ProjectSize                                    
  ,PSMRY.ActualCostId AS ProjectCost                                    
  ,PSMRY.SizeUoM AS ProjectSizeUOM                                    
  ,P.CreateDate AS CreateDate                                    
  ,UF.LastAccessed AS ModifiedDate                                    
  ,PSMRY.LastMasterUpdate                                    
  ,PSMRY.IsActivateRsCitation                                    
  ,PSMRY.IsPrintReferenceEditionDate                                 
  ,PSMRY.IsIncludeRsInSection                                    
  ,PSMRY.IsIncludeReInSection                                    
  ,PSMRY.SourceTagFormat                                    
  ,PSMRY.UnitOfMeasureValueTypeId                                    
  ,P.IsNamewithHeld                                    
  ,P.MasterDataTypeId                                    
  ,LMDT.[Description] AS MasterDataTypeName                                    
  ,LC.CountryCode                                  
  ,PSMRY.ProjectAccessTypeId                              
  ,PSMRY.OwnerId                      
  ,PSMRY.IsHiddenAllBsdSections            
  ,CAST(ISNULL(dbo.fn_GetProjectSettingValue(@ProjectId, @CustomerId, 'IsHiddenAllBsdFolders'),0) AS BIT) AS IsHiddenAllBsdFolders                      
  ,CASE WHEN @IsAnySectionIsLocked = 1                    
    THEN 1  --'All Master sections must be unlocked before hiding them.'                    
    ELSE 0                    
    END                    
    AS HideAllBsdSectionsStatusTypeId            
  ,CASE WHEN @IsAllowHideMasterFolder = 1            
    THEN 1            
    ELSE 0            
    END AS HideAllBsdFoldersStatusTypeId                   
  FROM Project P WITH (NOLOCK)                                                    
  INNER JOIN LuMasterDataType LMDT WITH (NOLOCK)                                    
   ON LMDT.MasterDataTypeId = P.MasterDataTypeId                    
  INNER JOIN ProjectSummary PSMRY WITH (NOLOCK)                                    
   ON P.ProjectId = PSMRY.ProjectId                                    
  INNER JOIN UserFolder UF WITH (NOLOCK)                                    
   ON P.ProjectId = UF.ProjectId                                    
  INNER JOIN ProjectAddress PAdress WITH (NOLOCK)                                    
   ON P.ProjectId = PAdress.ProjectId                                    
  INNER JOIN LuCountry LC WITH (NOLOCK)                                    
   ON PAdress.CountryId = LC.CountryId                                    
  LEFT OUTER JOIN LuStateProvince LS WITH (NOLOCK)                                    
   ON PAdress.StateProvinceId = LS.StateProvinceID                                    
  LEFT OUTER JOIN LuCity LCity WITH (NOLOCK)                                    
   ON PAdress.CityId = LCity.CityId                                    
  --LEFT OUTER JOIN ProjectGlobalTerm PGT WITH (NOLOCK)                                    
  -- ON PGT.ProjectId =P.ProjectId                                     
  WHERE P.ProjectId = @PProjectId               
  AND P.CustomerId = @PCustomerId;                        
  --AND PGT.[Name] = @ProjectIdGlobalTermName                        
END 