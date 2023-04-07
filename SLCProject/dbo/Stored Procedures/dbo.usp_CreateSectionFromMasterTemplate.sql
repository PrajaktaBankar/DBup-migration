
CREATE PROCEDURE [dbo].[usp_CreateSectionFromMasterTemplate]                 
 @ProjectId INT, @CustomerId INT, @UserId INT, @SourceTag VARCHAR (18),                 
 @Author NVARCHAR(500), @Description NVARCHAR(500), @UserName NVARCHAR(500) = '',                
 @UserAccessDivisionId NVARCHAR(MAX) = '', @RequestId INT              
AS                  
BEGIN                
 DECLARE @PProjectId INT = @ProjectId;                
 DECLARE @PCustomerId INT = @CustomerId;                
 DECLARE @PUserId INT = @UserId;                
 DECLARE @PSourceTag VARCHAR (18) = @SourceTag;                
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
   AND PSG.ProjectId = @PProjectId AND PSG.SectionId = @SectionId                
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
   AND PSG.ProjectId = @ProjectId AND PSG.SectionId = @SectionId                
 WHERE PSST_Template.SectionId = @TemplateSectionId                
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0                
 AND (PSST_Template_PSG.SegmentId IS NOT NULL                
 OR PSST_Template_MSG.SegmentId IS NOT NULL)                
 AND @IsTemplateMasterSectionOpened = 1                
              
              
                
--Insert target segment status into temp table of new section                
SELECT                
 * INTO #tmp_TgtProjectSegmentStatus                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @SectionId                
                
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
WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @SectionId AND PSST.CustomerId = @CustomerId
                
--UPDATE ProjectSegment                
UPDATE PSG                
SET PSG.SegmentStatusId = PSST.SegmentStatusId       
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON PSST.SegmentId = PSG.SegmentId                
WHERE PSG.ProjectId = @ProjectId AND PSG.SectionId = @SectionId AND PSST.SectionId = @SectionId                
                
UPDATE PSG                
SET PSG.SegmentDescription = PS.Description                
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON PSST.SegmentId = PSG.SegmentId                
INNER JOIN ProjectSection PS WITH (NOLOCK)                
 ON PSST.SectionId = PS.SectionId                
WHERE PSG.ProjectId = @ProjectId AND PSG.SectionId = @SectionId AND PSST.SectionId = @SectionId                
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
  ON SCHOP_Template.ProjectId = @ProjectId AND SCHOP_Template.CustomerId = @CustomerId
  AND SCHOP_Template.SectionId = @TemplateSectionId AND PCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode                
   AND PCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode                
   AND SCHOP_Template.ChoiceOptionSource = 'U'                
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
 WHERE PSRT_Template.ProjectId = @ProjectId AND PSRT_Template.SectionId = @TemplateSectionId                
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
 WHERE PSUT_Template.CustomerId = @CustomerId AND PSUT_Template.ProjectId = @ProjectId AND PSUT_Template.SectionId = @TemplateSectionId                
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
 WHERE PSGT_Template.ProjectId = @ProjectId AND PSGT_Template.SectionId = @TemplateSectionId                
              
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
 WHERE PNI_Template.ProjectId = @PProjectId AND PNI_Template.SectionId = @TemplateSectionId      
 
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
  WHERE PSRS_Template.ProjectId = @ProjectId AND PSRS_Template.SectionId = @TemplateSectionId
  AND PSRS_Template.SegmentId IS NULL
  AND PSRS_Template.mSegmentId IS NOT NULL                  
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
  WHERE PSRS_Template.ProjectId = @ProjectId AND PSRS_Template.SectionId = @TemplateSectionId                
  AND PSRS_Template.SegmentId IS NOT NULL
  AND PSRS_Template.mSegmentId IS NULL) AS X                
              
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
WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @SectionId                
              
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


