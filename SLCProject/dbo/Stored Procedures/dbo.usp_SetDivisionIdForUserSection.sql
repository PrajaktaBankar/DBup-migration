CREATE  PROCEDURE [dbo].[usp_SetDivisionIdForUserSection]                    
(                    
 @ProjectId INT,                    
 @SectionId INT,                    
 @CustomerId INT                    
)                    
AS                    
BEGIN                      
                        
 DECLARE @PProjectId INT = @ProjectId;                      
 DECLARE @PSectionId INT = @SectionId;                      
 DECLARE @PCustomerId INT = @CustomerId;                      
                        
DECLARE @DivisionCode NVARCHAR(500) = NULL;                      
DECLARE @DivisionId INT = NULL;                      
DECLARE @Description NVARCHAR(500) =  NULL;                    
DECLARE @MasterDataTypeId INT = 0;                    
DECLARE @FormatTypeId int=0, @IsMarsterDivision bit=0;                    
DECLARE @BSDMasterAdminDivId int=38  
DECLARE @CanadaMasterAdminDivId int=3000037              
DECLARE @ParentSectionId INT=0                    
                    
--Last Level section's Parent(Level 3)                    
SELECT @ParentSectionId=ParentSectionId,@FormatTypeId = PS.FormatTypeId FROM ProjectSection PS WITH(NOLOCK)                    
WHERE PS.SectionId = @PSectionId                      
                    
--Parent section(Level 2)                    
SELECT @ParentSectionId=ParentSectionId FROM ProjectSection PS  WITH(NOLOCK)                    
WHERE PS.SectionId = @ParentSectionId                      
                    
--Parent section(Level 1)                    
SELECT                   
@DivisionCode= CASE WHEN ISNULL(PS.mSectionId,0) = 0 THEN PS.SourceTag  ELSE LEFT(PS.SourceTag, 2) END                  
,@IsMarsterDivision = CASE WHEN ISNULL(PS.mSectionId,0) = 0 THEN 0 ELSE 1 END                  
,@DivisionId = PS.DivisionId                
FROM ProjectSection  PS WITH(NOLOCK)                    
WHERE PS.SectionId = @ParentSectionId                      
                    
SELECT @MasterDataTypeId = P.MasterDataTypeId FROM                     
Project P WITH(NOLOCK)                     
WHERE P.ProjectId = @PProjectId;                    
                    
--CALCULATE DIVISION ID AND CODE                        
IF @IsMarsterDivision = 1                  
BEGIN                  
SELECT                      
 @DivisionCode = MD.DivisionCode                      
   ,@DivisionId = MD.DivisionId                      
FROM SLCMaster..Division MD WITH (NOLOCK)                      
WHERE MD.DivisionCode=@DivisionCode                   
AND   MD.MasterDataTypeId  =@MasterDataTypeId                    
AND   MD.FormatTypeId = @FormatTypeId                      
END                  
ELSE                  
BEGIN                  
 SELECT @DivisionCode = CD.DivisionCode                  
  FROM CustomerDivision CD WITH (NOLOCK)                  
 WHERE CD.MasterDataTypeId = @MasterDataTypeId                   
 AND CD.CustomerId =@PCustomerId                   
 AND CD.DivisionCode = @DivisionCode                  
END;                  
                     
                      
IF(@DivisionId IS NULL OR @DivisionCode IS NULL)                    
BEGIN                     
  -- GET ParentSection Description                    
  select @DivisionCode = SourceTag from ProjectSection PS WITH (NOLOCK)                                
  WHERE PS.SectionId = @ParentSectionId;                                     
END                    
          
                  
 IF(@DivisionId IS NULL AND @DivisionCode = '9')          
BEGIN         
		-- This is set to 99 because there is no division for code 9, and to adjust the print logic for Administation Folder     
		set @DivisionCode = '99' 
        set @DivisionId=iif(@MasterDataTypeId=1,@BSDMasterAdminDivId,iif(@MasterDataTypeId=4,@CanadaMasterAdminDivId,@DivisionId))   
END           
                    
--UPDATE  ProjectSection                      
UPDATE PS                      
SET PS.DivisionId = @DivisionId                   
   ,PS.DivisionCode = @DivisionCode                      
FROM ProjectSection PS WITH (NOLOCK)                      
WHERE PS.SectionId = @PSectionId                      
                      
END  