CREATE Procedure usp_HideAllBsdSections                
(                
 @ProjectId int                  
,@CustomerId int                  
,@IsHide bit                  
)                  
AS                  
Begin                        
SET NOCOUNT ON;              
                
Declare                          
 @PProjectId int  = @ProjectId                        
,@PCustomerId int = @CustomerId                        
,@PIsHide bit = @IsHide                        
,@IsAnySectionIsLocked bit = 0                   
,@ResponseId int = 0;                    
      
IF @IsHide = 1      
BEGIN      
      
SELECT TOP 1         
   @IsAnySectionIsLocked = 1        
   FROM ProjectSection PS WITH (NOLOCK)        
   WHERE PS.ProjectId = @PProjectId      
   AND PS.CustomerId = @PCustomerId      
   AND PS.IsLastLevel = 1      
   AND ISNULL(IsLocked,0) = 1        
   AND ISNULL(PS.mSectionId,0) > 0     
      
END;  
  
IF @IsAnySectionIsLocked = 0  
BEGIN  
  
UPDATE PS      
  SET PS.IsHidden = @IsHide      
  FROM ProjectSection PS WITH (NOLOCK)      
  WHERE PS.ProjectId = @PProjectId      
  AND PS.CustomerId = @PCustomerId      
  AND PS.IsLastLevel = 1      
  AND ISNULL(PS.mSectionId,0) > 0      
      
  UPDATE PS                  
  SET                  
  PS.IsHiddenAllBsdSections = @IsHide                  
  FROM ProjectSummary PS WITH (NOLOCK)                  
  WHERE PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId    
  
END;  
          
 SELECT       
 CASE WHEN @IsAnySectionIsLocked = 1        
      THEN 1  --'All Master sections must be unlocked before hiding them.'        
      ELSE 0        
      END  AS   ResponseId;                    
End;