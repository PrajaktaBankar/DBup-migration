CREATE PROCEDURE usp_GetProjectSections  
 @ProjectId INT,  
 @SectionId INT,  
 @CustomerId INT  
AS  
BEGIN  
  
 SET NOCOUNT ON;  
  
 DECLARE @PProjectId INT = @ProjectId;                    
 DECLARE @PSectionId INT = @SectionId;                    
 DECLARE @PCustomerId INT = @CustomerId;                    
  
 DECLARE @MasterDataTypeId INT;                    
 SELECT @MasterDataTypeId = P.MasterDataTypeId FROM Project P WITH (NOLOCK) WHERE P.ProjectId = @PProjectId;  
  
 DECLARE @SourceTagFormat NVARCHAR(500);  
 SELECT @SourceTagFormat = SourceTagFormat FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.ProjectId = @PProjectId;  
  
 DROP TABLE IF EXISTS #Sections  
  
 CREATE TABLE #Sections  
 (  
  [Description] NVARCHAR(500) NULL,  
  Author NVARCHAR(500) NULL,  
  SectionCode INT NULL,     
  SourceTag  NVARCHAR(18) NULL,                              
  mSectionId  INT NULL,                      
  SectionId  INT NULL,                    
  IsDeleted  BIT NULL  
 )  
                 
 --Insert ProjectSection records  
 INSERT INTO #Sections  
 ([Description], Author, SectionCode,SourceTag,mSectionId,SectionId, IsDeleted)  
 SELECT                    
  S.[Description]                    
    ,S.Author                    
    ,S.SectionCode                    
    ,S.SourceTag                            
    ,S.mSectionId                    
    ,S.SectionId                    
    ,S.IsDeleted  
 FROM ProjectSection AS S WITH (NOLOCK)                    
 WHERE S.ProjectId = @PProjectId 
 AND S.IsLastLevel = 1
 AND S.CustomerId = @PCustomerId       
 AND ISNULL(S.IsDeleted,0)= 0    
           
 --Insert MasterSections records missing in ProjectSection  
 INSERT INTO #Sections    
 ([Description], Author, SectionCode,SourceTag,mSectionId,SectionId, IsDeleted)  
  SELECT                    
   MS.[Description]                    
  ,MS.Author                    
  ,MS.SectionCode                    
  ,MS.SourceTag                  
  ,MS.SectionId AS mSectionId                    
  ,0 AS SectionId                    
  ,MS.IsDeleted                    
  FROM SLCMaster..Section MS WITH (NOLOCK)               
  LEFT JOIN #Sections TMP WITH (NOLOCK)                    
   ON MS.SectionCode = TMP.SectionCode                    
  WHERE MS.MasterDataTypeId = @MasterDataTypeId                    
  AND MS.IsLastLevel = 1                    
  AND TMP.SectionId IS NULL;  
  
 -- Fetch All Project Sections  
 SELECT  
  S.[Description]                    
    ,S.Author                    
    ,S.SectionCode                    
    ,S.SourceTag  
    ,@SourceTagFormat AS SourceTagFormat                            
    ,S.mSectionId                    
    ,S.SectionId                    
    ,S.IsDeleted  
 FROM #Sections S;  
  
 DROP TABLE #Sections;  
  
  
END