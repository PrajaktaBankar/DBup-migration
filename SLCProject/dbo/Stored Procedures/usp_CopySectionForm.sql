CREATE PROCEDURE [dbo].[usp_CopySectionForm]    
(    
 @SourceProjectId INT,                              
 @SourceSectionId INT,                              
 @TargetProjectId INT,                              
 @CustomerId INT,                              
 @UserId INT,                              
 @SourceTag VARCHAR (18),                              
 @Author NVARCHAR(10),                              
 @Description NVARCHAR(500),                        
 @ParentSectionId INT,                                    
 @UserName NVARCHAR(500) = 'N/A',                            
 @UserAccessDivisionId NVARCHAR(MAX) = '' , 
 @DocumentPath NVARCHAR(150)null=null
)    
AS    
 BEGIN      
    DECLARE @PSourceProjectId int = @SourceProjectId;      
    DECLARE @PSourceSectionId int = @SourceSectionId;      
    DECLARE @PTargetProjectId int = @TargetProjectId;      
    DECLARE @PUserId int = @UserId;      
    DECLARE @PUserName NVARCHAR(500) = @UserName;      
    DECLARE @PParentSectionId int = @ParentSectionId;      
    DECLARE @PCustomerId int = @CustomerId;      
    DECLARE @PDescription nvarchar(500) = @Description;      
    DECLARE @PSourceTag varchar(18) = @SourceTag;      
    DECLARE @PAuthor nvarchar(100) = @Author;      
    DECLARE @PCreatedBy int = @UserId;      
    DECLARE @SectionSource int = 8      
 DECLARE @SectionDocumentTypeId INT = 1;  
      
      
      
 DECLARE @UserAccessDivisionIdTbl TABLE (DivisionId INT);                                
 DECLARE @FutureDivisionIdOfSectionTbl TABLE (DivisionId INT);                                
 DECLARE @FutureDivisionId INT;                                    
 DECLARE @ErrorMessage NVARCHAR(MAX) = 'Exception';                                     
 DECLARE @TargetSectionId INT = 0;                                        
                                     
   --If came from UI as undefined then make it empty as it should empty                                        
  IF @UserAccessDivisionId = 'undefined'                                        
  BEGIN                                
   SET @UserAccessDivisionId = ''                                        
  END                                
                                    
   --PUT USER DIVISION ID'S INTO TABLE                                       
  INSERT INTO @UserAccessDivisionIdTbl (DivisionId)                                       
  SELECT * FROM dbo.fn_SplitString(@UserAccessDivisionId, ',');                                       
                                       
  --CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE                                       
  INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)                                       
  EXEC usp_CalculateDivisionIdForUserSection @TargetProjectId                                       
    ,@CustomerId                                       
    ,@SourceTag                                       
    ,@UserId                                       
    ,@ParentSectionId                                       
                                      
  SELECT TOP 1 @FutureDivisionId = DivisionId FROM @FutureDivisionIdOfSectionTbl;                                    
                                    
  DECLARE @SourceMSectionId INT = 0, @SourceSectionCode INT = 0;                                      
  SELECT @SourceMSectionId = PS.mSectionId, @SourceSectionCode = PS.SectionCode                                      
  FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @SourceSectionId;                                        
              
  DECLARE @GrandParentSectionId INT = (SELECT ParentSectionId FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @ParentSectionId AND ProjectId = @TargetProjectId AND CustomerId = @CustomerId);            
  DECLARE @IsImportingInMasterDivision BIT = 0;                
              
   SELECT @IsImportingInMasterDivision = 1             
   from ProjectSection P WITH(NOLOCK)             
   WHERE P.SectionId = @GrandParentSectionId            
   AND P.ProjectId = @TargetProjectId             
   AND P.CustomerId = @CustomerId             
   AND ISNULL(P.mSectionId,0) > 0;            
      
  IF EXISTS (SELECT TOP 1  1 FROM ProjectSection WITH (NOLOCK) WHERE ProjectId = @TargetProjectId AND CustomerId = @CustomerId      
     AND ISNULL(IsDeleted,0) = 0 AND SourceTag = TRIM(@SourceTag) AND LOWER(Author) = LOWER(TRIM(@Author)))                                       
  BEGIN                              
   SET @ErrorMessage = 'Section already exists.';       
  END                                      
  ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0                                       
  BEGIN                                       
   SET @ErrorMessage = 'Section id is invalid.';      
  END                                      
  ELSE IF @IsImportingInMasterDivision = 1 AND @UserAccessDivisionId != '' AND @FutureDivisionId NOT IN (SELECT DivisionId FROM @UserAccessDivisionIdTbl)                                      
  BEGIN                                      
   SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';             
             
  END                                
 ELSE      
 BEGIN      
    DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@PTargetProjectId, @PCustomerId, @PParentSectionId, @PSourceTag, @PAuthor);            
            
    UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PTargetProjectId       
 AND CustomerId = @PCustomerId  AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;            
            
 INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                                  
    DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                                  
    Author, TemplateId,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, FormatTypeId, SpecViewModeId,                   
    IsLockedImportSection,IsTrackChanges,IsTrackChangeLock,TrackChangeLockedBy,SortOrder,SectionSource)                
    SELECT                
     @ParentSectionId AS ParentSectionId                
    ,@PTargetProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,@PUserId AS UserId                
    ,NULL AS DivisionId                
    ,NULL AS DivisionCode                
    ,@PDescription AS [Description]                
    ,PS.LevelId AS LevelId                                  
    ,1 AS IsLastLevel                                  
    ,@PSourceTag AS SourceTag                                  
    ,@PAuthor AS Author                                  
    ,PS.TemplateId AS TemplateId                                  
    ,GETUTCDATE() AS CreateDate                                  
    ,@PUserId AS CreatedBy                                  
    ,GETUTCDATE() AS ModifiedDate                                  
    ,@PUserId AS ModifiedBy                                  
    ,0 AS IsDeleted                    
    ,PS.FormatTypeId AS FormatTypeId                                  
    ,PS.SpecViewModeId AS SpecViewModeId                  
    ,PS.IsLockedImportSection AS IsLockedImportSection                
    ,PS.IsTrackChanges AS IsTrackChanges                 
    ,PS.IsTrackChangeLock AS IsTrackChangeLock                 
    ,PS.TrackChangeLockedBy As TrackChangeLockedBy            
    ,@SortOrder as SortOrder              
    ,PS.SectionSource As SectionSource      
    FROM ProjectSection PS WITH (NOLOCK)                
    WHERE PS.SectionId = @SourceSectionId;                
                    
    SET @TargetSectionId = SCOPE_IDENTITY();       
    IF(@TargetSectionId = 0) RETURN;      
      
  DROP TABLE IF EXISTS #SourceProjectSegmentStatus;        
      
 SELECT PSS.*                                        
    INTO #SourceProjectSegmentStatus                                        
    FROM ProjectSegmentStatus PSS WITH(NOLOCK)                                        
    WHERE PSS.ProjectId = @PSourceProjectId AND PSS.SectionId = @PSourceSectionId      
      
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
          --,PSG_Src.SegmentCode AS SegmentCode                            
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
    
  
    INSERT INTO SectionDocument      
     (ProjectId      
     ,SectionId   
     ,SectionDocumentTypeId      
     ,DocumentPath      
     ,OriginalFileName      
     ,CreateDate      
     ,CreatedBy)      
   SELECT @TargetProjectId  
     ,@TargetSectionId  
     ,SD.SectionDocumentTypeId  
  ,@DocumentPath,  
        SD.OriginalFileName  
  ,GETUTCDATE()  
        ,@UserId  
   FROm SectionDocument SD WITH (NOLOCK)   
   Where SD.SectionId = @SourceSectionId  
  
           BEGIN --INSERT ProjectPageSetting    
    INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId,SectionId,TypeId)                                                              
     SELECT  
     PPS.MarginTop                            
        ,PPS.MarginBottom                            
        ,PPS.MarginLeft   
     ,PPS.MarginRight                            
        ,PPS.EdgeHeader                            
        ,PPS.EdgeFooter                            
        ,PPS.IsMirrorMargin                                                              
        ,@TargetProjectId AS ProjectId      
        ,@CustomerId AS CustomerId     
        ,@TargetSectionId AS SectionId                                              
        ,PPS.TypeId                                                              
     FROM ProjectPageSetting PPS WITH (NOLOCK)                                                              
     WHERE PPS.SectionId = @SourceSectionId                                            
END  
  
BEGIN --INSERT ProjectPaperSetting                                                                            
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
     WHERE PPS.SectionId = @SourceSectionId                                            
END     
END

BEGIN --Insert DocLibraryMapping
INSERT INTO DocLibraryMapping
(CustomerId, ProjectId, SectionId, SegmentId, DocLibraryId, SortOrder
,IsActive, IsAttachedToFolder, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, AttachedByFullName)
SELECT @CustomerId AS CustomerId
	,@TargetProjectId AS ProjectId
	,@TargetSectionId
	,NULL AS SegmentId
	,DocLibraryId
	,SortOrder
	,IsActive
	,IsAttachedToFolder
	,DLM.IsDeleted
	,CreatedDate
	,CreatedBy
	,ModifiedDate
	,ModifiedBy
    ,AttachedByFullName
FROM DocLibraryMapping DLM WITH (NOLOCK)
WHERE DLM.CustomerId = @CustomerId AND DLM.ProjectId = @SourceProjectId AND DLM.SectionId = @SourceSectionId;
END

      
   SELECT @ErrorMessage as ErrorMessage,@TargetSectionId as TargetSectionId;      
END  
