CREATE Procedure usp_HideAllBsdFolders                          
(                                
 @ProjectId int                                  
,@CustomerId int                                  
,@MasterDataTypeId int          
,@IsHide bit       
,@UserId int                                 
)                                  
AS                                  
Begin                                        
SET NOCOUNT ON;                              
                                
Declare                                          
 @PProjectId int  = @ProjectId                                        
,@PCustomerId int = @CustomerId                                        
,@PIsHide bit = @IsHide                                        
,@ResponseId int = 0;
                      
IF @IsHide = 1                      
BEGIN                      
        
SELECT TOP 1 @ResponseId = 1              
 FROM ProjectSection userPS WITH(NOLOCK) INNER JOIN ProjectSection PS WITH(NOLOCK)              
 ON userPS.ParentSectionId = PS.SectionId               
 WHERE userPS.ProjectId = @PProjectId               
 AND userPS.CustomerId = @PCustomerId               
 AND userPS.LevelId <> 2              
 AND ISNULL(userPS.IsDeleted,0) = 0                
 AND ISNULL(userPS.mSectionId,0) = 0              
 AND ISNULL(PS.mSectionId,0) > 0;        
        
 IF(@ResponseId = 0)        
SELECT TOP 1                   
   @ResponseId = 2                  
   FROM ProjectSection PS WITH (NOLOCK)                  
   WHERE PS.ProjectId = @PProjectId                
   AND PS.CustomerId = @PCustomerId                
   AND PS.IsLastLevel = 1                
   AND ISNULL(IsLocked,0) = 1                  
   AND ISNULL(PS.mSectionId,0) > 0;                 
END;                  
                  
IF (@IsHide = 0 OR (@IsHide = 1 AND @ResponseId = 0))                
BEGIN                  
  UPDATE PS                      
  SET PS.IsHidden = @IsHide                      
  FROM ProjectSection PS WITH (NOLOCK)                      
  WHERE PS.ProjectId = @PProjectId                      
  AND PS.CustomerId = @PCustomerId                      
  AND ISNULL(PS.mSectionId,0) > 0          
  AND ((@MasterDataTypeId IN (1,4) AND PS.IsLastLevel = 0 AND PS.LevelId = 2) OR          
  (@MasterDataTypeId IN (2,3) AND ((LevelId = 1 and IsLastLevel= 0) OR           
 (ISNULL(mSectionId,0)>0 AND SourceTag IN('A','B','C','D','E','G')))))          
                        
      
   EXEC usp_SetProjectSettingValue @PProjectId,@PCustomerId, 'IsHiddenAllBsdFolders', @IsHide, @UserId;                          
                  
END;                  
                          
 SELECT @ResponseId  AS ResponseId;                                    
End; 