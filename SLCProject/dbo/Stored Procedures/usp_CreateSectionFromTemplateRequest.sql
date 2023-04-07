CREATE PROCEDURE usp_CreateSectionFromTemplateRequest              
(              
 @ProjectId INT,              
 @CustomerId INT,              
 @UserId INT,              
 @SourceTag VARCHAR(18),              
 @Author NVARCHAR(MAX),              
 @Description NVARCHAR(MAX),             
 @ParentSectionId INT,           
 @UserName NVARCHAR(MAX)='',              
 @UserAccessDivisionId NVARCHAR(MAX)=''              
)              
AS              
BEGIN                
--Paramenter Sniffing                
 DECLARE @PProjectId INT = @ProjectId;                  
 DECLARE @PCustomerId INT = @CustomerId;                  
 DECLARE @PUserId INT = @UserId;                  
 DECLARE @PSourceTag VARCHAR (18) = @SourceTag;                  
 DECLARE @PAuthor NVARCHAR(MAX) = @Author;                  
 DECLARE @PDescription NVARCHAR(MAX) = @Description;                  
 DECLARE @PUserName NVARCHAR(MAX) = @UserName;                  
 DECLARE @PUserAccessDivisionId NVARCHAR(MAX) = @UserAccessDivisionId;                  
                
 DECLARE @RequestId INT = 0;                                
 DECLARE @ErrorMessage NVARCHAR(MAX) = 'Exception';               
 DECLARe @QuedStatus INT = 1 ;                 
 DECLARE @RunningStatus INT=2 ;              
                
 --If came from UI as undefined then make it empty as it should empty                  
 IF @PUserAccessDivisionId = 'undefined'                  
 BEGIN                  
  SET @PUserAccessDivisionId = ''                  
 END                  
                    
                  
 DECLARE @BsdMasterDataTypeId INT = 1;                  
 DECLARE @CNMasterDataTypeId INT = 4;                  
                  
 DECLARE @MasterDataTypeId INT = (SELECT TOP 1  MasterDataTypeId FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);                  
                  
 DECLARE @UserAccessDivisionIdTbl TABLE (DivisionId INT);                  
 DECLARE @FutureDivisionIdOfSectionTbl TABLE (DivisionId INT);                  
                 
 DECLARE @TargetSectionId INT=0                
 DECLARE @TemplateSectionId INT=0                
 DECLARE @FutureDivisionId INT                
 DECLARE @TemplateSourceTag NVARCHAR(15) = '';                                
 DECLARE @TemplateAuthor NVARCHAR(50) = '';                 
 DECLARE @DefaultTemplateSourceTag NVARCHAR(15) = '';                                
                
                
 --SET DEFAULT TEMPLATE SOURCE TAG ACCORDING TO MASTER DATATYPEID                
 IF @MasterDataTypeId = @BsdMasterDataTypeId                
 BEGIN                
  SET @DefaultTemplateSourceTag = '99999';                
  SET @TemplateAuthor = 'RIB';                
 END                
 ELSE IF @MasterDataTypeId = @CNMasterDataTypeId                
 BEGIN                
  SET @DefaultTemplateSourceTag = '999999';                
  SET @TemplateAuthor = 'RIB';                
 END                
                
 DECLARE @TemplateMasterSectionId INT = (SELECT TOP 1 mSectionId FROM ProjectSection PS WITH (NOLOCK)                
        WHERE ProjectId = @PProjectId  AND CustomerId = @CustomerId                  
        AND PS.IsLastLevel = 1 AND ISNULL(PS.IsDeleted,0) = 0                     
        AND PS.mSectionId IS NOT NULL  AND PS.SourceTag = @DefaultTemplateSourceTag                  
        AND PS.Author = @TemplateAuthor);                     
                    
 IF EXISTS (SELECT TOP 1 1 FROM  SLCMaster..Section MS WITH (NOLOCK) WHERE MS.SectionId = @TemplateMasterSectionId AND MS.IsDeleted = 0)                
 BEGIN                
  SET @TemplateSourceTag = @DefaultTemplateSourceTag;                
 END                      
                
 --FETCH VARIABLE DETAILS                     
 SELECT @TemplateSectionId = PS.SectionId                     
    --,@TemplateSectionCode = PS.SectionCode                     
 FROM ProjectSection PS WITH (NOLOCK)                     
 WHERE PS.ProjectId = @PProjectId                     
 AND PS.CustomerId = @PCustomerId      
 AND PS.IsLastLevel = 1                     
 AND PS.mSectionId =@TemplateMasterSectionId                     
 AND PS.SourceTag = @TemplateSourceTag        
 AND PS.Author = @TemplateAuthor                     
                          
                
 --PUT USER DIVISION ID'S INTO TABLE                 
 INSERT INTO @UserAccessDivisionIdTbl (DivisionId)                 
 SELECT * FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');               
                 
 --CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE                 
 INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)                 
 EXEC usp_CalculateDivisionIdForUserSection @PProjectId                 
            ,@PCustomerId                 
       ,@PSourceTag                 
            ,@PUserId                 
            ,@ParentSectionId                 
                
 SELECT TOP 1 @FutureDivisionId = DivisionId FROM @FutureDivisionIdOfSectionTbl;                 
              
               
                 
 --PERFORM VALIDATIONS                 
 IF (@TemplateSourceTag = '')                 
 BEGIN                 
  SET @ErrorMessage = 'No master template found.';                
 END                 
 ELSE IF EXISTS (SELECT TOP 1  1                 
  FROM ProjectSection WITH (NOLOCK)                 
  WHERE ProjectId = @PProjectId                 
  AND CustomerId = @PCustomerId                 
  AND ISNULL(IsDeleted,0) = 0                 
  AND SourceTag = TRIM(@PSourceTag)                 
  AND LOWER(Author) = LOWER(TRIM(@PAuthor)))                 
 BEGIN                 
  SET @ErrorMessage = 'Section already exists.';                 
 END                
 ELSE IF EXISTS(Select TOP 1  1 from ProjectSection PS WITH(NOLOCK)              
 INNER JOIN ImportProjectRequest IPR WITH(NOLOCK)              
 ON PS.SectionId = IPR.TargetSectionId              
  WHERE PS.ProjectId = @PProjectId                 
  AND PS.CustomerId = @PCustomerId                 
  AND ISNULL(PS.IsDeleted,0) = 1                
  AND PS.SourceTag = TRIM(@PSourceTag)                 
  AND LOWER(PS.Author) = LOWER(TRIM(@PAuthor))               
  AND IPR.StatusId IN(@QuedStatus,@RunningStatus))              
  BEGIN              
   SET @ErrorMessage = 'Section already exists.';               
  END              
 ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0                 
 BEGIN                 
  SET @ErrorMessage = 'Section id is invalid.'                
 END         
 ELSE                
 BEGIN                
  --INSERT INTO ProjectSection        
  DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@PProjectId, @PCustomerId, @ParentSectionId, @PSourceTag, @PAuthor);         
          
  UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId  AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;        
                
  INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                
  DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                
  Author, TemplateId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted,                 
  FormatTypeId, SpecViewModeId,LockedByFullName,IsTrackChanges,IsTrackChangeLock,                
  TrackChangeLockedBy,SortOrder)                
  SELECT @ParentSectionId AS ParentSectionId                              
   ,@PProjectId AS ProjectId                
   ,@PCustomerId AS CustomerId                
   ,@PUserId AS UserId                
   ,@FutureDivisionId AS DivisionId                
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
   ,1 AS IsDeleted                
   ,PS_Template.FormatTypeId AS FormatTypeId                
   ,PS_Template.SpecViewModeId AS SpecViewModeId                
   ,@PUserName                
   ,IsTrackChanges                
   ,IsTrackChangeLock                
   ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy        
   ,@SortOrder AS SortOrder                
   FROM ProjectSection PS_Template WITH (NOLOCK)                
   WHERE PS_Template.SectionId = @TemplateSectionId;        
                   
  SET @TargetSectionId = scope_identity()                                
  SET @ErrorMessage = '';                
                
  INSERT INTO ImportProjectRequest(                
  SourceProjectId,TargetProjectId,SourceSectionId,TargetSectionId,                
  CreatedById,CustomerId,CreatedDate,StatusId,CompletedPercentage,                
  Source,IsNotify,IsDeleted)                
  SELECT @PProjectId,@PProjectId,@TemplateSectionId,@TargetSectionId,                
  @PUserId,@PCustomerId,getutcdate(),1,0,                
  'Import from Template',0,0                
                
  SET @RequestId=scope_identity();                
 END                
 SELECT @ErrorMessage as ErrorMessage,@RequestId as RequestId                
END 