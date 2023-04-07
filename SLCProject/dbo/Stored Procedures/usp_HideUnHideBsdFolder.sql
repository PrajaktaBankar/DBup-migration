CREATE PROCEDURE usp_HideUnHideBsdFolder                                    
(                                    
  @ProjectId int,                                    
  @CustomerId int,                                    
  @UserId int,                                    
  @IsHide bit,                                    
  @SectionId int                                    
)                                    
AS                                    
BEGIN                                    
SET NOCOUNT ON;                                    
DECLARE @PProjectId int = @ProjectId,                                    
  @PCustomerId int = @CustomerId,                                    
  @PUserId int = @UserId,                                    
  @PIsHide bit = @IsHide,                                    
  @PSectionId int = @SectionId,                                   
  @IsMasterFolder bit = 0;                                          
Declare @IsSectionLocked int = 0;       
DECLARE @IsHiddenAllBsdFolders bit = 0;     
DECLARE @IsHiddenAllBsdSections bit = 0; 
DECLARE @IsAllDivisionHidden int = 0; 
DECLARE @IsAllSeCtionHidden int = 0;  
DECLARE @MasterDataTypeId INT = (SELECT TOP 1 MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);                                    
                                    
IF @IsHide = 1                                   
BEGIN                              
                            
SELECT ProjectId,CustomerId,SectionId,ParentSectionId,IsLocked,IsLastLevel                             
INTO #ProjectSectionList                            
FROM ProjectSection                             
WHERE ProjectId=@PProjectId AND CustomerId= @PCustomerId AND ISNULL(IsDeleted,0) = 0                            
                             
SELECT TOP 1                                      
@IsSectionLocked = 1                                     
FROM #ProjectSectionList PS1 WITH (NOLOCK)                                    
INNER JOIN #ProjectSectionList PS2 WITH (NOLOCK)                                    
ON PS2.ParentSectionId = PS1.SectionId                                    
AND PS2.ProjectId = PS1.ProjectId                                    
AND PS2.CustomerId = PS1.CustomerId                                    
INNER JOIN #ProjectSectionList PS3 WITH (NOLOCK)                                    
ON PS3.ParentSectionId = PS2.SectionId                                    
AND PS3.ProjectId = PS2.ProjectId                                    
AND PS3.CustomerId = PS2.CustomerId                                    
WHERE PS1.SectionId = @PSectionId AND PS1.ProjectId= @PProjectId AND PS1.CustomerId =@PCustomerId                                    
AND PS3.IsLastLevel = 1 AND PS3.IsLocked = 1                                    
                                    
SELECT TOP 1                                      
@IsSectionLocked = 1                                     
FROM #ProjectSectionList PS1 WITH (NOLOCK)                                    
INNER JOIN #ProjectSectionList PS2 WITH (NOLOCK)                                    
ON PS2.ParentSectionId = PS1.SectionId                                    
AND PS2.ProjectId = PS1.ProjectId                                    
AND PS2.CustomerId = PS1.CustomerId                                    
WHERE PS1.SectionId = @PSectionId AND PS1.ProjectId= @PProjectId AND PS1.CustomerId =@PCustomerId                                    
AND PS2.IsLastLevel = 1 AND PS2.IsLocked = 1                                    
END;                                    
                                    
IF @IsSectionLocked = 0                                    
BEGIN                                    
                                     
 UPDATE  PS                                    
 SET IsHidden = @IsHide,                                    
 ModifiedBy = @PUserId,                                    
 ModifiedDate = GETUTCDATE()                                    
 FROM ProjectSection PS WITH (NOLOCK)                                     
 WHERE ProjectId=@PProjectId AND SectionId=@PSectionId AND CustomerId= @PCustomerId                                    
            
  IF(@MasterDataTypeId = 1 AND @MasterDataTypeId = 4)          
  BEGIN          
 SELECT @IsMasterFolder = 1             
 FROM ProjectSection PS WITH (NOLOCK)                     
 WHERE PS.SectionId = @PSectionId AND PS.ProjectId = @PProjectId                    
 AND PS.CustomerId = @PCustomerId AND PS.IsLastLevel= 0 AND PS.LevelId = 2          
 AND ISNULL(mSectionId,0) >0;                
  END          
  ELSE -- NMS Master          
  BEGIN          
 SELECT @IsMasterFolder = 1                   
 FROM ProjectSection PS WITH (NOLOCK)                     
 WHERE PS.SectionId = @PSectionId AND PS.ProjectId = @PProjectId                    
 AND PS.CustomerId = @PCustomerId AND ISlastLevel = 0 AND ISNULL(mSectionId,0) > 0           
 AND ISNULL(IsDeleted,0) = 0 AND (LevelId = 1 OR (LevelId = 2 AND Sourcetag IN ('A','B','C','D','E','G')));                  
  END;                            
  IF @IsHide = 0                    
  BEGIN                    
  DECLARE @IsLeafSection bit =  0;            
                      
  SELECT @IsLeafSection = 1                    
   FROM ProjectSection PS WITH (NOLOCK)                     
   WHERE PS.SectionId = @PSectionId AND PS.IsLastLevel= 1 AND PS.ProjectId = @PProjectId                    
   AND PS.CustomerId = @PCustomerId;                    
                    
  IF @IsLeafSection = 1 AND (SELECT TOP 1 ISNULL(IsHiddenAllBsdSections,0) FROM ProjectSummary WITH (NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId) = 1                    
  BEGIN                    
   UPDATE PS                    
   SET IsHiddenAllBsdSections = 0                    
   FROM ProjectSummary PS WITH (NOLOCK)                    
   WHERE ProjectId = @ProjectId AND CustomerId = @PCustomerId                    
  END;                 
            
IF (@IsMasterFolder = 1)            
  BEGIN                 
   EXEC usp_SetProjectSettingValue @PProjectId,@PCustomerId, 'IsHiddenAllBsdFolders', '0' , @UserId;           
  END;                
  END;       
 set @IsAllDivisionHidden=  dbo.udf_IsAllBsdMasterDivisionHidden(@PProjectId, @PCustomerId)
   IF(@IsAllDivisionHidden = 0)         
  BEGIN        
   set @IsHiddenAllBsdFolders=1        
 EXEC usp_SetProjectSettingValue @PProjectId,@PCustomerId, 'IsHiddenAllBsdFolders', '0' , @UserId;           
  END;     
 IF(@IsAllDivisionHidden = 1)--Check if all Master Folders(Divisions) are hidden          
  BEGIN        
   SET @IsHiddenAllBsdFolders=1        
 EXEC usp_SetProjectSettingValue @PProjectId,@PCustomerId, 'IsHiddenAllBsdFolders', '1' , @UserId;           
  END;     
      
  SET @IsAllSeCtionHidden=dbo.udf_IsAllBsdMasterSectionHidden(@PProjectId, @PCustomerId)
   IF(@IsAllSeCtionHidden = 1)          
  BEGIN        
   UPDATE PS                    
   SET IsHiddenAllBsdSections = 1                    
   FROM ProjectSummary PS WITH (NOLOCK)                    
   WHERE ProjectId = @ProjectId AND CustomerId = @PCustomerId   
     END;   
    
  IF(@IsAllSeCtionHidden = 0)          
  BEGIN        
   UPDATE PS                    
   SET IsHiddenAllBsdSections = 0                    
   FROM ProjectSummary PS WITH (NOLOCK)                    
   WHERE ProjectId = @ProjectId AND CustomerId = @PCustomerId                                                
END;                                             
END;     
    
                                     
                                    
SELECT @IsSectionLocked AS IsSectionLocked ,@IsHiddenAllBsdFolders AS IsHiddenFolder                                                                 
END 