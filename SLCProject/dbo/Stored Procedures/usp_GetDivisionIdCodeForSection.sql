            
CREATE PROCEDURE [dbo].[usp_GetDivisionIdCodeForSection]              
(                
 @ProjectId INT,                
 @CustomerId INT,                
 @SourceTag VARCHAR(18),                
 @UserId INT,                
 @ParentSectionId INT                
)                
AS                
BEGIN                        
 DECLARE @PProjectId INT  = @ProjectId;                      
 DECLARE @PCustomerId INT = @CustomerId;                      
 DECLARE @PSourceTag VARCHAR(18) = @SourceTag;                      
 DECLARE @PUserId INT = @UserId;                                          
 DECLARE @SubDiv_SectionId INT = @ParentSectionId;                    
 Declare @Div_SectionID INT = 0;                        
                        
--Declare variables                        
DECLARE @DivisionCode NVARCHAR(MAX) = NULL;                        
DECLARE @DivisionId INT = 0,@IsMasterDivision bit=0;                        
                 
SET @Div_SectionID = (SELECT TOP 1 ParentSectionId  FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @SubDiv_SectionId);          
                    
 SELECT                   
 @IsMasterDivision = CASE WHEN ISNULL(mSectionId,0) =0 THEN 0 ELSE 1 END                                
 FROM ProjectSection WITH (NOLOCK)                   
 WHERE SectionId=@Div_SectionID                  
 AND ProjectId= @PProjectId;             
           
 --SELECT  @IsMasterDivision,  @Div_SectionID;               
                 
 SELECT @DivisionId = DivisionId FROM ProjectSection WITH (NOLOCK)                
 WHERE SectionId = @Div_SectionID AND ProjectId = @PProjectId AND CustomerId = @PCustomerId;                
                    
IF @IsMasterDivision = 0                
BEGIN         
               
 SELECT                   
 @DivisionCode = CD.DivisionCode,                  
 @DivisionId = CD.DivisionId                  
 FROM ProjectSection PS WITH (NOLOCK)                  
 INNER JOIN CustomerDivision CD WITH (NOLOCK)                  
 ON CD.DivisionId = PS.DivisionId     
 WHERE PS.SectionId = @Div_SectionID AND PS.ProjectId =@PProjectId AND CD.CustomerId=@PCustomerId;                    
                    
END                    
ELSE IF @IsMasterDivision = 1                  
BEGIN                    
Drop table if EXISTS #tPS;                    
                    
--Calculate DivisionId and DivisionCode                        
select PS_Parent_2.SectionId,PS_Parent_2.SourceTag into #tPS from ProjectSection PS_Parent_2 WITH (NOLOCK)                        
where PS_Parent_2.ProjectId=@PProjectId                      
                    
SELECT                        
 @DivisionCode = MD.DivisionCode                        
   ,@DivisionId = MD.DivisionId                        
FROM Project P WITH (NOLOCK)                        
INNER JOIN ProjectSection PS_Parent_1 WITH (NOLOCK)                        
 ON P.ProjectId = PS_Parent_1.ProjectId                        
INNER JOIN #tPS PS_Parent_2 WITH (NOLOCK)                        
 ON PS_Parent_1.ParentSectionId = PS_Parent_2.SectionId                        
INNER JOIN SLCMaster..Division MD WITH (NOLOCK)                        
 ON LEFT(PS_Parent_2.SourceTag, 2) = MD.DivisionCode                        
  AND P.MasterDataTypeId = MD.MasterDataTypeId                        
WHERE PS_Parent_1.SectionId = @SubDiv_SectionId   AND P.ProjectId=@PProjectId                                   
AND PS_Parent_1.FormatTypeId = 1                        
                    
SELECT                        
 @DivisionCode = MD.DivisionCode                        
   ,@DivisionId = MD.DivisionId                        
FROM Project P WITH (NOLOCK)                        
INNER JOIN ProjectSection PS_Parent_1 WITH (NOLOCK)                        
 ON P.ProjectId = PS_Parent_1.ProjectId                        
INNER JOIN SLCMaster..Division MD WITH (NOLOCK)                        
 ON LEFT(PS_Parent_1.SourceTag, 2) = MD.DivisionCode                        
  AND P.MasterDataTypeId = MD.MasterDataTypeId                        
WHERE PS_Parent_1.SectionId = @SubDiv_SectionId                        
AND PS_Parent_1.FormatTypeId = 2                      
END;                    
                        
--Return data                        
SELECT                        
 @DivisionId AS DivisionId  , @DivisionCode AS   DivisionCode                 
END 