CREATE PROCEDURE [dbo].[usp_MapSectionToProject]              
@newProjectID INT NULL,             
@newCustomerID INT NULL,             
@newUserID INT NULL,             
@isCopied BIT NULL,             
@copiedProjectID INT NULL=NULL,             
@copiedCustomerID INT NULL=NULL,             
@copiedUserID INT NULL=NULL,            
@MasterDataTypeId INT NULL=NULL,      
@customerName VARCHAR(200)='',      
@userName VARCHAR(200)=''             
AS              
BEGIN            
            
DECLARE @Canada_Section_CutOffDate DATETIME2(7) = '20190420';            
            
DECLARE @PnewProjectID INT = @newProjectID;            
DECLARE @PnewCustomerID INT = @newCustomerID;            
DECLARE @PnewUserID INT = @newUserID;            
DECLARE @PisCopied BIT = @isCopied;            
DECLARE @PcopiedProjectID INT = @copiedProjectID;            
DECLARE @PcopiedCustomerID INT = @copiedCustomerID;            
DECLARE @PcopiedUserID INT = @copiedUserID;            
DECLARE @PMasterDataTypeId  INT = @MasterDataTypeId;            
DECLARE @RequestId INT = 0;          
DECLARE @PCustomerName  NVARCHAR(200)=@CustomerName;        
DECLARE @PUserName NVARCHAR(200)=@userName;        
        
            
IF (@PisCopied = 1)              
BEGIN            
--- Mark as deleted flag to Project Table            
UPDATE P            
SET P.IsDeleted = 1,  
 P.IsPermanentDeleted=1  
FROM Project P WITH (NOLOCK)            
WHERE P.ProjectId = @PnewProjectID;            
            
EXEC usp_MaintainCopyProjectProgress @PcopiedProjectID            
         ,@PnewProjectID            
         ,@PnewUserID            
         ,@PnewCustomerID            
         ,1            
         ,5            
         ,1        
   ,@PCustomerName            
   ,@PUserName;        
            
SELECT TOP 1 @RequestId=RequestId FROM CopyProjectRequest with(nolock) where TargetProjectId=@newProjectID          
          
EXEC usp_MaintainCopyProjectHistory @PnewProjectID            
           ,'New Project created'            
           ,'Project is Created and also create project summary'            
           ,1            
           ,1          
     ,@RequestId;          
END            
ELSE            
BEGIN            
            
DECLARE @SpecViewModeId INT = (SELECT            
  SpecViewModeId            
 FROM ProjectSummary WITH (NOLOCK)            
 WHERE ProjectId = @PnewProjectID            
 AND CustomerId = @PnewCustomerID);            
SET @SpecViewModeId =            
CASE            
 WHEN @SpecViewModeId IS NULL THEN 1            
 ELSE @SpecViewModeId            
END;            
            
SELECT            
 SectionId AS mSectionId            
   ,0 AS ParentSectionId            
   ,s.ParentSectionId AS mParentSectionId            
   ,@PnewProjectID AS [ProjectId]            
   ,@PnewCustomerID AS [CustomerId]            
   ,@PnewUserID AS [UserId]            
   ,DivisionId            
   ,[Description]            
   ,LevelId            
   ,IsLastLevel            
   ,SourceTag            
   ,Author            
   ,@PnewUserID AS CreatedBy            
   ,GETUTCDATE() AS CreateDate            
   ,@PnewUserID AS ModifiedBy            
   ,GETUTCDATE() AS ModifiedDate            
   ,[SectionCode]            
   ,[IsDeleted]            
   ,CASE            
  WHEN ParentSectionId = 0 OR            
   ParentSectionId IS NULL THEN 0            
  ELSE NULL            
 END AS TemplateId            
   ,[FormatTypeId]            
   ,[S].[DivisionCode]            
   ,@SpecViewModeId AS SpecViewModeId INTO #ProjectSection            
FROM [SLCMaster].[dbo].[Section] AS [S] WITH (NOLOCK)            
WHERE S.MasterDataTypeId = @PMasterDataTypeId            
AND S.IsDeleted = 0            
AND (S.PublicationDate >=            
CASE            
 WHEN @PMasterDataTypeId = 4 THEN (            
  CASE            
   WHEN S.IsLastLevel = 1 THEN @Canada_Section_CutOffDate            
   ELSE S.PublicationDate            
  END            
  )            
 ELSE S.PublicationDate            
END)     
            
INSERT INTO [ProjectSection] ([mSectionId], [ParentSectionId], [ProjectId], [CustomerId], [UserId], [DivisionId], [Description],            
[LevelId], [IsLastLevel], [SourceTag], [Author], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate], [SectionCode], [IsDeleted],            
[TemplateId],            
[FormatTypeId], [DivisionCode], [SpecViewModeId])            
 SELECT            
  ps.mSectionId            
    ,ps.ParentSectionId            
    ,@PnewProjectID AS [ProjectId]            
    ,@PnewCustomerID AS [CustomerId]            
    ,@PnewUserID AS [UserId]            
    ,ps.DivisionId            
    ,ps.[Description]            
    ,ps.LevelId            
    ,ps.IsLastLevel            
    ,ps.SourceTag            
    ,ps.Author            
    ,@PnewUserID AS CreatedBy            
    ,GETUTCDATE() AS CreateDate            
    ,@PnewUserID AS ModifiedBy            
    ,GETUTCDATE() AS ModifiedDate            
    ,ps.[SectionCode]            
    ,ps.[IsDeleted]            
    ,CASE            
   WHEN ParentSectionId = 0 OR            
    ParentSectionId IS NULL THEN 0            
   ELSE NULL            
  END AS TemplateId            
    ,ps.[FormatTypeId]            
    ,ps.[DivisionCode]            
    ,@SpecViewModeId AS SpecViewModeId            
 FROM #ProjectSection AS ps;            
          
select PPS.SectionId,PPS.mSectionId into #PSections from [ProjectSection] AS PPS     with(nolock)       
where PPS.[ProjectId] = @PnewProjectID            
AND PPS.[CustomerId] = @PnewCustomerID;            
            
UPDATE CPS            
SET CPS.ParentSectionId = PPS.SectionId            
FROM [ProjectSection] AS CPS WITH (NOLOCK)            
INNER JOIN #ProjectSection AS CMS WITH (NOLOCK)            
 ON CPS.mSectionId = CMS.mSectionId            
 AND CPS.ProjectId = CMS.ProjectId            
 AND CPS.CustomerId = CMS.CustomerId            
INNER JOIN #PSections AS PPS WITH (NOLOCK)            
 ON PPS.mSectionId = CMS.mParentSectionId            
WHERE CPS.[ProjectId] = @PnewProjectID            
AND CPS.[CustomerId] = @PnewCustomerID            
            
            
END    

--Section Tree Flexibility
DROP TABLE IF EXISTS  #t;

SELECT
 (ROW_NUMBER() OVER (ORDER BY SourceTag,Author)-1) AS SortOrderId
 ,SectionId
 ,ProjectId
 ,CustomerId
 INTO #t
FROM ProjectSection WITH (NOLOCK)
WHERE ProjectId=@PnewProjectID AND CustomerId = @PnewCustomerID  
ORDER BY SourceTag,Author

update PS
SET SortOrder = T.SortOrderId
FROM #t T INNER JOIN
ProjectSection  PS WITH (NOLOCK)
ON PS.SectionId = T.SectionId
AND PS.ProjectId= T.ProjectId
AND PS.CustomerId = T.CustomerId
   
END  