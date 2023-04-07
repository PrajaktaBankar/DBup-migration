CREATE PROCEDURE [dbo].[usp_ImportProjectSectionsForAlternateDoc]   
    (  
    @SourceProjectId INT,    
    @SourceSectionId INT,  
    @TargetProjectId INT,  
    @CustomerId INT,   
    @UserId INT,     
    @Description NVARCHAR(500),                                                
    @UserName NVARCHAR(500) = 'N/A',                       
    @RequestId INT,  
    @OriginalFileName NVARCHAR(500),  
    @DocumentPath NVARCHAR(500),
	@IncludeDocFolders BIT,
	@IncludeDocSections BIT
    )  
    AS  
    BEGIN    
     
    DECLARE @PSourceProjectId int = @SourceProjectId;      
    DECLARE @PSourceSectionId int = @SourceSectionId;      
    DECLARE @PTargetProjectId int = @TargetProjectId;      
    DECLARE @PUserId int = @UserId;      
    DECLARE @PUserName NVARCHAR(500) = @UserName;      
    DECLARE @PCustomerId int = @CustomerId;      
    DECLARE @PDescription nvarchar(500) = @Description;      
    DECLARE @PCreatedBy int = @UserId;    
    DECLARE @POriginalFileName NVARCHAR(500) = @OriginalFileName ;    
    DECLARE @PDocumentPath  NVARCHAR(500) = @DocumentPath;    
    --DECLARE VARIABLES      
    DECLARE @SectionSource int = 8      
    DECLARE @TargetSectionId INT = 0;                                        
    DECLARE @ParentSectionId INT = NULL;
	DECLARE @OldParentSectionId AS INT = 0;
    DECLARE @SectionCode INT = NULL;                                                                    
    DECLARE @SourceTag VARCHAR(18) = '';                                                                    
    DECLARE @Author NVARCHAR(MAX) = '';                                                                                
    DECLARE @mSectionId INT = 0;        
                                                                 
    DECLARE @ImportSource Nvarchar(100)='Import Alternate Document From Project'     
    DECLARE @ImportStart_Description NVARCHAR(50) = 'Import Started';     
    DECLARE @ImportProjectSection_Description NVARCHAR(50) = 'Project Section Imported';                                                                                                  
    DECLARE @ImportProjectSegment_Description NVARCHAR(50) = 'Project Segment Imported';                                                                                
    DECLARE @ImportProjectSegmentStatus_Description NVARCHAR(50) = 'Project Segment Status Imported';   
    DECLARE @ImportPageSetup_Description NVARCHAR(50) = 'Page Setup Settings Imported';
	DECLARE @ImportDocLibraryMapping_Description NVARCHAR(50) = 'Doc Library Mapping Imported'; 
    DECLARE @ImportComplete_Description NVARCHAR(50) = 'Import Completed';                                                                              
    DECLARE @ImportFailed_Description NVARCHAR(50) = 'IMPORT FAILED';                                                                  
                                                                            
    DECLARE @ImportStart_Step TINYINT = 1;    
    DECLARE @ImportProjectSection_Step TINYINT = 25;                                                                            
    DECLARE @ImportProjectSegmentStatus_Step TINYINT = 50;    
    DECLARE @ImportProjectSegment_Step TINYINT = 75;         
    DECLARE @ImportPageSetup_Step TINYINT = 80;
                                                                               
    DECLARE @ImportPending TINYINT =1;                                                                      
    DECLARE @ImportStarted TINYINT =2;                                                                      
    DECLARE @ImportCompleted TINYINT =3;                                                                      
    DECLARE @Importfailed TINYINT =4     
                                                                       
    DECLARE @ImportStart_Percentage TINYINT = 5;                                                                               
    DECLARE @ImportProjectSection_Percentage TINYINT = 30;                                                                                                
    DECLARE @ImportProjectSegmentStatus_Percentage TINYINT = 50;    
    DECLARE @ImportProjectSegment_Percentage TINYINT = 75;     
    DECLARE @ImportPageSetup_Percentage TINYINT = 80;
	DECLARE @ImportDocLibraryMapping_Percentage TINYINT = 90;
    DECLARE @ImportComplete_Percentage TINYINT = 100;                                 
    DECLARE @IsCompleted BIT =1;    
     
    DECLARE @ImportDocLibraryMapping_Step TINYINT = 24;  --Newly Added 
	DECLARE @ImportComplete_Step TINYINT = 22;                                                                            
    DECLARE @ImportFailed_Step TINYINT = 23    
                                                                              
    
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
                           
     
    --FETCH SOURCE PROJECT SECTION DETAILS INTO VARIABLES                                                                                  
    SELECT                                                   
    @SectionCode = SectionCode                                                                    
    ,@SourceTag = SourceTag                                                                    
    ,@mSectionId = ISNULL(mSectionId,0)                                                          
    ,@Author = Author
	,@OldParentSectionId = ParentSectionId
    FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSourceSectionId;      
            
      
    DECLARE @OldSectionId INT = 0, @Old_IsHiddenStatus BIT = 0;                              
    --Master Section                                                  
    IF (@mSectionId>0)                                                  
    BEGIN                                                  
        SELECT top 1                               
        @OldSectionId=SectionId                               
        ,@Old_IsHiddenStatus = PS.IsHidden                              
    FROM ProjectSection PS WITH (NOLOCK) WHERE PS.ProjectId = @PTargetProjectId                                                                            
        AND PS.IsLastLevel = 1                                                                                
        AND mSectionId=@mSectionId                                                  
        AND ISNULL(PS.IsDeleted,0) = 0                         
    END                                                  
    ELSE --User Section                                                  
    BEGIN                                                  
        SELECT top 1                               
        @OldSectionId=SectionID                       
        ,@Old_IsHiddenStatus = PS.IsHidden  FROM ProjectSection PS WITH (NOLOCK) WHERE PS.ProjectId = @PTargetProjectId                                                  
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
    FROM ProjectSection PS WITH (NOLOCK)  WHERE PS.SectionId = @OldSectionId                                                                  
                 
    SELECT TOP 1  * INTO #ImportRequest  FROM ImportProjectRequest WITH (NOLOCK) WHERE RequestId = @RequestId;                                                                  
       
    IF (SELECT CASE WHEN ISNULL(IsCreateFolderStructure,0) = 1 AND ISNULL(TargetParentSectionId,0) = 0 THEN 1 ELSE 0 END FROM #ImportRequest) = 1      
    BEGIN                                        
    DECLARE @SourceParentSectionId INT =0;                                         
    -- source section id                                        
    SELECT TOP 1  @SourceParentSectionId = ParentSectionId                                         
    FROM ProjectSection WITH (NOLOCK)                                         
    WHERE SectionId = (SELECT TOP 1 ISNULL(SourceSectionId,0) FROM #ImportRequest)                                        
    AND ProjectId = @PSourceProjectId AND CustomerId = @PCustomerId                              
    AND ISNULL(IsDeleted,0)=0                                  
                                        
    -- source sub folder                                        
    SELECT TOP 1  * INTO #SourceSubFolder                                        
    FROM ProjectSection WITH (NOLOCK)  WHERE SectionId = @SourceParentSectionId                                  
    AND ProjectId = @PSourceProjectId AND CustomerId = @PCustomerId                                    
    AND ISNULL(IsDeleted,0)=0                               
                                      
    --source division - top level folder                                 
    DEclare @Src_ParentSectionId int = 0;                              
    SELECT TOP 1  @Src_ParentSectionId = ParentSectionId FROM #SourceSubFolder                              
                              
    SELECT TOP 1 * INTO #SourceDivision                                        
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
           
    SELECT @PSID = SectionId  FROM ProjectSection WITH(NOLOCK)                                   
        WHERE ProjectId = @TargetProjectId AND CustomerId = @PCustomerId AND ParentSectionId = 0 AND mSectionId = 5; -- Front End Group                                    
                                  
        INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                              
        Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                                    
        CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                                       
        IsLocked,LockedByFullName,SortOrder)                                    
        SELECT @PSID, mSectionId, @TargetProjectId,CustomerId, UserId, DivisionId, DivisionCode,                                  
        Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, GETUTCDATE(),                                  
        @UserId,@UserId,GETUTCDATE(),FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,IsLocked,LockedByFullName,SortOrder                                    
        FROM #SourceDivision;                      
                      
    -- Update the Division SortOrder Here                    
        SET @T_CreatedDivId = SCOPE_IDENTITY();                                  
        EXEC usp_UpdateDivisionSortOrderAndParentSectionId @TargetProjectId, @PCustomerId, @T_CreatedDivId;                     
                                 
        INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                              
        Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                                    
        CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                                              
        IsLocked,LockedByFullName,SortOrder)                                    
        SELECT @T_CreatedDivId, mSectionId,@TargetProjectId,CustomerId, UserId, DivisionId, DivisionCode,                       
        Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, GETUTCDATE(),                                  
        @UserId,@UserId,GETUTCDATE(),FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,IsLocked,LockedByFullName ,SortOrder                                   
        FROM #SourceSubFolder                                  
                                  
        SET @ParentSectionId = SCOPE_IDENTITY();                    
        END;                                        
    ELSE                                        
        BEGIN                                     
        --If divisionExist                              
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
            
    --if subfolder not exist in target                          
        IF @ParentSectionId = 0                                  
        BEGIN                                  
        INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                                                              
        Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,                                                                    
        CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,                                                              
        IsLocked,LockedByFullName,SortOrder)                                    
        SELECT @Target_DivId,mSectionId,@TargetProjectId,CustomerId, UserId, DivisionId, DivisionCode,                                  
        Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, GETUTCDATE(),                                  
        @UserId,@UserId,GETUTCDATE(),FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,IsLocked,LockedByFullName ,SortOrder                                  
        FROM #SourceSubFolder                                  
                                    
        SET @ParentSectionId = SCOPE_IDENTITY();                                  
        END;                                                           
    END;                                        
                                        
    END;                                        
    ELSE                                        
    BEGIN                                        
    SELECT TOP 1  @ParentSectionId = ISNULL(TargetParentSectionId,0)  FROM #ImportRequest                         
                       
    IF ISNULL(@ParentSectionId,0) = 0                      
        BEGIN                      
        SELECT @ParentSectionId = ParentSectionId                      
        FROM ProjectSection                       
        WHERE SectionId = @OldSectionId                       
        AND ProjectId = @TargetProjectId                       
        AND CustomerId= @PCustomerId                      
    END;                                  
    END;                                         
     
    DECLARE @PMasterDataTypeId  INT=0;                          
    DECLARE @IsMarsterDivision  BIT =0;                          
    DECLARE @PDivisionCode NVARCHAR(500) = NULL;                                  
    DECLARE @PDivisionId INT = NULL;                                  
    DECLARE @PParentDescription NVARCHAR(500) =  NULL;                           
    DECLARE @SubDivisionParentSectionId INT=0                            
    DECLARE @PDivisionSourceTag  VARCHAR(18) = '';                          
                                                         
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
    --------------------------------------------------------------------       
    DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@PTargetProjectId, @PCustomerId, @ParentSectionId, @SourceTag, @Author);      
     
     
    --set the sort order    
    UPDATE PS    
        SET SortOrder = SortOrder + 1     
    FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PTargetProjectId    AND CustomerId = @PCustomerId  AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;      
    
    --Insert into ProjectSection    
    INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                                  
    DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                                  
    Author, TemplateId,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, FormatTypeId, SpecViewModeId,                   
    IsLockedImportSection,IsTrackChanges,IsTrackChangeLock,TrackChangeLockedBy,SortOrder,SectionSource)     
    SELECT    
    @ParentSectionId AS ParentSectionId,    
    @PTargetProjectId AS ProjectId ,    
    @PCustomerId AS CustomerId ,    
    @PUserId AS UserId,    
    @PDivisionId AS DivisionId,    
    @PDivisionCode AS DivisionCode ,    
    Description AS [Description],    
    PS.LevelId As LevelId ,    
    1 AS IsLastLevel,    
    @SourceTag AS SourceTag                                  
    ,@Author AS Author     
    ,PS.TemplateId AS TemplateId                                  
    ,GETUTCDATE() AS CreateDate                                  
    ,@PUserId AS CreatedBy                                  
    ,GETUTCDATE() AS ModifiedDate                                  
    ,@PUserId AS ModifiedBy                                  
    ,0 AS IsDeleted                    
    ,PS.FormatTypeId AS FormatTypeId                                  
    ,PS.SpecViewModeId AS SpecViewModeId                  
    ,1 AS IsLockedImportSection                
    ,PS.IsTrackChanges AS IsTrackChanges                 
    ,PS.IsTrackChangeLock AS IsTrackChangeLock                 
    ,PS.TrackChangeLockedBy As TrackChangeLockedBy            
    ,@SortOrder as SortOrder              
    ,PS.SectionSource As SectionSource           
    from ProjectSection PS where SectionId = @SourceSectionId    
    
    SET @TargetSectionId = SCOPE_IDENTITY();       
    IF(@TargetSectionId = 0) RETURN;     
     
                                                              
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
    
    DROP TABLE IF EXISTS #SourceProjectSegmentStatus;        
      
        SELECT PSS.*                                        
    INTO #SourceProjectSegmentStatus                                        
    FROM ProjectSegmentStatus PSS WITH(NOLOCK)                                        
    WHERE PSS.ProjectId = @PSourceProjectId AND PSS.SectionId = @PSourceSectionId      
      
    --select * from #SourceProjectSegmentStatus    
    INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,            
        IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,--SegmentStatusCode,       
        IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,            
        ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)            
        SELECT            
                @TargetSectionId AS SectionId            
            ,SrcPSS.ParentSegmentStatusId            
            ,SrcPSS.mSegmentStatusId            
            ,SrcPSS.mSegmentId            
            ,null AS SegmentId            
            ,'U' AS SegmentSource            
            ,'U' AS SegmentOrigin            
            ,SrcPSS.IndentLevel            
            ,SrcPSS.SequenceNumber            
            ,SrcPSS.SpecTypeTagId            
            ,SrcPSS.SegmentStatusTypeId            
            ,SrcPSS.IsParentSegmentStatusActive            
            ,@PTargetProjectId AS ProjectId            
            ,@PCustomerId AS CustomerId            
            --,null AS SegmentStatusCode            
            ,SrcPSS.IsShowAutoNumber            
            ,SrcPSS.IsRefStdParagraph            
            ,SrcPSS.FormattingJson            
            ,GETUTCDate() AS CreateDate            
            ,@UserId AS CreatedBy            
            ,@UserId AS ModifiedBy            
            ,GETUTCDate() AS ModifiedDate            
            ,SrcPSS.IsPageBreak            
            ,SrcPSS.IsDeleted            
            ,SrcPSS.SegmentStatusId As A_SegmentStatusId          
        FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)               
               
        DECLARE @SegmentStatusId BIGINT=SCOPE_IDENTITY();           
         
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
        ,@TargetSectionId                                                             
    ,@PUserId                                                                                        
        ,@PCustomerId                                                   
        ,@ImportStarted                                                                                   
        ,@ImportProjectSegmentStatus_Percentage --Percent                                                                                        
        ,0                                                                            
        ,@ImportSource                                                                    
        ,@RequestId;      
     
    
    SELECT PS.* INTO #SourceProjectSegment                                                        
    FROM ProjectSegment PS WITH (NOLOCK)                
    WHERE PS.ProjectId = @PSourceProjectId AND PS.SectionId = @PSourceSectionId;         
      
    
    INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,SegmentSource, --SegmentCode,       
    CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentId, BaseSegmentDescription)                            
    SELECT                            
    @SegmentStatusId AS SegmentStatusId                            
    ,@TargetSectionId AS SectionId                            
    ,@PTargetProjectId AS ProjectId                            
    ,@PCustomerId AS CustomerId                            
    ,@Description                            
    ,'U' AS SegmentSource                            
    ,@UserId AS CreatedBy                            
    ,GETUTCDATE() AS CreateDate                            
    ,@UserId AS ModifiedBy                            
    ,GETUTCDATE() AS ModifiedDate                            
    ,PS.IsDeleted                            
    ,PS.SegmentId AS A_SegmentId                            
    ,'' AS BaseSegmentDescription            
    FROM #SourceProjectSegment PS  WITH(NOLOCK)          
      
    DECLARE @SegmentId BIGINT=SCOPE_IDENTITY();             
      
    UPDATE PS      
    SET PS.SegmentId=@SegmentId      
    FROM ProjectSegmentStatus PS WITH(NOLOCK)      
    WHERE PS.SegmentStatusId=@SegmentStatusId      
      
EXEC usp_SetDivisionIdForUserSection @PTargetProjectId,@TargetSectionId,@PCustomerId      
       
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
    ,@TargetSectionId                                                                                   
    ,@PUserId                                                                
    ,@PCustomerId                                                                                        
    ,@ImportStarted                                               
    ,@ImportProjectSegment_Percentage --Percent                                                                                
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
    ,@ImportPageSetup_Description                                                                                        
    ,@ImportPageSetup_Description                                                                                  
    ,@IsCompleted                                     
    ,@ImportPageSetup_Step --Step                                                                                 
    ,@RequestId                                                                            
                                                                            
    --Add Logs to ImportProjectRequest                                                                            
    EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                                                  
    ,@PTargetProjectId                                                                                 
    ,@PSourceSectionId                                                                           
    ,@TargetSectionId                                                                                   
    ,@PUserId                                                                
    ,@PCustomerId                                                                                        
    ,@ImportStarted                                               
    ,@ImportPageSetup_Percentage --Percent                                                                                
    , 0                                                               
    ,@ImportSource                             
    , @RequestId;   
                
    IF NOT EXISTS(select top 1 1 from SectionDocument WITH (NOLOCK)  where SectionId = @TargetSectionId and ProjectId = @TargetProjectId )  
    BEGIN  
    --Insert Into SectionDocument Table     
    Insert INTO SectionDocument (ProjectId ,SectionId,SectionDocumentTypeId,DocumentPath,OriginalFileName,IsDeleted,ModifiedBy,ModifiedDate,CreateDate,CreatedBy)    
    select     
    PS.ProjectId,  
    PS.SectionId,    
    1 As SectionDocumentTypeId,    
    @PDocumentPath  As DocumentPath,    
    @POriginalFileName As  OriginalFileName,    
    0 AS IsDeleted ,    
    NULL,    
    NULL AS ModifiedDate,    
    GETUTCDATE(),    
    @PUserId AS CreatedBy    
    from ProjectSection PS    
  where PS.SectionId = @TargetSectionId    
    END  
      

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
                  
    UPDATE ps                                                        
    SET ps.IsLocked=0,    
    ps.IsLockedImportSection = 0,                                                        
    ps.LockedByFullName=''                                                        
    FROM ProjectSection ps WITH(NOLOCK)                                                        
    WHERE ps.SectionId=@TargetSectionId      
    
    
    SELECT                                  
    ps.SectionId                                                              
    ,ps.ParentSectionId                                                              
    ,ps.mSectionId                                                              
    ,ps.ProjectId                                                              
    ,ps.CustomerId                                                              
    ,ps.UserId                                                              
    ,ps.DivisionId                                                              
    ,ps.DivisionCode                                    
    ,ps.Description                                                              
    ,ps.SourceTag                                                              
    ,ps.Author    
    ,ps.SectionSource    
    ,ps.SectionCode   
    ,@PDocumentPath As DocumentPath  
    FROM ProjectSection ps WITH (NOLOCK)   
    WHERE ps.SectionId = @TargetSectionId and ps.ProjectId=@TargetProjectId                                                              
                                            
                                                   
EXEC usp_MaintainImportProjectHistory @PTargetProjectId                                                                                  
    ,@ImportComplete_Description                                                                                  
    ,@ImportComplete_Description                                                                            
    ,@IsCompleted                                                                 
    ,@ImportComplete_Step --Step                                                             
    ,@RequestId;                                                                      
                             
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                                   
    ,@PTargetProjectId                                                                           
    ,@PSourceSectionId                                                                      
    ,@TargetSectionId                                                                             
    ,@PUserId                     
    ,@PCustomerId                                                
    ,@ImportCompleted                                                                  
    ,@ImportComplete_Percentage --Percent                                                                                  
    ,0                                           
    ,@ImportSource                                                                   
    , @RequestId;           
    END  
GO


