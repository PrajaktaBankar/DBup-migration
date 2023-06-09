CREATE PROCEDURE [dbo].[usp_ImportSectionFromProject]                                      
(                                                        
@CustomerId INT,                                                                    
@UserId INT,                                                                    
@SourceProjectId INT,                                                                    
@SourceSectionId INT,                                                                    
@TargetProjectId INT,                                                                    
@UserName NVARCHAR(500)=NULL,                                                                
@RequestId INT,
@IncludeDocFolders BIT,
@IncludeDocSections BIT
)                                                                    
AS                                                                     
BEGIN                                                            
                                                                    
 DECLARE @PCustomerId INT = @CustomerId;                                                            
                                                                    
 DECLARE @PUserId INT = @UserId;                                                            
                                                                    
 DECLARE @PSourceProjectId INT = @SourceProjectId;                                                            
                                                                    
 DECLARE @PSourceSectionId INT = @SourceSectionId;                                                            
                                                                    
 DECLARE @PTargetProjectId INT = @TargetProjectId;                                                            
                                                                    
 DECLARE @PUserName NVARCHAR(500) = @UserName;                  
 DECLARE @PMasterDataTypeId  INT=0;                  
 DECLARE @IsMarsterDivision  BIT =0;                  
 DECLARE @PDivisionCode NVARCHAR(500) = NULL;                          
 DECLARE @PDivisionId INT = NULL;                          
 DECLARE @PParentDescription NVARCHAR(500) =  NULL;                   
 DECLARE @SubDivisionParentSectionId INT=0                    
 DECLARE @PDivisionSourceTag  VARCHAR(18) = '';                  
                                                                     
DECLARE @ImportStart_Description NVARCHAR(50) = 'Import Started';                                                                      
DECLARE @ImportProjectSection_Description NVARCHAR(50) = 'Import Project Section Imported';                                                                                          
DECLARE @ImportProjectSegment_Description NVARCHAR(50) = 'Project Segment Imported';                                                                        
DECLARE @ImportProjectSegmentStatus_Description NVARCHAR(50) = 'Project Segment Status Imported';                                                                                
DECLARE @ImportProjectSegmentChoice_Description NVARCHAR(50) = 'Project Segment Choice Imported';                                                                             
DECLARE @ImportProjectChoiceOption_Description NVARCHAR(50) = 'Project Choice Option Imported';                                                                              
DECLARE @ImportSelectedChoiceOption_USERCHOICE_Description NVARCHAR(50) = 'Selected Choice Option(USER CHOICE) Imported';                                                                             
DECLARE @ImportSelectedChoiceOption_MASTERCHOICE_Description NVARCHAR(50) = 'Selected Choice Option(MASTER CHOICE) Imported';                                                                                  
DECLARE @ImportProjectNote_Description NVARCHAR(50) = 'Project Note Imported';                            
DECLARE @ImportProjectNoteImage_Description NVARCHAR(50) = 'Project Note Image Imported';                                 
DECLARE @ImportProjectSegmentImage_Description NVARCHAR(50) = 'Project Segment Image Imported';                                            
DECLARE @ImportProjectReferenceStandard_Description NVARCHAR(50) = 'Project Reference Standard Imported';                                     
DECLARE @ImportProjectSegmentReferenceStandard_Description NVARCHAR(50) = 'Project Segment Reference Standard Imported';                                      
DECLARE @ImportProjectSegmentRequirementTag_Description NVARCHAR(50) = 'Project Segment Requirement Tag Imported';                                                                        
DECLARE @ImportProjectSegmentUserTag_Description NVARCHAR(50) = 'Project Segment User Tag Imported';                     
DECLARE @ImportHeader_Description NVARCHAR(50) = 'Header Imported';                                      
DECLARE @ImportFooter_Description NVARCHAR(50) = 'Footer Imported';   
DECLARE @ImportProjectSegmentGlobalTerm_Description NVARCHAR(50) = 'Project Segment Global Term Imported';                                                          
DECLARE @ImportProjectGlobalTerm_Description NVARCHAR(50) = 'Project Global Term Imported';                                                                     
DECLARE @ImportProjectSegmentLink_Description NVARCHAR(50) = 'Project Segment Link Imported';                                                         
DECLARE @ImportProjectHyperLink_Description NVARCHAR(50) = 'Project HyperLink Imported';                                          
DECLARE @ImportTrackSegmentStatus_Description NVARCHAR(50) = 'Project Track Status Imported';     
DECLARE @ImportpageSetupSettings_Description NVARCHAR(50) = 'Page Setup Settings Imported'; 
DECLARE @ImportDocLibraryMapping_Description NVARCHAR(50) = 'Doc Library Mapping Imported'; 
DECLARE @ImportComplete_Description NVARCHAR(50) = 'Import Completed';                                                                      
DECLARE @ImportFailed_Description NVARCHAR(50) = 'IMPORT FAILED';                                                                      
                                                
DECLARE @ImportStart_Percentage TINYINT = 5;                                                                       
DECLARE @ImportProjectSection_Percentage TINYINT = 10;                                                                                        
DECLARE @ImportProjectSegment_Percentage TINYINT = 15;                                                                        
DECLARE @ImportProjectSegmentStatus_Percentage TINYINT = 20;                                                                               
DECLARE @ImportProjectSegmentChoice_Percentage TINYINT = 25;                                                                         
DECLARE @ImportProjectChoiceOption_Percentage TINYINT = 30;                                                                             
DECLARE @ImportSelectedChoiceOption_USERCHOICE_Percentage TINYINT = 35;                                                                          
DECLARE @ImportSelectedChoiceOption_MASTERCHOICE_Percentage TINYINT = 40;                                                                             
DECLARE @ImportProjectNote_Percentage TINYINT = 45;                                                                               
DECLARE @ImportProjectNoteImage_Percentage TINYINT = 50;                                                                            
DECLARE @ImportProjectSegmentImage_Percentage TINYINT = 55;                                                                     
DECLARE @ImportProjectReferenceStandard_Percentage TINYINT = 60;                                                                     
DECLARE @ImportProjectSegmentReferenceStandard_Percentage TINYINT = 65;                                                                     
DECLARE @ImportProjectSegmentRequirementTag_Percentage TINYINT = 70;                                                                     
DECLARE @ImportProjectSegmentUserTag_Percentage TINYINT = 75;       
DECLARE @ImportHeader_Percentage TINYINT = 80;                                                                     
DECLARE @ImportFooter_Percentage TINYINT = 85;      
DECLARE @ImportProjectSegmentGlobalTerm_Percentage TINYINT = 90;                                                                     
DECLARE @ImportProjectGlobalTerm_Percentage TINYINT = 92;                                                                    
DECLARE @ImportProjectSegmentLink_Percentage TINYINT = 95;                                                                     
DECLARE @ImportProjectHyperLink_Percentage TINYINT = 96;                                               
DECLARE @ImportTrackSegmentStatus_Percentage TINYINT = 97;  
DECLARE @ImportPageSetupSettings_Percentage TINYINT = 98;  
DECLARE @ImportDocLibraryMapping_Percentage TINYINT = 99;
DECLARE @ImportComplete_Percentage TINYINT = 100;                                                                     
DECLARE @ImportFailed_Percentage TINYINT = 100;                                                                     
                                                                    
DECLARE @ImportStart_Step TINYINT = 1;                                                                      
DECLARE @ImportProjectSection_Step TINYINT = 2;                                                                    
DECLARE @ImportProjectSegment_Step TINYINT = 3;                                                                    
DECLARE @ImportProjectSegmentStatus_Step TINYINT = 4;                                                 
DECLARE @ImportProjectSegmentChoice_Step TINYINT = 5;                                                                    
DECLARE @ImportProjectChoiceOption_Step TINYINT = 6;                                                                    
DECLARE @ImportSelectedChoiceOption_USERCHOICE_Step TINYINT = 7;                          
DECLARE @ImportSelectedChoiceOption_MASTERCHOICE_Step TINYINT = 8;                                                                        
DECLARE @ImportProjectNote_Step TINYINT = 9;                                                                    
DECLARE @ImportProjectNoteImage_Step TINYINT = 10;                                                                    
DECLARE @ImportProjectSegmentImage_Step TINYINT = 11;                                                                    
DECLARE @ImportProjectReferenceStandard_Step TINYINT = 12;                                                                    
DECLARE @ImportProjectSegmentReferenceStandard_Step TINYINT = 13;                                                                    
DECLARE @ImportProjectSegmentRequirementTag_Step TINYINT = 14;                                             
DECLARE @ImportProjectSegmentUserTag_Step TINYINT = 15;                                                                    
DECLARE @ImportHeader_Step TINYINT = 16;                                                                    
DECLARE @ImportFooter_Step TINYINT = 17;                                                                    
DECLARE @ImportProjectSegmentGlobalTerm_Step TINYINT = 18;                                                                    
DECLARE @ImportProjectGlobalTerm_Step TINYINT = 19;                                                                    
DECLARE @ImportProjectSegmentLink_Step TINYINT = 20;                                                                    
DECLARE @ImportProjectHyperLink_Step TINYINT = 21;                                           
DECLARE @ImportTrackSegmentStatus_Step TINYINT = 24;--Newly Added   
DECLARE @ImportPageSetup_Step TINYINT = 25;  --Newly Added 
DECLARE @ImportDocLibraryMapping_Step TINYINT = 26;  --Newly Added 
DECLARE @ImportComplete_Step TINYINT = 22;                                                                    
DECLARE @ImportFailed_Step TINYINT = 23;                                                         
                                                              
DECLARE  @ImportPending TINYINT =1;                                                              
DECLARE  @ImportStarted TINYINT =2;                                                              
DECLARE  @ImportCompleted TINYINT =3;                                                              
DECLARE  @Importfailed TINYINT =4                                                              
           
DECLARE @IsCompleted BIT =1;                                                              
                                                              
DECLARE @ImportSource Nvarchar(100)='Import From Project'                                                               
                                                                                  
                                                           
 BEGIN TRY                                               
 --DECLARE VARIABLES                                                                          
 DECLARE @ParentSectionId INT = NULL;
 DECLARE @OldParentSectionId AS INT = 0;
                                                                    
 DECLARE @ParentSectionTbl AS TABLE (                                                                          
  ParentSectionId INT                                                                          
 );                                                     
                                                                    
 DECLARE @TargetSectionId INT = NULL;                                                            
                         
 DECLARE @SectionCode INT = NULL;                                                            
 DECLARE @TargetSectionCode INT = NULL;                                                            
                                                                    
 DECLARE @SourceTag VARCHAR(18) = '';                                                            
                                                                          
 DECLARE @mSectionId INT = 0;                                                            
                                                          
 DECLARE @Author NVARCHAR(MAX) = '';                                                                        
                                                                     
    --Add Logs to ImportProjectHistory                       
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                       
           ,@ImportStart_Description                                                                      
           ,@ImportStart_Description                                                                                
           ,@IsCompleted                                                                           
           ,@ImportStart_Step --Step                                                             
     ,@RequestId                                                                    
                                                                    
 --Add Logs to ImportProjectRequest                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                             
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                          
         ,@PUserId                                                                       
         ,@PCustomerId                                                                                
        ,@ImportStarted                                                                   
         ,@ImportStart_Percentage --Percent                                             
         , 0                                                                    
   ,@ImportSource                                                                  
         , @RequestId;                                                           
                                            
--FETCH SECTIONS DETAILS INTO VARIABLES                                                                          
SELECT                                           
 @SectionCode = SectionCode                                                            
   ,@SourceTag = SourceTag                                                            
   ,@mSectionId = ISNULL(mSectionId,0)                                                  
   ,@Author = Author
   ,@OldParentSectionId = ParentSectionId
FROM ProjectSection WITH (NOLOCK)                                       
WHERE SectionId = @PSourceSectionId;                                                            
                                                            
--DELETE EXISTING ONE And Also Lock IT.                                                              
--DECLARE @OldSectionId INT=(SELECT top 1 SectionId FROM ProjectSection PS WITH (NOLOCK)                                                                          
--WHERE PS.ProjectId = @PTargetProjectId                                                                       
--AND PS.IsLastLevel = 1                                                                          
--AND (ISNULL(PS.mSectionId,0) = @mSectionId                                             
--         OR (PS.Sourcetag = @SourceTag AND PS.Author = @Author ))                                                    
----AND PS.SourceTag=@SourceTag                                                                     
--AND ISNULL(PS.IsDeleted,0) = 0)                                            
                                          
DECLARE @OldSectionId INT = 0, @Old_IsHiddenStatus BIT = 0;                      
 --Master Section                                          
IF (@mSectionId>0)                                          
BEGIN                                          
 SELECT top 1                       
 @OldSectionId=SectionId                       
 ,@Old_IsHiddenStatus = PS.IsHidden                      
 FROM ProjectSection PS WITH (NOLOCK)                                                                        
 WHERE PS.ProjectId = @PTargetProjectId                                                                    
 AND PS.IsLastLevel = 1                                                                        
 AND mSectionId=@mSectionId                                          
 AND ISNULL(PS.IsDeleted,0) = 0                                          
END                                          
ELSE --User Section                                          
BEGIN                                          
 SELECT top 1                       
 @OldSectionId=SectionID                       
 ,@Old_IsHiddenStatus = PS.IsHidden                      
 FROM ProjectSection PS WITH (NOLOCK)                                                        
 WHERE PS.ProjectId = @PTargetProjectId                                          
 AND PS.IsLastLevel = 1                                                          
 AND PS.Sourcetag = @SourceTag AND PS.Author = @Author                                                               
 AND ISNULL(PS.IsDeleted,0) = 0                                          
END                                          
                                                                   
--DELETE EXISTING ONE And Also Lock IT                                                   
UPDATE PS                                                            
SET PS.IsDeleted = 1,                                                      
 PS.IsLocked=1,                                                      
 PS.LockedBy=@UserId,                          
 PS.LockedByFullName=@UserName                                                      
FROM ProjectSection PS WITH (NOLOCK)                                                            
WHERE PS.SectionId = @OldSectionId                                                          
                                                       
                                
SELECT TOP 1                         
* INTO #ImportRequest                                
FROM ImportProjectRequest WITH (NOLOCK)                                
WHERE RequestId = @RequestId;                                                          
                                
IF (SELECT CASE WHEN ISNULL(IsCreateFolderStructure,0) = 1 AND ISNULL(TargetParentSectionId,0) = 0 THEN 1 ELSE 0 END FROM #ImportRequest) = 1                                
BEGIN                                
DECLARE @SourceParentSectionId INT =0;                                 
 -- source section id                                
 SELECT TOP 1                                
 @SourceParentSectionId = ParentSectionId                                 
 FROM ProjectSection WITH (NOLOCK)                                 
 WHERE SectionId = (SELECT TOP 1 ISNULL(SourceSectionId,0) FROM #ImportRequest)                                
 AND ProjectId = @PSourceProjectId AND CustomerId = @PCustomerId                      
 AND ISNULL(IsDeleted,0)=0                          
                                
 -- source sub folder                                
 SELECT TOP 1                                
  * INTO #SourceSubFolder                                
 FROM ProjectSection WITH (NOLOCK)                                
 WHERE SectionId = @SourceParentSectionId                          
  AND ProjectId = @PSourceProjectId AND CustomerId = @PCustomerId                            
  AND ISNULL(IsDeleted,0)=0                       
                              
 --source division - top level folder                         
 DEclare @Src_ParentSectionId int = 0;                      
 SELECT TOP 1                       
 @Src_ParentSectionId = ParentSectionId FROM #SourceSubFolder                      
                      
 SELECT TOP 1                                 
 * INTO #SourceDivision                                
 FROM ProjectSection WITH (NOLOCK)                                
 WHERE SectionId = @Src_ParentSectionId                         
  AND ProjectId = @PSourceProjectId AND CustomerId = @PCustomerId                              
   AND ISNULL(IsDeleted,0)=0;                      
                                
 -- check source division exist in target project                            
 DECLARE @Div_SourceTag NVARCHAR(18) = ( SELECT TOP 1 ISNULL(SourceTag,'') FROM #SourceDivision);          
 DECLARE @Div_Description NVARCHAR(MAX) = ( SELECT TOP 1 ISNULL([Description],'') FROM #SourceDivision);                                
 DECLARE @IsDivExistInTarget TINYINT = 0, @Target_DivId INT = 0, @Div_Discrip NVARCHAR(1000) =NULL;                                
 DECLARE @T_CreatedDivId INT = 0;                                
                                
 IF(@Div_SourceTag IS NOT NULL AND @Div_SourceTag <> '')          
 SELECT TOP 1 @IsDivExistInTarget= 1 ,@Target_DivId = SectionId                                
 FROM ProjectSection WITH (NOLOCK) WHERE UPPER(SourceTag) = UPPER(@Div_SourceTag) AND UPPER([Description]) = UPPER(@Div_Description)          
 AND ProjectId = @TargetProjectId AND CustomerId = @PCustomerId AND IsLastLevel <> 1 AND ISNULL(IsDeleted,0)=0;                                
ELSE          
 SELECT TOP 1 @IsDivExistInTarget= 1 ,@Target_DivId = SectionId                                
 FROM ProjectSection WITH (NOLOCK) WHERE UPPER([Description]) = UPPER(@Div_Description) AND (SourceTag IS NULL OR SourceTag = '')          
 AND ProjectId = @TargetProjectId AND CustomerId = @PCustomerId AND IsLastLevel <> 1 AND ISNULL(IsDeleted,0)=0;                                 
          
 IF @IsDivExistInTarget = 0                                
 BEGIN                           
                          
   DECLARE @PSID INT = 0;                          
                             
   SELECT @PSID = SectionId                           
   FROM ProjectSection WITH(NOLOCK)                           
   WHERE ProjectId = @TargetProjectId AND CustomerId = @PCustomerId AND ParentSectionId = 0 AND mSectionId = 5; -- Front End Group                            
                          
  INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                      
  Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                            
  CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                               
  IsLocked,LockedByFullName,SortOrder, PendingUpdateCount)                            
  SELECT @PSID, mSectionId, @TargetProjectId,CustomerId, UserId, DivisionId, DivisionCode,                          
  Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, GETUTCDATE(),                          
  @UserId,@UserId,GETUTCDATE(),FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,IsLocked,LockedByFullName,SortOrder, PendingUpdateCount                            
  FROM #SourceDivision;              
                          
              
  -- Update the Division SortOrder Here            
  SET @T_CreatedDivId = SCOPE_IDENTITY();                          
  EXEC usp_UpdateDivisionSortOrderAndParentSectionId @TargetProjectId, @PCustomerId, @T_CreatedDivId;             
                         
  INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                      
  Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                            
  CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                                      
  IsLocked,LockedByFullName,SortOrder, PendingUpdateCount)                            
  SELECT @T_CreatedDivId, mSectionId,@TargetProjectId,CustomerId, UserId, DivisionId, DivisionCode,                          
  Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, GETUTCDATE(),                          
  @UserId,@UserId,GETUTCDATE(),FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,IsLocked,LockedByFullName ,SortOrder, PendingUpdateCount                           
  FROM #SourceSubFolder                          
                          
  SET @ParentSectionId = SCOPE_IDENTITY();                          
 END;                                
 ELSE                                
 BEGIN                             
                           
 SELECT @Div_Discrip = Description                               
  ,@Div_SourceTag = SourceTag                              
  FROM #SourceSubFolder;                            
SET @ParentSectionId = 0;                          
                          
-- check already sub folder exist in target project                          
 SELECT @ParentSectionId = SectionId                           
 FROM ProjectSection WITH (NOLOCK)                           
 WHERE ProjectId=@TargetProjectId                           
 AND CustomerId = @PCustomerId                          
 AND UPPER(SourceTag) = UPPER(@Div_SourceTag)                          
 AND UPPER(Description) = UPPER(@Div_Discrip)                       
 AND ISNULL(IsDeleted,0) = 0                      
                          
 IF @ParentSectionId = 0                          
 BEGIN                          
  INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                      
  Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                            
  CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                                      
  IsLocked,LockedByFullName,SortOrder, PendingUpdateCount)                            
  SELECT @Target_DivId,mSectionId,@TargetProjectId,CustomerId, UserId, DivisionId, DivisionCode,                          
  Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, GETUTCDATE(),                          
  @UserId,@UserId,GETUTCDATE(),FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,IsLocked,LockedByFullName ,SortOrder, PendingUpdateCount                          
  FROM #SourceSubFolder                          
                            
   SET @ParentSectionId = SCOPE_IDENTITY();                          
 END;                                                   
END;                                
                                
END;                                
ELSE                                
BEGIN                                
 SELECT TOP 1                                
 @ParentSectionId = ISNULL(TargetParentSectionId,0)                                
 FROM #ImportRequest                 
               
 IF ISNULL(@ParentSectionId,0) = 0              
 BEGIN              
 SELECT @ParentSectionId = ParentSectionId              
 FROM ProjectSection               
 WHERE SectionId = @OldSectionId               
 AND ProjectId = @TargetProjectId               
 AND CustomerId= @PCustomerId              
 END;                             
END;                                
                    
     -- get parent id of section which  is imported                  
 select @SubDivisionParentSectionId=ParentSectionId from projectsection WITH(NOLOCK)  where SectionId=@ParentSectionId;                  
                  
   SELECT @PMasterDataTypeId = P.MasterDataTypeId FROM                         
    Project P WITH(NOLOCK)                         
    WHERE P.ProjectId = @PTargetProjectId;                  
                  
  SELECT                       
  @PDivisionCode= CASE WHEN ISNULL(PS.mSectionId,0) = 0 THEN PS.SourceTag  ELSE LEFT(PS.SourceTag, 2) END                      
  ,@IsMarsterDivision = CASE WHEN ISNULL(PS.mSectionId,0) = 0 THEN 0 ELSE 1 END,                  
  @PParentDescription=PS.Description                     
 ,@PDivisionId = PS.DivisionId ,                  
 @PDivisionSourceTag=PS.SourceTag                  
 FROM ProjectSection  PS WITH(NOLOCK)                        
 WHERE PS.SectionId = @SubDivisionParentSectionId                   
                                  
IF @IsMarsterDivision = 1                      
BEGIN                      
SELECT                          
 @PDivisionCode = MD.DivisionCode                        
   ,@PDivisionId = MD.DivisionId                          
FROM SLCMaster..Division MD WITH (NOLOCK)                          
WHERE MD.DivisionCode=@PDivisionCode                       
AND   MD.MasterDataTypeId  =@PMasterDataTypeId                                
END                      
ELSE                      
BEGIN                      
 SELECT  @PDivisionId =CD.DivisionId, @PDivisionCode = CD.DivisionCode  FROM CustomerDivision CD WITH(NOLOCK)                                                           
 WHERE CD.CustomerId = @CustomerId AND ((@PDivisionSourceTag IS NOT NULL AND UPPER(CD.DivisionCode) = UPPER(@PDivisionSourceTag) AND UPPER(CD.DivisionTitle) = UPPER(@PParentDescription)                                 
 OR @PDivisionSourceTag IS NULL AND CD.DivisionCode IS NULL AND UPPER(CD.DivisionTitle) = UPPER(@PParentDescription))) AND CD.IsActive=1 AND IsNull(CD.IsDeleted,0)=0             
END                  
                
DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@TargetProjectId, @CustomerId, @ParentSectionId, @SourceTag, @Author);                  
                  
UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @TargetProjectId AND CustomerId = @CustomerId  AND SortOrder >= @SortOrder;                  
                                                       
                                 
INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                      
Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                            
CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                                      
IsLocked,LockedByFullName,IsHidden,SortOrder, PendingUpdateCount)                                            
 SELECT                                                        
  @ParentSectionId AS ParentSectionId                                                            
 ,mSectionId                                                            
 ,@PTargetProjectId AS ProjectId                                                            
 ,@PCustomerId AS CustomerId                                                            
 ,@PUserId AS UserId                                                            
 ,@PDivisionId as DivisionId  --TODO                                                          
 ,@PDivisionCode as DivisionCode --TODO                                                           
 ,Description                                                            
 ,LevelId                                                            
 ,IsLastLevel                           
 ,SourceTag                                                            
 ,Author                                     
 ,TemplateId                                                            
 ,SectionCode                  
 ,IsDeleted                                                            
 ,GETUTCDATE()                                                            
 ,@PUserId                                                           
 ,@PUserId                                                            
 ,GETUTCDATE()                                                            
 ,FormatTypeId                                                            
 ,SpecViewModeId                                                      
 ,IsTrackChanges                                                      
 ,IsTrackChangeLock                                                      
 ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy                                                      
 ,1                                                      
 ,@UserName                  
 ,@Old_IsHiddenStatus                
 ,@SortOrder
 ,PendingUpdateCount
 FROM ProjectSection PS WITH (NOLOCK)                                                            
 WHERE PS.SectionId = @PSourceSectionId;                                                      
                                                            
SET @TargetSectionId = SCOPE_IDENTITY();                                                            
                                                          
                                                      
   --Add Logs to ImportProjectHistory                                                                    
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                   
           ,@ImportProjectSection_Description                                                                                
           ,@ImportProjectSection_Description                                                                                
        ,@IsCompleted                                                                            
           ,@ImportProjectSection_Step --Step                                                                         
     ,@RequestId             
                                                                    
 --Add Logs to ImportProjectRequest                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                 
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
           ,@ImportStarted                                                                       
         ,@ImportProjectSection_Percentage --Percent                                                                                
         , 0                                       
    ,@ImportSource                                                                      
         , @RequestId;                                                                     
          
--INSERT Src SegmentStatus into Temp tables                                                                          
SELECT                                                            
 PSST.[SegmentStatusId] ,PSST.[SectionId],PSST.[ParentSegmentStatusId],
	PSST.[mSegmentStatusId] ,PSST.[mSegmentId] ,PSST.[SegmentId] ,PSST.[SegmentSource] ,PSST.[SegmentOrigin] ,
	PSST.[IndentLevel] ,PSST.[SequenceNumber] ,PSST.[SpecTypeTagId] ,PSST.[SegmentStatusTypeId] ,
	PSST.[IsParentSegmentStatusActive] ,PSST.[ProjectId] ,PSST.[CustomerId] ,PSST.[SegmentStatusCode] ,
	PSST.[IsShowAutoNumber] ,PSST.[IsRefStdParagraph] ,PSST.[FormattingJson] ,PSST.[CreateDate] ,
	PSST.[CreatedBy] ,PSST.[ModifiedDate] ,PSST.[ModifiedBy] ,PSST.[IsPageBreak] ,PSST.[SLE_DocID] ,
	PSST.[SLE_ParentID] ,PSST.[SLE_SegmentID] ,PSST.[SLE_ProjectSegID] ,PSST.[SLE_StatusID] ,PSST.[A_SegmentStatusId] ,
	PSST.[IsDeleted] ,PSST.[TrackOriginOrder] ,PSST.[MTrackDescription]
 INTO #SrcSegmentStatusTMP                                                            
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                                           
WHERE PSST.SectionId = @PSourceSectionId                                             
AND PSST.ProjectId = @PSourceProjectId AND PSST.CustomerId = @CustomerId
AND ISNULL(PSST.IsDeleted, 0) = 0                                                            
                                                            
--INSERT PROJECTSEGMENT STATUS                                                                          
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,                                    
IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,                                       
SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsPageBreak, A_SegmentStatusId)                                                            
 SELECT                                          
  @TargetSectionId AS SectionId                                                            
  ,PSS.ParentSegmentStatusId                                                            
    ,PSS.mSegmentStatusId                                                            
    ,PSS.mSegmentId                                                            
    ,PSS.SegmentId                     
    ,PSS.SegmentSource                                                            
    ,PSS.SegmentOrigin                                                            
    ,PSS.IndentLevel                                                            
    ,PSS.SequenceNumber                                                            
    ,PSS.SpecTypeTagId                                                            
    ,PSS.SegmentStatusTypeId                      
    ,PSS.IsParentSegmentStatusActive                                                            
    ,@PTargetProjectId AS ProjectId                                                            
    ,@PCustomerId AS CustomerId                                                            
    ,PSS.SegmentStatusCode                                                            
    ,PSS.IsShowAutoNumber                                                   
    ,PSS.IsRefStdParagraph                                                            
    ,PSS.FormattingJson                                                            
    ,GETUTCDATE() AS CreateDate                                                            
    ,@PUserId AS CreatedBy                                                            
    ,@PUserId AS ModifiedBy                                                            
    ,GETUTCDATE() AS ModifiedDate                                                            
    ,PSS.IsPageBreak                                                            
    ,PSS.SegmentStatusId                    
 FROM #SrcSegmentStatusTMP PSS WITH (NOLOCK);                                                            
                                                            
--INSERT Tgt SegmentStatus into Temp tables                                                                          
CREATE TABLE #tmp_TgtSegmentStatus([SegmentStatusId] [bigint] PRIMARY KEY ,
	[SectionId] [int] ,[ParentSegmentStatusId] [bigint] ,[mSegmentStatusId] [int] ,[mSegmentId] [int] ,[SegmentId] [bigint] ,
	[SegmentSource] [char](1) ,[SegmentOrigin] [char](1) ,[IndentLevel] [tinyint] ,[SequenceNumber] [decimal](18, 4) ,
	[SpecTypeTagId] [int] ,[SegmentStatusTypeId] [int] ,[IsParentSegmentStatusActive] [bit] ,[ProjectId] [int] ,[CustomerId] [int] ,
	[SegmentStatusCode] [bigint] ,[IsShowAutoNumber] [bit] ,[IsRefStdParagraph] [bit] ,[FormattingJson] [nvarchar](255) ,
	[CreateDate] [datetime2](7) ,[CreatedBy] [int] ,[ModifiedDate] [datetime2](7) ,[ModifiedBy] [int] ,[IsPageBreak] [bit] ,
	[SLE_DocID] [int] ,[SLE_ParentID] [int] ,[SLE_SegmentID] [int] ,[SLE_ProjectSegID] [int] ,[SLE_StatusID] [int] ,
	[A_SegmentStatusId] [bigint] ,[IsDeleted] [bit] ,[TrackOriginOrder] [nvarchar](2) ,[MTrackDescription] [nvarchar](max) )
 INSERT INTO #tmp_TgtSegmentStatus  (SegmentStatusId , [SectionId] ,[ParentSegmentStatusId] ,[mSegmentStatusId] ,[mSegmentId] ,[SegmentId] ,[SegmentSource]  ,
	[SegmentOrigin]  ,[IndentLevel] ,[SequenceNumber]   ,[SpecTypeTagId]  ,[SegmentStatusTypeId] ,[IsParentSegmentStatusActive] ,
	[ProjectId] ,[CustomerId]  ,[SegmentStatusCode],[IsShowAutoNumber] ,[IsRefStdParagraph] ,[FormattingJson] ,[CreateDate]   ,
	[CreatedBy] ,[ModifiedDate] ,[ModifiedBy] ,[IsPageBreak],[SLE_DocID] ,[SLE_ParentID] ,[SLE_SegmentID] ,[SLE_ProjectSegID] ,
	[SLE_StatusID]  ,[A_SegmentStatusId] ,[IsDeleted] ,[TrackOriginOrder] ,[MTrackDescription] )
SELECT                                                                
 SegmentStatusId , [SectionId] ,[ParentSegmentStatusId] ,[mSegmentStatusId] ,[mSegmentId] ,[SegmentId] ,[SegmentSource]  ,
	[SegmentOrigin]  ,[IndentLevel] ,[SequenceNumber]   ,[SpecTypeTagId]  ,[SegmentStatusTypeId] ,[IsParentSegmentStatusActive] ,
	[ProjectId] ,[CustomerId]  ,[SegmentStatusCode],[IsShowAutoNumber] ,[IsRefStdParagraph] ,[FormattingJson] ,[CreateDate]   ,
	[CreatedBy] ,[ModifiedDate] ,[ModifiedBy] ,[IsPageBreak],[SLE_DocID] ,[SLE_ParentID] ,[SLE_SegmentID] ,[SLE_ProjectSegID] ,
	[SLE_StatusID]  ,[A_SegmentStatusId] ,[IsDeleted] ,[TrackOriginOrder] ,[MTrackDescription] 
	-- into #tmp_TgtSegmentStatus  
	 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                                                                
WHERE PSST.SectionId = @TargetSectionId                                                             
AND    PSST.ProjectId = @PTargetProjectId AND PSST.CustomerId = @CustomerId      

SELECT                                                            
 SegmentStatusId                                                            
   ,A_SegmentStatusId INTO #NewOldIdMapping                                                            
FROM #tmp_TgtSegmentStatus                                                            
                                                            
--UPDATE PARENT SEGMENT STATUS ID                                                                          
UPDATE TGT                                                            
SET TGT.ParentSegmentStatusId = t.SegmentStatusId                                                            
FROM #tmp_TgtSegmentStatus TGT                                                            
INNER JOIN #NewOldIdMapping t                                                            
 ON TGT.ParentSegmentStatusId = t.A_SegmentStatusId                               
CREATE TABLE #tmp_SrcSegment ( ID BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY, [NewSegmentStatusId] [bigint] ,[SectionId] [INT]                                                                
   ,[ProjectId] [INT],[CustomerId] [INT],[SegmentDescription] [NVARCHAR](MAX),[SegmentSource] [CHAR]                                                         
   ,[SegmentCode] [BIGINT],[CreatedBy] [int],[CreateDate] [datetime2](7),[ModifiedBy] [INT]                                                        
   ,[ModifiedDate] [datetime2](7) ,[A_SegmentId] [BIGINT],[BaseSegmentDescription] [NVARCHAR](MAX)) 
INSERT INTO #tmp_SrcSegment                                                                                             
SELECT                                                            
 PSST_Src.SegmentStatusId AS NewSegmentStatusId                                                            
   ,@TargetSectionId AS SectionId                                                            
   ,@PTargetProjectId AS ProjectId                                                            
   ,@PCustomerId AS CustomerId                                                        
   ,PSG.SegmentDescription                                                            
   ,PSG.SegmentSource                                                     
   ,PSG.SegmentCode                                                            
   ,@PUserId AS CreatedBy                                                            
   ,GETUTCDATE() AS CreateDate                                                            
   ,@PUserId AS ModifiedBy                                                    
   ,GETUTCDATE() AS ModifiedDate                                                            
   ,PSG.SegmentId AS A_SegmentId                                                            
   ,BaseSegmentDescription                                                           
FROM ProjectSegment PSG WITH (NOLOCK)                                                            
INNER JOIN #tmp_TgtSegmentStatus PSST_Src WITH (NOLOCK)                                                            
 ON PSG.SectionId = @PSourceSectionId                                                       
 AND PSG.SegmentStatusId = PSST_Src.A_SegmentStatusId                                                            
WHERE PSG.SectionId = @PSourceSectionId                                                                 
AND PSG.ProjectId = @PSourceProjectId                                                       
 AND ISNULL(PSG.IsDeleted,0)=0                                                          
                                                          
--INSERT INTO PROJECTSEGMENT                                                                          
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,         
SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId, BaseSegmentDescription)                                               
 SELECT                                                            
NewSegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,             
SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId, BaseSegmentDescription                                                              
FROM #tmp_SrcSegment PSG_Source (NOLOCK)                                                            
                                                  
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectSegment_Description                                                                                
           ,@ImportProjectSegment_Description                                                                          
           ,@IsCompleted                             
           ,@ImportProjectSegment_Step --Step                                                                         
     ,@RequestId                                                                    
                                                                    
 --Add Logs to ImportProjectRequest                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                          
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                   
  , @TargetSectionId                                                                           
         ,@PUserId                                                        
         ,@PCustomerId                                                                                
          ,@ImportStarted                                       
         ,@ImportProjectSegment_Percentage --Percent                                                                        
         , 0                                                       
    ,@ImportSource                                                                   
         , @RequestId;                                                                     
                                                                          
                                                          
--INSERT Tgt Segment into Temp tables                                                                          
SELECT                                                           
 PSG.SegmentId                                                            
   ,PSG.SegmentStatusId                                                            
   ,PSG.SectionId                                                
   ,PSG.ProjectId                                                            
   ,PSG.CustomerId                                                            
   ,PSG.SegmentCode                                                       
   ,PSG.IsDeleted                                                            
   ,PSG.A_SegmentId                                                            
   ,PSG.BaseSegmentDescription INTO #tmp_TgtSegment                                                       
FROM ProjectSegment PSG WITH (NOLOCK)                                                            
WHERE PSG.SectionId = @TargetSectionId                                                       
AND    PSG.ProjectId = @PTargetProjectId                                                            
  AND ISNULL(PSG.IsDeleted,0)=0                                                          
                                                          
 --UPDATE SegmentId IN ProjectSegmentStatus Temp (Changed for CSI 37207)                                                      
SELECT PSST_Source.ProjectId , PSST_Source.SectionId , PSST_Source.CustomerId, PSST_Source.SegmentStatusCode ,PSG_Target.SegmentId
INTO #temp_UpdateTgtSegmentStatus
FROM ProjectSegmentStatus PSST_Source WITH (NOLOCK)                                                          
INNER JOIN ProjectSegment PSG_Source WITH (NOLOCK) ON PSST_Source.SectionId=PSG_Source.SectionId AND PSST_Source.SegmentId = PSG_Source.SegmentId                                                          
INNER JOIN #tmp_TgtSegment PSG_Target WITH (NOLOCK) ON PSG_Target.SectionId = @TargetSectionId AND PSG_Source.SegmentCode = PSG_Target.SegmentCode 
WHERE PSST_Source.ProjectId = @SourceProjectId AND PSST_Source.SectionId = @PSourceSectionId AND PSST_Source.CustomerId = @CustomerId 

UPDATE PSST_Target                                                          
SET PSST_Target.SegmentId = UpSoTa.SegmentId                                     
FROM #tmp_TgtSegmentStatus PSST_Target WITH (NOLOCK)
INNER JOIN #temp_UpdateTgtSegmentStatus UpSoTa with (NOLOCK) on  UpSoTa.SegmentStatusCode=PSST_Target.SegmentStatusCode
WHERE PSST_Target.SectionId = @TargetSectionId                                                            

--UPDATE ParentSegmentStatusId IN ORIGINAL TABLES                                                                          
UPDATE PSST                                                            
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId                          
   ,PSST.SegmentId = TMP.SegmentId                                                            
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                                                            
INNER JOIN #tmp_TgtSegmentStatus TMP WITH (NOLOCK)                                                            
 ON PSST.SegmentStatusId = TMP.SegmentStatusId                                                            
WHERE PSST.SectionId = @TargetSectionId                                                       
AND PSST.ProjectId = @PTargetProjectId AND PSST.CustomerId = @CustomerId                                                         
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
        ,@ImportProjectSegmentStatus_Description                                                                                
           ,@ImportProjectSegmentStatus_Description                                                                                
          ,@IsCompleted                                                                           
           ,@ImportProjectSegmentStatus_Step --Step                                                                         
     ,@RequestId                                                                    
    
 --Add Logs to ImportProjectRequest                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                          
  , @TargetSectionId                                                          ,@PUserId                                                                                
         ,@PCustomerId                                           
         ,@ImportStarted                                                                           
         ,@ImportProjectSegmentStatus_Percentage --Percent                                                                                
         , 0                                                                    
    ,@ImportSource                                                            
         , @RequestId;                                
                                                                          
--INSERT PROJECTSEGMENT CHOICE                                                                          
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,                                                            
SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentChoiceId)                                                            
 SELECT                                                            
  @TargetSectionId AS SectionId                                                   
    ,PS_Target.SegmentStatusId                                                            
    ,PS_Target.SegmentId                                                            
    ,PCH_Source.ChoiceTypeId                                                            
    ,@PTargetProjectId AS ProjectId                              
   ,@PCustomerId AS CustomerId                                                            
    ,PCH_Source.SegmentChoiceSource                                                            
    ,PCH_Source.SegmentChoiceCode                                        
    ,@PUserId AS CreatedBy                                                      
    ,GETUTCDATE() AS CreateDate                                                            
    ,@PUserId AS ModifiedBy                                                            
    ,GETUTCDATE() AS ModifiedDate                                                            
    ,SegmentChoiceId AS A_SegmentChoiceId                                                            
 FROM ProjectSegmentChoice PCH_Source WITH (NOLOCK)                                                            
 --INNER JOIN #tmp_SrcSegment PS_Source WITH (NOLOCK)                                                                          
 -- ON PCH_Source.SegmentId = PS_Source.SegmentId                                                                          
 INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)                                                            
  ON PCH_Source.SectionId=@SourceSectionId                                                       
  AND PCH_Source.SegmentId = PS_Target.A_SegmentId                                                            
 WHERE PCH_Source.ProjectId = @PSourceProjectId AND PCH_Source.CustomerId = @CustomerId AND PCH_Source.SectionId = @PSourceSectionId                                                            
 AND ISNULL(PCH_Source.IsDeleted, 0) = 0                                                            
--AND ISNULL(PS_Target.IsDeleted, 0) = 0                                                                    

                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                     
           ,@ImportProjectSegmentChoice_Description                                                                                
       ,@ImportProjectSegmentChoice_Description                                                                                
           ,@IsCompleted                                                                         
           ,@ImportProjectSegmentChoice_Step --Step                                                                         
     ,@RequestId                                                                    
                                                             --Add Logs to ImportProjectRequest                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                               
  , @TargetSectionId                                                                           
         ,@PUserId                                                                                
         ,@PCustomerId                                                  
           ,@ImportStarted                                                                        
         ,@ImportProjectSegmentChoice_Percentage --Percent                                                                                
         , 0                                                                    
    ,@ImportSource                                                                  
         , @RequestId;                                                                     
                                                                          
SELECT                                                            
 ProjectId                                                            
   ,SectionId                                                            
   ,CustomerId                                       
   ,SegmentChoiceId                                                          
   ,A_SegmentChoiceId INTO #tgtProjectSegmentChoice                                                            
FROM ProjectSegmentChoice WITH (NOLOCK)                         
WHERE ProjectId = @TargetProjectId AND CustomerId = @CustomerId AND SectionId = @TargetSectionId                                           
                                                            
--INSERT INTO CHOICE OPTIONS                                                            
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,                                                            
CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_ChoiceOptionId)                                                            
 SELECT                                                            
  t.SegmentChoiceId                                                            
    ,PCH_Source.SortOrder                                                            
    ,PCH_Source.ChoiceOptionSource                                                            
    ,PCH_Source.OptionJson                                                            
    ,t.ProjectId                                                            
    ,t.SectionId                                                            
    ,t.CustomerId                                  
    ,PCH_Source.ChoiceOptionCode                                                            
    ,@PUserId AS CreatedBy                                                            
    ,GETUTCDATE() AS CreateDate                                
    ,@PUserId AS ModifiedBy                                    
    ,GETUTCDATE() AS ModifiedDate                                                            
    ,PCH_Source.ChoiceOptionId                                                            
 FROM ProjectChoiceOption PCH_Source (NOLOCK)                                               
 INNER JOIN #tgtProjectSegmentChoice t                                                            
  ON PCH_Source.SectionId=@SourceSectionId                                                      
  AND PCH_Source.SegmentChoiceId = t.A_SegmentChoiceId                                                            
 --INNER JOIN ProjectSegmentChoice PCH_Source WITH (NOLOCK)                                                                          
 -- ON PCH_Source.ProjectId = @PSourceProjectId                                                                          
 --  AND PCH_Source.SectionId = @PSourceSectionId                                                                          
 --  AND PCHOP_Source.SegmentChoiceId = PCH_Source.SegmentChoiceId                                                                          
 --INNER JOIN ProjectSegmentChoice PCH_Target WITH (NOLOCK)                                                                          
 -- ON PCH_Target.ProjectId = @PTargetProjectId                                                                          
 --  AND PCH_Target.SectionId = @TargetSectionId                                                                          
 --  AND PCH_Source.SegmentChoiceCode = PCH_Target.SegmentChoiceCode                    
 --INNER JOIN #tmp_TgtSegment PS_Target ON PS_Target.SegmentId = t.SegmentId                                                                  
 WHERE PCH_Source.ProjectId = @PSourceProjectId AND PCH_Source.SectionId = @PSourceSectionId
 AND PCH_Source.CustomerId = @CustomerId
 AND ISNULL(PCH_Source.IsDeleted, 0) = 0                                                            

--- Update the Value of SectionID and SectionTitle choices for user choices for legacy data
--- CSI 78348
drop table if exists #tmpProjectChoiceOption2
select pco.CustomerId
        , pco.ProjectID
        , pco.SectionId
        , pco.ChoiceOptionId
        , pco.OptionJson
        , pco1.optiontypename
        , pco1.SortOrder 
        , pco1.[Value]
        , pco1.[Id]
        , ps.SourceTag
        , ps.Author
        , ps.SectionCode
        , Ps.Description
	into #tmpProjectChoiceOption2
from ProjectChoiceOption pco
	cross apply openjson(pco.OptionJSON)
		WITH (
							OptionTypeName NVARCHAR(200) '$.OptionTypeName',
							[SortOrder] INT '$.SortOrder',
							[Value] NVARCHAR(255) '$.Value',
							[Id] INT '$.Id'
						) pco1
	inner join dbo.projectsection ps on ps.CustomerId=pco.CustomerId										
										and ps.SectionCode=pco1.[Id]
										and ps.ProjectId=@SourceProjectID
where pco.CustomerId=@CustomerID
	and pco.ProjectId=@TargetProjectID
	and pco.SectionId=@TargetSectionId
	and OptionTypeName = 'SectionID'
	and [Id]>1000000 --user added section

if @@Rowcount > 0
begin 
	Update tcp3 set tcp3.OptionJson = JSON_MODIFY(tcp3.optionJson, '$[0].Value', SourceTag)
		from #tmpProjectChoiceOption2 tcp3
			cross apply openjson(tcp3.OptionJson) j
		where tcp3.optiontypename='SectionID'

	Update tcp3 set tcp3.OptionJson = JSON_MODIFY(tcp3.optionJson, '$[2].Value', Description)
		from #tmpProjectChoiceOption2 tcp3
			cross apply openjson(tcp3.OptionJson) j
		where tcp3.optiontypename='SectionID'

	-- Update the Source Document
	Update pco set pco.OptionJson=tcp3.OptionJson
			from #tmpProjectChoiceOption2 tcp3
			inner join dbo.ProjectChoiceOption pco on tcp3.CustomerId=pco.CustomerId
											and tcp3.ProjectId=pco.ProjectId
											and tcp3.SectionId=pco.SectionId
											and tcp3.ChoiceOptionId=pco.ChoiceOptionId
	where pco.CustomerId=@CustomerID 
			and pco.ProjectId=@TargetProjectID
			and pco.SectionId=@TargetSectionID
end
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectChoiceOption_Description                                                                                
           ,@ImportProjectChoiceOption_Description                                                         
          ,@IsCompleted                                                                           
         ,@ImportProjectChoiceOption_Step --Step                                                                         
     ,@RequestId                                                                    
                           
 --Add Logs to ImportProjectRequest                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                         
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
          ,@ImportStarted                                                 
         ,@ImportProjectChoiceOption_Percentage --Percent                         
         , 0                                                                    
   ,@ImportSource                                                                      
         , @RequestId;                                                                     
                                                    
                               
DROP TABLE #tgtProjectSegmentChoice                                                            
                                                            
----INSERT SELECTED CHOICE OPTIONS OF USER CHOICE                                                                         
--INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId)                                                        
-- SELECT DISTINCT                                                            
--  SCHOP_Source.SegmentChoiceCode                                                            
--    ,SCHOP_Source.ChoiceOptionCode                                                            
--    ,SCHOP_Source.ChoiceOptionSource                                                            
--    ,SCHOP_Source.IsSelected                                                            
--    ,@TargetSectionId AS SectionId                                                            
--    ,@PTargetProjectId AS ProjectId                                                            
--    ,@PCustomerId AS CustomerId                                                            
-- FROM SelectedChoiceOption SCHOP_Source WITH (NOLOCK)                 
-- --INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)                                                            
-- -- ON PSC.SectionId = SCHOP_Source.SectionId                                       
-- --  AND PSC.ProjectId = SCHOP_Source.ProjectId                                                            
-- --  AND PSC.SegmentChoiceCode = SCHOP_Source.SegmentChoiceCode                                                            
-- --INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)                                                            
-- -- ON PCO.SegmentChoiceId = PSC.SegmentChoiceId                                                            
-- --  AND PCO.SectionId = PCO.SectionId                                                            
-- --  AND PCO.ChoiceOptionCode=SCHOP_Source.ChoiceOptionCode                                                          
-- --  AND SCHOP_Source.SegmentChoiceCode=PSC.SegmentChoiceCode                                                          
-- --  AND PCO.ProjectId = SCHOP_Source.ProjectId                                                  
-- --INNER JOIN #tmp_TgtSegment PS_Target                                                                    
-- -- ON PSC.SegmentId = PS_Target.SegmentId                                                                    
-- WHERE SCHOP_Source.SectionId = @PSourceSectionId                                                          
-- AND SCHOP_Source.ProjectId = @PSourceProjectId                                           
-- AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0                                                            
-- --AND ISNULL(PS_Target.IsDeleted, 0) = 0                                                                  
-- AND SCHOP_Source.ChoiceOptionSource = 'U'                                                            
                                   
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportSelectedChoiceOption_USERCHOICE_Description                                                                                
          ,@ImportSelectedChoiceOption_USERCHOICE_Description                                                                                
           ,@IsCompleted                                                                            
           ,@ImportSelectedChoiceOption_USERCHOICE_Step --Step                                                                         
     ,@RequestId                                                                    
                                                                   
 --Add Logs to ImportProjectRequest                                                                     
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                            
         ,@PTargetProjectId                                          
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                           
         ,@PUserId                                                              
         ,@PCustomerId                                                                                
         ,@ImportStarted                                                                           
        ,@ImportSelectedChoiceOption_USERCHOICE_Percentage --Percent                                 
         , 0                                                                    
   ,@ImportSource                                                          
         , @RequestId;                                                    
                                                                          
--INSERT SELECTED CHOICE OPTIONS OF MASTER CHOICE                                                                        
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson)                                                            
 SELECT        
  SCHOP_Source.SegmentChoiceCode                                 
    ,SCHOP_Source.ChoiceOptionCode                                                            
    ,SCHOP_Source.ChoiceOptionSource                                                            
    ,SCHOP_Source.IsSelected                                                            
    ,@TargetSectionId AS SectionId                                                         
    ,@PTargetProjectId AS ProjectId                                                            
    ,@PCustomerId AS CustomerId                                                            
    ,SCHOP_Source.OptionJson                                                            
 FROM SelectedChoiceOption SCHOP_Source WITH (NOLOCK)                                                            
 WHERE SCHOP_Source.ProjectId = @PSourceProjectId AND SCHOP_Source.CustomerId = @CustomerId AND SCHOP_Source.SectionId = @PSourceSectionId                                                       
 AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0                                            
 --AND SCHOP_Source.ChoiceOptionSource = 'M'                                                            
                                                            
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                  
           ,@ImportSelectedChoiceOption_MASTERCHOICE_Description                                                                                
          ,@ImportSelectedChoiceOption_MASTERCHOICE_Description                                                                                
           ,@IsCompleted                                                                     
           ,@ImportSelectedChoiceOption_MASTERCHOICE_Step --Step                                                                         
     ,@RequestId                                 
                                                                    
 --Add Logs to ImportProjectRequest                                                 
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                       
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
          ,@ImportStarted                                                                       
    ,@ImportSelectedChoiceOption_MASTERCHOICE_Percentage --Percent                                                            
 , 0                                                                    
   ,@ImportSource                                                                 
         , @RequestId;                                                                          
                                                                          
--INSERT NOTE                                                                          
INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy,                                                            
CreatedUserName, ModifiedUserName, IsDeleted, NoteCode, A_NoteId)                                  
 SELECT                                                            
  t.SectionId                                                            
    ,t.SegmentStatusId                                                            
    ,PN.NoteText                                                            
    ,GETUTCDATE() AS CreateDate                                                            
    ,GETUTCDATE() AS ModifiedDate                                                            
    ,t.ProjectId                                                            
    ,t.CustomerId                                                            
    ,PN.Title                                                            
   ,t.CreatedBy                                                            
    ,t.ModifiedBy                                                            
    ,@PUserName AS CreatedUserName                                                            
    ,@PUserName AS ModifiedUserName                                                            
    ,PN.IsDeleted                                                            
    ,PN.NoteCode                                                            
    ,PN.NoteId AS A_NoteId                                     
 FROM ProjectNote PN WITH (NOLOCK)                                                        
 INNER JOIN #tmp_TgtSegmentStatus t                                                            
  ON PN.SectionId=@SourceSectionId                                                      
 AND PN.SegmentStatusId = t.A_SegmentStatusId                                                            
 --INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                                                                          
 -- ON PN.SegmentStatusId = PSS_Source.SegmentStatusId                                                                  
 --INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)                    
 -- ON PSS_Source.SegmentStatusCode = PSS_Target.SegmentStatusCode                                                                          
 WHERE PN.SectionId = @PSourceSectionId                                            
 AND PN.ProjectId = @PSourceProjectId                                                            
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectNote_Description                                                                                
          ,@ImportProjectNote_Description                                              
         ,@IsCompleted                                                                
           ,@ImportProjectNote_Step --Step                                                                         
     ,@RequestId;                                                                    
                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                      
  ,@PSourceSectionId                                                                    
  , @TargetSectionId                 
         ,@PUserId                                                                   
         ,@PCustomerId                                                                                
           ,@ImportStarted                                                                   
       ,@ImportProjectNote_Percentage --Percent                                                                                
         , 0                                                                    
    ,@ImportSource                                                                   
         , @RequestId;                                                                             
                                                                          
SELECT                                                            
 * INTO #note                                                            
FROM ProjectNote WITH (NOLOCK)                                                            
WHERE SectionId = @TargetSectionId                                                            
AND ProjectId = @TargetProjectId                                                   
                                                            
--INSERT Project Note Images                                                                          
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)                                                            
 SELECT                                                            
  t.NoteId                                                            
    ,t.SectionId                                         
    ,ImageId                                                            
    ,t.ProjectId                                                            
    ,t.CustomerId                                                         
 FROM ProjectNoteImage PNI WITH (NOLOCK)                                                            
 INNER JOIN #note t WITH (NOLOCK)                                       
  ON PNI.NoteId = t.A_NoteId                                                            
 --INNER JOIN ProjectNote PN_Target WITH (NOLOCK)                                                                          
 -- ON PN_Target.ProjectId = @PTargetProjectId                                                                          
 --  AND PN_Target.SectionId = @TargetSectionId                                                                          
 --  AND PN_Source.NoteCode = PN_Target.NoteCode                                                                          
 WHERE PNI.SectionId = @PSourceSectionId                                                            
 AND PNI.ProjectId = @PSourceProjectId                                                            
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectNoteImage_Description                                                                                
          ,@ImportProjectNoteImage_Description                                                                                
          ,@IsCompleted                                                                   
           ,@ImportProjectNoteImage_Step --Step                                            
     ,@RequestId;                                                                
                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                 
     ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                      
  , @TargetSectionId                                                                           
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
          ,@ImportStarted                                                                         
       ,@ImportProjectNoteImage_Percentage --Percent                                                                                
         , 0                                                                    
    ,@ImportSource                                                                 
         , @RequestId;                                                                        
                            
DROP TABLE #note                                                            
                                                            
--INSERT ProjectSegmentImage                                                                          
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)                                                            
 SELECT                                                            
  @TargetSectionId AS SectionId                          
    ,ImageId                                                            
    ,@PTargetProjectId AS ProjectId                             
    ,@PCustomerId AS CustomerId                                                            
    ,0 AS SegmentId                                                            
 ,PSI.ImageStyle                                                           
 FROM ProjectSegmentImage PSI WITH (NOLOCK)                                                            
 WHERE PSI.SectionId = @PSourceSectionId                                                                 
 AND PSI.ProjectId = @PSourceProjectId                                                       
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectSegmentImage_Description                                                                                
          ,@ImportProjectSegmentImage_Description                                                                                
          ,@IsCompleted                                                                    
  ,@ImportProjectSegmentImage_Step --Step                                                                         
     ,@RequestId;                                                                   
                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                          
         ,@PUserId                                                                                
         ,@PCustomerId                                                                    
          ,@ImportStarted                                                                   
       ,@ImportProjectSegmentImage_Percentage --Percent                                                 
         , 0                                                                    
    ,@ImportSource                                                                 
         , @RequestId;                                              
                                                          
--INSERT ProjectReferenceStandard                                                 
                                              
IF EXISTS (SELECT                                                
   Top 1 ProjectId                                               
  FROM ProjectReferenceStandard WITH (NOLOCK)                                               
  WHERE ProjectId = @TargetProjectId)                                                
BEGIN                                                
   SELECT                                                                              
    PRS.RefStandardId                                                
   ,max(RSE.RefStdEditionId) AS RefStdEditionId                               
 INTO #RSlatestEdition                                                             
 FROM ProjectReferenceStandard  PRS  WITH (NOLOCK)  INNER  JOIN                                                  
  ReferenceStandardEdition RSE WITH (NOLOCK) on PRS.RefStandardId=RSE.RefStdId                                                          
 WHERE PRS.SectionId = @TargetSectionId                                                              
 AND   PRS.ProjectId = @TargetProjectId                                                              
 AND ISNULL(PRS.IsDeleted, 0) = 0                                                  
 Group by PRS.RefStandardId                                        
                                                
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete,                                                                
RefStdCode, PublicationDate, SectionId, CustomerId)                                     
 SELECT                                                                
  @PTargetProjectId AS ProjectId                                                                
    ,PRS.RefStandardId                                                                
    ,PRS.RefStdSource                                                                
    ,PRS.mReplaceRefStdId                                                                
    ,TRS.RefStdEditionId                                                            
    ,PRS.IsObsolete                                                                
    ,PRS.RefStdCode                                                       
    ,PRS.PublicationDate                                                                
    ,@TargetSectionId AS SectionId                                                               
    ,@PCustomerId AS CustomerId                                                                
 FROM ProjectReferenceStandard PRS WITH (NOLOCK) INNER JOIN #RSlatestEdition TRS  ON PRS.RefStandardId=TRS.RefStandardId                                                             
 WHERE PRS.SectionId = @PSourceSectionId                                                                
 AND   PRS.ProjectId = @PSourceProjectId                                                              
 AND ISNULL(PRS.IsDeleted, 0) = 0                                                  
 END                                               
 ELSE                                                
 BEGIN                                                
    INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete,                                                                
RefStdCode, PublicationDate, SectionId, CustomerId)                                                                
 SELECT                      
  @PTargetProjectId AS ProjectId                                                                
    ,RefStandardId                                    
    ,RefStdSource                                                                
    ,mReplaceRefStdId                                                            
    ,RefStdEditionId                                                                
    ,IsObsolete                                                                
    ,RefStdCode                                                       
    ,PublicationDate                                                                
    ,@TargetSectionId AS SectionId                                                                
    ,@PCustomerId AS CustomerId                                                                
 FROM ProjectReferenceStandard WITH (NOLOCK)                                                                
 WHERE SectionId = @PSourceSectionId                                                                
 AND   ProjectId = @PSourceProjectId                                                              
 AND ISNULL(IsDeleted, 0) = 0                                                             
   END                                                   
                                
DECLARE	@MasterSectionId INT = NULL
DECLARE @PMasterSectionId AS INT = @MasterSectionId;
IF ISNULL(@PMasterSectionId,0) = 0
BEGIN 
	SET @PMasterSectionId = (SELECT TOP 1  
	mSectionId  
	FROM ProjectSection WITH (NOLOCK)  
	WHERE ProjectId = @TargetProjectId  
	AND CustomerId = @PCustomerId  
	AND SectionId = @TargetSectionId);  
END;

DROP TABLE IF EXISTS #tempRefStds 
SELECT  
  rs.RefStdId  
  ,rs.MasterDataTypeId  
  ,rs.RefStdName  
  ,rs.ReplaceRefStdId  
  ,rs.IsObsolete  
  ,rs.RefStdCode  
  ,rs.CreateDate  
  ,rs.ModifiedDate  
  ,rs.PublicationDate  
  ,MAX(rse.RefStdEditionId) AS RefStdEditionId INTO #tempRefStds  
FROM [SLCMaster].[dbo].ReferenceStandard AS rs WITH (NOLOCK)  
INNER JOIN [SLCMaster].[dbo].ReferenceStandardEdition AS rse WITH (NOLOCK)  
ON rs.RefStdId = rse.RefStdId  
INNER JOIN [SLCMaster].[dbo].SegmentReferenceStandard SRS WITH (NOLOCK)  
ON SRS.RefStandardId = rs.RefStdId  
WHERE SRS.SectionId = @PMasterSectionId  
GROUP BY rs.RefStdId  
  ,rs.MasterDataTypeId  
  ,rs.RefStdName  
  ,rs.ReplaceRefStdId  
  ,rs.IsObsolete  
  ,rs.RefStdCode  
  ,rs.CreateDate  
  ,rs.ModifiedDate  
  ,rs.PublicationDate;   

DROP TABLE IF EXISTS #temptablePRS 
SELECT 
  @PTargetProjectId AS ProjectId                                                                
  ,RefStandardId                                    
  ,RefStdSource                                                                
  ,mReplaceRefStdId                                                            
  ,RefStdEditionId                                                                
  ,IsObsolete                                                                
  ,RefStdCode                                                       
  ,PublicationDate                                                                
  ,@TargetSectionId AS SectionId                                                                
  ,@PCustomerId AS CustomerId 
INTO #temptablePRS FROM ProjectReferenceStandard WITH (NOLOCK) WHERE ProjectId = @PSourceProjectId AND SectionId = @PSourceSectionId  

-- updating temp table #temptablePRS with minimum RefStdEditionId which is present in the project for the customer
UPDATE t1 SET t1.RefStdEditionId = t2.RefStdEditionId
  FROM #temptablePRS t1
    INNER JOIN (
        SELECT ProjectId, RefStandardId, RefStdSource, RefStdEditionId, ROW_NUMBER() OVER (PARTITION BY RefStandardId ORDER BY RefStdEditionId ASC) RowNo
        FROM ProjectReferenceStandard 
		WHERE CustomerId = @PCustomerId 
		AND ProjectId = @TargetProjectId 
		AND ISNULL(IsDeleted,0) = 0
        ) 
		t2 ON t1.RefStandardId = t2.RefStandardId 
		AND t2.RowNo = 1;
 
-- #RSlatestEdition doesnot hold data to import, here importing minimum refEditionId of the project for [dbo].[ProjectReferenceStandard]
INSERT INTO [dbo].[ProjectReferenceStandard] (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)  
SELECT  
  tempTable.ProjectId  
  ,tempTable.RefStandardId  
  ,'M' AS RefStdSource  
  ,tempTable.mReplaceRefStdId  
  ,tempTable.RefStdEditionId  
  ,tempTable.IsObsolete  
  ,tempTable.RefStdCode  
  ,tempTable.PublicationDate  
  ,tempTable.SectionId  
  ,@PCustomerId  
FROM #temptablePRS AS tempTable WHERE RefStandardId NOT IN (SELECT RefStdId FROM #tempRefStds)                                                          
                                                            
   EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectReferenceStandard_Description                                                      
          ,@ImportProjectReferenceStandard_Description                                                
         ,@IsCompleted                                                          
           ,@ImportProjectReferenceStandard_Step --Step                                                                      
     ,@RequestId;                                                           
                                                                    
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                           
         ,@PUserId                                                                        
         ,@PCustomerId                                    
          ,@ImportStarted                                    
       ,@ImportProjectReferenceStandard_Percentage --Percent                                                                                
         , 0                                                            
   ,@ImportSource                        
         , @RequestId;                                                                           
                                                                          
--INSERT ProjectSegmentReferenceStandard                                                              
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate,                                                                          
CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode, IsDeleted)                                                                          
 SELECT                                                        
  @TargetSectionId AS SectionId                                                                          
    ,PS_Target.SegmentId                                                                          
    ,RefStandardId    
    ,RefStandardSource                                                                          
    ,mRefStandardId                                                                          
    ,GETUTCDATE() AS CreateDate                                                                          
  ,@PUserId AS CreatedBy                                                                          
    ,GETUTCDATE() AS ModifiedDate                                  ,@PUserId AS ModifiedBy                                                                          
    ,@PCustomerId AS CustomerId                                                                          
    ,@PTargetProjectId AS ProjectId                                                                          
    ,mSegmentId                                                                          
    ,RefStdCode                                                                          
    ,PSRS.IsDeleted                                                         
 FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)                                                        
 --INNER JOIN #tmp_SrcSegment PS_Source WITH (NOLOCK)                                                                                
 -- ON PSRS.SegmentId = PS_Source.SegmentId                                                              
 INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)                                                                          
  ON PSRS.SegmentId = PS_Target.A_SegmentId                                                             
 WHERE PSRS.ProjectId = @PSourceProjectId AND PSRS.SectionId = @PSourceSectionId
                                                                     
EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
  ,@ImportProjectSegmentReferenceStandard_Description                                                           
          ,@ImportProjectSegmentReferenceStandard_Description                                                                                
       ,@IsCompleted                                                                        
           ,@ImportProjectSegmentReferenceStandard_Step --Step                                      
     ,@RequestId;                                                                    
                                                                    
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                           
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
         ,@ImportStarted                                                                    
       ,@ImportProjectSegmentReferenceStandard_Percentage --Percent                                                                               
         , 0                                                                    
   ,@ImportSource                                                 , @RequestId;                                                                              
                                 
--INSERT ProjectSegmentRequirementTag             
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId,                                                            
CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId)                                                    
 SELECT                                                     
  @TargetSectionId AS SectionId                                                            
    ,PSS_Target.SegmentStatusId                                                            
    ,PSRT.RequirementTagId                                                            
    ,PSRT.CreateDate                                                            
    ,PSRT.ModifiedDate                                                            
    ,@PTargetProjectId AS ProjectId                                                            
    ,@PCustomerId AS CustomerId                                                            
    ,PSRT.CreatedBy                                                   
    ,PSRT.ModifiedBy                                                            
    ,PSRT.mSegmentRequirementTagId                                                            
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                                                            
 --INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                                                                          
 -- ON PSRT.SegmentStatusId = PSS_Source.SegmentStatusId                                                                          
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)                                                            
  ON PSRT.SegmentStatusId = PSS_Target.A_SegmentStatusId                                                            
 WHERE PSRT.ProjectId = @PSourceProjectId                                                            
 AND PSRT.SectionId = @PSourceSectionId                                                            
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                               
           ,@ImportProjectSegmentRequirementTag_Description                                          
          ,@ImportProjectSegmentRequirementTag_Description                                                
           ,@IsCompleted                                                                        
           ,@ImportProjectSegmentRequirementTag_Step --Step                                                                          
           ,@RequestId;                                                                    
                                                                    
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                              
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                           
         ,@PUserId                                                                          
         ,@PCustomerId                                                                                
           ,@ImportStarted                                                                      
       ,@ImportProjectSegmentRequirementTag_Percentage --Percent                                                                                
         , 0                                                                    
    ,@ImportSource                                                                 
       , @RequestId;                                                                              
                                                                          
--INSERT ProjectSegmentUserTag                                                                          
INSERT INTO ProjectSegmentUserTag (SectionId, SegmentStatusId, UserTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)                                                     
 SELECT                                                            
  @TargetSectionId AS SectionId                                                            
    ,PSS_Target.SegmentStatusId                  
    ,PSUT.UserTagId                                                            
   ,PSUT.CreateDate                                                            
    ,PSUT.ModifiedDate                                                            
    ,@PTargetProjectId AS ProjectId                                                     
 ,@PCustomerId AS CustomerId                                                            
    ,PSUT.CreatedBy                                                         
    ,PSUT.ModifiedBy                                                            
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                                                            
 --INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                                                                          
 -- ON PSUT.SegmentStatusId = PSS_Source.SegmentStatusId                                                                          
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)                                                      
  ON PSUT.SegmentStatusId = PSS_Target.A_SegmentStatusId                               
 WHERE PSUT.CustomerId = @CustomerId AND PSUT.ProjectId = @PSourceProjectId AND PSUT.SectionId = @PSourceSectionId
                                                            
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                
           ,@ImportProjectSegmentUserTag_Description                                                                                
   ,@ImportProjectSegmentUserTag_Description                                                                                
          ,@IsCompleted                                          
           ,@ImportProjectSegmentUserTag_Step --Step                                                                         
     ,@RequestId;                                                             
                                                                    
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                                
         ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                 
  , @TargetSectionId                                                                           
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
           ,@ImportStarted                                                                          
       ,@ImportProjectSegmentUserTag_Percentage --Percent                                                                                
         , 0                                                                    
   ,@ImportSource                                                                 
         , @RequestId;                                                                           
                                                                          
--INSERT Header                                                                          
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy,                                                            
CreatedDate, ModifiedBy, ModifiedDate, TypeId,AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId,           
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId,
IsShowLineAboveHeader,IsShowLineBelowHeader)                                                            
 SELECT                                                            
  @PTargetProjectId AS ProjectId,@TargetSectionId AS SectionId,@PCustomerId AS CustomerId,Description,IsLocked,LockedByFullName,LockedBy,ShowFirstPage,@PUserId AS CreatedBy                                                            
    ,GETUTCDATE() AS CreatedDate,ModifiedBy,GETUTCDATE() AS ModifiedDate,TypeId,AltHeader,FPHeader,UseSeparateFPHeader,HeaderFooterCategoryId
    ,[DateFormat],TimeFormat,HeaderFooterDisplayTypeId,DefaultHeader,FirstPageHeader,OddPageHeader,EvenPageHeader,DocumentTypeId
    ,IsShowLineAboveHeader
    ,IsShowLineBelowHeader
 FROM Header WITH (NOLOCK)                                                            
 WHERE SectionId = @PSourceSectionId                                          
 AND ProjectId = @PSourceProjectId                                                        
                                                            
EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                  
        ,@ImportHeader_Description                                                                                
          ,@ImportHeader_Description                                                                                
         ,@IsCompleted                                                                       
           ,@ImportHeader_Step --Step                                                                         
     ,@RequestId;                                                                    
                                                                
EXEC usp_MaintainImportProjectProgress @PSourceProjectId            
       ,@PTargetProjectId                                                                         
   ,@PSourceSectionId                                                                    
  , @TargetSectionId                                                                           
         ,@PUserId                                                                                
         ,@PCustomerId                                                                                
          ,@ImportStarted                                                          
       ,@ImportHeader_Percentage --Percent                                                
         , 0                                                                    
   ,@ImportSource                                                                 
         , @RequestId;                                                                         
                                                                          
--INSERT Footer                                                                          
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, 
CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId,           
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,
IsShowLineAboveFooter,IsShowLineBelowFooter)                                                                    
 SELECT @PTargetProjectId AS ProjectId,@TargetSectionId AS SectionId,@PCustomerId AS CustomerId,Description ,IsLocked,LockedByFullName,LockedBy,ShowFirstPage,@PUserId AS CreatedBy                                                                    
    ,GETUTCDATE() AS CreatedDate,ModifiedBy,GETUTCDATE() AS ModifiedDate,TypeId,AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId,
    [DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,
IsShowLineAboveFooter,IsShowLineBelowFooter
 FROM Footer WITH (NOLOCK)                                                                
 WHERE SectionId = @PSourceSectionId                                                                    
 AND  ProjectId = @PSourceProjectId                                                                 
                                                               
EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
           ,@ImportFooter_Description                                                                 
          ,@ImportFooter_Description                                                                          
         ,@IsCompleted                                                                      
           ,@ImportFooter_Step --Step                                                                   
     ,@RequestId;                                                              
                                                              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                          
         ,@PTargetProjectId                                                                   
   ,@PSourceSectionId                                                              
  , @TargetSectionId                                                                     
         ,@PUserId                                        
         ,@PCustomerId                                
          ,@ImportStarted                         
       ,@ImportFooter_Percentage --Percent                                             
         , 0                                                              
    ,@ImportSource                                                           
         , @RequestId;                                      

--INSERT ProjectSegmentGlobalTerm                                                                    
INSERT INTO ProjectSegmentGlobalTerm (SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, CreatedDate,                                                      
CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, IsLocked, LockedByFullName, UserLockedId, IsDeleted)                                                      
 SELECT                                 
  @TargetSectionId AS SectionId                                                      
    ,PS_Target.SegmentId                                                      
    ,mSegmentId                                                      
    ,UserGlobalTermId                                                      
    ,GlobalTermCode                                                      
    ,GETUTCDATE() AS CreatedDate                                                      
    ,@PUserId AS CreatedBy                                                      
    ,GETUTCDATE() AS ModifiedDate                                                      
    ,@PUserId AS ModifiedBy                                                      
    ,@PCustomerId AS CustomerId                                                      
    ,@PTargetProjectId AS ProjectId                                                      
    ,IsLocked                                                
    ,LockedByFullName                                            
    ,UserLockedId                                                      
 ,PSGT.IsDeleted                                                      
 FROM ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)          
 --INNER JOIN #tmp_SrcSegment PS_Source WITH (NOLOCK)                                                                    
 -- ON PSGT.SegmentId = PS_Source.SegmentId                                                             
 INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)                                      
  ON PS_Target.SegmentId = PS_Target.A_SegmentId                                     
 WHERE PSGT.ProjectId = @PSourceProjectId AND PSGT.SectionId = @PSourceSectionId
                                                      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
           ,@ImportProjectSegmentGlobalTerm_Description                                  
          ,@ImportProjectSegmentGlobalTerm_Description                                                                          
          ,@IsCompleted                                                                           
           ,@ImportProjectSegmentGlobalTerm_Step --Step                                                                   
     ,@RequestId;                                                              
                                                              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                       ,@PTargetProjectId                                                                   
   ,@PSourceSectionId                                                              
  , @TargetSectionId                                                                     
         ,@PUserId                                                                          
         ,@PCustomerId                                                                          
         ,@ImportStarted           
       ,@ImportProjectSegmentGlobalTerm_Percentage --Percent                                                                          
         , 0                                                              
   ,@ImportSource                                                           
         , @RequestId;                                                    
                                                                    
SELECT                                                      
 * INTO #PrjSegGblTerm                                
FROM ProjectSegmentGlobalTerm WITH (NOLOCK)                                                      
WHERE ProjectId = @TargetProjectId AND SectionId = @TargetSectionId                                                      
                                                      
--INSERT ProjectGlobalTerm                                                                    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value, GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy,                                                      
ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)                                                   
 SELECT                                                      
  PGT_Source.mGlobalTermId                                                      
    ,@PTargetProjectId ProjectId                                                      
    ,@PCustomerId AS CustomerId                                                      
    ,PGT_Source.Name                                                      
    ,PGT_Source.value                                                      
 ,PGT_Source.GlobalTermSource                                                       ,PGT_Source.GlobalTermCode                                                      
    ,GETUTCDATE() AS CreatedDate                                                      
    ,@PUserId AS CreatedBy                                                      
    ,GETUTCDATE() AS ModifiedDate                                           
    ,@PUserId AS ModifiedBy                                      
    ,PGT_Source.UserGlobalTermId                                                      
    ,PGT_Source.IsDeleted                                              
 FROM ProjectGlobalTerm PGT_Source WITH (NOLOCK)                                                      
 INNER JOIN #PrjSegGblTerm PSGT_Source WITH (NOLOCK)                                                      
  ON PGT_Source.GlobalTermCode = PSGT_Source.GlobalTermCode                                                      
 --  AND PGT_Source.GlobalTermCode = PSGT_Source.GlobalTermCode                                                                    
 --LEFT JOIN ProjectGlobalTerm PGT_Target WITH (NOLOCK)                                                                    
 -- ON PGT_Target.ProjectId = @PTargetProjectId                                                                    
 --  AND PGT_Source.GlobalTermCode = PGT_Target.GlobalTermCode                                                                    
 WHERE PSGT_Source.SectionId = @PSourceSectionId                                                      
 AND PGT_Source.ProjectId = @PSourceProjectId                                                      
 AND PSGT_Source.IsDeleted = 0                                                      
                                                      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
           ,@ImportProjectGlobalTerm_Description                                                                          
          ,@ImportProjectGlobalTerm_Description                                                                    
       ,@IsCompleted                                                                         
            ,@ImportProjectGlobalTerm_Step --Step     
     ,@RequestId;                                                             
                                                              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                          
         ,@PTargetProjectId                                     
   ,@PSourceSectionId                                                              
, @TargetSectionId                    
         ,@PUserId                                                          
         ,@PCustomerId                                                                          
          ,@ImportStarted                                                             
        ,@ImportProjectGlobalTerm_Percentage --Percent                                                                          
         , 0                                                              
   ,@ImportSource                                                           
         , @RequestId;                                                           
                                                                    
SELECT                                                      
 * INTO #tmp_SrcSegmentLink                                                      
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)                                                     
WHERE PSLNK.ProjectId = @PSourceProjectId                                                      
AND (PSLNK.SourceSectionCode = @SectionCode                                      
OR PSLNK.TargetSectionCode = @SectionCode)                                                      
AND ISNULL(PSLNK.IsDeleted, 0)=0;                                                      
          
SELECT                                                      
 * INTO #tmp_TgtSegmentLink                                                      
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)                                                      
WHERE PSLNK.ProjectId = @PTargetProjectId                                                      
AND (PSLNK.SourceSectionCode = @SectionCode                                                      
OR PSLNK.TargetSectionCode = @SectionCode)                                          
AND ISNULL(PSLNK.IsDeleted, 0)=0;                                                      
                                                      
--INSERT ProjectSegmentLink                                                                    
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,                                                     
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,                                                      
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,                          
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,                                                      
ProjectId, CustomerId, SegmentLinkSourceTypeId)                                                      
 SELECT                                                      
  PSLNK_Source.SourceSectionCode AS SourceSectionCode                                             
    ,PSLNK_Source.SourceSegmentStatusCode AS SourceSegmentStatusCode                                                      
    ,PSLNK_Source.SourceSegmentCode AS SourceSegmentCode                                                      
    ,PSLNK_Source.SourceSegmentChoiceCode AS SourceSegmentChoiceCode                                                      
    ,PSLNK_Source.SourceChoiceOptionCode AS SourceChoiceOptionCode                                                      
    ,PSLNK_Source.LinkSource AS LinkSource                                                      
    ,PSLNK_Source.TargetSectionCode AS TargetSectionCode                                                      
    ,PSLNK_Source.TargetSegmentStatusCode AS TargetSegmentStatusCode                                                      
    ,PSLNK_Source.TargetSegmentCode AS TargetSegmentCode                                                      
    ,PSLNK_Source.TargetSegmentChoiceCode AS TargetSegmentChoiceCode                                                      
    ,PSLNK_Source.TargetChoiceOptionCode AS TargetChoiceOptionCode                                                      
    ,PSLNK_Source.LinkTarget AS LinkTarget                                                      
    ,PSLNK_Source.LinkStatusTypeId AS LinkStatusTypeId                                                      
  ,PSLNK_Source.IsDeleted AS IsDeleted                                                      
    ,GETUTCDATE() AS CreateDate                                                      
    ,@PUserId AS CreatedBy                                                      
    ,@PUserId AS ModifiedBy                                                      
    ,GETUTCDATE() AS ModifiedDate                                                      
    ,@PTargetProjectId AS ProjectId                                                      
    ,@PCustomerId AS CustomerId                                                      
    ,PSLNK_Source.SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId                                                      
 FROM #tmp_SrcSegmentLink PSLNK_Source WITH (NOLOCK)                                                      
 LEFT JOIN #tmp_TgtSegmentLink PSLNK_Target WITH (NOLOCK)                                                      
  ON PSLNK_Source.SourceSectionCode = PSLNK_Target.SourceSectionCode                                                      
   AND PSLNK_Source.SourceSegmentStatusCode = PSLNK_Target.SourceSegmentStatusCode                                                      
   AND PSLNK_Source.SourceSegmentCode = PSLNK_Target.SourceSegmentCode                                                      
   AND ISNULL(PSLNK_Source.SourceSegmentChoiceCode, 0) = ISNULL(PSLNK_Target.SourceSegmentChoiceCode, 0)                                                   
   AND ISNULL(PSLNK_Source.SourceChoiceOptionCode, 0) = ISNULL(PSLNK_Target.SourceChoiceOptionCode, 0)                                                      
   AND PSLNK_Source.LinkSource = PSLNK_Target.LinkSource                                   
   AND PSLNK_Source.TargetSectionCode = PSLNK_Target.TargetSectionCode                                                      
   AND PSLNK_Source.TargetSegmentStatusCode = PSLNK_Target.TargetSegmentStatusCode                                                      
   AND PSLNK_Source.TargetSegmentCode = PSLNK_Target.TargetSegmentCode                                                      
   AND ISNULL(PSLNK_Source.TargetSegmentChoiceCode, 0) = ISNULL(PSLNK_Target.TargetSegmentChoiceCode, 0)                                                      
   AND ISNULL(PSLNK_Source.TargetChoiceOptionCode, 0) = ISNULL(PSLNK_Target.TargetChoiceOptionCode, 0)                                                      
   AND PSLNK_Source.LinkTarget = PSLNK_Target.LinkTarget                                
   AND PSLNK_Source.SegmentLinkSourceTypeId = PSLNK_Target.SegmentLinkSourceTypeId                                     
 WHERE PSLNK_Target.SegmentLinkId IS NULL                                              
                                                       
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
           ,@ImportProjectSegmentLink_Description                                                                          
          ,@ImportProjectSegmentLink_Description                                                   
      ,@IsCompleted                                                                       
            ,@ImportProjectSegmentLink_Step --Step                                                                   
     ,@RequestId;                                                              
         
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                               
         ,@PTargetProjectId                                                                   
   ,@PSourceSectionId                                                              
  , @TargetSectionId                                                                     
         ,@PUserId                                                                          
         ,@PCustomerId                                                                          
          ,@ImportStarted                                                             
        ,@ImportProjectSegmentLink_Percentage --Percent                                                  
         , 0                                                 
    ,@ImportSource                                          
         , @RequestId;                                                                   
                                                 
--- INSERT ProjectHyperLink                                                              
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,                                                      
CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy                                                      
, A_HyperLinkId)                                                      
 SELECT                                                      
  @TargetSectionId                                                      
    ,PSS_Target.SegmentId                  
    ,PSS_Target.SegmentStatusId                                                      
    ,@TargetProjectId                                                      
    ,PSS_Target.CustomerId                                                      
    ,LinkTarget                                                      
    ,LinkText                                                      
    ,LuHyperLinkSourceTypeId                                                      
    ,GETUTCDATE()                                              
    ,@UserId                                                      
    ,PHL.HyperLinkId                                                      
 FROM ProjectHyperLink PHL WITH (NOLOCK)                                   
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target                                                      
  ON PHL.SegmentStatusId = PSS_Target.A_SegmentStatusId                                                      
 WHERE PHL.SectionId = @PSourceSectionId                                                   
 AND PHL.ProjectId = @PSourceProjectId                         
                                                      
---UPDATE NEW HyperLinkId in SegmentDescription                                                             
                                                      
DECLARE @MultipleHyperlinkCount INT = 0;                                                      
SELECT                                                      
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl                                                      
FROM ProjectHyperLink WITH(NOLOCK)                                                      
WHERE SectionId = @TargetSectionId                                                       
AND  ProjectId = @TargetProjectId                                                    
GROUP BY SegmentStatusId                                                      
SELECT                                                      
 @MultipleHyperlinkCount = MAX(TotalCountSegmentStatusId)                                                      
FROM #TotalCountSegmentStatusIdTbl                                                      
WHILE (@MultipleHyperlinkCount > 0)                                                      
BEGIN                                                      
                                                      
UPDATE PS                                                      
SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')                          
FROM ProjectHyperLink PHL WITH (NOLOCK)                                                      
INNER JOIN ProjectSegment PS WITH (NOLOCK)                                                      
 ON PS.SegmentStatusId = PHL.SegmentStatusId                                                      
 AND PS.SegmentId = PHL.SegmentId                                                      
 AND PS.SectionId = PHL.SectionId                                                      
 AND PS.ProjectId = PHL.ProjectId                                                      
 AND PS.CustomerId = PHL.CustomerId                                                      
WHERE PHL.SectionId = @TargetSectionId                                             
AND PHL.ProjectId = @TargetProjectId                                                      
AND PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%'                 
AND PS.SegmentDescription LIKE '%{HL#%'                                                      
SET @MultipleHyperlinkCount =@MultipleHyperlinkCount-1;                                                
END                                                      
                                                    
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                  
           ,@ImportProjectHyperLink_Description                                                                          
          ,@ImportProjectHyperLink_Description                                              
      ,@IsCompleted                                                                      
            ,@ImportProjectHyperLink_Step --Step                                                                   
     ,@RequestId;                                                              
                                                              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                          
         ,@PTargetProjectId                                                                   
   ,@PSourceSectionId                                                              
  , @TargetSectionId                       
         ,@PUserId                                                                          
         ,@PCustomerId                                                                          
           ,@ImportStarted                                                             
        ,@ImportProjectHyperLink_Percentage --Percent                                                                          
         , 0                                                              
    ,@ImportSource                                                     
         , @RequestId;                                      
--- For Import from Project Track Changes                                  
                               
 DECLARE @tempTrackChanges TABLE ( SegmentStatusID BIGINT,SegmentStatusTypeId INT,PrevStatusSegmentStatusTypeId INT                                  
 ,InitialStatusSegmentStatusTypeId INT,IsAccepted BIT,UserId INT ,UserFullName NVARCHAR(100),CreatedDate Date,ModifiedById INT,ModifiedByUserFullName NVARCHAR(100)                                  
,ModifiedDate Date,TenantId INT,InitialStatus NVARCHAR(50),IsSegmentStatusChangeBySelection NVARCHAR(50),CurrentStatus BIT)                                  
                                   
 INSERT INTO @tempTrackChanges                                  
 SELECT                                  
 t.SegmentStatusId                                   
,tss.SegmentStatusTypeId                                   
,tss.PrevStatusSegmentStatusTypeId                                   
,tss.InitialStatusSegmentStatusTypeId                                   
,tss.IsAccepted                                   
,tss.UserId                                   
,tss.UserFullName                                   
,tss.CreatedDate                                   
,tss.ModifiedById                                   
,tss.ModifiedByUserFullName                                   
,tss.ModifiedDate                    
,tss.TenantId                                   
,tss.InitialStatus                                   
,tss.IsSegmentStatusChangeBySelection                                   
,tss.CurrentStatus                            
FROM #tmp_TgtSegmentStatus t  inner join TrackSegmentStatusType tss WITH (NOLOCK)                            
ON tss.SegmentStatusId=t.A_SegmentStatusId                            
WHERE tss.SectionId=@SourceSectionId                                 
AND tss.ProjectId=@SourceProjectId                                 
AND tss.CustomerId=@CustomerId                                  
AND ISNULL (tss.IsAccepted,0)=0                                
                                       
INSERT INTO TrackSegmentStatusType (ProjectId           
,SectionId                                
,CustomerId                                
,SegmentStatusId                                
,SegmentStatusTypeId                                
,PrevStatusSegmentStatusTypeId                                
,InitialStatusSegmentStatusTypeId                                
,IsAccepted                                
,UserId                                
,UserFullName                                
,CreatedDate                                
,ModifiedById                                
,ModifiedByUserFullName                                
,ModifiedDate                                
,TenantId                        
,InitialStatus                                
,IsSegmentStatusChangeBySelection                                
,CurrentStatus)                                
SELECT                                 
@TargetProjectId,                                
@TargetSectionId,                                
@CustomerId                                
,ttc.SegmentStatusId                                   
,ttc.SegmentStatusTypeId                                   
,ttc.PrevStatusSegmentStatusTypeId                                   
,ttc.InitialStatusSegmentStatusTypeId                                   
,ttc.IsAccepted                                
,ttc.UserId                                   
,ttc.UserFullName                                   
,getutcdate()                                
,null                                  
,null                  
,null                                
,ttc.TenantId                                   
,ttc.InitialStatus                                   
,ttc.IsSegmentStatusChangeBySelection                                   
,ttc.CurrentStatus FROM @tempTrackChanges ttc --INNER JOIN #tmp_TgtSegmentStatus tss WITH (NOLOCK)                                   
--ON tss.A_SegmentStatusId=ttc.SegmentStatusId                                  
                              
INSERT INTO                       
    bsdlogging..TrackSegmentStatusTypeHistory (                                
    ProjectId,                                
    SectionId,                                
    CustomerId,                                
    SegmentStatusId,                                
    SegmentStatusTypeId,                                
    IsAccepted,                                
    UserId,                                
    UserFullName,                                
    CreatedDate,                                
    ModifiedById,                                
    ModifiedByUserFullName,                                
    ModifiedDate,                                
    TenantId                                
    )                                
 Select                                
    @TargetProjectId,                                
    @TargetSectionId,                                
    @CustomerId,                                
    tss.SegmentStatusId,                                
  ttc.SegmentStatusTypeId,                                
    ttc.IsAccepted,                          
    ttc.UserId,                                
    ttc.UserFullName,                                
    getutcdate(),      null,                                
    null,                                
    null,                                
    ttc.TenantId                                
 FROM                                
    @tempTrackChanges ttc                                
    INNER JOIN #tmp_TgtSegmentStatus tss WITH (NOLOCK)                                
    ON tss.A_SegmentStatusId = ttc.SegmentStatusId                              
                              
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
         ,@ImportTrackSegmentStatus_Description                                                                          
         ,@ImportTrackSegmentStatus_Description                                                                    
         ,@IsCompleted                                                     
            ,@ImportTrackSegmentStatus_Step --Step                                                                   
     ,@RequestId;                                                              
                                                   
EXEC usp_MaintainImportProjectProgress @PSourceProjectId               
         ,@PTargetProjectId                                                                   
   ,@PSourceSectionId                                                              
  , @TargetSectionId                                                                     
         ,@PUserId                                                                          
         ,@PCustomerId                                        
          ,@ImportCompleted                                                          
        ,@ImportTrackSegmentStatus_Percentage --Percent                                                                          
         , 0                                                              
    ,@ImportSource                                                           
         , @RequestId;                                  

--INSERT ProjectPageSetting                                                                          
INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId,SectionId,TypeId)                                                            
 SELECT
 PPS.MarginTop                          
    ,PPS.MarginBottom                          
    ,PPS.MarginLeft 
	,PPS.MarginRight                          
    ,PPS.EdgeHeader                          
    ,PPS.EdgeFooter                          
    ,PPS.IsMirrorMargin                                                            
    ,@PTargetProjectId AS ProjectId                  
    ,@PCustomerId AS CustomerId   
	,@TargetSectionId AS SectionId                                                          
    ,PPS.TypeId                                                            
 FROM ProjectPageSetting PPS WITH (NOLOCK)                                                            
 WHERE PPS.SectionId = @PSourceSectionId                                          
 AND PPS.ProjectId = @PSourceProjectId 

 --INSERT ProjectPaperSetting                                                                          
INSERT INTO ProjectPaperSetting (PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId,SectionId)                                                            
 SELECT
 PPS.PaperName                          
    ,PPS.PaperWidth                          
    ,PPS.PaperHeight                          
    ,PPS.PaperOrientation                          
    ,PPS.PaperSource                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                                                          
    ,@TargetSectionId AS SectionId                   
 FROM ProjectPaperSetting PPS WITH (NOLOCK)                                                            
 WHERE PPS.SectionId = @PSourceSectionId                                          
 AND PPS.ProjectId = @PSourceProjectId  

 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
         ,@ImportpageSetupSettings_Description                                                                          
         ,@ImportpageSetupSettings_Description                                                                    
         ,@IsCompleted                                                     
         ,@ImportPageSetup_Step --Step                                                                   
     ,@RequestId;   

EXEC usp_MaintainImportProjectProgress @PSourceProjectId 
         , @PTargetProjectId                                                                   
         , @PSourceSectionId                                                              
         , @TargetSectionId                                                                     
         , @PUserId                                                                          
         , @PCustomerId                                        
         , @ImportCompleted                                                          
         , @ImportPageSetupSettings_Percentage --Percent                                                                          
         , 0                                                              
         , @ImportSource                                                           
         , @RequestId;  
                      


--Mark documents deleted for already exist section which is being marked deleted as new section is being copied
UPDATE DocLibraryMapping SET IsDeleted = 1 WHERE CustomerId = @PCustomerId AND ProjectId = @PTargetProjectId AND SectionId = @OldSectionId;


--INSERT DocLibraryMapping for Section
IF @IncludeDocSections = 1
BEGIN
	INSERT INTO DocLibraryMapping
	(CustomerId, ProjectId, SectionId, SegmentId, DocLibraryId, SortOrder
	,IsActive, IsAttachedToFolder, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, AttachedByFullName)
	SELECT @CustomerId AS CustomerId
		,@TargetProjectId AS ProjectId
		,@TargetSectionId
		,NULL AS SegmentId
		,DLM.DocLibraryId
		,DLM.SortOrder
		,DLM.IsActive
		,DLM.IsAttachedToFolder
		,DLM.IsDeleted
		,DLM.CreatedDate
		,DLM.CreatedBy
		,DLM.ModifiedDate
		,DLM.ModifiedBy
        ,DLM.AttachedByFullName
	FROM DocLibraryMapping DLM WITH (NOLOCK)
	LEFT JOIN DocLibraryMapping A WITH (NOLOCK) ON A.CustomerId = @PCustomerId AND A.ProjectId = @PTargetProjectId AND A.SectionId = @TargetSectionId AND A.DocLibraryId = DLM.DocLibraryId
        AND ISNULL(A.IsDeleted, 0) = 0
	WHERE A.DocLibraryId IS NULL AND DLM.CustomerId = @PCustomerId AND DLM.ProjectId = @PSourceProjectId AND DLM.SectionId = @PSourceSectionId;
END


--INSERT DocLibraryMapping for Folder
IF @IncludeDocFolders = 1
BEGIN
	INSERT INTO DocLibraryMapping
	(CustomerId, ProjectId, SectionId, SegmentId, DocLibraryId, SortOrder
	,IsActive, IsAttachedToFolder, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, AttachedByFullName)
	SELECT @CustomerId AS CustomerId
		,@TargetProjectId AS ProjectId
		,@ParentSectionId
		,NULL AS SegmentId
		,DLM.DocLibraryId
		,DLM.SortOrder
		,DLM.IsActive
		,DLM.IsAttachedToFolder
		,DLM.IsDeleted
		,DLM.CreatedDate
		,DLM.CreatedBy
		,DLM.ModifiedDate
		,DLM.ModifiedBy
        ,DLM.AttachedByFullName
	FROM DocLibraryMapping DLM WITH (NOLOCK)
	LEFT JOIN DocLibraryMapping A WITH (NOLOCK) ON A.CustomerId = @PCustomerId AND A.ProjectId = @PTargetProjectId AND A.SectionId = @ParentSectionId AND A.DocLibraryId = DLM.DocLibraryId
        AND ISNULL(A.IsDeleted, 0) = 0
	WHERE A.DocLibraryId IS NULL AND DLM.CustomerId = @PCustomerId AND DLM.ProjectId = @PSourceProjectId AND DLM.SectionId = @OldParentSectionId;
END

 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
         ,@ImportDocLibraryMapping_Description                                                                          
         ,@ImportDocLibraryMapping_Description                                                                    
         ,@IsCompleted                                                     
         ,@ImportDocLibraryMapping_Step --Step                                                                   
     ,@RequestId;   

EXEC usp_MaintainImportProjectProgress @PSourceProjectId 
         , @PTargetProjectId                                                                   
         , @PSourceSectionId                                                              
         , @TargetSectionId                                                                     
         , @PUserId                                                                          
         , @PCustomerId                                        
         , @ImportCompleted                                                          
         , @ImportDocLibraryMapping_Percentage --Percent                                                                          
         , 0                                                              
         , @ImportSource                                                           
         , @RequestId;


 if(ISNULL(@PDivisionId,0)=0)
            exec usp_SetDivisionIdForUserSection @PTargetProjectId,@TargetSectionId,@PCustomerId  
        
 UPDATE ps                                                
 SET ps.IsLocked=0,                                                
  ps.LockedByFullName=''                                                
 FROM ProjectSection ps WITH(NOLOCK)                                                
 WHERE ps.SectionId=@TargetSectionId                      
                                                
--SELECT FINAL REQUIRED RESULT                                                                    
SELECT                                                      
 SectionId                                                      
   ,ParentSectionId                                                      
   ,mSectionId                                                      
   ,ProjectId                                                      
   ,CustomerId                                                      
   ,UserId                                                      
   ,DivisionId                                                      
   ,DivisionCode                            
   ,Description                                                      
   ,SourceTag                                                      
   ,Author                                          
   ,SectionCode                                                      
   ,@OldSectionId as A_SectionId                                                    
FROM ProjectSection WITH (NOLOCK)                                                      
WHERE SectionId = @TargetSectionId                                                      
                                                      
--UNLOCK Source And Target Section                                  
--EXEC usp_unLockImportedSourceAndTargetSection @PSourceSectionId                                                                    
--     ,@PTargetProjectId                                                                    
--            ,@SourceTag                                                                    
--            ,@Author                                                       
--            ,0                                                                    
      EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
           ,@ImportComplete_Description                                                                          
          ,@ImportComplete_Description                                                                    
         ,@IsCompleted                                                         
            ,@ImportComplete_Step --Step                                                     
     ,@RequestId;                                                              
                     
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                           
         ,@PTargetProjectId                                                                   
   ,@PSourceSectionId                                                              
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
                                                              
DECLARE @ResultMessage NVARCHAR(MAX);                                                                          
SET @ResultMessage = 'Rollback Transaction. Error Number: ' + CONVERT(VARCHAR(MAX), ERROR_NUMBER()) +                                                                    
'. Error Message: ' + CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) +                                                                          
'. Procedure Name: ' + CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) +                                                                          
'. Error Severity: ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +                                                                        
'. Line Number: ' + CONVERT(VARCHAR(5), ERROR_LINE());                    
                                                   
EXEC usp_unLockImportedSourceAndTargetSection @PSourceSectionId                                                                    
            ,@PTargetProjectId                                                                    
  ,@SourceTag                                                                    
            ,@Author                                                                    
            ,1                                                                 
                                                                 
    EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                          
           ,@ImportFailed_Description                                                                          
          ,@ResultMessage                                                                    
         ,@IsCompleted                                                         
            ,@ImportFailed_Step --Step                                                                   
     ,@RequestId;                                                              
                                                              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                          
         ,@PTargetProjectId                                                      
   ,@PSourceSectionId                                                              
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


