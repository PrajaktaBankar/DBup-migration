Use SLCProject
GO

PRINT N'Altering [dbo].[usp_GetAllNotifications]...';


GO
ALTER PROCEDURE [dbo].[usp_GetAllNotifications]
(    
 @CustomerId INT,    
 @UserId INT,    
 @IsSystemManager BIT=0    
)    
AS    
BEGIN    
	DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())    
	
	DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,
							RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,
							StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),
							TaskName nvarchar(500),StatusDescription nvarchar(50),IsOfficeMaster BIT)
	
	INSERT INTO @RES
	SELECT CPR.RequestId  
	,CPR.SourceProjectId  
	,CPR.TargetProjectId  
	,0  AS TargetSectionId      
	,CPR.CreatedDate  AS RequestDateTime 
	,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
	,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime  
	,CPR.StatusId  
	,CPR.IsNotify  
	,CPR.CompletedPercentage  
	,'CopyProject' AS [Source]
	,CONVERT(nvarchar(500),'') AS TaskName
	,CONVERT(nvarchar(50),'') AS StatusDescription
	,0
	FROM CopyProjectRequest CPR WITH(NOLOCK)    
	--INNER JOIN Project P WITH(NOLOCK)    
	  -- ON P.ProjectId = CPR.TargetProjectId   
	  -- INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)
	  -- ON LCS.CopyStatusId=CPR.StatusId   
	WHERE CPR.CreatedById=@UserId  
	AND ISNULL(CPR.IsDeleted,0)=0    
	AND CPR.CreatedDate> @DateBefore30Days 
	--ORDER by CPR.CreatedDate DESC    
 
	INSERT INTO @RES
	SELECT CPR.RequestId          
	,CPR.SourceProjectId  
	,CPR.TargetProjectId  
	,CPR.TargetSectionId     
	,CPR.CreatedDate AS RequestDateTime         
	,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
	,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime          
	,CPR.StatusId          
	,CPR.IsNotify          
	,CPR.CompletedPercentage       
	,CPR.Source
	,CONVERT(nvarchar(500),'') AS TaskName
	,CONVERT(nvarchar(50),'') AS StatusDescription
	,0
	 FROM ImportProjectRequest CPR WITH(NOLOCK)         
	 WHERE CPR.CreatedById=@UserId AND [Source] IN('SpecAPI','Import from Template')     
	 AND ISNULL(CPR.IsDeleted,0)=0       
	 AND CPR.CreatedDate> @DateBefore30Days           
	 --ORDER by CPR.CreatedDate DESC  

	 UPDATE t
	 SET t.StatusDescription=LCS.StatusDescription
	 FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)     
	 ON t.StatusId=LCS.CopyStatusId

	 UPDATE t
	 SET t.TaskName=P.Name,
		 t.IsOfficeMaster=p.IsOfficeMaster
	 FROM @RES t INNER JOIN Project P WITH(NOLOCK)     
	 ON t.TargetProjectId=P.ProjectId
	 WHERE P.CustomerId=@CustomerId
	 AND t.[Source]='CopyProject'

	 UPDATE t
	 SET t.TaskName=PS.Description
	 FROM @RES t INNER JOIN ProjectSection PS WITH(NOLOCK)     
	 ON t.TargetSectionId=PS.SectionId
	 WHERE PS.CustomerId=@CustomerId
	 AND t.[Source] IN('SpecAPI','Import from Template')

	 UPDATE CPR
	 SET CPR.IsNotify = 1
	   ,ModifiedDate = GETUTCDATE()
	 FROM ImportProjectRequest CPR WITH (NOLOCK)
	 INNER JOIN @RES t
	 ON CPR.RequestId = t.RequestId
	 AND CPR.[Source]=t.[Source]
	 WHERE CPR.IsNotify = 0 

	 SELECT * FROM @RES
	 ORDER BY RequestDateTimeStr DESC
	 --Check type sorting performance

END
GO
PRINT N'Altering [dbo].[usp_GetNotificationProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_GetNotificationProgress]
 @UserId int,  
 @RequestIdList nvarchar(100)='',  
 @CustomerId int,  
 @CopyProject BIT=0,  
 @ImportSection BIT=0
AS  
BEGIN  
 --find and mark as failed copy project requests which running loner(more than 30 mins)  
 --EXEC usp_UpdateLongRunningRequestsASFailed  
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())  
 DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,  
       RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,  
       StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),  
       TaskName nvarchar(500),StatusDescription nvarchar(50),IsOfficeMaster BIT)
  
 IF(@CopyProject=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT  CPR.RequestId  
  ,CPR.SourceProjectId    
  ,CPR.TargetProjectId    
  ,0  AS TargetSectionId  
  ,CPR.CreatedDate  AS RequestDateTime   
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
  ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
  ,CPR.StatusId    
  ,CPR.IsNotify    
  ,CPR.CompletedPercentage    
  ,'CopyProject' AS [Source]  
  ,CONVERT(nvarchar(500),'') AS TaskName  
  ,CONVERT(nvarchar(50),'') AS StatusDescription  
  ,0
  FROM CopyProjectRequest CPR WITH (NOLOCK)  
  WHERE CPR.CreatedById = @UserId AND CPR.IsNotify = 0  
  AND ISNULL(CPR.IsDeleted, 0) = 0    
  AND CPR.CreatedDate> @DateBefore30Days    
    
  UPDATE t  
  SET t.TaskName=P.Name ,
	  t.IsOfficeMaster=P.IsOfficeMaster
  FROM @RES t INNER JOIN Project P WITH(NOLOCK)   
  ON P.ProjectId=t.TargetProjectId  
  WHERE P.CustomerId=@CustomerId  

   UPDATE CPR  
   SET CPR.IsNotify = 1  
   ,ModifiedDate = GETUTCDATE()  
    FROM CopyProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	WHERE CPR.IsNotify = 0   
 END  
   
 IF(@ImportSection=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT CPR.RequestId    
  ,CPR.SourceProjectId    
  ,CPR.TargetProjectId    
  ,CPR.TargetSectionId   
  ,CPR.CreatedDate AS RequestDateTime   
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
  ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
  ,CPR.StatusId    
  ,CPR.IsNotify    
  ,CPR.CompletedPercentage     
  ,CPR.Source  
  ,CONVERT(nvarchar(500),'') AS TaskName  
  ,CONVERT(nvarchar(50),'') AS StatusDescription 
  ,0
   FROM ImportProjectRequest CPR WITH(NOLOCK)   
   WHERE CPR.CreatedById=@UserId AND [Source] IN('SpecAPI','Import from Template')   
   AND ISNULL(CPR.IsDeleted,0)=0     
   AND CPR.IsNotify=0  
   AND CPR.CreatedDate> @DateBefore30Days    
  
  UPDATE t  
  SET t.TaskName=PS.Description  
  FROM @RES t INNER JOIN ProjectSection PS WITH(NOLOCK)       
  ON t.TargetSectionId=PS.SectionId  
  WHERE PS.CustomerId=@CustomerId  
  AND t.[Source] IN('SpecAPI','Import from Template')  

   UPDATE CPR  
	SET CPR.IsNotify = 1  
    ,ModifiedDate = GETUTCDATE()  
	FROM ImportProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	--AND CPR.[Source]=t.[Source]  
	WHERE CPR.IsNotify = 0   
 END   
  
 UPDATE t  
 SET t.StatusDescription=LCS.StatusDescription  
 FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)       
 ON t.StatusId=LCS.CopyStatusId  
  
 SELECT * FROM @RES  
 ORDER BY RequestDateTimeStr DESC  
  
  
END
GO
PRINT N'Altering [dbo].[usp_CreateSectionFromMasterTemplate]...';


GO
ALTER PROCEDURE [usp_CreateSectionFromMasterTemplate]                 
 @ProjectId INT, @CustomerId INT, @UserId INT, @SourceTag VARCHAR (10),                 
 @Author NVARCHAR(500), @Description NVARCHAR(500), @UserName NVARCHAR(500) = '',                
 @UserAccessDivisionId NVARCHAR(MAX) = '', @RequestId INT              
AS                  
BEGIN                
 DECLARE @PProjectId INT = @ProjectId;                
 DECLARE @PCustomerId INT = @CustomerId;                
 DECLARE @PUserId INT = @UserId;                
 DECLARE @PSourceTag VARCHAR (10) = @SourceTag;                
 DECLARE @PAuthor NVARCHAR(500) = @Author;                
 DECLARE @PDescription NVARCHAR(500) = @Description;                
 DECLARE @PUserName NVARCHAR(500) = @UserName;                
 DECLARE @PUserAccessDivisionId NVARCHAR(MAX) = @UserAccessDivisionId;                
                
--If came from UI as undefined then make it empty as it should empty                
IF @PUserAccessDivisionId = 'undefined'                
BEGIN                
SET @PUserAccessDivisionId = ''                
END                
                
--DECLARE VARIABLES                
DECLARE @DefaultTemplateSourceTag NVARCHAR(10) = '';                
--DECLARE @AlternateTemplateSourceTag NVARCHAR(MAX) = '';                
                
DECLARE @DefaultTemplateMasterSectionId INT = 0;                
DECLARE @AlternateTemplateMasterSectionId INT = 0;                
                
DECLARE @TemplateSourceTag NVARCHAR(10) = '';                
DECLARE @TemplateAuthor NVARCHAR(50) = '';                
DECLARE @TemplateMasterSectionId INT = 0;                
DECLARE @TemplateSectionId INT = 0;                
DECLARE @TemplateSectionCode INT = 0;                
                
DECLARE @SectionId INT = 0;                
DECLARE @SectionCode INT = 0;                
DECLARE @DivisionCode NVARCHAR(500) = NULL;                
DECLARE @DivisionId INT = NULL;                
DECLARE @ParentSectionId INT = 0;                
                
DECLARE @IsSuccess BIT = 1;                
DECLARE @ErrorMessage NVARCHAR(80) = '';                
DECLARE @ParentSectionIdTable TABLE (                
 ParentSectionId INT                
);                
DECLARE @IsTemplateMasterSectionOpened BIT = 0;                
                
DECLARE @BsdMasterDataTypeId INT = 1;                
DECLARE @CNMasterDataTypeId INT = 4;                
                
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1                
  MasterDataTypeId                
 FROM Project WITH (NOLOCK)                
 WHERE ProjectId = @PProjectId);                
                
DECLARE @UserAccessDivisionIdTbl TABLE (                
 DivisionId INT                
);                
                
DECLARE @FutureDivisionIdOfSectionTbl TABLE (                
 DivisionId INT                
);                
                
DECLARE @FutureDivisionId INT = NULL;                
              
DECLARE @ImportStart_Description NVARCHAR(100) = 'Import Started';                  
DECLARE @ImportNoMasterTemplateFound_Description NVARCHAR(100)='No Master Template Found';              
DECLARE @ImportSectionAlreadyExists_Description NVARCHAR(100)='Section Already Exists';              
DECLARE @ImportSectionIdInvalid_Description NVARCHAR(100)='SectionId is Invalid';              
DECLARE @NoAccessRights_Description NVARCHAR(100)='You dont have access rights to import section';              
DECLARE @ImportProjectSection_Description NVARCHAR(100) = 'Import Project Section Imported';               
DECLARE @ImportProjectSegment_Description NVARCHAR(100) = 'Project Segment Imported';                
DECLARE @ImportProjectSegmentStatus_Description NVARCHAR(100) = 'Project Segment Status Imported';                  
DECLARE @ImportProjectSegmentChoice_Description NVARCHAR(100)='Project Segment Choice Imported';              
DECLARE @ImportProjectChoiceOption_Description NVARCHAR(100) = 'Project Choice Option Imported';                          
DECLARE @ImportSelectedChoiceOption_Description NVARCHAR(100) = 'Selected Choice Option Imported';               
DECLARE @ImportProjectDisciplineSection_Description NVARCHAR(100) = 'Project Discipline Section Imported';               
DECLARE @ImportProjectNote_Description NVARCHAR(100) = 'Project Note Imported';            
DECLARE @ImportProjectSegmentLink_Description NVARCHAR(100) = 'Project Segment Link Imported';               
DECLARE @ImportProjectSegmentRequirementTag_Description NVARCHAR(100) = 'Project SegmentRequirement Tag';              
DECLARE @ImportProjectSegmentUserTag_Description NVARCHAR(100) = 'Project Segment User Tag Imported';                
DECLARE @ImportProjectSegmentGlobalTerm_Description NVARCHAR(100) = 'Project Segment Global Term Imported';                  
DECLARE @ImportProjectSegmentImage_Description NVARCHAR(100) = 'Project Segment Image Imported';                
DECLARE @ImportProjectHyperLink_Description NVARCHAR(100) = 'Project HyperLink Imported';                
DECLARE @ImportProjectNoteImage_Description NVARCHAR(100) = 'Project Note Image Imported';              
DECLARE @ImportProjectSegmentReferenceStandard_Description NVARCHAR(100) = 'Project Segment Reference Standard Imported';               
DECLARE @ImportHeader_Description NVARCHAR(100) = 'Header Imported';                    
DECLARE @ImportFooter_Description NVARCHAR(100) = 'Footer Imported';                        
DECLARE @ImportProjectReferenceStandard_Description NVARCHAR(100) = 'Project Reference Standard Imported';               
DECLARE @ImportComplete_Description NVARCHAR(100) = 'Import Completed';                  
DECLARE @ImportFailed_Description NVARCHAR(100) = 'IMPORT FAILED';                 
              
                
DECLARE @ImportStart_Percentage TINYINT = 5;                 
DECLARE @ImportProjectSection_Percentage TINYINT = 10;               
DECLARE @ImportProjectSegment_Percentage TINYINT = 15;                
DECLARE @ImportProjectSegmentStatus_Percentage TINYINT = 20;                
DECLARE @ImportProjectSegmentChoice_Percentage TINYINT = 25;              
DECLARE @ImportProjectChoiceOption_Percentage TINYINT = 30;                         
DECLARE @ImportSelectedChoiceOption_Percentage TINYINT = 35;               
DECLARE @ImportProjectDisciplineSection_Percentage TINYINT = 40;               
DECLARE @ImportProjectNote_Percentage TINYINT = 45;              
DECLARE @ImportProjectSegmentLink_Percentage TINYINT = 50;              
DECLARE @ImportProjectSegmentRequirementTag_Percentage TINYINT = 55;              
DECLARE @ImportProjectSegmentUserTag_Percentage TINYINT = 60;              
DECLARE @ImportProjectSegmentGlobalTerm_Percentage TINYINT = 65;                  
DECLARE @ImportProjectSegmentImage_Percentage TINYINT = 70;                
DECLARE @ImportProjectHyperLink_Percentage TINYINT = 75;              
DECLARE @ImportProjectNoteImage_Percentage TINYINT = 80;              
DECLARE @ImportProjectSegmentReferenceStandard_Percentage TINYINT = 85;               
DECLARE @ImportHeader_Percentage TINYINT = 90;                
DECLARE @ImportFooter_Percentage TINYINT = 95;               
DECLARE @ImportProjectReferenceStandard_Percentage TINYINT = 97;              
DECLARE @ImportNoMasterTemplateFound_Percentage TINYINT = 100;                  
DECLARE @ImportSectionAlreadyExists_Percentage TINYINT = 100;                  
DECLARE @ImportSectionidInvalid_Percentage TINYINT = 100;              
DECLARE @NoAccessRights_Percentage TINYINT = 100;                
DECLARE @ImportComplete_Percentage TINYINT = 100;                  
DECLARE @ImportFailed_Percentage TINYINT = 100;                
                    
DECLARE @ImportStart_Step TINYINT = 1;                  
DECLARE @ImportNoMasterTemplateFound_Step TINYINT = 2;                 
DECLARE @ImportSectionAlreadyExists_Step TINYINT = 3;                
DECLARE @ImportSectionIdInvalid_Step TINYINT = 4;                
DECLARE @NoAccessRights_Step TINYINT = 5;              
DECLARE @ImportProjectSection_Step TINYINT = 6;              
DECLARE @ImportProjectSegment_Step TINYINT = 7;                  
DECLARE @ImportProjectSegmentChoice_Step TINYINT = 8;                
DECLARE @ImportProjectChoiceOption_Step TINYINT = 9;                
DECLARE @ImportSelectedChoiceOption_Step TINYINT = 10;                
DECLARE @ImportProjectDisciplineSection_Step TINYINT = 11;               
DECLARE @ImportProjectNote_Step TINYINT = 12;              
DECLARE @ImportProjectSegmentLink_Step TINYINT = 13;              
DECLARE @ImportProjectSegmentRequirementTag_Step TINYINT = 14;              
DECLARE @ImportProjectSegmentUserTag_Step TINYINT = 15;              
DECLARE @ImportProjectSegmentGlobalTerm_Step TINYINT = 16;               
DECLARE @ImportProjectSegmentImage_Step TINYINT = 17;              
DECLARE @ImportProjectHyperLink_Step TINYINT = 18;              
DECLARE @ImportProjectNoteImage_Step TINYINT = 19;              
DECLARE @ImportProjectSegmentReferenceStandard_Step TINYINT = 20;              
DECLARE @ImportHeader_Step TINYINT = 21;              
DECLARE @ImportFooter_Step TINYINT = 22;              
DECLARE @ImportProjectReferenceStandard_Step TINYINT = 23;             
DECLARE @ImportProjectSegmentStatus_Step TINYINT = 24;               
DECLARE @ImportComplete_Step TINYINT = 25;                 
DECLARE @ImportFailed_Step TINYINT = 25;             
        
DECLARE  @ImportPending TINYINT =1;        
DECLARE  @ImportStarted TINYINT =2;        
DECLARE  @ImportCompleted TINYINT =3;        
DECLARE  @Importfailed TINYINT =4        
        
DECLARE @IsCompleted BIT =1;        
        
DECLARE @ImportSource Nvarchar(100)='Import From Template'        
              
                
--TEMP TABLES                
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentStatus;                
DROP TABLE IF EXISTS #tmp_TgtProjectSegmentStatus;                
DROP TABLE IF EXISTS #tmp_SrcMasterNote;                
DROP TABLE IF EXISTS #tmp_TgtProjectNote;                
DROP TABLE IF EXISTS #tmp_SrcProjectSegment;                
                
BEGIN TRY                
--BEGIN TRANSACTION                
              
 --Add Logs to ImportProjectHistory                
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportStart_Description                            
           ,@ImportStart_Description                            
           ,@IsCompleted                            
           ,@ImportStart_Step --Step                     
     ,@RequestId;              
                
 --Add Logs to ImportProjectRequest                
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                         
         ,@ImportStart_Percentage --Percent                            
         , 0                
         ,@ImportSource               
         , @RequestId;               
              
--SET DEFAULT TEMPLATE SOURCE TAG ACCORDING TO MASTER DATATYPEID                
IF @MasterDataTypeId = @BsdMasterDataTypeId                
BEGIN                
SET @DefaultTemplateSourceTag = '99999';                
SET @TemplateAuthor = 'BSD';                
END                
ELSE IF @MasterDataTypeId = @CNMasterDataTypeId                
BEGIN                
SET @DefaultTemplateSourceTag = '99999';                
SET @TemplateAuthor = 'BSD';                
END                
                
--NOTE:Below condition is due to deleted master template on DEV                
--NOTE:SET Appropriate Master Template Section to be copy    
     
DECLARE @mSectionId INT = ( SELECT TOP 1                
  mSectionId                
 FROM ProjectSection PS WITH (NOLOCK)                
 WHERE ProjectId = @PProjectId  
      AND CustomerId = @CustomerId  
   AND PS.IsLastLevel = 1                
      AND ISNULL(PS.IsDeleted,0) = 0     
   AND PS.mSectionId IS NOT NULL  
   AND PS.SourceTag = @DefaultTemplateSourceTag  
   AND PS.Author = @TemplateAuthor);     
    
           
IF EXISTS (SELECT                
 TOP 1                
  1                
 FROM  SLCMaster..Section MS WITH (NOLOCK)                
 WHERE MS.SectionId = @mSectionId                           
 AND MS.IsDeleted = 0)                
BEGIN                
SET @TemplateSourceTag = @DefaultTemplateSourceTag;                
END                
     
--FETCH VARIABLE DETAILS                
SELECT                
 @TemplateSectionId = PS.SectionId                
   ,@TemplateMasterSectionId = PS.mSectionId                
   ,@TemplateSectionCode = PS.SectionCode                
--FROM Project P WITH (NOLOCK)                
FROM ProjectSection PS WITH (NOLOCK)                
 --ON P.ProjectId = PS.ProjectId                
--INNER JOIN SLCMaster..Section MS WITH (NOLOCK)                
-- ON PS.mSectionId = MS.SectionId                
-- and isnull(PS.IsDeleted,0) = isnull(MS.IsDeleted,0)                
WHERE PS.ProjectId = @PProjectId                
AND PS.CustomerId = @PCustomerId                
AND PS.IsLastLevel = 1                
--AND isnull(MS.IsDeleted,0)= 0                
AND PS.mSectionId =@mSectionId                
AND PS.SourceTag = @TemplateSourceTag                
AND PS.Author = @TemplateAuthor                
                
--CHECK WHETHER MASTER TEMPLATE SECTION IS OPENED OR NOT                
IF EXISTS (SELECT TOP 1                
  1                
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId        
  AND PSST.ProjectId = PS.ProjectId          
 WHERE PSST.ProjectId = @PProjectId                
 AND PS.mSectionId = @TemplateMasterSectionId                
 --AND PS.CustomerId = @CustomerId  
 AND PSST.SequenceNumber = 0                
 AND PSST.IndentLevel = 0)                
BEGIN                
SET @IsTemplateMasterSectionOpened = 1;                
END                
                
--CALCULATE ParentSectionId                
INSERT INTO @ParentSectionIdTable (ParentSectionId)                
EXEC usp_GetParentSectionIdForImportedSection @PProjectId                
            ,@PCustomerId                
            ,@PUserId                
            ,@PSourceTag;                
                
SELECT TOP 1                
 @ParentSectionId = ParentSectionId                
FROM @ParentSectionIdTable;                
                
--PUT USER DIVISION ID'S INTO TABLE                
INSERT INTO @UserAccessDivisionIdTbl (DivisionId)                
 SELECT                
  *                
 FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');                
                
--CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE                
INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)                
EXEC usp_CalculateDivisionIdForUserSection @PProjectId                
            ,@PCustomerId                
            ,@PSourceTag                
            ,@PUserId                
            ,@ParentSectionId                
SELECT TOP 1                
 @FutureDivisionId = DivisionId                
FROM @FutureDivisionIdOfSectionTbl;                
                
                
--PERFORM VALIDATIONS                
IF (@TemplateSourceTag = '')                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'No master template found.';                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportNomastertemplatefound_Description                            
            ,@ImportNomastertemplatefound_Description                             
           ,@IsCompleted                            
           ,@ImportNomastertemplatefound_Step --Step                     
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                    
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                         
         ,@ImportNomastertemplatefound_Percentage --Percent                            
         , 0                
    ,@ImportSource               
         , @RequestId;               
              
END                
                
ELSE IF EXISTS (SELECT TOP 1                 
  1                
 FROM ProjectSection WITH (NOLOCK)                
 WHERE ProjectId = @PProjectId                
 AND CustomerId = @PCustomerId                
 AND ISNULL(IsDeleted,0) = 0                
 AND SourceTag = TRIM(@PSourceTag)                
 AND LOWER(Author) = LOWER(TRIM(@PAuthor)))                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'Section already exists.';                
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportSectionalreadyexists_Description                            
          ,@ImportSectionalreadyexists_Description                             
           ,@IsCompleted                            
            ,@ImportSectionalreadyexists_Step --Step                     
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
  ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                         
         ,@ImportSectionalreadyexists_Percentage --Percent                            
         , 0                
    ,@ImportSource                
         , @RequestId;               
END                
                
ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'Section id is invalid.';                
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportSectionidinvalid_Description                            
           ,@ImportSectionidinvalid_Description                            
           ,@IsCompleted                            
            ,@ImportSectionidinvalid_step --Step         
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                           
         ,@ImportSectionidinvalid_Percentage --Percent                            
         , 0                
    ,@ImportSource              
         , @RequestId;               
END                
                
ELSE IF  @PUserAccessDivisionId != ''                
 AND @FutureDivisionId NOT IN (SELECT                
  DivisionId                
 FROM @UserAccessDivisionIdTbl)                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';                
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@NoAccessRights_Description                  
            ,@NoAccessRights_Description                                
           ,@IsCompleted                           
            ,@NoAccessRights_step --Step                     
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                            
         ,@NoAccessRights_Percentage --Percent                            
         , 0                
   ,@ImportSource                
         , @RequestId;               
END                
                
ELSE                
BEGIN                
                
--INSERT INTO ProjectSection                
INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                
DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                
Author, TemplateId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, FormatTypeId, SpecViewModeId)                
 SELECT                
  @ParentSectionId AS ParentSectionId              
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,@PUserId AS UserId                
    ,NULL AS DivisionId                
    ,NULL AS DivisionCode                
    ,@PDescription AS Description                
    ,PS_Template.LevelId AS LevelId                
    ,1 AS IsLastLevel                
    ,@PSourceTag AS SourceTag                
    ,@PAuthor AS Author                
    ,PS_Template.TemplateId AS TemplateId                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
    ,0 AS IsDeleted                
    ,PS_Template.FormatTypeId AS FormatTypeId                
    ,PS_Template.SpecViewModeId AS SpecViewModeId                
 FROM ProjectSection PS_Template WITH (NOLOCK)                
 WHERE PS_Template.SectionId = @TemplateSectionId                
                
SET @SectionId = scope_identity()                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSection_Description                            
           ,@ImportProjectSection_Description                            
           ,@IsCompleted                          
           ,@ImportProjectSection_Step --Step                     
     ,@RequestId;              
                
 --Add Logs to ImportProjectRequest                
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                          
         ,@ImportProjectSection_Percentage --Percent                            
         , 0                
    ,@ImportSource              
         , @RequestId;               
               
--GET NEW SECTION ID                
SELECT TOP 1                
 --@SectionId = SectionId,                
   @SectionCode = SectionCode                
FROM ProjectSection WITH (NOLOCK)                
WHERE SectionId = @SectionId                 
AND ProjectId = @PProjectId                
AND CustomerId = @PCustomerId                
--AND mSectionId IS NULL                
--AND SourceTag = @PSourceTag                
--AND Author = @PAuthor                
--AND IsDeleted = 0                
                
--CALCULATE DIVISION ID AND CODE                
EXEC usp_SetDivisionIdForUserSection @PProjectId                
         ,@SectionId                
         ,@PCustomerId;                
                
--Fetch Src ProjectSegmentStatus data into temp table                
SELECT                
 * INTO #tmp_SrcProjectSegmentStatus                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
WHERE PSST.ProjectId = @PProjectId                
AND PSST.SectionId = @TemplateSectionId                
                
--Fetch Src ProjectSegment data into temp table                
SELECT                
 * INTO #tmp_SrcProjectSegment                
FROM ProjectSegment PSG WITH (NOLOCK)                
WHERE PSG.ProjectId = @PProjectId                
AND PSG.SectionId = @TemplateSectionId                
                
--INSERT INTO ProjectSegment                
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId,                
SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                
 SELECT                
  NULL AS SegmentStatusId                
    ,@SectionId AS SectionId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,MSG_Template.SegmentDescription AS SegmentDescription                
    ,'U' AS SegmentSource                
    ,MSG_Template.SegmentCode AS SegmentCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM SLCMaster..SegmentStatus MSST_Template WITH (NOLOCK)                
 INNER JOIN SLCMaster..Segment MSG_Template WITH (NOLOCK)                
  ON MSST_Template.SegmentId = MSG_Template.SegmentId                
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId                
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  NULL AS SegmentStatusId                
    ,@SectionId AS SectionId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,(CASE                
   WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentDescription                
   ELSE PSST_Template_MSG.SegmentDescription                
  END) AS SegmentDescription                
    ,'U' AS SegmentSource                
    ,(CASE                
   WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentCode                
   ELSE PSST_Template_MSG.SegmentCode                
  END) AS SegmentCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
 LEFT JOIN #tmp_SrcProjectSegment PSST_Template_PSG WITH (NOLOCK)          
  ON PSST_Template.SegmentId = PSST_Template_PSG.SegmentId                
   AND PSST_Template.SegmentOrigin = 'U'                
 LEFT JOIN SLCMaster..Segment PSST_Template_MSG WITH (NOLOCK)                
  ON PSST_Template.mSegmentId = PSST_Template_MSG.SegmentId                
   AND PSST_Template.SegmentOrigin = 'M'                
 WHERE PSST_Template.SectionId = @TemplateSectionId                
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0                
 AND (PSST_Template_PSG.SegmentId IS NOT NULL                
 OR PSST_Template_MSG.SegmentId IS NOT NULL)                
 AND @IsTemplateMasterSectionOpened = 1                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
        ,@ImportProjectSegment_Description                            
           ,@ImportProjectSegment_Description                            
           ,@IsCompleted                            
           ,@ImportProjectSegment_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                        
         ,@ImportProjectSegment_Percentage --Percent                            
         , 0                
    ,@ImportSource             
         , @RequestId;               
                
--INSERT INTO ProjectSegmentStatus                
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource,                
SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId,                
IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber,                
IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,                
IsPageBreak, IsDeleted)                
 SELECT                
  @SectionId AS SectionId                
    ,0 AS ParentSegmentStatusId                
    ,MSST_Template.SegmentStatusId AS mSegmentStatusId                
    ,MSST_Template.SegmentId AS mSegmentId                
    ,PSG.SegmentId AS SegmentId                
    ,'U' AS SegmentSource                
    ,'U' AS SegmentOrigin                
    ,MSST_Template.IndentLevel AS IndentLevel                
    ,MSST_Template.SequenceNumber AS SequenceNumber                
    ,(CASE                
   WHEN MSST_Template.SpecTypeTagId = 1 THEN 4                
   WHEN MSST_Template.SpecTypeTagId = 2 THEN 3                
   ELSE MSST_Template.SpecTypeTagId                
  END) AS SpecTypeTagId                
    ,MSST_Template.SegmentStatusTypeId AS SegmentStatusTypeId                
    ,MSST_Template.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,MSST_Template.SegmentStatusCode AS SegmentStatusCode                
    ,MSST_Template.IsShowAutoNumber AS IsShowAutoNumber                
    ,MSST_Template.IsRefStdParagraph AS IsRefStdParagraph                
    ,MSST_Template.FormattingJson AS FormattingJson                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
    ,0 AS IsPageBreak                
    ,MSST_Template.IsDeleted AS IsDeleted                
 FROM SLCMaster..SegmentStatus MSST_Template WITH (NOLOCK)                
 INNER JOIN SLCMaster..Segment MSG_Template WITH (NOLOCK)                
  ON MSST_Template.SegmentId = MSG_Template.SegmentId                
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
  ON MSG_Template.SegmentCode = PSG.SegmentCode                
   AND PSG.SectionId = @SectionId                
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId                
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,0 AS ParentSegmentStatusId                
    ,PSST_Template.mSegmentStatusId AS mSegmentStatusId                
    ,PSST_Template.mSegmentId AS mSegmentId                
    ,PSG.SegmentId AS SegmentId                
    ,'U' AS SegmentSource                
    ,'U' AS SegmentOrigin                
    ,PSST_Template.IndentLevel AS IndentLevel                
    ,PSST_Template.SequenceNumber AS SequenceNumber                
    ,(CASE                
   WHEN PSST_Template.SpecTypeTagId = 1 THEN 4                
   WHEN PSST_Template.SpecTypeTagId = 2 THEN 3                
   ELSE PSST_Template.SpecTypeTagId                
  END) AS SpecTypeTagId                
    ,PSST_Template.SegmentStatusTypeId AS SegmentStatusTypeId                
    ,PSST_Template.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,PSST_Template.SegmentStatusCode AS SegmentStatusCode                
    ,PSST_Template.IsShowAutoNumber AS IsShowAutoNumber                
    ,PSST_Template.IsRefStdParagraph AS IsRefStdParagraph                
    ,PSST_Template.FormattingJson AS FormattingJson                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
    ,0 AS IsPageBreak                
    ,PSST_Template.IsDeleted AS IsDeleted                
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
 LEFT JOIN #tmp_SrcProjectSegment PSST_Template_PSG WITH (NOLOCK)                
  ON PSST_Template.SegmentId = PSST_Template_PSG.SegmentId                
   AND PSST_Template.SegmentOrigin = 'U'                
 LEFT JOIN SLCMaster..Segment PSST_Template_MSG WITH (NOLOCK)                
  ON PSST_Template.mSegmentId = PSST_Template_MSG.SegmentId                
   AND PSST_Template.SegmentOrigin = 'M'                
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
  ON (CASE                
    WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentCode                
    ELSE PSST_Template_MSG.SegmentCode                
   END) = PSG.SegmentCode                
   AND PSG.SectionId = @SectionId                
 WHERE PSST_Template.SectionId = @TemplateSectionId                
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0                
 AND (PSST_Template_PSG.SegmentId IS NOT NULL                
 OR PSST_Template_MSG.SegmentId IS NOT NULL)                
 AND @IsTemplateMasterSectionOpened = 1                
              
              
                
--Insert target segment status into temp table of new section                
SELECT                
 * INTO #tmp_TgtProjectSegmentStatus                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
WHERE PSST.SectionId = @SectionId                
                
--UPDATE TEMP TABLE ProjectSegmentStatus                
UPDATE PSST_Child                
SET PSST_Child.ParentSegmentStatusId = PSST_Parent.SegmentStatusId                
FROM #tmp_TgtProjectSegmentStatus PSST_Child WITH (NOLOCK)                
INNER JOIN SLCMaster..SegmentStatus MSST_Template_Child WITH (NOLOCK)                
 ON PSST_Child.SegmentStatusCode = MSST_Template_Child.SegmentStatusCode                
INNER JOIN SLCMaster..SegmentStatus MSST_Template_Parent WITH (NOLOCK)                
 ON MSST_Template_Child.ParentSegmentStatusId = MSST_Template_Parent.SegmentStatusId                
INNER JOIN #tmp_TgtProjectSegmentStatus PSST_Parent WITH (NOLOCK)                
 ON MSST_Template_Parent.SegmentStatusCode = PSST_Parent.SegmentStatusCode                
WHERE PSST_Child.SectionId = @SectionId                
AND PSST_Parent.SectionId = @SectionId                
AND MSST_Template_Child.SectionId = @TemplateMasterSectionId                
AND @IsTemplateMasterSectionOpened = 0                
                
UPDATE PSST_Child                
SET PSST_Child.ParentSegmentStatusId = PSST_Parent.SegmentStatusId                
FROM #tmp_TgtProjectSegmentStatus PSST_Child WITH (NOLOCK)                
INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template_Child WITH (NOLOCK)                
 ON PSST_Child.SegmentStatusCode = PSST_Template_Child.SegmentStatusCode                
 AND PSST_Template_Child.SectionId = @TemplateSectionId                
INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template_Parent WITH (NOLOCK)                
 ON PSST_Template_Child.ParentSegmentStatusId = PSST_Template_Parent.SegmentStatusId                
 AND PSST_Template_Parent.SectionId = @TemplateSectionId                
INNER JOIN #tmp_TgtProjectSegmentStatus PSST_Parent WITH (NOLOCK)                
 ON PSST_Template_Parent.SegmentStatusCode = PSST_Parent.SegmentStatusCode                
WHERE PSST_Child.SectionId = @SectionId                
AND PSST_Parent.SectionId = @SectionId                
AND @IsTemplateMasterSectionOpened = 1                
                
--UPDATE IN ORIGINAL TABLE                
UPDATE PSST                
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN #tmp_TgtProjectSegmentStatus TMP WITH (NOLOCK)                
 ON PSST.SegmentStatusId = TMP.SegmentStatusId                
WHERE PSST.SectionId = @SectionId                
                
--UPDATE ProjectSegment                
UPDATE PSG                
SET PSG.SegmentStatusId = PSST.SegmentStatusId       
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON PSST.SegmentId = PSG.SegmentId                
WHERE PSST.SectionId = @SectionId                
                
UPDATE PSG                
SET PSG.SegmentDescription = PS.Description                
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON PSST.SegmentId = PSG.SegmentId                
INNER JOIN ProjectSection PS WITH (NOLOCK)                
 ON PSST.SectionId = PS.SectionId                
WHERE PSST.SectionId = @SectionId                
AND PSST.SequenceNumber = 0                
AND PSST.IndentLevel = 0                
                
--INSERT INTO ProjectSegmentChoice                
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId,                
CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,PSST.SegmentId AS SegmentId                
    ,MCH_Template.ChoiceTypeId AS ChoiceTypeId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,'U' AS SegmentChoiceSource                
    ,MCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)                
  ON PSST.mSegmentId = MCH_Template.SegmentId                
 WHERE PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,PSST.SegmentId AS SegmentId                
    ,MCH_Template.ChoiceTypeId AS ChoiceTypeId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,'U' AS SegmentChoiceSource                
    ,MCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode                
   AND PSST_Template.SectionId = @TemplateSectionId                
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)                
  ON PSST.mSegmentId = MCH_Template.SegmentId                
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'M'                
 AND @IsTemplateMasterSectionOpened = 1                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,PSST.SegmentId AS SegmentId                
    ,PCH_Template.ChoiceTypeId AS ChoiceTypeId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,'U' AS SegmentChoiceSource                
    ,PCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode                
   AND PSST_Template.SectionId = @TemplateSectionId                
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)                
  ON PSST_Template.SegmentId = PCH_Template.SegmentId                
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'U'                
 AND @IsTemplateMasterSectionOpened = 1                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentChoice_Description                            
           ,@ImportProjectSegmentChoice_Description                            
           ,@IsCompleted                            
           ,@ImportProjectSegmentChoice_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                         
         ,@ImportProjectSegmentChoice_Percentage --Percent                            
         , 0                
    ,@ImportSource           
         , @RequestId;               
                
--INSERT INTO ProjectChoiceOption                
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson,                
ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                
 SELECT                
  PCH.SegmentChoiceId AS SegmentChoiceId      ,MCHOP_Template.SortOrder AS SortOrder                
    ,'U' AS ChoiceOptionSource                
    ,MCHOP_Template.OptionJson AS OptionJson                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,@PCustomerId AS CustomerId                
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)                
  ON PSST.mSegmentId = MCH_Template.SegmentId                
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)                
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId                
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                
  ON PSST.SegmentId = PCH.SegmentId                
   AND MCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode                
 WHERE PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  PCH.SegmentChoiceId AS SegmentChoiceId                
    ,MCHOP_Template.SortOrder AS SortOrder                
    ,'U' AS ChoiceOptionSource                
    ,MCHOP_Template.OptionJson AS OptionJson                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,@PCustomerId AS CustomerId                
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode                
   AND PSST_Template.SectionId = @TemplateSectionId                
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)                
  ON PSST.mSegmentId = MCH_Template.SegmentId                
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)                
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId                
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                
  ON PSST.SegmentId = PCH.SegmentId                
   AND MCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode                
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'M'                
 AND @IsTemplateMasterSectionOpened = 1                
 UNION                
 SELECT                
  PCH.SegmentChoiceId AS SegmentChoiceId                
    ,PCHOP_Template.SortOrder AS SortOrder                
    ,'U' AS ChoiceOptionSource                
    ,PCHOP_Template.OptionJson AS OptionJson                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,@PCustomerId AS CustomerId                
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode                
   AND PSST_Template.SectionId = @TemplateSectionId                
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)                
  ON PSST_Template.SegmentId = PCH_Template.SegmentId                
 INNER JOIN ProjectChoiceOption PCHOP_Template WITH (NOLOCK)                
  ON PCH_Template.SegmentChoiceId = PCHOP_Template.SegmentChoiceId                
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                
  ON PSST.SegmentId = PCH.SegmentId                
   AND PCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode                
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'U'                
 AND @IsTemplateMasterSectionOpened = 1                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectChoiceOption_Description                            
           ,@ImportProjectChoiceOption_Description                            
           ,@IsCompleted                          
           ,@ImportProjectChoiceOption_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                       
         ,@ImportProjectChoiceOption_Percentage --Percent                            
         , 0                
    ,@ImportSource          
         , @RequestId;               
                
--INSERT INTO SelectedChoiceOption                
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource,                
IsSelected, SectionId, ProjectId, CustomerId, OptionJson)                
 SELECT                
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,'U' AS ChoiceOptionSource                
    ,SCHOP_Template.IsSelected AS IsSelected                
    ,@SectionId AS SectionId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,NULL AS OptionJson                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)                
  ON PSST.mSegmentId = MCH_Template.SegmentId                
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)                
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId                
 INNER JOIN SLCMaster..SelectedChoiceOption SCHOP_Template WITH (NOLOCK)                
  ON MCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode                
   AND MCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode                
 WHERE PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,'U' AS ChoiceOptionSource                
    ,SCHOP_Template.IsSelected AS IsSelected                
    ,@SectionId AS SectionId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,SCHOP_Template.OptionJson AS OptionJson                
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode                
   AND PSST_Template.SectionId = @TemplateSectionId                
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)                
  ON PSST.mSegmentId = MCH_Template.SegmentId                
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)                
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId                
 INNER JOIN SelectedChoiceOption SCHOP_Template WITH (NOLOCK)                
  ON MCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode                
   AND MCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode                
   AND SCHOP_Template.ChoiceOptionSource = 'M'                
   AND SCHOP_Template.SectionId = @TemplateSectionId                
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'M'                
 AND @IsTemplateMasterSectionOpened = 1                
 UNION                
 SELECT                
  PCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,'U' AS ChoiceOptionSource                
    ,SCHOP_Template.IsSelected AS IsSelected                
    ,@SectionId AS SectionId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,SCHOP_Template.OptionJson AS OptionJson                
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)                
  ON PSST_Template.SegmentId = PCH_Template.SegmentId                
 INNER JOIN ProjectChoiceOption PCHOP_Template WITH (NOLOCK)                
  ON PCH_Template.SegmentChoiceId = PCHOP_Template.SegmentChoiceId                
 INNER JOIN SelectedChoiceOption SCHOP_Template WITH (NOLOCK)                
  ON PCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode                
   AND PCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode                
   AND SCHOP_Template.ChoiceOptionSource = 'U'                
   AND SCHOP_Template.SectionId = @TemplateSectionId                
 WHERE PSST_Template.SectionId = @TemplateSectionId                
 AND PSST_Template.SegmentOrigin = 'U'                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportSelectedChoiceOption_Description                            
           ,@ImportSelectedChoiceOption_Description                            
           ,@IsCompleted                          
           ,@ImportSelectedChoiceOption_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null               
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                   
        ,@ImportSelectedChoiceOption_Percentage --Percent                            
         , 0                
    ,@ImportSource           
         , @RequestId;               
                
--INSERT INTO ProjectDisciplineSection                
INSERT INTO ProjectDisciplineSection (SectionId, Disciplineld, ProjectId, CustomerId, IsActive)                
 SELECT                
  @SectionId AS SectionId                
    ,MDS.DisciplineId AS Disciplineld                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,1 AS IsActive                
 FROM SLCMaster..DisciplineSection MDS WITH (NOLOCK)                
 INNER JOIN LuProjectDiscipline LPD WITH (NOLOCK)                
  ON MDS.DisciplineId = LPD.Disciplineld                
 WHERE MDS.SectionId = @TemplateMasterSectionId                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectDisciplineSection_Description                            
           ,@ImportProjectDisciplineSection_Description                            
           ,@IsCompleted                        
           ,@ImportProjectDisciplineSection_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted               
         ,@ImportProjectDisciplineSection_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectNote                
INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,      
CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode)                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,MNT_Template.NoteText AS NoteText                
    ,GETUTCDATE() AS CreateDate                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,'' AS Title                
    ,@PUserId AS CreatedBy                
    ,@PUserId AS ModifiedBy                
  ,@PUserName AS CreatedUserName                
    ,@PUserName AS ModifiedUserName                
    ,0 AS IsDeleted                
    ,MNT_Template.NoteId AS NoteCode                
 FROM SLCMaster..Note MNT_Template WITH (NOLOCK)                
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
  ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId                
 WHERE MNT_Template.SectionId = @TemplateMasterSectionId                
 AND PSST.SectionId = @SectionId                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,PNT_Template.NoteText AS NoteText                
    ,GETUTCDATE() AS CreateDate                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,PNT_Template.Title AS Title                
    ,@PUserId AS CreatedBy                
    ,@PUserId AS ModifiedBy                
    ,@PUserName AS CreatedUserName                
    ,@PUserName AS ModifiedUserName                
    ,0 AS IsDeleted                
    ,PNT_Template.NoteCode AS NoteCode                
 FROM ProjectNote PNT_Template WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PNT_Template.SegmentStatusId = PSST_Template.SegmentStatusId                
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode                
   AND PSST.SectionId = @SectionId                
 WHERE PNT_Template.SectionId = @TemplateSectionId                
 AND ISNULL(PNT_Template.IsDeleted, 0) = 0                
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectNote_Description                            
           ,@ImportProjectNote_Description                            
           ,@IsCompleted                           
           ,@ImportProjectNote_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                   
         ,@ImportProjectNote_Percentage --Percent                            
         , 0                
    ,@ImportSource         
         , @RequestId;               
                
              
--INSERT INTO ProjectSegmentLink                
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,                
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,                
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,                
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,                
ProjectId, CustomerId, SegmentLinkSourceTypeId)                
 SELECT                
  (CASE                
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN @SectionCode                
   ELSE MSLNK.SourceSectionCode                
  END) AS SourceSectionCode                
    ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode                
    ,MSLNK.SourceSegmentCode AS SourceSegmentCode                
    ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode                
    ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode                
    ,(CASE                
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN 'U'                
   ELSE MSLNK.LinkSource                
  END) AS LinkSource                
    ,(CASE                
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN @SectionCode                
   ELSE MSLNK.TargetSectionCode                
  END) AS TargetSectionCode                
    ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode                
    ,MSLNK.TargetSegmentCode AS TargetSegmentCode                
    ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode                
    ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode                
    ,(CASE                
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN 'U'                
   ELSE MSLNK.LinkTarget                
  END) AS LinkTarget                
    ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId                
    ,MSLNK.IsDeleted AS IsDeleted                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,(CASE                
   WHEN MSLNK.SegmentLinkSourceTypeId = 1 THEN 5                
   ELSE MSLNK.SegmentLinkSourceTypeId                
  END) AS SegmentLinkSourceTypeId                
 FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)                
 WHERE (MSLNK.SourceSectionCode = @TemplateSectionCode                
 OR MSLNK.TargetSectionCode = @TemplateSectionCode)                
 AND MSLNK.IsDeleted = 0                
 AND @IsTemplateMasterSectionOpened = 0                
               
                
SELECT                
   (CASE                
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN @SectionCode                
    ELSE PSLNK.SourceSectionCode                
   END) AS SourceSectionCode                
     ,PSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode                
     ,PSLNK.SourceSegmentCode AS SourceSegmentCode                
     ,PSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode                
     ,PSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode                
     ,(CASE                
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN 'U'                
    ELSE PSLNK.LinkSource                
   END) AS LinkSource                
     ,(CASE                
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN @SectionCode                
    ELSE PSLNK.TargetSectionCode                
   END) AS TargetSectionCode                
     ,PSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode                
     ,PSLNK.TargetSegmentCode AS TargetSegmentCode                
     ,PSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode                
     ,PSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode                
     ,(CASE                
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN 'U'                
    ELSE PSLNK.LinkTarget                
   END) AS LinkTarget                
     ,PSLNK.LinkStatusTypeId AS LinkStatusTypeId                
     ,PSLNK.IsDeleted AS IsDeleted                
     ,GETUTCDATE() AS CreateDate                
     ,@PUserId AS CreatedBy                
     ,@PUserId AS ModifiedBy                
     ,GETUTCDATE() AS ModifiedDate                
     ,@PProjectId AS ProjectId                
     ,@PCustomerId AS CustomerId                
     ,(CASE                
    WHEN PSLNK.SegmentLinkSourceTypeId = 1 THEN 5                
    ELSE PSLNK.SegmentLinkSourceTypeId                
   END) AS SegmentLinkSourceTypeId                
  INTO #X FROM ProjectSegmentLink PSLNK WITH (NOLOCK)                
  WHERE PSLNK.ProjectId = @PProjectId                
  AND PSLNK.CustomerId = @PCustomerId                
  AND (PSLNK.SourceSectionCode = @TemplateSectionCode                
  OR PSLNK.TargetSectionCode = @TemplateSectionCode)                
  AND PSLNK.IsDeleted = 0                
  AND @IsTemplateMasterSectionOpened = 1                
                
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,                
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,                
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,                
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,                
ProjectId, CustomerId, SegmentLinkSourceTypeId)                
 SELECT                
  X.*                
 FROM #x AS X                
 LEFT JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)                
  ON X.SourceSectionCode = PSLNK.SourceSectionCode                
   AND X.SourceSegmentStatusCode = PSLNK.SourceSegmentStatusCode                
   AND X.SourceSegmentCode = PSLNK.SourceSegmentCode                
   AND X.SourceSegmentChoiceCode = PSLNK.SourceSegmentChoiceCode                
   AND X.SourceChoiceOptionCode = PSLNK.SourceChoiceOptionCode                
   AND X.LinkSource = PSLNK.LinkSource                
   AND X.TargetSectionCode = PSLNK.TargetSectionCode                
   AND X.TargetSegmentStatusCode = PSLNK.TargetSegmentStatusCode                
   AND X.TargetSegmentCode = PSLNK.TargetSegmentCode                
   AND X.TargetSegmentChoiceCode = PSLNK.TargetSegmentChoiceCode                
   AND X.TargetChoiceOptionCode = PSLNK.TargetChoiceOptionCode                
   AND X.LinkTarget = PSLNK.LinkTarget                
   AND X.LinkStatusTypeId = PSLNK.LinkStatusTypeId                
   AND X.IsDeleted = PSLNK.IsDeleted                
   AND X.ProjectId = PSLNK.ProjectId                
   AND X.CustomerId = PSLNK.CustomerId                
   AND X.SegmentLinkSourceTypeId = PSLNK.SegmentLinkSourceTypeId                
 WHERE PSLNK.SegmentLinkId IS NULL                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentLink_Description                            
           ,@ImportProjectSegmentLink_Description                            
           ,@IsCompleted                           
           ,@ImportProjectSegmentLink_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                  
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted               
         ,@ImportProjectSegmentLink_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectSegmentRequirementTag                
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId,                
CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,MSRT_Template.RequirementTagId AS RequirementTagId                
    ,GETUTCDATE() AS CreateDate                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,@PUserId AS CreatedBy                
    ,@PUserId AS ModifiedBy                
 FROM SLCMaster..SegmentRequirementTag MSRT_Template WITH (NOLOCK)                
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
  ON MSRT_Template.SegmentStatusId = PSST.mSegmentStatusId                
 WHERE MSRT_Template.SectionId = @TemplateMasterSectionId                
 AND PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,PSRT_Template.RequirementTagId AS RequirementTagId                
    ,GETUTCDATE() AS CreateDate                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,@PUserId AS CreatedBy                
    ,@PUserId AS ModifiedBy                
 FROM ProjectSegmentRequirementTag PSRT_Template WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSRT_Template.SegmentStatusId = PSST_Template.SegmentStatusId                
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode                
   AND PSST.SectionId = @SectionId                
 WHERE PSRT_Template.SectionId = @TemplateSectionId                
 AND @IsTemplateMasterSectionOpened = 1                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentRequirementTag_Description                            
           ,@ImportProjectSegmentRequirementTag_Description                            
           ,@IsCompleted                         
           ,@ImportProjectSegmentRequirementTag_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted        
         ,@ImportProjectSegmentRequirementTag_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectSegmentUserTag                
INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId,                
UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)                
 SELECT                
  @PCustomerId AS CustomerId                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,PSUT_Template.UserTagId AS UserTagId                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
 FROM ProjectSegmentUserTag PSUT_Template WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)                
  ON PSUT_Template.SegmentStatusId = PSST_Template.SegmentStatusId                
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode                
   AND PSST.SectionId = @SectionId                
 WHERE PSUT_Template.SectionId = @TemplateSectionId                
 AND @IsTemplateMasterSectionOpened = 1                
                
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentUserTag_Description                            
           ,@ImportProjectSegmentUserTag_Description                            
           ,@IsCompleted                           
           ,@ImportProjectSegmentUserTag_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                     
         ,@ImportProjectSegmentUserTag_Percentage --Percent                            
         , 0                
    ,@ImportSource          
         , @RequestId;               
                
--INSERT INTO ProjectSegmentGlobalTerm                
INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId,                
UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)                
 SELECT                
  @PCustomerId AS CustomerId                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,PSG.SegmentId AS SegmentId                
    ,NULL AS mSegmentId                
    ,PSGT_Template.UserGlobalTermId AS UserGlobalTermId                
    ,PSGT_Template.GlobalTermCode AS GlobalTermCode                
    ,PSGT_Template.IsLocked AS IsLocked                
    ,PSGT_Template.LockedByFullName AS LockedByFullName                
    ,PSGT_Template.UserLockedId AS UserLockedId                
    ,GETUTCDATE() AS CreatedDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
 FROM ProjectSegmentGlobalTerm PSGT_Template WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)                
  ON PSGT_Template.SegmentId = PSG_Template.SegmentId                
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
  ON PSG_Template.SegmentCode = PSG.SegmentCode                
   AND PSG.SectionId = @SectionId                
 WHERE PSGT_Template.SectionId = @TemplateSectionId                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentGlobalTerm_Description         
           ,@ImportProjectSegmentGlobalTerm_Description                            
           ,@IsCompleted                           
           ,@ImportProjectSegmentGlobalTerm_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                 
         ,@ImportProjectSegmentGlobalTerm_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectSegmentImage                
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId)                
 SELECT                
  @SectionId AS SectionId                
    ,PSI_Template.ImageId AS ImageId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,PSG.SegmentId AS SegmentId                
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)                
  ON PSI_Template.SegmentId = PSG_Template.SegmentId                
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
  ON PSG_Template.SegmentCode = PSG.SegmentCode                
   AND PSG.SectionId = @SectionId                
 WHERE PSI_Template.SectionId = @TemplateSectionId                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,PSI_Template.ImageId AS ImageId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,PSI_Template.SegmentId AS SegmentId                
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)                
 WHERE PSI_Template.SectionId = @TemplateSectionId                
 AND (PSI_Template.SegmentId IS NULL                
 OR PSI_Template.SegmentId <= 0)                
              
  EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentImage_Description                            
           ,@ImportProjectSegmentImage_Description                            
           ,@IsCompleted                           
           ,@ImportProjectSegmentImage_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                      
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                  
         ,@ImportProjectSegmentImage_Percentage --Percent                            
         , 0                
    ,@ImportSource          
         , @RequestId;               
        --INSERT INTO ProjectHyperLink                
--NOTE IMP:For updating proper HyperLinkId in final table, CustomerId used for temp purpose                
--TODO:Need to correct ProjectHyperLink table's ModifiedBy Column                
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText,                
LuHyperLinkSourceTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)                
 SELECT                
  @SectionId AS SectionId                
    ,PSST.SegmentId AS SegmentId                
    ,PSST.SegmentStatusId AS SegmentStatusId                
    ,@PProjectId AS ProjectId         
    ,MHL_Template.HyperLinkId AS MasterHyperLinkId                
    ,MHL_Template.LinkTarget AS LinkTarget                
    ,MHL_Template.LinkText AS LinkText                
    ,MHL_Template.LuHyperLinkSourceTypeId AS LuHyperLinkSourceTypeId                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
 FROM SLCMaster..Note MNT_Template WITH (NOLOCK)                
 INNER JOIN SLCMaster..HyperLink MHL_Template WITH (NOLOCK)                
  ON MNT_Template.SegmentStatusId = MHL_Template.SegmentStatusId                
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
  ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId                
   AND PSST.SectionId = @SectionId                
 WHERE MNT_Template.SectionId = @TemplateMasterSectionId                
               
--Fetch Src Master notes into temp table                
SELECT                
 * INTO #tmp_SrcMasterNote                
FROM SLCMaster..Note WITH (NOLOCK)                
WHERE SectionId = @TemplateMasterSectionId;                
                
--Fetch tgt project notes into temp table                
SELECT                
 * INTO #tmp_TgtProjectNote                
FROM ProjectNote PNT WITH (NOLOCK)                
WHERE SectionId = @SectionId;                
                
--UPDATE NEW HyperLinkId IN NoteText                
DECLARE @HyperLinkLoopCount INT = 1;                
DECLARE @HyperLinkTable TABLE (                
 RowId INT                
   ,HyperLinkId INT                
   ,MasterHyperLinkId INT                
);                
                
INSERT INTO @HyperLinkTable (RowId, HyperLinkId, MasterHyperLinkId)                
 SELECT                
  ROW_NUMBER() OVER (ORDER BY PHL.HyperLinkId ASC) AS RowId       
    ,PHL.HyperLinkId                
    ,PHL.CustomerId                
 FROM ProjectHyperLink PHL WITH (NOLOCK)                
 WHERE PHL.SectionId = @SectionId;                
                
declare @HyperLinkTableRowCount INT=(SELECT                
  COUNT(*)                
 FROM @HyperLinkTable)                
WHILE (@HyperLinkLoopCount <= @HyperLinkTableRowCount)                
BEGIN                
DECLARE @HyperLinkId INT = 0;                
DECLARE @MasterHyperLinkId INT = 0;                
                
SELECT                
 @HyperLinkId = HyperLinkId                
   ,@MasterHyperLinkId = MasterHyperLinkId                
FROM @HyperLinkTable                
WHERE RowId = @HyperLinkLoopCount;                
                
UPDATE PNT                
SET PNT.NoteText =                
REPLACE(PNT.NoteText, '{HL#' + CAST(@MasterHyperLinkId AS NVARCHAR(MAX)) + '}',                
'{HL#' + CAST(@HyperLinkId AS NVARCHAR(MAX)) + '}')                
FROM #tmp_SrcMasterNote MNT_Template WITH (NOLOCK)                
INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
 ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId     
 AND PSST.SectionId = @SectionId                
INNER JOIN #tmp_TgtProjectNote PNT WITH (NOLOCK)                
 ON PSST.SegmentStatusId = PNT.SegmentStatusId                
WHERE MNT_Template.SectionId = @TemplateMasterSectionId                
                
SET @HyperLinkLoopCount = @HyperLinkLoopCount + 1;                
END                
                
--Update NoteText back into original table from temp table                
UPDATE PNT                
SET PNT.NoteText = TMP.NoteText                
FROM ProjectNote PNT WITH (NOLOCK)                
INNER JOIN #tmp_TgtProjectNote TMP WITH (NOLOCK)                
 ON PNT.NoteId = TMP.NoteId                
WHERE PNT.SectionId = @SectionId;                
                
--UPDATE PROPER CustomerId IN ProjectHyperLink                
UPDATE PHL                
SET PHL.CustomerId = @PCustomerId                
FROM ProjectHyperLink PHL WITH (NOLOCK)                
WHERE PHL.SectionId = @SectionId                
              
   EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectHyperLink_Description                            
           ,@ImportProjectHyperLink_Description                            
           ,@IsCompleted                           
           ,@ImportProjectHyperLink_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                    
         ,@ImportProjectHyperLink_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectNoteImage                
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)                
 SELECT                
  PN.NoteId AS NoteId                
    ,@SectionId AS SectionId                
    ,PNI_Template.ImageId AS ImageId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
 FROM ProjectNoteImage PNI_Template WITH (NOLOCK)                
 INNER JOIN ProjectNote PN_Template WITH (NOLOCK)                
  ON PNI_Template.NoteId = PN_Template.NoteId                
 INNER JOIN ProjectNote PN WITH (NOLOCK)                
  ON PN.SectionId = @SectionId    
   AND PN_Template.NoteCode = PN.NoteCode                            
 WHERE PNI_Template.SectionId = @TemplateSectionId      
 
    EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectNoteImage_Description                            
           ,@ImportProjectNoteImage_Description                            
           ,@IsCompleted                          
           ,@ImportProjectNoteImage_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId             
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted               
         ,@ImportProjectNoteImage_Percentage --Percent                            
         , 0                
   ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectSegmentReferenceStandard                
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,                
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode, IsDeleted)                
 SELECT                
 DISTINCT                
  @SectionId AS SectionId                
    ,X.SegmentId                
    ,X.RefStandardId                
    ,X.RefStandardSource                
    ,X.mRefStandardId                
    ,GETUTCDATE() AS CreateDate                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,@PUserId AS ModifiedBy                
    ,@PCustomerId AS CustomerId                
    ,@PProjectId AS ProjectId                
    ,X.mSegmentId                
    ,X.RefStdCode                
    ,X.IsDeleted                
 FROM (SELECT                
   PSST.SegmentId AS SegmentId                
     ,NULL AS RefStandardId                
    ,'M' AS RefStandardSource                
     ,MRS_Template.RefStdId AS mRefStandardId                
     ,NULL AS mSegmentId                
     ,MRS_Template.RefStdCode AS RefStdCode                
     ,CAST(0 AS BIT) AS IsDeleted                
  FROM SLCMaster..SegmentReferenceStandard MSRS_Template WITH (NOLOCK)                
  INNER JOIN SLCMaster..ReferenceStandard MRS_Template WITH (NOLOCK)                
 ON MSRS_Template.RefStandardId = MRS_Template.RefStdId                
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST                
   ON MSRS_Template.SegmentId = PSST.mSegmentId                
   AND PSST.SectionId = @SectionId                
  WHERE MSRS_Template.SectionId = @TemplateMasterSectionId                
  UNION                
  SELECT                
   PSST.SegmentId AS SegmentId                
     ,PSRS_Template.RefStandardId AS RefStandardId                
     ,PSRS_Template.RefStandardSource AS RefStandardSource                
     ,PSRS_Template.mRefStandardId AS mRefStandardId                
     ,NULL AS mSegmentId                
     ,PSRS_Template.RefStdCode AS RefStdCode                
     ,PSRS_Template.IsDeleted                
  FROM ProjectSegmentReferenceStandard PSRS_Template WITH (NOLOCK)                
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
   ON PSRS_Template.mSegmentId = PSST.mSegmentId                
   AND PSST.SectionId = @SectionId                
  WHERE PSRS_Template.SectionId = @TemplateSectionId                
  AND PSRS_Template.mSegmentId IS NOT NULL                
  AND PSRS_Template.SegmentId IS NULL                
  UNION                
  SELECT                
   PSG.SegmentId AS SegmentId                
     ,PSRS_Template.RefStandardId AS RefStandardId                
     ,PSRS_Template.RefStandardSource AS RefStandardSource                
     ,PSRS_Template.mRefStandardId AS mRefStandardId                
     ,NULL AS mSegmentId                
     ,PSRS_Template.RefStdCode AS RefStdCode                
     ,PSRS_Template.IsDeleted                
  FROM ProjectSegmentReferenceStandard PSRS_Template WITH (NOLOCK)                
  INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)         
   ON PSRS_Template.SegmentId = PSG_Template.SegmentId                
  INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
   ON PSG_Template.SegmentCode = PSG.SegmentCode                
   AND PSG.SectionId = @SectionId                
  WHERE PSRS_Template.SectionId = @TemplateSectionId                
  AND PSRS_Template.mSegmentId IS NULL                
  AND PSRS_Template.SegmentId IS NOT NULL) AS X                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentReferenceStandard_Description                            
           ,@ImportProjectSegmentReferenceStandard_Description                            
           ,@IsCompleted                          
           ,@ImportProjectSegmentReferenceStandard_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                 
         ,@ImportProjectSegmentReferenceStandard_Percentage --Percent                            
         , 0                
   ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO Header                
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy,                
ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltHeader, FPHeader,                
UseSeparateFPHeader, HeaderFooterCategoryId, DateFormat, TimeFormat)                
 SELECT                
  @PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,@PCustomerId AS CustomerId                
    ,Description                
    ,NULL AS IsLocked                
    ,NULL AS LockedByFullName                
    ,NULL AS LockedBy                
    ,ShowFirstPage                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreatedDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,TypeId                
    ,AltHeader                
    ,FPHeader                
    ,UseSeparateFPHeader                
    ,HeaderFooterCategoryId                
    ,DateFormat                
    ,TimeFormat                
 FROM Header WITH (NOLOCK)                
 WHERE SectionId = @TemplateSectionId                
              
EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportHeader_Description                            
           ,@ImportHeader_Description                            
           ,@IsCompleted                     
           ,@ImportHeader_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                  
         ,@ImportHeader_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO Footer                
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy,                
ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter,                
UseSeparateFPFooter, HeaderFooterCategoryId, DateFormat, TimeFormat)                
 SELECT                
  @PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
    ,@PCustomerId AS CustomerId                
    ,Description                
    ,NULL AS IsLocked                
    ,NULL AS LockedByFullName                
    ,NULL AS LockedBy                
    ,ShowFirstPage                
    ,@PUserId AS CreatedBy                
    ,GETUTCDATE() AS CreatedDate                
    ,@PUserId AS ModifiedBy                
    ,GETUTCDATE() AS ModifiedDate                
    ,TypeId                
    ,AltFooter                
    ,FPFooter                
    ,UseSeparateFPFooter                
    ,HeaderFooterCategoryId                
    ,DateFormat                
    ,TimeFormat                
 FROM Footer WITH (NOLOCK)                
 WHERE SectionId = @TemplateSectionId                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportFooter_Description                            
           ,@ImportFooter_Description                            
           ,@IsCompleted                      
           ,@ImportFooter_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                      
         ,@ImportFooter_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectReferenceStandard                
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,                
RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)                
 SELECT                
 DISTINCT                
  @PProjectId AS ProjectId                
    ,X.RefStandardId                
    ,X.RefStdSource                
    ,X.mReplaceRefStdId                
    ,X.RefStdEditionId                
    ,X.IsObsolete                
    ,X.RefStdCode                
    ,GETUTCDATE() AS PublicationDate             
    ,@SectionId AS SectionId                
    ,@PCustomerId AS CustomerId                
 FROM (SELECT                
   MRS.RefStdId AS RefStandardId                
     ,'M' AS RefStdSource                
     ,MRS.ReplaceRefStdId AS mReplaceRefStdId                
     ,MAX(MRSE.RefStdEditionId) AS RefStdEditionId                
     ,MRS.IsObsolete AS IsObsolete                
     ,MRS.RefStdCode AS RefStdCode                
  FROM SLCMaster..SegmentReferenceStandard MSRS WITH (NOLOCK)                
  INNER JOIN SLCMaster..ReferenceStandard MRS WITH (NOLOCK)                
   ON MSRS.RefStandardId = MRS.RefStdId                
  INNER JOIN SLCMaster..ReferenceStandardEdition MRSE WITH (NOLOCK)                
   ON MRS.RefStdId = MRSE.RefStdId                
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
   ON MSRS.SegmentId = PSST.mSegmentId                
   AND PSST.SectionId = @SectionId                
  WHERE MSRS.SectionId = @TemplateMasterSectionId                
  GROUP BY MRS.RefStdId                
    ,MRS.ReplaceRefStdId                
    ,MRS.IsObsolete                
    ,MRS.RefStdCode                
  UNION                
  SELECT                
   PRS.RefStandardId AS RefStandardId                
     ,PRS.RefStdSource AS RefStdSource                
     ,PRS.mReplaceRefStdId AS mReplaceRefStdId                
     ,PRS.RefStdEditionId AS RefStdEditionId                
     ,PRS.IsObsolete AS IsObsolete                
     ,PRS.RefStdCode AS RefStdCode                
  FROM ProjectReferenceStandard PRS WITH (NOLOCK)                
  WHERE PRS.ProjectId = @PProjectId                
  AND PRS.CustomerId = @PCustomerId                
  AND PRS.SectionId = @SectionId                
  AND PRS.IsDeleted = 0) AS X                
 LEFT JOIN ProjectReferenceStandard PRS WITH (NOLOCK)                
  ON PRS.ProjectId = @PProjectId                
   AND PRS.RefStandardId = X.RefStandardId                
   AND PRS.RefStdSource = X.RefStdSource                
   AND ISNULL(PRS.mReplaceRefStdId, 0) = ISNULL(X.mReplaceRefStdId, 0)                
   AND PRS.RefStdEditionId = X.RefStdEditionId                
   AND PRS.IsObsolete = X.IsObsolete                
   AND PRS.SectionId = @SectionId                
   AND PRS.CustomerId = @PCustomerId                
 WHERE PRS.ProjRefStdId IS NULL                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectReferenceStandard_Description                            
           ,@ImportProjectReferenceStandard_Description                            
           ,@IsCompleted                      
           ,@ImportProjectReferenceStandard_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
        ,@PCustomerId                            
         ,@ImportStarted                      
         ,@ImportProjectReferenceStandard_Percentage --Percent                            
         , 0                
   ,@ImportSource        
         , @RequestId;         
                
--UPDATE ProjectSegmentStatus at last                
UPDATE PSST                
SET PSST.mSegmentStatusId = NULL                
   ,PSST.mSegmentId = NULL                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
WHERE PSST.SectionId = @SectionId                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentStatus_Description                            
           ,@ImportProjectSegmentStatus_Description                            
           ,@IsCompleted                   
           ,@ImportProjectSegmentStatus_Step --Step                     
     ,@RequestId;              
             
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                    
         ,@ImportProjectSegmentStatus_Percentage --Percent                            
         , 0                
   ,@ImportSource          
         , @RequestId;               
                
END                
                
              
                
SELECT                
 @IsSuccess AS IsSuccess                
   ,@ErrorMessage AS ErrorMessage                
                
SELECT                
 *                
FROM ProjectSection WITH (NOLOCK)                
WHERE SectionId = @SectionId              
                  
    EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportComplete_Description                            
           ,@ImportComplete_Description                            
           ,@IsCompleted                    
           ,@ImportComplete_Step --Step                     
     ,@RequestId;              
                
 --Add Logs to ImportProjectRequest                
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportCompleted                        
         ,@ImportComplete_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
              
               
END TRY                
                
BEGIN CATCH                
DECLARE @ResultMessage NVARCHAR(MAX);                            
SET @ResultMessage = 'Rollback Transaction. Error Number: ' + CONVERT(VARCHAR(MAX), ERROR_NUMBER()) +                      
'. Error Message: ' + CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) +                            
'. Procedure Name: ' + CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) +                            
'. Error Severity: ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +                            
'. Line Number: ' + CONVERT(VARCHAR(5), ERROR_LINE());                    
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportFailed_Description                            
          ,@ResultMessage                      
           ,@IsCompleted                  
            ,@ImportFailed_Step --Step                     
     ,@RequestId;                
                
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId                       
         ,@PUserId                            
         ,@PCustomerId                         
    ,@Importfailed                        
        ,@ImportFailed_Percentage --Percent                            
         , 0                
       ,@ImportSource          
         , @RequestId;                
              
END CATCH                  
END
GO
PRINT N'Altering [dbo].[usp_CreateNewProject]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateNewProject] (
@Name NVARCHAR(500),  
@IsOfficeMaster BIT,  
@Description NVARCHAR(100),  
@MasterDataTypeId INT,  
@UserId INT,  
@CustomerId INT,  
@ModifiedByFullName NVARCHAR(500),  
@GlobalProjectID NVARCHAR(36),  
@CreatedBy    INT 
)
AS  
BEGIN
DECLARE @PName NVARCHAR(500) = @Name;
DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;
DECLARE @PDescription NVARCHAR(100) = @Description;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
DECLARE @PUserId INT = @UserId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PModifiedByFullName NVARCHAR(500) = @ModifiedByFullName;
DECLARE @PGlobalProjectID NVARCHAR(36) = @GlobalProjectID;
DECLARE @PCreatedBy INT = @CreatedBy;

  
    DECLARE @TemplateId INT=0;
		-- Get Template ID as per master datatype
	IF @PMasterDataTypeId=1
	BEGIN
SET @TemplateId = (SELECT TOP 1
		TemplateId
	FROM Template WITH (NOLOCK)
	WHERE IsSystem = 1
	AND MasterDataTypeId = @PMasterDataTypeId
	AND IsDeleted = 0);
  
	 END
	 ELSE
	 BEGIN
SET @TemplateId = (SELECT TOP 1
		TemplateId
	FROM Template WITH (NOLOCK)
	WHERE IsSystem = 1
	AND MasterDataTypeId != 1
	AND IsDeleted = 0);
 END
-- make entry to project table
INSERT INTO Project ([Name]
, IsOfficeMaster
, [Description]
, TemplateId
, MasterDataTypeId
, UserId
, CustomerId
, CreateDate
, CreatedBy
, ModifiedBy
, ModifiedDate
, IsDeleted
, IsMigrated
, IsNamewithHeld
, IsLocked
, GlobalProjectID
, IsPermanentDeleted
, A_ProjectId
, IsProjectMoved
, ModifiedByFullName)
	VALUES (@PName, @PIsOfficeMaster, @PDescription, @TemplateId, @PMasterDataTypeId, @PUserId, @PCustomerId, GETUTCDATE(), @PCreatedBy, @PCreatedBy, GETUTCDATE(), 0, NULL, 0, 0,@PGlobalProjectID, NULL, NULL, NULL, @PModifiedByFullName)

DECLARE @NewProjectId INT = SCOPE_IDENTITY();

-- make entry to UserFolder table
INSERT INTO UserFolder (FolderTypeId
, ProjectId
, UserId
, LastAccessed
, CustomerId
, LastAccessByFullName)
	VALUES (1, @NewProjectId, @PUserId, GETUTCDATE(), @PCustomerId, @PModifiedByFullName)

-- Select newly created project.
SELECT
	@NewProjectId AS ProjectId
   ,@PName AS [Name]
   ,@PIsOfficeMaster AS IsOfficeMaster
   ,@PDescription AS [Description]
   ,@TemplateId AS TemplateId
   ,@PMasterDataTypeId AS MasterDataTypeId
   ,@PUserId AS UserId
   ,@PCustomerId AS CustomerId
   ,GETUTCDATE() AS CreateDate
   ,@PCreatedBy AS CreatedBy
   ,@PCreatedBy AS ModifiedBy
   ,GETUTCDATE() AS ModifiedDate
   ,0 AS IsDeleted
   ,NULL AS IsMigrated
   ,0 AS IsNamewithHeld
   ,0 AS IsLocked
   ,@PGlobalProjectID AS GlobalProjectID
   ,NULL AS IsPermanentDeleted
   ,NULL AS A_ProjectId
   ,NULL AS IsProjectMoved
   ,@PModifiedByFullName AS ModifiedByFullName
   ,@NewProjectId AS Id
--FROM Project WITH (NOLOCK)
--WHERE ProjectId = @NewProjectId


END
GO
PRINT N'Altering [dbo].[usp_GetSourceTargetLinksCount]...';


GO
ALTER PROCEDURE usp_GetSourceTargetLinksCount  
(@ProjectId INT, @SectionId INT, @CustomerId INT, @SectionCode INT, @MasterDataTypeId TINYINT = 1, @CatalogueType NVARCHAR(100) = 'FS') 
AS    
BEGIN
  
--PARAMETER SNIFFING CARE  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
  
--VARIABLES  
--DECLARE @PMasterDataTypeId INT = ( SELECT  
--  P.MasterDataTypeId  
-- FROM Project P WITH (NOLOCK)  
-- WHERE P.ProjectId = @PProjectId  
-- AND P.CustomerId = @PCustomerId);  
  
--CONSTANTS  
DECLARE @MasterSegmentLinkSourceTypeId_CNST INT = 1;
DECLARE @UserSegmentLinkSourceTypeId_CNST INT = 5;

--TABLES  
--1.SegmentStatus of Section and their SrcLinksCount and TgtLinksCount  
DROP TABLE IF EXISTS #ResultTable
CREATE TABLE #ResultTable (
	ProjectId INT NOT NULL
   ,SectionId INT NOT NULL
   ,CustomerId INT NOT NULL
   ,SectionCode INT NULL
   ,SegmentStatusCode INT NULL
   ,SegmentCode INT NULL
   ,SegmentSource CHAR(1) NULL
   ,SrcLinksCnt INT NULL
   ,TgtLinksCnt INT NULL
   ,SegmentDescription NVARCHAR(MAX) NULL
   ,SequenceNumber DECIMAL(10, 4) NULL
   ,SegmentStatusId INT NULL
   ,SegmentId INT NULL
   ,mSegmentId INT NULL
   ,IndentLevel INT NULL
   ,SpecTypeTagId INT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#ResultTable_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
ON #ResultTable ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--2.Lookup SpecTypeTagsId Tables  
DROP TABLE IF EXISTS #SpecTypeTagIdTable
CREATE TABLE #SpecTypeTagIdTable (
	SpecTypeTagId INT
);

--3.Distinct SegmentStatus from Links tables  
DROP TABLE IF EXISTS #DistinctSegmentStatus
CREATE TABLE #DistinctSegmentStatus (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SegmentStatusCode INT NULL
   ,SegmentSource CHAR(1) NULL
   ,SectionCode INT NULL
   ,SegmentCode INT NULL
   ,IsDeleted BIT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#DistinctSegmentStatus_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
ON #DistinctSegmentStatus ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--4.Section's of Project table  
DROP TABLE IF EXISTS #SectionsTable
CREATE TABLE #SectionsTable (
	SectionId INT NULL
   ,SectionCode INT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#SectionsTable_SectionCode]
ON #SectionsTable ([SectionCode])

--5.All Src and Tgt Links Table  
DROP TABLE IF EXISTS #SegmentLinksTable
CREATE TABLE #SegmentLinksTable (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SourceSectionCode INT NULL
   ,SourceSegmentStatusCode INT NULL
   ,SourceSegmentCode INT NULL
   ,SourceSegmentChoiceCode INT NULL
   ,SourceChoiceOptionCode INT NULL
   ,LinkSource NVARCHAR(MAX) NULL
   ,TargetSectionCode INT NULL
   ,TargetSegmentStatusCode INT NULL
   ,TargetSegmentCode INT NULL
   ,TargetSegmentChoiceCode INT NULL
   ,TargetChoiceOptionCode INT NULL
   ,LinkTarget NVARCHAR(MAX) NULL
   ,LinkStatusTypeId INT NULL
   ,SegmentLinkCode INT NULL
   ,SegmentLinkSourceTypeId INT NULL
   ,IsSrcLink INT NULL
   ,IsTgtLink INT NULL
   ,IsDeleted BIT NULL
);

--INSERT SEGMENT STATUS IN THIS LIST  
INSERT INTO #ResultTable (ProjectId, SectionId, CustomerId, SegmentStatusCode,
SequenceNumber, SegmentCode, SegmentDescription, SegmentSource, SectionCode,
SrcLinksCnt, TgtLinksCnt, SegmentStatusId, SegmentId, mSegmentId, IndentLevel, SpecTypeTagId)
	SELECT
		PSSTV.ProjectId
	   ,PSSTV.SectionId
	   ,PSSTV.CustomerId
	   ,PSSTV.SegmentStatusCode
	   ,PSSTV.SequenceNumber
	   ,PSSTV.SegmentCode
	   ,PSSTV.SegmentDescription
	   ,CAST(PSSTV.SegmentOrigin AS CHAR(1)) AS SegmentSource
	   ,PSSTV.SectionCode
	   ,0 AS SrcLinksCnt
	   ,0 AS TgtLinksCnt
	   ,PSSTV.SegmentStatusId
	   ,PSSTV.SegmentId
	   ,PSSTV.mSegmentId
	   ,PSSTV.IndentLevel
	   ,(CASE
			WHEN PSSTV.SpecTypeTagId IS NOT NULL THEN PSSTV.SpecTypeTagId
			ELSE 0
		END) AS SpecTypeTagId
	FROM ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	WHERE PSSTV.ProjectId = @PProjectId
	AND PSSTV.SectionId = @PSectionId
	AND PSSTV.CustomerId = @PCustomerId
	AND ISNULL(PSSTV.IsDeleted, 0) = 0

--REMOVE THOSE TO WHOME THERE IS DO NOT HAVE ACCESS DEPENDS UPON CATALOGUE TYPE  
IF @PCatalogueType != 'FS'
BEGIN
INSERT INTO #SpecTypeTagIdTable (SpecTypeTagId)
	SELECT
		SpecTypeTagId
	FROM LuProjectSpecTypeTag WITH (NOLOCK)
	WHERE TagType IN (SELECT
			*
		FROM dbo.fn_SplitString(@PCatalogueType, ','));

DELETE RT
	FROM #ResultTable RT
WHERE RT.SpecTypeTagId NOT IN (SELECT
			TBL.SpecTypeTagId
		FROM #SpecTypeTagIdTable TBL)
END

--TODO--BELOW CODE NEED TO BE MOVE IN COMMON SP  
--INSERT SOURCE AND TARGET LINKS FROM PROJECT DB  
INSERT INTO #SegmentLinksTable (ProjectId, CustomerId,
SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode,
TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId,
IsSrcLink, IsTgtLink, SegmentLinkSourceTypeId, IsDeleted, SegmentLinkCode)
	--INSERT SOURCE LINKS FROM PROJECT DB  
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
	   ,PSLNK.SourceSectionCode
	   ,PSLNK.SourceSegmentStatusCode
	   ,PSLNK.SourceSegmentCode
	   ,PSLNK.SourceSegmentChoiceCode
	   ,PSLNK.SourceChoiceOptionCode
	   ,PSLNK.LinkSource
	   ,PSLNK.TargetSectionCode
	   ,PSLNK.TargetSegmentStatusCode
	   ,PSLNK.TargetSegmentCode
	   ,PSLNK.TargetSegmentChoiceCode
	   ,PSLNK.TargetChoiceOptionCode
	   ,PSLNK.LinkTarget
	   ,PSLNK.LinkStatusTypeId
	   ,1 AS IsSrcLink
	   ,0 AS IsTgtLink
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.IsDeleted
	   ,PSLNK.SegmentLinkCode
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #ResultTable INPJSON WITH (NOLOCK)
		ON PSLNK.TargetSectionCode = INPJSON.SectionCode
			AND PSLNK.TargetSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.TargetSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkTarget = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.SegmentLinkSourceTypeId IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)
	AND ISNULL(PSLNK.IsDeleted, 0) = 0
	UNION
	--INSERT TARGET LINKS FROM PROJECT DB  
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
	   ,PSLNK.SourceSectionCode
	   ,PSLNK.SourceSegmentStatusCode
	   ,PSLNK.SourceSegmentCode
	   ,PSLNK.SourceSegmentChoiceCode
	   ,PSLNK.SourceChoiceOptionCode
	   ,PSLNK.LinkSource
	   ,PSLNK.TargetSectionCode
	   ,PSLNK.TargetSegmentStatusCode
	   ,PSLNK.TargetSegmentCode
	   ,PSLNK.TargetSegmentChoiceCode
	   ,PSLNK.TargetChoiceOptionCode
	   ,PSLNK.LinkTarget
	   ,PSLNK.LinkStatusTypeId
	   ,0 AS IsSrcLink
	   ,1 AS IsTgtLink
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.IsDeleted
	   ,PSLNK.SegmentLinkCode
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #ResultTable INPJSON WITH (NOLOCK)
		ON PSLNK.SourceSectionCode = INPJSON.SectionCode
			AND PSLNK.SourceSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.SourceSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkSource = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.SegmentLinkSourceTypeId IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)
	AND ISNULL(PSLNK.IsDeleted, 0) = 0

--FETCH SECTIONS OF PROJECT IN TEMP TABLE  
INSERT INTO #SectionsTable (SectionId, SectionCode)
	SELECT
		PS.SectionId
	   ,PS.SectionCode
	FROM ProjectSection PS WITH (NOLOCK)
	WHERE PS.ProjectId = @PProjectId
	AND PS.CustomerId = @PCustomerId
	AND PS.IsLastLevel = 1
	AND ISNULL(PS.IsDeleted, 0) = 0

--DELETE THOSE LINKS WHOSE LINK SOURCE TYPE IS NOT MASTER OR USER  
--DELETE FROM #SegmentLinksTable  
--WHERE SegmentLinkSourceTypeId NOT IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)  

--DELETE WHICH ARE SOFT DELETED IN DB  
--DELETE FROM #SegmentLinksTable  
--WHERE IsDeleted = 1  

--DELETE SOURCE LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT  
DELETE SLNK
	FROM #SegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.SourceSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--DELETE TARGET LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT  
DELETE SLNK
	FROM #SegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.TargetSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--FETCH DISTINCT SEGMENT STATUS CODE  
INSERT INTO #DistinctSegmentStatus (ProjectId, CustomerId, SegmentStatusCode, SectionCode)
	SELECT DISTINCT
		X.ProjectId
	   ,X.CustomerId
	   ,X.SegmentStatusCode
	   ,X.SectionCode
	FROM (SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.SourceSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.SourceSectionCode AS SectionCode
		FROM #SegmentLinksTable SLNKS UNION
		SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.TargetSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.TargetSectionCode AS SectionCode
		FROM #SegmentLinksTable SLNKS) AS X

UPDATE DSTSG
SET DSTSG.SegmentCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentCode
	END)
   ,DSTSG.SegmentSource = CAST((CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentOrigin
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentOrigin
	END) AS CHAR(1))
   ,DSTSG.SectionCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SectionCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SectionCode
	END)
   ,DSTSG.IsDeleted = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.IsDeleted
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.IsDeleted
	END)
FROM #DistinctSegmentStatus DSTSG WITH (NOLOCK)
LEFT JOIN ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	ON DSTSG.ProjectId = PSSTV.ProjectId
	AND DSTSG.CustomerId = PSSTV.CustomerId
	AND DSTSG.SectionCode = PSSTV.SectionCode
	AND DSTSG.SegmentStatusCode = PSSTV.SegmentStatusCode
	AND ISNULL(PSSTV.IsDeleted, 0) = 0

LEFT JOIN SLCMaster..SegmentStatusView MSSTV WITH (NOLOCK)
	ON DSTSG.SegmentStatusCode = MSSTV.SegmentStatusCode
	AND ISNULL(MSSTV.IsDeleted, 0) = 0

--DELETE UNMATCHED SEGMENT CODE IN SRC AND TGT LINKS AS WELL  
DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.SourceSectionCode = DSST.SectionCode
		AND SLNK.SourceSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.SourceSegmentCode = DSST.SegmentCode
		AND SLNK.LinkSource = DSST.SegmentSource
WHERE (SLNK.IsSrcLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.TargetSectionCode = DSST.SectionCode
		AND SLNK.TargetSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.TargetSegmentCode = DSST.SegmentCode
		AND SLNK.LinkTarget = DSST.SegmentSource
WHERE (SLNK.IsTgtLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @PProjectId
		AND SCHV.CustomerId = @PCustomerId
		AND SLNK.SourceSectionCode = SCHV.SectionCode
		AND SLNK.SourceSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.SourceSegmentCode = SCHV.SegmentCode
		AND SLNK.SourceSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.SourceChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkSource = SCHV.ChoiceOptionSource
WHERE SCHV.ProjectId = @PProjectId
	AND SCHV.SectionId = @PSectionId
	AND SLNK.IsSrcLink = 1
	AND ISNULL(SLNK.SourceSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.SourceChoiceOptionCode, 0) > 0
	AND SLNK.LinkSource = 'U'
	AND SCHV.SegmentStatusId IS NULL

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @PProjectId
		AND SCHV.CustomerId = @PCustomerId
		AND SLNK.TargetSectionCode = SCHV.SectionCode
		AND SLNK.TargetSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.TargetSegmentCode = SCHV.SegmentCode
		AND SLNK.TargetSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.TargetChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkTarget = SCHV.ChoiceOptionSource
WHERE SCHV.ProjectId = @PProjectId
	AND SCHV.SectionId = @PSectionId
	AND SLNK.IsTgtLink = 1
	AND ISNULL(SLNK.TargetSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.TargetChoiceOptionCode, 0) > 0
	AND SLNK.LinkTarget = 'U'
	AND SCHV.SegmentStatusId IS NULL

--UPDATE TGT LINKS COUNT  
UPDATE TBL
SET TBL.TgtLinksCnt = X.TgtLinksCnt
FROM #ResultTable TBL
INNER JOIN (SELECT
		SourceSegmentStatusCode
	   ,LinkSource
	   ,COUNT(1) AS TgtLinksCnt
	FROM #SegmentLinksTable
	WHERE IsTgtLink = 1
	GROUP BY SourceSegmentStatusCode
			,LinkSource
			,IsTgtLink) X
	ON TBL.SegmentStatusCode = X.SourceSegmentStatusCode
	AND TBL.SegmentSource = X.LinkSource

--UPDATE SRC LINKS COUNT  
UPDATE TBL
SET TBL.SrcLinksCnt = X.SrcLinksCnt
FROM #ResultTable TBL
INNER JOIN (SELECT
		TargetSegmentStatusCode
	   ,LinkTarget
	   ,COUNT(1) AS SrcLinksCnt
	FROM #SegmentLinksTable
	WHERE IsSrcLink = 1
	GROUP BY TargetSegmentStatusCode
			,LinkTarget
			,IsSrcLink) X
	ON TBL.SegmentStatusCode = X.TargetSegmentStatusCode
	AND TBL.SegmentSource = X.LinkTarget

--DELETE UNWANTED RECORDS FROM RESULT LINKS TABLE  
DELETE FROM #ResultTable
WHERE SrcLinksCnt <= 0
	AND TgtLinksCnt <= 0

SELECT * FROM #ResultTable WITH (NOLOCK)
ORDER BY SequenceNumber ASC

--FETCH CHOICE LIST  
--DROP TABLE IF EXISTS #t  

SELECT
	t.SegmentStatusCode
   ,psc.SegmentChoiceCode
   ,CAST(pco.OptionJson AS NVARCHAR(MAX)) AS OptionJson
   ,psc.ChoiceTypeId
   ,pco.ChoiceOptionCode
   ,pco.SortOrder
   ,CAST(0 AS BIT) AS IsSelected INTO #t
FROM ProjectSegmentChoice psc WITH (NOLOCK)
INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
	ON psc.SegmentChoiceId = pco.SegmentChoiceId
		AND pco.ProjectId = @PProjectId
		AND pco.SectionId = @PSectionId
INNER JOIN #ResultTable t
	ON t.mSegmentId = psc.SegmentId
WHERE psc.ProjectId = @PProjectId
AND psc.CustomerId = @PCustomerId
AND psc.SectionId = @PSectionId;


INSERT INTO #t
	SELECT
		t.SegmentStatusCode
	   ,sc.SegmentChoiceCode
	   ,CAST(co.OptionJson AS NVARCHAR(MAX)) AS OptionJson
	   ,sc.ChoiceTypeId
	   ,co.ChoiceOptionCode
	   ,co.SortOrder
	   ,CAST(0 AS BIT) AS IsSelected
	FROM SLCMaster..SegmentChoice sc WITH (NOLOCK)
	INNER JOIN SLCMaster..ChoiceOption co WITH (NOLOCK)
		ON sc.SegmentChoiceId = co.SegmentChoiceId
	INNER JOIN #ResultTable t
		ON t.mSegmentId = sc.SegmentId;

INSERT INTO #t
	SELECT
		t.SegmentStatusCode
	   ,psc.SegmentChoiceCode
	   ,CAST(pco.OptionJson AS NVARCHAR(MAX)) AS OptionJson
	   ,psc.ChoiceTypeId
	   ,pco.ChoiceOptionCode
	   ,pco.SortOrder
	   ,CAST(0 AS BIT) AS IsSelected
	FROM #ResultTable t
	INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
		ON t.SegmentStatusId = psc.SegmentStatusId
	INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
		ON psc.SegmentChoiceId = pco.SegmentChoiceId
			AND pco.ProjectId = @PProjectId
			AND pco.SectionId = @PSectionId
	WHERE psc.ProjectId = @PProjectId
	AND psc.CustomerId = @PCustomerId
	AND psc.SectionId = @PSectionId
	AND ISNULL(pco.IsDeleted, 0) = 0;

SELECT	* FROM #t;

--UPDATE t
--SET t.IsSelected = sco.IsSelected
--FROM #t t
--INNER JOIN SelectedChoiceOption sco WITH (NOLOCK)
--	ON t.ChoiceOptionCode = sco.ChoiceOptionCode
--WHERE sco.SectionId = @SectionId
--AND ISNULL(sco.IsDeleted, 0) = 0
--AND sco.IsSelected = 1

--SELECT  
-- RT.SegmentStatusCode  
--   ,SCHV.SegmentChoiceCode  
--   ,SCHV.ChoiceOptionCode  
--   ,SCHV.SortOrder  
--   ,SCHV.IsSelected  
--   ,SCHV.OptionJson  
--   ,SCHV.ChoiceTypeId  
--FROM SegmentChoiceView SCHV WITH (NOLOCK)  
--INNER JOIN #ResultTable RT WITH (NOLOCK)  
-- ON SCHV.SegmentStatusId = RT.SegmentStatusId  
--WHERE SCHV.ProjectId = @PProjectId  
--AND SCHV.CustomerId = @PCustomerId  
--AND SCHV.SectionId = @PSectionId  
--AND SCHV.IsSelected = 1  

----Fetch SECTION LIST  
--SELECT
--	PS.SectionCode
--   ,PS.SourceTag
--   ,PS.[Description] AS Description
--FROM ProjectSection PS WITH (NOLOCK)
--WHERE PS.ProjectId = @PProjectId
--AND PS.CustomerId = @PCustomerId
--AND PS.IsLastLevel = 1
--UNION
--SELECT
--	MS.SectionCode
--   ,MS.SourceTag
--   ,CAST(MS.Description AS NVARCHAR(500)) AS Description
--FROM SLCMaster..Section MS WITH (NOLOCK)
--LEFT JOIN ProjectSection PS WITH (NOLOCK)
--	ON PS.ProjectId = @PProjectId
--		AND PS.CustomerId = @PCustomerId
--		AND PS.mSectionId = MS.SectionId
--WHERE MS.MasterDataTypeId = @PMasterDataTypeId
--AND MS.IsLastLevel = 1
--AND PS.SectionId IS NULL
END
GO
PRINT N'Altering [dbo].[usp_SpecDataActivateDeactivateMappedSegment]...';


GO
ALTER   procedure [dbo].[usp_SpecDataActivateDeactivateMappedSegment]
(
   @SegmentStatusJson NVARCHAR(max)
)
AS
BEGIN
DECLARE @TempMappingtable TABLE (
ProjectId INT
,CustomerId INT
,SectionId INT
,SegmentStatusId INT
,ActionTypeId INT
,RowId INT
)

INSERT INTO @TempMappingtable
SELECT
*
,ROW_NUMBER() OVER (ORDER BY SegmentStatusId ASC) AS RowId
FROM OPENJSON(@SegmentStatusJson)
WITH (
ProjectId INT '$.ProjectId',
CustomerId INT '$.CustomerId',
SectionId INT '$.SectionId',
SegmentStatusId INT '$.SegmentStatusId',
ActionTypeId INT '$.ActionTypeId'
);

DECLARE @RowCount INT = (SELECT
COUNT(SectionId)
FROM @TempMappingtable);

DECLARE @n INT = 1;

DECLARE @SegmentTempTable TABLE (
SegmentStatusId INT
,SectionId INT
,ParentSegmentStatusId INT
,mSegmentStatusId INT
,mSegmentId INT
,IndentLevel INT
,ProjectId INT
,SegmentId INT
,CustomerId INT
)

DECLARE @SegmentStatusId INT = 0;
DECLARE @SectionId INT = 0;
DECLARE @ProjectId INT = 0;
DECLARE @ActionTypeId INT = 0;

WHILE (@RowCount >= @n)
BEGIN

DELETE FROM @SegmentTempTable

SET @SegmentStatusId = 0;
SET @SectionId = 0;
SET @ProjectId = 0;
SET @ActionTypeId = 0;

SELECT
@SegmentStatusId = pss.SegmentStatusId
,@SectionId = pss.SectionId
,@ProjectId = pss.ProjectId
,@ActionTypeId = TMTBL.ActionTypeId
FROM @TempMappingtable TMTBL
INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
ON pss.ProjectId = TMTBL.ProjectId
AND pss.mSegmentStatusId = TMTBL.SegmentStatusId
AND pss.CustomerId = TMTBL.CustomerId
WHERE RowId = @n

PRINT @ActionTypeId

IF (@ActionTypeId <> 2)

BEGIN
;
WITH cte
AS
(SELECT
a.SegmentStatusId
,a.SectionId
,a.ParentSegmentStatusId
,a.mSegmentStatusId
,a.mSegmentId
,a.IndentLevel
,a.ProjectId
,a.SegmentId
,a.CustomerId
FROM ProjectSegmentStatus a WITH (NOLOCK)
WHERE a.SegmentStatusId = @SegmentStatusId
AND ISNULL(a.IsDeleted, 0) = 0
UNION ALL
SELECT
s.SegmentStatusId
,s.SectionId
,s.ParentSegmentStatusId
,s.mSegmentStatusId
,s.mSegmentId
,s.IndentLevel
,s.ProjectId
,s.SegmentId
,c.CustomerId

FROM ProjectSegmentStatus s WITH (NOLOCK)
JOIN cte c
ON s.SegmentStatusId = c.ParentSegmentStatusId
AND ISNULL(s.IsDeleted, 0) = 0
--AND s.IndentLevel > 0
--AND c.IndentLevel > 0
)

INSERT INTO @SegmentTempTable (SegmentStatusId
, SectionId
, ParentSegmentStatusId
, mSegmentStatusId
, mSegmentId
, IndentLevel
, ProjectId
, SegmentId
, CustomerId)
SELECT
ss.SegmentStatusId
,ss.SectionId
,ss.ParentSegmentStatusId
,ss.mSegmentStatusId
,ss.mSegmentId
,ss.IndentLevel
,ss.ProjectId
,ss.SegmentId
,ss.CustomerId

FROM ProjectSegmentStatus ss WITH (NOLOCK)
WHERE ss.SegmentStatusId = @SegmentStatusId
UNION
SELECT
C.SegmentStatusId
,C.SectionId
,C.ParentSegmentStatusId
,C.mSegmentStatusId
,C.mSegmentId
,C.IndentLevel
,C.ProjectId
,C.SegmentId
,C.CustomerId
FROM cte C

UPDATE pss
SET pss.IsParentSegmentStatusActive = 1
,SegmentStatusTypeId = 2
,SpecTypeTagId = 2
FROM ProjectSegmentStatus pss WITH (NOLOCK)
INNER JOIN @SegmentTempTable STT
ON STT.SegmentStatusId = pss.SegmentStatusId
AND ISNULL(pss.IsDeleted, 0) = 0

END
ELSE
BEGIN

UPDATE pss
SET pss.IsParentSegmentStatusActive = 0
,SegmentStatusTypeId = 6
,SpecTypeTagId = NULL
FROM ProjectSegmentStatus pss WITH (NOLOCK)
WHERE pss.SegmentStatusId = @SegmentStatusId
AND ISNULL(pss.IsDeleted, 0) = 0
END

SET @n = @n + 1;
END

END
GO
PRINT N'Altering [dbo].[usp_SpecDataSetSegmentChoiceOption]...';


GO
ALTER procedure [dbo].[usp_SpecDataSetSegmentChoiceOption]
(
   @SegmentStatusJson NVARCHAR(max)
)
AS
BEGIN

DECLARE @TempMappingtable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson nvarchar(MAX)
   ,RowId INT
)

INSERT INTO @TempMappingtable
	SELECT
		*
	   ,ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId
	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentChoiceId INT '$.SegmentChoiceId',
	ChoiceOptionId INT '$.ChoiceOptionId'
	, SegmentStatusId INT '$.SegmentStatusId'
	, OptionJson NVARCHAR(MAX) '$.OptionJson'
	);

DECLARE @CustomerId INT = 0;
DECLARE @ProjectId INT = 0;

SELECT TOP 1
	@CustomerId = CustomerId
   ,@ProjectId = ProjectId
FROM @TempMappingtable

DECLARE @SingleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @SingleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId,
ChoiceOptionId, SegmentStatusId, OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
	FROM SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)
	INNER JOIN @TempMappingtable TMT
		ON slcmsc.SectionId = TMT.SectionId
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
			AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode
			AND slcmsc.ChoiceTypeId = 1

DECLARE @SingleSelectionFinalChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @SingleSelectionFinalChoiceTable
	SELECT
		ProjectId
	   ,CustomerId
	   ,SectionId
	   ,SegmentChoiceId
	   ,ChoiceOptionId
	   ,SegmentStatusId
	   ,OptionJson
	FROM (SELECT
			*
		   ,ROW_NUMBER() OVER (PARTITION BY SegmentChoiceId ORDER BY ChoiceOptionId DESC) AS RowNo
		FROM @SingleSelectionChoiceTable) AS X
	WHERE X.RowNo = 1

DECLARE @MultipleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @MultipleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId,
ChoiceOptionId, SegmentStatusId, OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
	FROM SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)
	INNER JOIN @TempMappingtable TMT
		ON slcmsc.SectionId = TMT.SectionId
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
			AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode
			AND slcmsc.ChoiceTypeId > 1

DROP TABLE IF EXISTS #ChoiceTempTable

SELECT DISTINCT
	SCO.SelectedChoiceOptionId
   ,SCO.SegmentChoiceCode
   ,SCO.ChoiceOptionCode
   ,SCO.ProjectId
   ,SCO.CustomerId
   ,SCO.SectionId
   ,0 AS IsSelected
   ,SCO.OptionJson
   ,TMTBL.SectionId AS mSectionId INTO #ChoiceTempTable
FROM @TempMappingtable TMTBL 
INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)
	ON SCO.ProjectId = TMTBL.ProjectId
		AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
		AND SCO.CustomerId = TMTBL.CustomerId
		AND SCO.ChoiceOptionSource = 'M'
WHERE SCO.ProjectId = @ProjectId
AND SCO.CustomerId = @CustomerId



IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @SingleSelectionChoiceTable)
	> 0)
BEGIN

UPDATE SCO
SET SCO.IsSelected = 1
   ,SCO.OptionJson = IIF(TMTBL.OptionJson = '', NULL, TMTBL.OptionJson)
FROM #ChoiceTempTable SCO
INNER JOIN @SingleSelectionFinalChoiceTable TMTBL
	ON TMTBL.SectionId = SCO.mSectionId
	AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId

END

IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @MultipleSelectionChoiceTable)
	> 0)
BEGIN
UPDATE SCO
SET SCO.IsSelected = 1
   ,SCO.OptionJson = IIF(TMTBL.OptionJson = '', NULL, TMTBL.OptionJson)
FROM #ChoiceTempTable SCO WITH (NOLOCK)
INNER JOIN @MultipleSelectionChoiceTable TMTBL
	ON TMTBL.SectionId = SCO.mSectionId
	AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId

END

UPDATE SCO
SET SCO.IsSelected = CHT.IsSelected
   ,SCO.OptionJson = CHT.OptionJson
FROM #ChoiceTempTable CHT
INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)
	ON SCO.SelectedChoiceOptionId = CHT.SelectedChoiceOptionId
WHERE SCO.ProjectId = @ProjectId
AND SCO.CustomerId = @CustomerId

END
GO
PRINT N'Altering [dbo].[usp_UpdateCopyProjectStepProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_UpdateCopyProjectStepProgress]
AS
BEGIN

   	--find and mark as failed copy project requests which running loner(more than 30 mins)
	SELECT cpr.RequestId into #longRunningRequests
	FROM dbo.CopyProjectRequest cpr WITH(nolock) 
	INNER JOIN dbo.CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 
	and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2

	IF(EXISTS(select top 1 1 from #longRunningRequests))
	BEGIN
		UPDATE cpr
		SET cpr.StatusId=5
			,cpr.IsNotify=0
			,cpr.IsEmailSent=0
			,cpr.ModifiedDate=GETUTCDATE()
		FROM dbo.CopyProjectRequest cpr WITH(nolock) 
		INNER JOIN #longRunningRequests cph WITH(NOLOCK)
		ON cpr.RequestId=cph.RequestId
	END
END;
GO
PRINT N'Altering [dbo].[usp_CreateSectionFromMasterTemplate_Job]...';


GO
ALTER PROCEDURE [usp_CreateSectionFromMasterTemplate_Job] 
 @RequestId INT              
AS  
BEGIN
	DECLARE @PProjectId INT;
	DECLARE @PCustomerId INT;
	DECLARE @PUserId INT;
	DECLARE @PUserName NVARCHAR(MAX);

	--DECLARE VARIABLES
	DECLARE @TemplateMasterSectionId INT = 0;
	DECLARE @TemplateSectionCode INT = 0;
	DECLARE @TargetSectionCode INT = 0;

	DECLARE @TemplateSectionId INT = 0;
	DECLARE @TargetSectionId INT = 0;
               
	DECLARE @IsTemplateMasterSectionOpened BIT = 0;
        
	DECLARE @IsCompleted BIT =1;        
	DECLARE @ImportStart_Description NVARCHAR(100) = 'Import Started';  
	DECLARE @ImportNoMasterTemplateFound_Description NVARCHAR(100)='No Master Template Found';              
	DECLARE @ImportSectionAlreadyExists_Description NVARCHAR(100)='Section Already Exists';              
	DECLARE @ImportSectionIdInvalid_Description NVARCHAR(100)='SectionId is Invalid';              
	DECLARE @NoAccessRights_Description NVARCHAR(100)='You dont have access rights to import section';              
	DECLARE @ImportProjectSection_Description NVARCHAR(100) = 'Import Project Section Imported';               
	DECLARE @ImportProjectSegment_Description NVARCHAR(100) = 'Project Segment Imported';
	DECLARE @ImportProjectSegmentStatus_Description NVARCHAR(100) = 'Project Segment Status Imported';  
	DECLARE @ImportProjectSegmentChoice_Description NVARCHAR(100)='Project Segment Choice Imported';              
	DECLARE @ImportProjectChoiceOption_Description NVARCHAR(100) = 'Project Choice Option Imported';          
	DECLARE @ImportSelectedChoiceOption_Description NVARCHAR(100) = 'Selected Choice Option Imported';               
	DECLARE @ImportProjectDisciplineSection_Description NVARCHAR(100) = 'Project Discipline Section Imported';               
	DECLARE @ImportProjectNote_Description NVARCHAR(100) = 'Project Note Imported';            
	DECLARE @ImportProjectSegmentLink_Description NVARCHAR(100) = 'Project Segment Link Imported';               
	DECLARE @ImportProjectSegmentRequirementTag_Description NVARCHAR(100) = 'Project SegmentRequirement Tag';              
	DECLARE @ImportProjectSegmentUserTag_Description NVARCHAR(100) = 'Project Segment User Tag Imported';
	DECLARE @ImportProjectSegmentGlobalTerm_Description NVARCHAR(100) = 'Project Segment Global Term Imported';  
	DECLARE @ImportProjectSegmentImage_Description NVARCHAR(100) = 'Project Segment Image Imported';
	DECLARE @ImportProjectHyperLink_Description NVARCHAR(100) = 'Project HyperLink Imported';
	DECLARE @ImportProjectNoteImage_Description NVARCHAR(100) = 'Project Note Image Imported';              
	DECLARE @ImportProjectSegmentReferenceStandard_Description NVARCHAR(100) = 'Project Segment Reference Standard Imported';               
	DECLARE @ImportHeader_Description NVARCHAR(100) = 'Header Imported';    
	DECLARE @ImportFooter_Description NVARCHAR(100) = 'Footer Imported';        
	DECLARE @ImportProjectReferenceStandard_Description NVARCHAR(100) = 'Project Reference Standard Imported';               
	DECLARE @ImportComplete_Description NVARCHAR(100) = 'Import Completed';  
	DECLARE @ImportFailed_Description NVARCHAR(100) = 'IMPORT FAILED'; 
              

	DECLARE @ImportStart_Percentage TINYINT = 5; 
	DECLARE @ImportProjectSection_Percentage TINYINT = 10;               
	DECLARE @ImportProjectSegment_Percentage TINYINT = 15;
	DECLARE @ImportProjectSegmentStatus_Percentage TINYINT = 20;
	DECLARE @ImportProjectSegmentChoice_Percentage TINYINT = 25;              
	DECLARE @ImportProjectChoiceOption_Percentage TINYINT = 30;         
	DECLARE @ImportSelectedChoiceOption_Percentage TINYINT = 35;               
	DECLARE @ImportProjectDisciplineSection_Percentage TINYINT = 40;               
	DECLARE @ImportProjectNote_Percentage TINYINT = 45;              
	DECLARE @ImportProjectSegmentLink_Percentage TINYINT = 50;              
	DECLARE @ImportProjectSegmentRequirementTag_Percentage TINYINT = 55;              
	DECLARE @ImportProjectSegmentUserTag_Percentage TINYINT = 60;              
	DECLARE @ImportProjectSegmentGlobalTerm_Percentage TINYINT = 65;  
	DECLARE @ImportProjectSegmentImage_Percentage TINYINT = 70;
	DECLARE @ImportProjectHyperLink_Percentage TINYINT = 75;              
	DECLARE @ImportProjectNoteImage_Percentage TINYINT = 80;              
	DECLARE @ImportProjectSegmentReferenceStandard_Percentage TINYINT = 85;               
	DECLARE @ImportHeader_Percentage TINYINT = 90;
	DECLARE @ImportFooter_Percentage TINYINT = 95;               
	DECLARE @ImportProjectReferenceStandard_Percentage TINYINT = 97;              
	DECLARE @ImportNoMasterTemplateFound_Percentage TINYINT = 100;  
	DECLARE @ImportSectionAlreadyExists_Percentage TINYINT = 100;  
	DECLARE @ImportSectionidInvalid_Percentage TINYINT = 100;              
	DECLARE @NoAccessRights_Percentage TINYINT = 100;
	DECLARE @ImportComplete_Percentage TINYINT = 100;  
	DECLARE @ImportFailed_Percentage TINYINT = 100;
    
	DECLARE @ImportStart_Step TINYINT = 1;  
	DECLARE @ImportNoMasterTemplateFound_Step TINYINT = 2; 
	DECLARE @ImportSectionAlreadyExists_Step TINYINT = 3;
	DECLARE @ImportSectionIdInvalid_Step TINYINT = 4;
	DECLARE @NoAccessRights_Step TINYINT = 5;              
	DECLARE @ImportProjectSection_Step TINYINT = 6;              
	DECLARE @ImportProjectSegment_Step TINYINT = 7;  
	DECLARE @ImportProjectSegmentChoice_Step TINYINT = 8;
	DECLARE @ImportProjectChoiceOption_Step TINYINT = 9;
	DECLARE @ImportSelectedChoiceOption_Step TINYINT = 10;
	DECLARE @ImportProjectDisciplineSection_Step TINYINT = 11;               
	DECLARE @ImportProjectNote_Step TINYINT = 12;              
	DECLARE @ImportProjectSegmentLink_Step TINYINT = 13;              
	DECLARE @ImportProjectSegmentRequirementTag_Step TINYINT = 14;              
	DECLARE @ImportProjectSegmentUserTag_Step TINYINT = 15;              
	DECLARE @ImportProjectSegmentGlobalTerm_Step TINYINT = 16;               
	DECLARE @ImportProjectSegmentImage_Step TINYINT = 17;              
	DECLARE @ImportProjectHyperLink_Step TINYINT = 18;              
	DECLARE @ImportProjectNoteImage_Step TINYINT = 19;              
	DECLARE @ImportProjectSegmentReferenceStandard_Step TINYINT = 20;              
	DECLARE @ImportHeader_Step TINYINT = 21;              
	DECLARE @ImportFooter_Step TINYINT = 22;              
	DECLARE @ImportProjectReferenceStandard_Step TINYINT = 23;             
	DECLARE @ImportProjectSegmentStatus_Step TINYINT = 24;               
	DECLARE @ImportComplete_Step TINYINT = 25; 
	DECLARE @ImportFailed_Step TINYINT = 25;             
        
	DECLARE @ImportPending TINYINT =1;        
	DECLARE @ImportStarted TINYINT =2;        
	DECLARE @ImportCompleted TINYINT =3;        
	DECLARE @Importfailed TINYINT =4    
	DECLARE @ImportSource nvarchar(1)=''     
	--TEMP TABLES
	DROP TABLE IF EXISTS #tmp_SrcProjectSegmentStatus;
	DROP TABLE IF EXISTS #tmp_TgtProjectSegmentStatus;
	DROP TABLE IF EXISTS #tmp_SrcMasterNote;
	DROP TABLE IF EXISTS #tmp_TgtProjectNote;
	DROP TABLE IF EXISTS #tmp_SrcProjectSegment;

BEGIN TRY
--BEGIN TRANSACTION               
	
	SELECT top 1 
	@TemplateSectionId=SourceSectionId,
	@TargetSectionId=TargetSectionId,
	@PProjectId=SourceProjectId,
	@PCustomerId=CustomerId,
	@PUserId=CreatedById
	from ImportProjectRequest with(NOLOCK)
	where RequestId=@RequestId

	SELECT top 1
	@TargetSectionCode=SectionCode
	from ProjectSection WITH(NOLOCK)
	where SectionId=@TargetSectionId
	and ProjectId=@PProjectId

	SELECT top 1
	@TemplateSectionCode=SectionCode,
	@TemplateMasterSectionId=mSectionId
	from ProjectSection WITH(NOLOCK)
	where SectionId=@TemplateSectionId
	and ProjectId=@PProjectId

--CHECK WHETHER MASTER TEMPLATE SECTION IS OPENED OR NOT
IF EXISTS (SELECT TOP 1
  1
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN ProjectSection PS WITH (NOLOCK)
  ON PSST.SectionId = PS.SectionId        
  AND PSST.ProjectId = PS.ProjectId          
 WHERE PSST.ProjectId = @PProjectId
 AND PS.mSectionId = @TemplateMasterSectionId
 --AND PS.CustomerId = @CustomerId  
 AND PSST.SequenceNumber = 0
 AND PSST.IndentLevel = 0)
BEGIN
SET @IsTemplateMasterSectionOpened = 1;
END


--CALCULATE DIVISION ID AND CODE
EXEC usp_SetDivisionIdForUserSection @PProjectId
         ,@TargetSectionId
         ,@PCustomerId;

--Fetch Src ProjectSegmentStatus data into temp table
SELECT
 * INTO #tmp_SrcProjectSegmentStatus
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PProjectId
AND PSST.SectionId = @TemplateSectionId

--Fetch Src ProjectSegment data into temp table
SELECT
 * INTO #tmp_SrcProjectSegment
FROM ProjectSegment PSG WITH (NOLOCK)
WHERE PSG.ProjectId = @PProjectId
AND PSG.SectionId = @TemplateSectionId

--INSERT INTO ProjectSegment
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId,
SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
 SELECT
  NULL AS SegmentStatusId
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,MSG_Template.SegmentDescription AS SegmentDescription
    ,'U' AS SegmentSource
    ,MSG_Template.SegmentCode AS SegmentCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM SLCMaster..SegmentStatus MSST_Template WITH (NOLOCK)
 INNER JOIN SLCMaster..Segment MSG_Template WITH (NOLOCK)
  ON MSST_Template.SegmentId = MSG_Template.SegmentId
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  NULL AS SegmentStatusId
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,(CASE
   WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentDescription
   ELSE PSST_Template_MSG.SegmentDescription
  END) AS SegmentDescription
    ,'U' AS SegmentSource
    ,(CASE
   WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentCode
   ELSE PSST_Template_MSG.SegmentCode
  END) AS SegmentCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
 LEFT JOIN #tmp_SrcProjectSegment PSST_Template_PSG WITH (NOLOCK)          
  ON PSST_Template.SegmentId = PSST_Template_PSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'U'
 LEFT JOIN SLCMaster..Segment PSST_Template_MSG WITH (NOLOCK)
  ON PSST_Template.mSegmentId = PSST_Template_MSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'M'
 WHERE PSST_Template.SectionId = @TemplateSectionId
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0
 AND (PSST_Template_PSG.SegmentId IS NOT NULL
 OR PSST_Template_MSG.SegmentId IS NOT NULL)
 AND @IsTemplateMasterSectionOpened = 1
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
        ,@ImportProjectSegment_Description            
           ,@ImportProjectSegment_Description            
           ,@IsCompleted            
           ,@ImportProjectSegment_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted        
         ,@ImportProjectSegment_Percentage --Percent            
         , 0
    ,@ImportSource             
         , @RequestId;               

--INSERT INTO ProjectSegmentStatus
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource,
SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId,
IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber,
IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,
IsPageBreak, IsDeleted)
 SELECT
  @TargetSectionId AS SectionId
    ,0 AS ParentSegmentStatusId
    ,MSST_Template.SegmentStatusId AS mSegmentStatusId
    ,MSST_Template.SegmentId AS mSegmentId
    ,PSG.SegmentId AS SegmentId
    ,'U' AS SegmentSource
    ,'U' AS SegmentOrigin
    ,MSST_Template.IndentLevel AS IndentLevel
    ,MSST_Template.SequenceNumber AS SequenceNumber
    ,(CASE
   WHEN MSST_Template.SpecTypeTagId = 1 THEN 4
   WHEN MSST_Template.SpecTypeTagId = 2 THEN 3
   ELSE MSST_Template.SpecTypeTagId
  END) AS SpecTypeTagId
    ,MSST_Template.SegmentStatusTypeId AS SegmentStatusTypeId
    ,MSST_Template.IsParentSegmentStatusActive AS IsParentSegmentStatusActive
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,MSST_Template.SegmentStatusCode AS SegmentStatusCode
    ,MSST_Template.IsShowAutoNumber AS IsShowAutoNumber
    ,MSST_Template.IsRefStdParagraph AS IsRefStdParagraph
    ,MSST_Template.FormattingJson AS FormattingJson
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
    ,0 AS IsPageBreak
    ,MSST_Template.IsDeleted AS IsDeleted
 FROM SLCMaster..SegmentStatus MSST_Template WITH (NOLOCK)
 INNER JOIN SLCMaster..Segment MSG_Template WITH (NOLOCK)
  ON MSST_Template.SegmentId = MSG_Template.SegmentId
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON MSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,0 AS ParentSegmentStatusId
    ,PSST_Template.mSegmentStatusId AS mSegmentStatusId
    ,PSST_Template.mSegmentId AS mSegmentId
    ,PSG.SegmentId AS SegmentId
    ,'U' AS SegmentSource
    ,'U' AS SegmentOrigin
    ,PSST_Template.IndentLevel AS IndentLevel
    ,PSST_Template.SequenceNumber AS SequenceNumber
    ,(CASE
   WHEN PSST_Template.SpecTypeTagId = 1 THEN 4
   WHEN PSST_Template.SpecTypeTagId = 2 THEN 3
   ELSE PSST_Template.SpecTypeTagId
  END) AS SpecTypeTagId
    ,PSST_Template.SegmentStatusTypeId AS SegmentStatusTypeId
    ,PSST_Template.IsParentSegmentStatusActive AS IsParentSegmentStatusActive
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PSST_Template.SegmentStatusCode AS SegmentStatusCode
    ,PSST_Template.IsShowAutoNumber AS IsShowAutoNumber
    ,PSST_Template.IsRefStdParagraph AS IsRefStdParagraph
    ,PSST_Template.FormattingJson AS FormattingJson
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
    ,0 AS IsPageBreak
    ,PSST_Template.IsDeleted AS IsDeleted
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
 LEFT JOIN #tmp_SrcProjectSegment PSST_Template_PSG WITH (NOLOCK)
  ON PSST_Template.SegmentId = PSST_Template_PSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'U'
 LEFT JOIN SLCMaster..Segment PSST_Template_MSG WITH (NOLOCK)
  ON PSST_Template.mSegmentId = PSST_Template_MSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'M'
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON (CASE
    WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentCode
    ELSE PSST_Template_MSG.SegmentCode
   END) = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE PSST_Template.SectionId = @TemplateSectionId
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0
 AND (PSST_Template_PSG.SegmentId IS NOT NULL
 OR PSST_Template_MSG.SegmentId IS NOT NULL)
 AND @IsTemplateMasterSectionOpened = 1
              
              

--Insert target segment status into temp table of new section
SELECT
 * INTO #tmp_TgtProjectSegmentStatus
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SectionId = @TargetSectionId

--UPDATE TEMP TABLE ProjectSegmentStatus
UPDATE PSST_Child
SET PSST_Child.ParentSegmentStatusId = PSST_Parent.SegmentStatusId
FROM #tmp_TgtProjectSegmentStatus PSST_Child WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentStatus MSST_Template_Child WITH (NOLOCK)
 ON PSST_Child.SegmentStatusCode = MSST_Template_Child.SegmentStatusCode
INNER JOIN SLCMaster..SegmentStatus MSST_Template_Parent WITH (NOLOCK)
 ON MSST_Template_Child.ParentSegmentStatusId = MSST_Template_Parent.SegmentStatusId
INNER JOIN #tmp_TgtProjectSegmentStatus PSST_Parent WITH (NOLOCK)
 ON MSST_Template_Parent.SegmentStatusCode = PSST_Parent.SegmentStatusCode
WHERE PSST_Child.SectionId = @TargetSectionId
AND PSST_Parent.SectionId = @TargetSectionId
AND MSST_Template_Child.SectionId = @TemplateMasterSectionId
AND @IsTemplateMasterSectionOpened = 0

UPDATE PSST_Child
SET PSST_Child.ParentSegmentStatusId = PSST_Parent.SegmentStatusId
FROM #tmp_TgtProjectSegmentStatus PSST_Child WITH (NOLOCK)
INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template_Child WITH (NOLOCK)
 ON PSST_Child.SegmentStatusCode = PSST_Template_Child.SegmentStatusCode
 AND PSST_Template_Child.SectionId = @TemplateSectionId
INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template_Parent WITH (NOLOCK)
 ON PSST_Template_Child.ParentSegmentStatusId = PSST_Template_Parent.SegmentStatusId
 AND PSST_Template_Parent.SectionId = @TemplateSectionId
INNER JOIN #tmp_TgtProjectSegmentStatus PSST_Parent WITH (NOLOCK)
 ON PSST_Template_Parent.SegmentStatusCode = PSST_Parent.SegmentStatusCode
WHERE PSST_Child.SectionId = @TargetSectionId
AND PSST_Parent.SectionId = @TargetSectionId
AND @IsTemplateMasterSectionOpened = 1

--UPDATE IN ORIGINAL TABLE
UPDATE PSST
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN #tmp_TgtProjectSegmentStatus TMP WITH (NOLOCK)
 ON PSST.SegmentStatusId = TMP.SegmentStatusId
WHERE PSST.SectionId = @TargetSectionId

--UPDATE ProjectSegment
UPDATE PSG
SET PSG.SegmentStatusId = PSST.SegmentStatusId       
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
 ON PSST.SegmentId = PSG.SegmentId
WHERE PSST.SectionId = @TargetSectionId

UPDATE PSG
SET PSG.SegmentDescription = PS.Description
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
 ON PSST.SegmentId = PSG.SegmentId
INNER JOIN ProjectSection PS WITH (NOLOCK)
 ON PSST.SectionId = PS.SectionId
WHERE PSST.SectionId = @TargetSectionId
AND PSST.SequenceNumber = 0
AND PSST.IndentLevel = 0

--INSERT INTO ProjectSegmentChoice
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId,
CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSST.SegmentId AS SegmentId
    ,MCH_Template.ChoiceTypeId AS ChoiceTypeId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'U' AS SegmentChoiceSource
    ,MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 WHERE PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSST.SegmentId AS SegmentId
    ,MCH_Template.ChoiceTypeId AS ChoiceTypeId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'U' AS SegmentChoiceSource
    ,MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'M'
 AND @IsTemplateMasterSectionOpened = 1
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSST.SegmentId AS SegmentId
    ,PCH_Template.ChoiceTypeId AS ChoiceTypeId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'U' AS SegmentChoiceSource
    ,PCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)
  ON PSST_Template.SegmentId = PCH_Template.SegmentId
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'U'
 AND @IsTemplateMasterSectionOpened = 1
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentChoice_Description            
           ,@ImportProjectSegmentChoice_Description            
           ,@IsCompleted            
           ,@ImportProjectSegmentChoice_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted         
         ,@ImportProjectSegmentChoice_Percentage --Percent            
         , 0
    ,@ImportSource           
         , @RequestId;               

--INSERT INTO ProjectChoiceOption
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson,
ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
 SELECT
  PCH.SegmentChoiceId AS SegmentChoiceId      ,MCHOP_Template.SortOrder AS SortOrder
    ,'U' AS ChoiceOptionSource
    ,MCHOP_Template.OptionJson AS OptionJson
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
  ON PSST.SegmentId = PCH.SegmentId
   AND MCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode
 WHERE PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  PCH.SegmentChoiceId AS SegmentChoiceId
    ,MCHOP_Template.SortOrder AS SortOrder
    ,'U' AS ChoiceOptionSource
    ,MCHOP_Template.OptionJson AS OptionJson
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
  ON PSST.SegmentId = PCH.SegmentId
   AND MCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'M'
 AND @IsTemplateMasterSectionOpened = 1
 UNION
 SELECT
  PCH.SegmentChoiceId AS SegmentChoiceId
    ,PCHOP_Template.SortOrder AS SortOrder
    ,'U' AS ChoiceOptionSource
    ,PCHOP_Template.OptionJson AS OptionJson
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)
  ON PSST_Template.SegmentId = PCH_Template.SegmentId
 INNER JOIN ProjectChoiceOption PCHOP_Template WITH (NOLOCK)
  ON PCH_Template.SegmentChoiceId = PCHOP_Template.SegmentChoiceId
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
  ON PSST.SegmentId = PCH.SegmentId
   AND PCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'U'
 AND @IsTemplateMasterSectionOpened = 1
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectChoiceOption_Description            
           ,@ImportProjectChoiceOption_Description            
           ,@IsCompleted          
           ,@ImportProjectChoiceOption_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted       
         ,@ImportProjectChoiceOption_Percentage --Percent            
         , 0
    ,@ImportSource          
         , @RequestId;               

--INSERT INTO SelectedChoiceOption
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource,
IsSelected, SectionId, ProjectId, CustomerId, OptionJson)
 SELECT
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,'U' AS ChoiceOptionSource
    ,SCHOP_Template.IsSelected AS IsSelected
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,NULL AS OptionJson
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN SLCMaster..SelectedChoiceOption SCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode
   AND MCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode
 WHERE PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,'U' AS ChoiceOptionSource
    ,SCHOP_Template.IsSelected AS IsSelected
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,SCHOP_Template.OptionJson AS OptionJson
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN SelectedChoiceOption SCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode
   AND MCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode
   AND SCHOP_Template.ChoiceOptionSource = 'M'
   AND SCHOP_Template.SectionId = @TemplateSectionId
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'M'
 AND @IsTemplateMasterSectionOpened = 1
 UNION
 SELECT
  PCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,'U' AS ChoiceOptionSource
    ,SCHOP_Template.IsSelected AS IsSelected
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,SCHOP_Template.OptionJson AS OptionJson
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)
  ON PSST_Template.SegmentId = PCH_Template.SegmentId
 INNER JOIN ProjectChoiceOption PCHOP_Template WITH (NOLOCK)
  ON PCH_Template.SegmentChoiceId = PCHOP_Template.SegmentChoiceId
 INNER JOIN SelectedChoiceOption SCHOP_Template WITH (NOLOCK)
  ON PCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode
   AND PCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode
   AND SCHOP_Template.ChoiceOptionSource = 'U'
   AND SCHOP_Template.SectionId = @TemplateSectionId
 WHERE PSST_Template.SectionId = @TemplateSectionId
 AND PSST_Template.SegmentOrigin = 'U'
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportSelectedChoiceOption_Description            
           ,@ImportSelectedChoiceOption_Description            
           ,@IsCompleted          
           ,@ImportSelectedChoiceOption_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null               
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted   
        ,@ImportSelectedChoiceOption_Percentage --Percent            
         , 0
    ,@ImportSource           
         , @RequestId;               

--INSERT INTO ProjectDisciplineSection
INSERT INTO ProjectDisciplineSection (SectionId, Disciplineld, ProjectId, CustomerId, IsActive)
 SELECT
  @TargetSectionId AS SectionId
    ,MDS.DisciplineId AS Disciplineld
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,1 AS IsActive
 FROM SLCMaster..DisciplineSection MDS WITH (NOLOCK)
 INNER JOIN LuProjectDiscipline LPD WITH (NOLOCK)
  ON MDS.DisciplineId = LPD.Disciplineld
 WHERE MDS.SectionId = @TemplateMasterSectionId
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectDisciplineSection_Description            
           ,@ImportProjectDisciplineSection_Description            
           ,@IsCompleted        
           ,@ImportProjectDisciplineSection_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted               
         ,@ImportProjectDisciplineSection_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectNote
INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,      
CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,MNT_Template.NoteText AS NoteText
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'' AS Title
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
  ,@PUserName AS CreatedUserName
    ,@PUserName AS ModifiedUserName
    ,0 AS IsDeleted
    ,MNT_Template.NoteId AS NoteCode
 FROM SLCMaster..Note MNT_Template WITH (NOLOCK)
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId
 WHERE MNT_Template.SectionId = @TemplateMasterSectionId
 AND PSST.SectionId = @TargetSectionId
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PNT_Template.NoteText AS NoteText
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PNT_Template.Title AS Title
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
    ,@PUserName AS CreatedUserName
    ,@PUserName AS ModifiedUserName
    ,0 AS IsDeleted
    ,PNT_Template.NoteCode AS NoteCode
 FROM ProjectNote PNT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PNT_Template.SegmentStatusId = PSST_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode
   AND PSST.SectionId = @TargetSectionId
 WHERE PNT_Template.SectionId = @TemplateSectionId
 AND ISNULL(PNT_Template.IsDeleted, 0) = 0
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectNote_Description            
           ,@ImportProjectNote_Description            
           ,@IsCompleted           
           ,@ImportProjectNote_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted   
         ,@ImportProjectNote_Percentage --Percent            
         , 0
    ,@ImportSource         
         , @RequestId;               

              
--INSERT INTO ProjectSegmentLink
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,
ProjectId, CustomerId, SegmentLinkSourceTypeId)
 SELECT
  (CASE
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN @TargetSectionCode
   ELSE MSLNK.SourceSectionCode
  END) AS SourceSectionCode
    ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
    ,MSLNK.SourceSegmentCode AS SourceSegmentCode
    ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
    ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
    ,(CASE
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN 'U'
   ELSE MSLNK.LinkSource
  END) AS LinkSource
    ,(CASE
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN @TargetSectionCode
   ELSE MSLNK.TargetSectionCode
  END) AS TargetSectionCode
    ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
    ,MSLNK.TargetSegmentCode AS TargetSegmentCode
    ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
    ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
    ,(CASE
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN 'U'
   ELSE MSLNK.LinkTarget
  END) AS LinkTarget
    ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId
    ,MSLNK.IsDeleted AS IsDeleted
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,(CASE
   WHEN MSLNK.SegmentLinkSourceTypeId = 1 THEN 5
   ELSE MSLNK.SegmentLinkSourceTypeId
  END) AS SegmentLinkSourceTypeId
 FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)
 WHERE (MSLNK.SourceSectionCode = @TemplateSectionCode
 OR MSLNK.TargetSectionCode = @TemplateSectionCode)
 AND MSLNK.IsDeleted = 0
 AND @IsTemplateMasterSectionOpened = 0
               

SELECT
   (CASE
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN @TargetSectionCode
    ELSE PSLNK.SourceSectionCode
   END) AS SourceSectionCode
     ,PSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
     ,PSLNK.SourceSegmentCode AS SourceSegmentCode
     ,PSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
     ,PSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
     ,(CASE
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN 'U'
    ELSE PSLNK.LinkSource
   END) AS LinkSource
     ,(CASE
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN @TargetSectionCode
    ELSE PSLNK.TargetSectionCode
   END) AS TargetSectionCode
     ,PSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
     ,PSLNK.TargetSegmentCode AS TargetSegmentCode
     ,PSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
     ,PSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
     ,(CASE
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN 'U'
    ELSE PSLNK.LinkTarget
   END) AS LinkTarget
     ,PSLNK.LinkStatusTypeId AS LinkStatusTypeId
     ,PSLNK.IsDeleted AS IsDeleted
     ,GETUTCDATE() AS CreateDate
     ,@PUserId AS CreatedBy
     ,@PUserId AS ModifiedBy
     ,GETUTCDATE() AS ModifiedDate
     ,@PProjectId AS ProjectId
     ,@PCustomerId AS CustomerId
     ,(CASE
    WHEN PSLNK.SegmentLinkSourceTypeId = 1 THEN 5
    ELSE PSLNK.SegmentLinkSourceTypeId
   END) AS SegmentLinkSourceTypeId
  INTO #X FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
  WHERE PSLNK.ProjectId = @PProjectId
  AND PSLNK.CustomerId = @PCustomerId
  AND (PSLNK.SourceSectionCode = @TemplateSectionCode
  OR PSLNK.TargetSectionCode = @TemplateSectionCode)
  AND PSLNK.IsDeleted = 0
  AND @IsTemplateMasterSectionOpened = 1

INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,
ProjectId, CustomerId, SegmentLinkSourceTypeId)
 SELECT
  X.*
 FROM #x AS X
 LEFT JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
  ON X.SourceSectionCode = PSLNK.SourceSectionCode
   AND X.SourceSegmentStatusCode = PSLNK.SourceSegmentStatusCode
   AND X.SourceSegmentCode = PSLNK.SourceSegmentCode
   AND X.SourceSegmentChoiceCode = PSLNK.SourceSegmentChoiceCode
   AND X.SourceChoiceOptionCode = PSLNK.SourceChoiceOptionCode
   AND X.LinkSource = PSLNK.LinkSource
   AND X.TargetSectionCode = PSLNK.TargetSectionCode
   AND X.TargetSegmentStatusCode = PSLNK.TargetSegmentStatusCode
   AND X.TargetSegmentCode = PSLNK.TargetSegmentCode
   AND X.TargetSegmentChoiceCode = PSLNK.TargetSegmentChoiceCode
   AND X.TargetChoiceOptionCode = PSLNK.TargetChoiceOptionCode
   AND X.LinkTarget = PSLNK.LinkTarget
   AND X.LinkStatusTypeId = PSLNK.LinkStatusTypeId
   AND X.IsDeleted = PSLNK.IsDeleted
   AND X.ProjectId = PSLNK.ProjectId
   AND X.CustomerId = PSLNK.CustomerId
   AND X.SegmentLinkSourceTypeId = PSLNK.SegmentLinkSourceTypeId
 WHERE PSLNK.SegmentLinkId IS NULL
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentLink_Description            
           ,@ImportProjectSegmentLink_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentLink_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null  
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted               
         ,@ImportProjectSegmentLink_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentRequirementTag
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId,
CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,MSRT_Template.RequirementTagId AS RequirementTagId
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
 FROM SLCMaster..SegmentRequirementTag MSRT_Template WITH (NOLOCK)
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON MSRT_Template.SegmentStatusId = PSST.mSegmentStatusId
 WHERE MSRT_Template.SectionId = @TemplateMasterSectionId
 AND PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSRT_Template.RequirementTagId AS RequirementTagId
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
 FROM ProjectSegmentRequirementTag PSRT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSRT_Template.SegmentStatusId = PSST_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode
   AND PSST.SectionId = @TargetSectionId
 WHERE PSRT_Template.SectionId = @TemplateSectionId
 AND @IsTemplateMasterSectionOpened = 1
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentRequirementTag_Description            
           ,@ImportProjectSegmentRequirementTag_Description            
           ,@IsCompleted         
           ,@ImportProjectSegmentRequirementTag_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted        
         ,@ImportProjectSegmentRequirementTag_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentUserTag
INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId,
UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
 SELECT
  @PCustomerId AS CustomerId
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSUT_Template.UserTagId AS UserTagId
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
 FROM ProjectSegmentUserTag PSUT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSUT_Template.SegmentStatusId = PSST_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode
   AND PSST.SectionId = @TargetSectionId
 WHERE PSUT_Template.SectionId = @TemplateSectionId
 AND @IsTemplateMasterSectionOpened = 1

EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentUserTag_Description            
           ,@ImportProjectSegmentUserTag_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentUserTag_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted     
         ,@ImportProjectSegmentUserTag_Percentage --Percent            
         , 0
    ,@ImportSource          
         , @RequestId;               

--INSERT INTO ProjectSegmentGlobalTerm
INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId,
UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)
 SELECT
  @PCustomerId AS CustomerId
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,PSG.SegmentId AS SegmentId
    ,NULL AS mSegmentId
    ,PSGT_Template.UserGlobalTermId AS UserGlobalTermId
    ,PSGT_Template.GlobalTermCode AS GlobalTermCode
    ,PSGT_Template.IsLocked AS IsLocked
    ,PSGT_Template.LockedByFullName AS LockedByFullName
    ,PSGT_Template.UserLockedId AS UserLockedId
    ,GETUTCDATE() AS CreatedDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
 FROM ProjectSegmentGlobalTerm PSGT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)
  ON PSGT_Template.SegmentId = PSG_Template.SegmentId
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON PSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE PSGT_Template.SectionId = @TemplateSectionId
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentGlobalTerm_Description         
           ,@ImportProjectSegmentGlobalTerm_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentGlobalTerm_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted 
         ,@ImportProjectSegmentGlobalTerm_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentImage
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)
 SELECT
  @TargetSectionId AS SectionId
    ,PSI_Template.ImageId AS ImageId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PSG.SegmentId AS SegmentId
	,PSI_Template.ImageStyle
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)
  ON PSI_Template.SegmentId = PSG_Template.SegmentId
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON PSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE PSI_Template.SectionId = @TemplateSectionId
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSI_Template.ImageId AS ImageId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PSI_Template.SegmentId AS SegmentId
	,PSI_Template.ImageStyle
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)
 WHERE PSI_Template.SectionId = @TemplateSectionId
 AND (PSI_Template.SegmentId IS NULL
 OR PSI_Template.SegmentId <= 0)
              
  EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentImage_Description            
           ,@ImportProjectSegmentImage_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentImage_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null      
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted  
         ,@ImportProjectSegmentImage_Percentage --Percent            
         , 0
    ,@ImportSource          
         , @RequestId;               
        --INSERT INTO ProjectHyperLink
--NOTE IMP:For updating proper HyperLinkId in final table, CustomerId used for temp purpose
--TODO:Need to correct ProjectHyperLink table's ModifiedBy Column
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText,
LuHyperLinkSourceTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentId AS SegmentId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,@PProjectId AS ProjectId         
    ,MHL_Template.HyperLinkId AS MasterHyperLinkId
    ,MHL_Template.LinkTarget AS LinkTarget
    ,MHL_Template.LinkText AS LinkText
    ,MHL_Template.LuHyperLinkSourceTypeId AS LuHyperLinkSourceTypeId
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
 FROM SLCMaster..Note MNT_Template WITH (NOLOCK)
 INNER JOIN SLCMaster..HyperLink MHL_Template WITH (NOLOCK)
  ON MNT_Template.SegmentStatusId = MHL_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId
   AND PSST.SectionId = @TargetSectionId
 WHERE MNT_Template.SectionId = @TemplateMasterSectionId
               
--Fetch Src Master notes into temp table
SELECT
 * INTO #tmp_SrcMasterNote
FROM SLCMaster..Note WITH (NOLOCK)
WHERE SectionId = @TemplateMasterSectionId;

--Fetch tgt project notes into temp table
SELECT
 * INTO #tmp_TgtProjectNote
FROM ProjectNote PNT WITH (NOLOCK)
WHERE SectionId = @TargetSectionId;

--UPDATE NEW HyperLinkId IN NoteText
DECLARE @HyperLinkLoopCount INT = 1;
DECLARE @HyperLinkTable TABLE (
 RowId INT
   ,HyperLinkId INT
   ,MasterHyperLinkId INT
);

INSERT INTO @HyperLinkTable (RowId, HyperLinkId, MasterHyperLinkId)
 SELECT
  ROW_NUMBER() OVER (ORDER BY PHL.HyperLinkId ASC) AS RowId       
    ,PHL.HyperLinkId
    ,PHL.CustomerId
 FROM ProjectHyperLink PHL WITH (NOLOCK)
 WHERE PHL.SectionId = @TargetSectionId;

declare @HyperLinkTableRowCount INT=(SELECT  COUNT(*)  FROM @HyperLinkTable)
WHILE (@HyperLinkLoopCount <= @HyperLinkTableRowCount)
BEGIN
DECLARE @HyperLinkId INT = 0;
DECLARE @MasterHyperLinkId INT = 0;

SELECT
 @HyperLinkId = HyperLinkId
   ,@MasterHyperLinkId = MasterHyperLinkId
FROM @HyperLinkTable
WHERE RowId = @HyperLinkLoopCount;

UPDATE PNT
SET PNT.NoteText =
REPLACE(PNT.NoteText, '{HL#' + CAST(@MasterHyperLinkId AS NVARCHAR(MAX)) + '}',
'{HL#' + CAST(@HyperLinkId AS NVARCHAR(MAX)) + '}')
FROM #tmp_SrcMasterNote MNT_Template WITH (NOLOCK)
INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId     
 AND PSST.SectionId = @TargetSectionId
INNER JOIN #tmp_TgtProjectNote PNT WITH (NOLOCK)
 ON PSST.SegmentStatusId = PNT.SegmentStatusId
WHERE MNT_Template.SectionId = @TemplateMasterSectionId

SET @HyperLinkLoopCount = @HyperLinkLoopCount + 1;
END

--Update NoteText back into original table from temp table
UPDATE PNT
SET PNT.NoteText = TMP.NoteText
FROM ProjectNote PNT WITH (NOLOCK)
INNER JOIN #tmp_TgtProjectNote TMP WITH (NOLOCK)
 ON PNT.NoteId = TMP.NoteId
WHERE PNT.SectionId = @TargetSectionId;

--UPDATE PROPER CustomerId IN ProjectHyperLink
UPDATE PHL
SET PHL.CustomerId = @PCustomerId
FROM ProjectHyperLink PHL WITH (NOLOCK)
WHERE PHL.SectionId = @TargetSectionId
              
   EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectHyperLink_Description            
           ,@ImportProjectHyperLink_Description            
           ,@IsCompleted           
           ,@ImportProjectHyperLink_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted    
         ,@ImportProjectHyperLink_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectNoteImage
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)
 SELECT
  PN.NoteId AS NoteId
    ,@TargetSectionId AS SectionId
    ,PNI_Template.ImageId AS ImageId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
 FROM ProjectNoteImage PNI_Template WITH (NOLOCK)
 INNER JOIN ProjectNote PN_Template WITH (NOLOCK)
  ON PNI_Template.NoteId = PN_Template.NoteId
 INNER JOIN ProjectNote PN WITH (NOLOCK)
  ON PN.SectionId = @TargetSectionId
   AND PN_Template.NoteCode = PN.NoteCode
 WHERE PNI_Template.SectionId = @TemplateSectionId     
 
    EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectNoteImage_Description            
           ,@ImportProjectNoteImage_Description            
           ,@IsCompleted          
           ,@ImportProjectNoteImage_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId             
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted               
         ,@ImportProjectNoteImage_Percentage --Percent            
         , 0
   ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentReferenceStandard
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode, IsDeleted)
 SELECT
 DISTINCT
  @TargetSectionId AS SectionId
    ,X.SegmentId
    ,X.RefStandardId
    ,X.RefStandardSource
    ,X.mRefStandardId
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
    ,@PCustomerId AS CustomerId
    ,@PProjectId AS ProjectId
    ,X.mSegmentId
    ,X.RefStdCode
    ,X.IsDeleted
 FROM (SELECT
   PSST.SegmentId AS SegmentId
     ,NULL AS RefStandardId
    ,'M' AS RefStandardSource
     ,MRS_Template.RefStdId AS mRefStandardId
     ,NULL AS mSegmentId
     ,MRS_Template.RefStdCode AS RefStdCode
     ,CAST(0 AS BIT) AS IsDeleted
  FROM SLCMaster..SegmentReferenceStandard MSRS_Template WITH (NOLOCK)
  INNER JOIN SLCMaster..ReferenceStandard MRS_Template WITH (NOLOCK)
 ON MSRS_Template.RefStandardId = MRS_Template.RefStdId
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST
   ON MSRS_Template.SegmentId = PSST.mSegmentId
   AND PSST.SectionId = @TargetSectionId
  WHERE MSRS_Template.SectionId = @TemplateMasterSectionId
  UNION
  SELECT
   PSST.SegmentId AS SegmentId
     ,PSRS_Template.RefStandardId AS RefStandardId
     ,PSRS_Template.RefStandardSource AS RefStandardSource
     ,PSRS_Template.mRefStandardId AS mRefStandardId
     ,NULL AS mSegmentId
     ,PSRS_Template.RefStdCode AS RefStdCode
     ,PSRS_Template.IsDeleted
  FROM ProjectSegmentReferenceStandard PSRS_Template WITH (NOLOCK)
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
   ON PSRS_Template.mSegmentId = PSST.mSegmentId
   AND PSST.SectionId = @TargetSectionId
  WHERE PSRS_Template.SectionId = @TemplateSectionId
  AND PSRS_Template.mSegmentId IS NOT NULL
  AND PSRS_Template.SegmentId IS NULL
  UNION
  SELECT
   PSG.SegmentId AS SegmentId
     ,PSRS_Template.RefStandardId AS RefStandardId
     ,PSRS_Template.RefStandardSource AS RefStandardSource
     ,PSRS_Template.mRefStandardId AS mRefStandardId
     ,NULL AS mSegmentId
     ,PSRS_Template.RefStdCode AS RefStdCode
     ,PSRS_Template.IsDeleted
  FROM ProjectSegmentReferenceStandard PSRS_Template WITH (NOLOCK)
  INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)         
   ON PSRS_Template.SegmentId = PSG_Template.SegmentId
  INNER JOIN ProjectSegment PSG WITH (NOLOCK)
   ON PSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
  WHERE PSRS_Template.SectionId = @TemplateSectionId
  AND PSRS_Template.mSegmentId IS NULL
  AND PSRS_Template.SegmentId IS NOT NULL) AS X
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentReferenceStandard_Description            
           ,@ImportProjectSegmentReferenceStandard_Description            
           ,@IsCompleted          
           ,@ImportProjectSegmentReferenceStandard_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted 
         ,@ImportProjectSegmentReferenceStandard_Percentage --Percent            
         , 0
   ,@ImportSource        
         , @RequestId;               

--INSERT INTO Header
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy,
ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltHeader, FPHeader,
UseSeparateFPHeader, HeaderFooterCategoryId, DateFormat, TimeFormat)
 SELECT
  @PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,Description
    ,NULL AS IsLocked
    ,NULL AS LockedByFullName
    ,NULL AS LockedBy
    ,ShowFirstPage
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreatedDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
    ,TypeId
    ,AltHeader
    ,FPHeader
    ,UseSeparateFPHeader
    ,HeaderFooterCategoryId
    ,DateFormat
    ,TimeFormat
 FROM Header WITH (NOLOCK)
 WHERE SectionId = @TemplateSectionId
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportHeader_Description            
           ,@ImportHeader_Description            
           ,@IsCompleted     
           ,@ImportHeader_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted  
         ,@ImportHeader_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO Footer
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy,
ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter,
UseSeparateFPFooter, HeaderFooterCategoryId, DateFormat, TimeFormat)
 SELECT
  @PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,Description
    ,NULL AS IsLocked
    ,NULL AS LockedByFullName
    ,NULL AS LockedBy
    ,ShowFirstPage
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreatedDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
    ,TypeId
    ,AltFooter
    ,FPFooter
    ,UseSeparateFPFooter
    ,HeaderFooterCategoryId
    ,DateFormat
    ,TimeFormat
 FROM Footer WITH (NOLOCK)
 WHERE SectionId = @TemplateSectionId
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportFooter_Description            
           ,@ImportFooter_Description            
           ,@IsCompleted      
           ,@ImportFooter_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted      
         ,@ImportFooter_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectReferenceStandard
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,
RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)
 SELECT
 DISTINCT
  @PProjectId AS ProjectId
    ,X.RefStandardId
    ,X.RefStdSource
    ,X.mReplaceRefStdId
    ,X.RefStdEditionId
    ,X.IsObsolete
    ,X.RefStdCode
    ,GETUTCDATE() AS PublicationDate             
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
 FROM (SELECT
   MRS.RefStdId AS RefStandardId
     ,'M' AS RefStdSource
     ,MRS.ReplaceRefStdId AS mReplaceRefStdId
     ,MAX(MRSE.RefStdEditionId) AS RefStdEditionId
     ,MRS.IsObsolete AS IsObsolete
     ,MRS.RefStdCode AS RefStdCode
  FROM SLCMaster..SegmentReferenceStandard MSRS WITH (NOLOCK)
  INNER JOIN SLCMaster..ReferenceStandard MRS WITH (NOLOCK)
   ON MSRS.RefStandardId = MRS.RefStdId
  INNER JOIN SLCMaster..ReferenceStandardEdition MRSE WITH (NOLOCK)
   ON MRS.RefStdId = MRSE.RefStdId
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
   ON MSRS.SegmentId = PSST.mSegmentId
   AND PSST.SectionId = @TargetSectionId
  WHERE MSRS.SectionId = @TemplateMasterSectionId
  GROUP BY MRS.RefStdId
    ,MRS.ReplaceRefStdId
    ,MRS.IsObsolete
    ,MRS.RefStdCode
  UNION
  SELECT
   PRS.RefStandardId AS RefStandardId
     ,PRS.RefStdSource AS RefStdSource
     ,PRS.mReplaceRefStdId AS mReplaceRefStdId
     ,PRS.RefStdEditionId AS RefStdEditionId
     ,PRS.IsObsolete AS IsObsolete
     ,PRS.RefStdCode AS RefStdCode
  FROM ProjectReferenceStandard PRS WITH (NOLOCK)
  WHERE PRS.ProjectId = @PProjectId
  AND PRS.CustomerId = @PCustomerId
  AND PRS.SectionId = @TargetSectionId
  AND PRS.IsDeleted = 0) AS X
 LEFT JOIN ProjectReferenceStandard PRS WITH (NOLOCK)
  ON PRS.ProjectId = @PProjectId
   AND PRS.RefStandardId = X.RefStandardId
   AND PRS.RefStdSource = X.RefStdSource
   AND ISNULL(PRS.mReplaceRefStdId, 0) = ISNULL(X.mReplaceRefStdId, 0)
   AND PRS.RefStdEditionId = X.RefStdEditionId
   AND PRS.IsObsolete = X.IsObsolete
   AND PRS.SectionId = @TargetSectionId
   AND PRS.CustomerId = @PCustomerId
 WHERE PRS.ProjRefStdId IS NULL
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectReferenceStandard_Description            
           ,@ImportProjectReferenceStandard_Description            
           ,@IsCompleted      
           ,@ImportProjectReferenceStandard_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
        ,@PCustomerId            
         ,@ImportStarted      
         ,@ImportProjectReferenceStandard_Percentage --Percent            
         , 0
   ,@ImportSource        
         , @RequestId;         

--UPDATE ProjectSegmentStatus at last
UPDATE PSST
SET PSST.mSegmentStatusId = NULL
   ,PSST.mSegmentId = NULL
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SectionId = @TargetSectionId
              
	update ps
	set ps.IsLocked=0,
		ps.IsDeleted=0,
		ps.LockedBy=0,
		ps.LockedByFullName=''
	from ProjectSection ps WITH(NOLOCK)
	WHERE ps.SectionId=@TargetSectionId

 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentStatus_Description            
           ,@ImportProjectSegmentStatus_Description            
           ,@IsCompleted   
           ,@ImportProjectSegmentStatus_Step --Step     
     ,@RequestId;              
             
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted    
         ,@ImportProjectSegmentStatus_Percentage --Percent            
         , 0
   ,@ImportSource          
         , @RequestId;               

SELECT
 *
FROM ProjectSection WITH (NOLOCK)
WHERE SectionId = @TargetSectionId              
  
    EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportComplete_Description            
           ,@ImportComplete_Description            
           ,@IsCompleted    
           ,@ImportComplete_Step --Step     
     ,@RequestId;              

 --Add Logs to ImportProjectRequest
 EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportCompleted        
         ,@ImportComplete_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               
              
               
END TRY

BEGIN CATCH
	
	update ps
	set ps.IsLocked=0,
		ps.LockedBy=0,
		ps.LockedByFullName=''
	from ProjectSection ps WITH(NOLOCK)
	WHERE ps.SectionId=@TargetSectionId
	
	DECLARE @ResultMessage NVARCHAR(MAX);            
	SET @ResultMessage = concat('Rollback Transaction. Error Number: ' , CONVERT(VARCHAR(MAX), ERROR_NUMBER()) ,      
	'. Error Message: ' , CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) ,            
	'. Procedure Name: ' , CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) ,            
	'. Error Severity: ' , CONVERT(VARCHAR(5), ERROR_SEVERITY()) ,            
	'. Line Number: ' , CONVERT(VARCHAR(5), ERROR_LINE()))    
              
			  --insert into temp values(@ResultMessage,GETUTCDATE())

	 EXEC usp_MaintainImportProjectHistory @PProjectId            
			   ,@ImportFailed_Description            
			  ,@ResultMessage      
			   ,@IsCompleted  
				,@ImportFailed_Step --Step     
		 ,@RequestId;

	EXEC usp_MaintainImportProjectProgress null            
			 ,@PProjectId     
	   ,null
	  , @TargetSectionId       
			 ,@PUserId            
			 ,@PCustomerId         
		,@Importfailed        
			,@ImportFailed_Percentage --Percent            
			 , 0
		   ,@ImportSource          
			 , @RequestId;
              
END CATCH  
END
GO
PRINT N'Refreshing [dbo].[usp_CreateImportProjectRequest]...';


GO
