CREATE PROCEDURE usp_HideUnHideBsdSection          
(          
 @ProjectId int          
 ,@CustomerId int          
 ,@SectionId int          
 ,@IsHide bit          
)          
AS          
BEGIN          
SET NOCOUNT ON;          
DECLARE @PProjectId int = @ProjectId          
 ,@PCustomerId int = @CustomerId          
 ,@PSectionId int = @SectionId          
 ,@PIsHide bit = @IsHide;        
   
DECLARE @IsHiddenAllBsdMasterSection bit=0;   
DECLARE @IsSectionLocked int = 0;          
IF @PIsHide = 1          
BEGIN          
          
SELECT TOP 1           
@IsSectionLocked = 1          
FROM ProjectSection PS WITH (NOLOCK)          
WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId           
AND PS.SectionId = @PSectionId          
AND PS.IsLocked = 1          
          
END;          
          
IF @IsSectionLocked = 0          
BEGIN          
             
   UPDATE PS          
   SET          
   IsHidden = @IsHide           
   FROM ProjectSection PS WITH (NOLOCK)          
   WHERE PS.SectionId = @PSectionId AND PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId           
           
   IF NOT EXISTS(SELECT TOP 1 * FROM ProjectSection PS WITH(NOLOCK) WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId AND     
  PS.IsLastLevel = 1 AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsHidden,0) = 0)    
 UPDATE PSM SET PSM.IsHiddenAllBsdSections = 1 FROM ProjectSummary PSM WITH(NOLOCK) WHERE PSM.ProjectId = @PProjectId AND PSM.CustomerId = @PCustomerId;  
    
END;   
    IF(dbo.udf_IsAllBsdMasterSectionHidden(@PProjectId, @PCustomerId) = 1)--Check if all Master Folders(Divisions) are hidden      
  BEGIN    
  set @IsHiddenAllBsdMasterSection=1    
     UPDATE PS          
    SET   PS.IsHiddenAllBsdSections = @IsHiddenAllBsdMasterSection          
   FROM ProjectSummary PS WITH (NOLOCK)          
   WHERE  PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId     
  END;

  IF(dbo.udf_IsAllBsdMasterSectionHidden(@PProjectId, @PCustomerId) = 0)    
  BEGIN    
  set @IsHiddenAllBsdMasterSection=0   
     UPDATE PS          
    SET   PS.IsHiddenAllBsdSections = @IsHiddenAllBsdMasterSection          
   FROM ProjectSummary PS WITH (NOLOCK)          
   WHERE  PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId     
  END;       
SELECT @IsSectionLocked AS IsSectionLocked,@IsHiddenAllBsdMasterSection AS  IsHiddenAllBsdSection ;          
          
END