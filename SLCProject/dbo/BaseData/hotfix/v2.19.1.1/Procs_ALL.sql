USE SLCProject
Go

ALTER PROCEDURE [dbo].[usp_CopyProjectSection]                 
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
 @UserAccessDivisionId NVARCHAR(MAX) = ''                      
)                          
AS                          
BEGIN                          
                            
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
                               
       IF EXISTS (SELECT TOP 1  1                                 
     FROM ProjectSection WITH (NOLOCK)                                 
     WHERE ProjectId = @TargetProjectId                                 
     AND CustomerId = @CustomerId                                 
     AND ISNULL(IsDeleted,0) = 0                                 
     AND SourceTag = TRIM(@SourceTag)                                 
     AND LOWER(Author) = LOWER(TRIM(@Author)))                                 
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
   EXEC usp_CreateTargetSection @SourceSectionId, @TargetProjectId, @CustomerId, @UserId, @SourceTag, @Author, @Description,@ParentSectionId, @TargetSectionId OUTPUT;                                  
          
 IF(@TargetSectionId = 0) RETURN;                                
                                
   DECLARE @TargetSectionCode INT = 0;                                
   SELECT @TargetSectionCode = PS.SectionCode                               
   FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @TargetSectionId;                 
                                  
   DROP TABLE IF EXISTS #SourceProjectSegmentStatus;                                  
   DROP TABLE IF EXISTS #SourceProjectSegment;                                  
   DROP TABLE IF EXISTS #TargetProjectSegmentStatus;                                  
   --DROP TABLE IF EXISTS #TargetProjectSegment;                                  
   DROP TABLE IF EXISTS #TargetSegmentStatus;                                  
   Drop table if exists #tmp_SrcComment                                   
   DROP TABLE if exists #NewOldCommentIdMapping                                  
                                  
   BEGIN -- Initialize few parameters                                  
                                   
                                   
    DECLARE @IsMasterSection BIT = 0;                                  
   IF @SourceMSectionId IS NULL                                   
     SET @IsMasterSection = 0;                                  
    ELSE                                  
     SET @IsMasterSection = 1;                                  
                                  
    DECLARE @IsSectionOpen BIT = 0;                                  
    IF EXISTS (SELECT TOP 1 1                                                  
     FROM ProjectSegmentStatus PSS WITH (NOLOCK)                                   
     WHERE PSS.ProjectId = @SourceProjectId                                          
     AND PSS.SectionId = @SourceSectionId                                     
     AND PSS.IndentLevel = 0                                  
     AND ISNULL(PSS.IsDeleted, 0) = 0)                                                  
    BEGIN                                                  
     SET @IsSectionOpen = 1;                                                  
    END                                  
   END                                  
                                  
   --IF(@IsSectionOpen = 1)                                  
    BEGIN                                  
                                     
    SELECT PSS.*                                  
    INTO #SourceProjectSegmentStatus                                  
    FROM ProjectSegmentStatus PSS WITH(NOLOCK)                                  
    WHERE PSS.ProjectId = @SourceProjectId AND PSS.SectionId = @SourceSectionId                                  
                                  
    --select top 1 * from ProjectSegment                                  
    --Fetch Src ProjectSegment data into temp table                                                  
     SELECT PS.*                                  
INTO #SourceProjectSegment                                                  
     FROM ProjectSegment PS WITH (NOLOCK)                                                  
     WHERE PS.ProjectId = @SourceProjectId AND PS.SectionId = @SourceSectionId;                                  
                
                                  
     -- Insert records into ProjectSegmentStatus                                      
     INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,                                        
     IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,                                        
     SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,                                        
     ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)                                        
     ((SELECT                                  
    @TargetSectionId AS SectionId                                        
    ,SrcPSS.ParentSegmentStatusId AS ParentSegmentStatusId                                  
    ,SrcPSS.mSegmentStatusId AS mSegmentStatusId                                  
    ,(CASE                                                  
   WHEN @IsSectionOpen = 1                                  
   THEN SrcPSS.mSegmentId                                  
   ELSE SrcPSS.SegmentId                              
   END) AS mSegmentId                                 
    --,SrcPSS.mSegmentId AS mSegmentId                                  
    ,(CASE                                  
     WHEN SrcPSS.SegmentOrigin = 'U'                                  
     THEN SrcPSS.SegmentId                                  
  ELSE SrcPSS.mSegmentId                                  
     END) AS SegmentId                                  
     ,'U' AS SegmentSource                                      
     ,'U' AS SegmentOrigin                                        
     ,SrcPSS.IndentLevel AS IndentLevel                                  
     ,SrcPSS.SequenceNumber AS SequenceNumber                                        
     ,SrcPSS.SpecTypeTagId AS SpecTypeTagId                                        
     ,SrcPSS.SegmentStatusTypeId AS SegmentStatusTypeId                                        
     ,SrcPSS.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                                        
     ,@TargetProjectId AS ProjectId                                        
     ,@CustomerId AS CustomerId                                        
     ,SrcPSS.SegmentStatusCode AS SegmentStatusCode                       
     ,SrcPSS.IsShowAutoNumber AS IsShowAutoNumber                                        
     ,SrcPSS.IsRefStdParagraph AS IsRefStdParagraph                                        
     ,SrcPSS.FormattingJson AS FormattingJson                                        
     ,SrcPSS.CreateDate AS CreateDate                                        
     ,SrcPSS.CreatedBy AS CreatedBy                           
     ,SrcPSS.ModifiedBy AS ModifiedBy                                        
     ,SrcPSS.ModifiedDate AS ModifiedDate                                        
     ,SrcPSS.IsPageBreak AS IsPageBreak                                  
     ,SrcPSS.IsDeleted AS IsDeleted                                        
     ,SrcPSS.SegmentStatusId AS A_SegmentStatusId                                  
     FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                  
     WHERE @IsSectionOpen = 1)                                  
     UNION                                  
     (SELECT                                                  
   @TargetSectionId AS SectionId                                                  
   ,SrcMSS.ParentSegmentStatusId AS ParentSegmentStatusId                                           
   ,SrcMSS.SegmentStatusId AS mSegmentStatusId                              
   ,SrcMSS.SegmentId AS mSegmentId                                                  
   ,SrcMSS.SegmentId AS SegmentId                                  
   ,'U' AS SegmentSource                                                  
   ,'U' AS SegmentOrigin                                                  
   ,SrcMSS.IndentLevel AS IndentLevel                                                  
   ,SrcMSS.SequenceNumber AS SequenceNumber                                        
   ,(CASE                                                  
    WHEN SrcMSS.SpecTypeTagId = 1 THEN 4                                                  
    WHEN SrcMSS.SpecTypeTagId = 2 THEN 3                                                  
  ELSE SrcMSS.SpecTypeTagId                                                  
    END) AS SpecTypeTagId                         ,SrcMSS.SegmentStatusTypeId AS SegmentStatusTypeId                                                  
   ,SrcMSS.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                                                  
   ,@TargetProjectId AS ProjectId                                                  
   ,@CustomerId AS CustomerId                                                  
   ,SrcMSS.SegmentStatusCode AS SegmentStatusCode                                                  
   ,SrcMSS.IsShowAutoNumber AS IsShowAutoNumber                                                  
   ,SrcMSS.IsRefStdParagraph AS IsRefStdParagraph                                                  
   ,SrcMSS.FormattingJson AS FormattingJson                                                  
   ,GETUTCDATE() AS CreateDate                                                  
   ,@UserId AS CreatedBy                                                  
   ,@UserId AS ModifiedBy                                  
   ,GETUTCDATE() AS ModifiedDate                                                  
 ,0 AS IsPageBreak                                                  
   ,SrcMSS.IsDeleted AS IsDeleted                                  
   ,SrcMSS.SegmentStatusId AS A_SegmentStatusId                                                  
   FROM SLCMaster..SegmentStatus SrcMSS WITH (NOLOCK)                                                  
   INNER JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)               
   ON SrcMSS.SegmentId = SrcMS.SegmentId                                              
   WHERE SrcMSS.SectionId = @SourceMSectionId                                                  
   AND ISNULL(SrcMSS.IsDeleted, 0) = 0                                  
   AND @IsSectionOpen = 0))                                  
                                  
                                  
     SELECT PSS.*                 
     INTO #TargetProjectSegmentStatus                             
     FROM ProjectSegmentStatus PSS WITH(NOLOCK)                                  
     WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;                                  
                                  
     -- Insert records into ProjectSegment                                                  
     INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId,                    
     SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId,BaseSegmentDescription)                                        
     ((SELECT                                                  
    NULL AS SegmentStatusId                                                  
   ,@TargetSectionId AS SectionId                                                  
   ,@TargetProjectId AS ProjectId                                                  
   ,@CustomerId AS CustomerId                        
   ,(CASE                                                  
   WHEN SrcPSS.SegmentOrigin = 'U' THEN SrcPS.SegmentDescription                                                  
   ELSE SrcMS.SegmentDescription                        
   END) AS SegmentDescription                                  
   ,'U' AS SegmentSource                                                  
   ,(CASE                                                  
   WHEN SrcPS.SegmentId IS NOT NULL                                  
   THEN SrcPS.SegmentCode                                  
   ELSE SrcMS.SegmentCode                                  
   END) AS SegmentCode                                  
   --,SrcMS.SegmentCode AS SegmentCode                                  
   ,@UserId AS CreatedBy                                  
   ,GETUTCDATE() AS CreateDate                                  
   ,@UserId AS ModifiedBy                                  
   ,GETUTCDATE() AS ModifiedDate                                  
   ,(CASE                                                  
    WHEN SrcPSS.SegmentOrigin = 'U'                                  
   THEN SrcPS.SegmentId                                  
    ELSE SrcMS.SegmentId                                  
    END) AS A_SegmentId                                  
   --,SrcPS.SegmentId AS SrcPSSegmentId                                  
   --,SrcMS.SegmentId AS SrcMSSegmentId                                  
    ,SrcPS.BaseSegmentDescription
   FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
   LEFT JOIN #SourceProjectSegment SrcPS WITH (NOLOCK)                                            
   ON SrcPSS.SegmentId = SrcPS.SegmentId                                                  
   AND SrcPSS.SegmentOrigin = 'U'                                                  
   LEFT JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)                               
   ON SrcPSS.mSegmentId = SrcMS.SegmentId                                                  
   AND SrcPSS.SegmentOrigin = 'M'                                                  
   WHERE SrcPSS.SectionId = @SourceSectionId                                                  
   AND ISNULL(SrcPSS.IsDeleted, 0) = 0                                  
   AND (SrcPS.SegmentId IS NOT NULL                                                  
   OR SrcMS.SegmentId IS NOT NULL)                                  
   AND @IsSectionOpen = 1)                                  
  UNION                                  
   (SELECT                                                  
    NULL AS SegmentStatusId                                                  
   ,@TargetSectionId AS SectionId                                                  
   ,@TargetProjectId AS ProjectId                                                  
   ,@CustomerId AS CustomerId                                                  
   ,SrcMS.SegmentDescription AS SegmentDescription                                                  
   ,'U' AS SegmentSource                                                  
   ,SrcMS.SegmentCode AS SegmentCode                                           
   ,@UserId AS CreatedBy                                  
   ,GETUTCDATE() AS CreateDate                                                  
   ,@UserId AS ModifiedBy                                                  
   ,GETUTCDATE() AS ModifiedDate                                  
   ,SrcMS.SegmentId AS A_SegmentId 
   ,NULL AS BaseSegmentDescription                                                 
   FROM SLCMaster..SegmentStatus SrcMSS WITH (NOLOCK)                                                  
   INNER JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)                                                  
    ON SrcMSS.SegmentId = SrcMS.SegmentId                                                  
   WHERE SrcMSS.SectionId = @SourceMSectionId                                                  
   AND ISNULL(SrcMSS.IsDeleted, 0) = 0                                                  
   AND @IsSectionOpen = 0))                                  
                                  
                                  
     BEGIN -- Update ProjectSegmentStatus and ProjectSegment with correct mappings                                  
      -- Update proper ParentSegmentStatusId                                  
      UPDATE PSS                                  
      SET PSS.ParentSegmentStatusId = TPSS.SegmentStatusId                                  
      FROM ProjectSegmentStatus PSS WITH(NOLOCK)                                  
    INNER JOIN #TargetProjectSegmentStatus TPSS WITH(NOLOCK)                                   
    ON TPSS.A_SegmentStatusId = PSS.ParentSegmentStatusId                                  
    WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;                                  
                                  
      -- Update proper SegmentStatusId into ProjectSegment                                  
      UPDATE PS                                  
      SET PS.SegmentStatusId = PSS.SegmentStatusId                                  
      FROM ProjectSegment PS WITH(NOLOCK)                                  
      INNER JOIN #TargetProjectSegmentStatus PSS WITH(NOLOCK)                                  
    ON PS.SectionId = PSS.SectionId AND PS.A_SegmentId = PSS.SegmentId                                  
    WHERE PS.ProjectId = @TargetProjectId AND PS.SectionId = @TargetSectionId;                                  
                                  
      -- Update proper SegmentId into ProjectSegmentStatus                                  
      UPDATE PSS                                  
      SET PSS.SegmentId = PS.SegmentId                                  
      FROM ProjectSegmentStatus PSS WITH(NOLOCK)                                  
      INNER JOIN ProjectSegment PS WITH(NOLOCK)                                   
    ON PS.SectionId = PSS.SectionId AND PS.SegmentStatusId = PSS.SegmentStatusId                                  
    WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;                         
                     
  --- For Track Changes                      
   DECLARE @tempTrackChanges TABLE (                  
    SegmentStatusID BIGINT,                  
    SegmentStatusTypeId INT,                  
    PrevStatusSegmentStatusTypeId INT,                  
    InitialStatusSegmentStatusTypeId INT,                  
    IsAccepted BIT,                  
    UserId INT,                  
    UserFullName NVARCHAR(100),                  
    CreatedDate Date,                  
    ModifiedById INT,                  
    ModifiedByUserFullName NVARCHAR(100),                  
    ModifiedDate Date,                  
    TenantId INT,                  
    InitialStatus NVARCHAR(50),                  
    IsSegmentStatusChangeBySelection NVARCHAR(50),                  
    CurrentStatus BIT                  
 )                  
 INSERT INTO                  
    @tempTrackChanges                  
 SELECT                  
    SegmentStatusId,                  
    SegmentStatusTypeId,                  
    PrevStatusSegmentStatusTypeId,                  
    InitialStatusSegmentStatusTypeId,                  
    IsAccepted,                  
    UserId,                  
    UserFullName,                  
    CreatedDate,                  
    ModifiedById,                  
    ModifiedByUserFullName,                  
    ModifiedDate,                  
    TenantId,                  
    InitialStatus,                  
    IsSegmentStatusChangeBySelection,                  
    CurrentStatus                  
 FROM                  
    TrackSegmentStatusType WITH (NOLOCK)                  
 WHERE                  
    SectionId = @SourceSectionId                  
    AND ProjectId = @SourceProjectId                  
    AND CustomerId = @CustomerId                  
    AND ISNULL (IsAccepted, 0) = 0                  
 INSERT INTO                  
    TrackSegmentStatusType (                  
    ProjectId,                  
    SectionId,                  
    CustomerId,                  
    SegmentStatusId,                  
    SegmentStatusTypeId,                  
    PrevStatusSegmentStatusTypeId,                  
    InitialStatusSegmentStatusTypeId,                  
    IsAccepted,                  
    UserId,                  
    UserFullName,                  
    CreatedDate,                  
    ModifiedById,                  
    ModifiedByUserFullName,                  
    ModifiedDate,                  
    TenantId,                  
    InitialStatus,                  
    IsSegmentStatusChangeBySelection,                  
    CurrentStatus                  
    )                  
 SELECT                  
    @SourceProjectId,                  
    @TargetSectionId,                  
    @CustomerId,                  
    tpss.SegmentStatusId,                  
    ttc.SegmentStatusTypeId,                  
    ttc.PrevStatusSegmentStatusTypeId,                  
    ttc.InitialStatusSegmentStatusTypeId,                  
    ttc.IsAccepted,                  
    ttc.UserId,                  
    ttc.UserFullName,                  
    ttc.CreatedDate,                  
    ttc.ModifiedById,                  
    ttc.ModifiedByUserFullName,                  
    ttc.ModifiedDate,                  
    ttc.TenantId,                  
    ttc.InitialStatus,                  
    ttc.IsSegmentStatusChangeBySelection,                  
    ttc.CurrentStatus                  
 FROM                  
    @tempTrackChanges ttc                  
    INNER JOIN #TargetProjectSegmentStatus tpss WITH (NOLOCK)                  
    ON tpss.A_SegmentStatusId = ttc.SegmentStatusId                  
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
    INNER JOIN #TargetProjectSegmentStatus tss WITH (NOLOCK)                  
    ON tss.A_SegmentStatusId = ttc.SegmentStatusId                    
   END                              

     SELECT PSS.*                                    
     INTO #TargetSegmentStatus                                    
     FROM ProjectSegmentStatus PSS WITH(NOLOCK)     
  INNER JOIN ProjectSegment PS WITH (NOLOCK)    
  ON PS.SegmentStatusId = PSS.SegmentStatusId    
  AND PS.SegmentId = PSS.SegmentId                                   
     WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId    
  AND ISNULL(PS.IsDeleted,0) = 0                                   
                                     
     BEGIN -- Insert choices from source to target section ProjectChoiceOption                                  
   INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId,                                                  
   CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                                                  
   (SELECT                                                  
     @TargetSectionId AS SectionId                                   
    ,TPSS.SegmentStatusId AS SegmentStatusId                                                  
    ,TPSS.SegmentId AS SegmentId                                                  
    ,SrcMSC.ChoiceTypeId AS ChoiceTypeId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,'U' AS SegmentChoiceSource                                    
    ,SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                                                  
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreateDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                   
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                                                  
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                                                  
     ON TPSS.mSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId                                  
    WHERE TPSS.SectionId = @TargetSectionId                                                  
    AND @IsSectionOpen = 0)                                  
    UNION                                  
    (SELECT                                                  
     @TargetSectionId AS SectionId                                                  
    ,TPSS.SegmentStatusId AS SegmentStatusId                                                  
    ,TPSS.SegmentId AS SegmentId                                  
    ,SrcMSC.ChoiceTypeId AS ChoiceTypeId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,'U' AS SegmentChoiceSource                  
    ,SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                            
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreateDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                                                  
    INNER JOIN #SourceProjectSegmentStatus SPSS WITH (NOLOCK)                                                  
     ON TPSS.SegmentStatusCode = SPSS.SegmentStatusCode                                                  
      AND SPSS.SectionId = @SourceSectionId                                                  
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                                                  
     ON TPSS.mSegmentId = SrcMSC.SegmentId                                                  
    WHERE TPSS.SectionId = @TargetSectionId                                  
    AND SPSS.SegmentOrigin = 'M'                                                  
    AND @IsSectionOpen = 1)                                  
    UNION          
    (SELECT                                                  
     @TargetSectionId AS SectionId                                                  
    ,TPSS.SegmentStatusId AS SegmentStatusId                                                  
    ,TPSS.SegmentId AS SegmentId                                                  
    ,SrcPSC.ChoiceTypeId AS ChoiceTypeId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,'U' AS SegmentChoiceSource                                                  
    ,SrcPSC.SegmentChoiceCode AS SegmentChoiceCode                                           
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreateDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                                                  
    INNER JOIN #SourceProjectSegmentStatus SPSS WITH (NOLOCK)                                                  
     ON TPSS.SegmentStatusCode = SPSS.SegmentStatusCode                                                  
      AND SPSS.SectionId = @SourceSectionId                                                  
    INNER JOIN ProjectSegmentChoice SrcPSC WITH (NOLOCK)                                                  
     ON SPSS.SegmentId = SrcPSC.SegmentId         
  AND SrcPSC.SectionId = SPSS.SectionId              
    WHERE TPSS.SectionId = @TargetSectionId                                                  
    AND SPSS.SegmentOrigin = 'U'                                                  
    AND @IsSectionOpen = 1)                                  
     END                                  
                                  
     BEGIN -- Insert options from source to target section ProjectChoiceOption                                  
   INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson,                           
   ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                                                  
    (SELECT                                                  
    PCH.SegmentChoiceId AS SegmentChoiceId,                                  
    SrcMCO.SortOrder AS SortOrder                                                  
    ,'U' AS ChoiceOptionSource                                      
    ,SrcMCO.OptionJson AS OptionJson                                     
    ,@TargetProjectId AS ProjectId                                                  
    ,@TargetSectionId AS SectionId                                                  
    ,@CustomerId AS CustomerId                      
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                                                  
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreateDate                                  
    ,@UserId AS ModifiedBy                                  
    ,GETUTCDATE() AS ModifiedDate                                 
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                                                  
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                                                  
    ON TPSS.mSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId                                                
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                                                  
    ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                                                  
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                                         
    ON TPSS.SegmentId = PCH.SegmentId                                        
    AND SrcMSC.SegmentChoiceCode = PCH.SegmentChoiceCode                                                  
    WHERE TPSS.SectionId = @TargetSectionId                          
    AND @IsSectionOpen = 0)                                                 
    UNION                                  
    (SELECT                                                  
    PCH.SegmentChoiceId AS SegmentChoiceId                                                  
    ,SrcMCO.SortOrder AS SortOrder                                                  
    ,'U' AS ChoiceOptionSource                                                  
    ,SrcMCO.OptionJson AS OptionJson                                      
    ,@TargetProjectId AS ProjectId                                                  
    ,@TargetSectionId AS SectionId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                                                  
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreateDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                                                  
    INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
    ON TPSS.SegmentStatusCode = SrcPSS.SegmentStatusCode                                                  
    AND SrcPSS.SectionId = @SourceSectionId                                                  
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                                                  
    ON TPSS.mSegmentId = SrcMSC.SegmentId                                                  
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                                                  
    ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                                                  
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                                                  
    ON TPSS.SegmentId = PCH.SegmentId                                                  
    AND SrcMSC.SegmentChoiceCode = PCH.SegmentChoiceCode                                                  
    WHERE TPSS.SectionId = @TargetSectionId                                                  
    AND SrcPSS.SegmentOrigin = 'M'                                             
    AND @IsSectionOpen = 1)                                  
    UNION                                                  
    (SELECT                                                  
    PCH.SegmentChoiceId AS SegmentChoiceId                                                  
    ,SrcPCO.SortOrder AS SortOrder                                                  
    ,'U' AS ChoiceOptionSource                                                  
  ,SrcPCO.OptionJson AS OptionJson                                                  
    ,@TargetProjectId AS ProjectId                        
    ,@TargetSectionId AS SectionId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,SrcPCO.ChoiceOptionCode AS ChoiceOptionCode                                                  
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreateDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                                                  
    INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
    ON TPSS.SegmentStatusCode = SrcPSS.SegmentStatusCode                                                  
    AND SrcPSS.SectionId = @SourceSectionId                                                  
    INNER JOIN ProjectSegmentChoice SrcPSC WITH (NOLOCK)                                                  
    ON SrcPSS.SegmentId = SrcPSC.SegmentId                                                  
    INNER JOIN ProjectChoiceOption SrcPCO WITH (NOLOCK)                                                  
    ON SrcPSC.SegmentChoiceId = SrcPCO.SegmentChoiceId              
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                               
    ON TPSS.SegmentId = PCH.SegmentId                                                  
    AND SrcPSC.SegmentChoiceCode = PCH.SegmentChoiceCode                                                  
    WHERE TPSS.SectionId = @TargetSectionId                                                  
    AND SrcPSS.SegmentOrigin = 'U'                                           
    AND @IsSectionOpen = 1)                                  
     END                                  
                                  
     BEGIN -- Insert selected choice options from source to target                                  
   INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource,                                                  
   IsSelected, SectionId, ProjectId, CustomerId, OptionJson)                                                  
    (SELECT                                                  
     SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                                                  
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                                                  
    ,'U' AS ChoiceOptionSource                                                  
    ,SrcMSCO.IsSelected AS IsSelected                                                  
    ,@TargetSectionId AS SectionId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,NULL AS OptionJson                                                  
    FROM #TargetSegmentStatus TrgPSS WITH (NOLOCK)                                                  
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                                                  
     ON TrgPSS.MSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId                                                  
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                                                  
     ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                                                  
    INNER JOIN SLCMaster..SelectedChoiceOption SrcMSCO WITH (NOLOCK)                                                  
     ON SrcMSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                                                  
      AND SrcMCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                                                  
    WHERE TrgPSS.SectionId = @TargetSectionId                
    AND @IsSectionOpen = 0)                                  
    UNION                                                  
    (SELECT                                                  
     SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                                                  
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                                                  
    ,'U' AS ChoiceOptionSource                                                  
    ,SrcMSCO.IsSelected AS IsSelected                                                  
    ,@TargetSectionId AS SectionId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,SrcMSCO.OptionJson AS OptionJson                                                  
    FROM #TargetSegmentStatus PSST WITH (NOLOCK)                                                  
    INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
     ON PSST.SegmentStatusCode = SrcPSS.SegmentStatusCode                               
      AND SrcPSS.SectionId = @SourceSectionId                                                  
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                                                  
     ON PSST.mSegmentId = SrcMSC.SegmentId                              
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                                                  
     ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                                                  
    INNER JOIN SelectedChoiceOption SrcMSCO WITH (NOLOCK)                                                  
     ON  SrcMSCO.SectionId = @SourceSectionId         
   AND SrcMSCO.ProjectId = @SourceProjectId          
   AND SrcMSCO.CustomerId = @CustomerId           
   AND SrcMSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                                                  
      AND SrcMCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                                  
      AND SrcMSCO.ChoiceOptionSource = 'M'                                                  
    WHERE PSST.SectionId = @TargetSectionId                                                  
    AND SrcPSS.SegmentOrigin = 'M'                                                  
    AND @IsSectionOpen = 1)                                               
    UNION                                                  
    (SELECT                                                  
     SrcPSC.SegmentChoiceCode AS SegmentChoiceCode                                              
    ,SrcPCO.ChoiceOptionCode AS ChoiceOptionCode                                                  
    ,'U' AS ChoiceOptionSource                                                  
    ,SrcMSCO.IsSelected AS IsSelected                                                  
    ,@TargetSectionId AS SectionId             
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,SrcMSCO.OptionJson AS OptionJson                                                  
    FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
    INNER JOIN ProjectSegmentChoice SrcPSC WITH (NOLOCK)                                                  
     ON SrcPSS.SegmentId = SrcPSC.SegmentId                                                  
    INNER JOIN ProjectChoiceOption SrcPCO WITH (NOLOCK)                                                  
     ON SrcPSC.SegmentChoiceId = SrcPCO.SegmentChoiceId                                                  
    INNER JOIN SelectedChoiceOption SrcMSCO WITH (NOLOCK)                                                  
     ON SrcPSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                                                  
      AND SrcPCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                                                  
      AND SrcMSCO.ChoiceOptionSource = 'U'                       
      AND SrcMSCO.SectionId = @SourceSectionId                                                  
    WHERE SrcPSS.SectionId = @SourceSectionId                                                  
    AND SrcPSS.SegmentOrigin = 'U'                                  
    AND @IsSectionOpen = 1)                                  
     END                                  
                                  
     BEGIN -- Add records into ProjectSegmentLink                                  
     DROP TABLE IF EXISTS #ProjectSegmentLinkTemp;                            
   CREATE TABLE #ProjectSegmentLinkTemp                          
   (                          
  SourceSectionCode BIGINT,                          
    SourceSegmentStatusCode BIGINT,                        
  SourceSegmentCode BIGINT,                        
  SourceSegmentChoiceCode BIGINT,                        
  SourceChoiceOptionCode BIGINT,                        
  LinkSource varchar,                        
  TargetSectionCode int,                        
  TargetSegmentStatusCode BIGINT,                        
  TargetSegmentCode BIGINT,                        
  TargetSegmentChoiceCode BIGINT,                        
  TargetChoiceOptionCode BIGINT,                             LinkTarget varchar,                          
  LinkStatusTypeId int,                          
  IsDeleted bit,                          
  CreateDate datetime2,                          
  CreatedBy int,                          
  ModifiedBy int,                          
  ModifiedDate datetime2,                          
  ProjectId int,                          
  CustomerId int,                          
  SegmentLinkCode BIGINT,                          
  SegmentLinkSourceTypeId int,                          
   )                          
   IF(@IsSectionOpen = 0)                          
   BEGIN                          
        INSERT INTO #ProjectSegmentLinkTemp                          
     SELECT                        
    (CASE WHEN MSLNK.SourceSectionCode = @SourceSectionCode THEN @TargetSectionCode  ELSE MSLNK.SourceSectionCode END) AS SourceSectionCode                          
    ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode                          
    ,MSLNK.SourceSegmentCode AS SourceSegmentCode                          
    ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode                          
    ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode                          
    ,(CASE                          
    WHEN MSLNK.SourceSectionCode = @SourceSectionCode THEN 'U'                          
ELSE MSLNK.LinkSource                          
    END) AS LinkSource                          
    ,(CASE  WHEN MSLNK.TargetSectionCode = @SourceSectionCode THEN @TargetSectionCode  ELSE MSLNK.TargetSectionCode  END) AS TargetSectionCode                          
    ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode                          
    ,MSLNK.TargetSegmentCode AS TargetSegmentCode                          
    ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode                          
    ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode                          
    ,(CASE                          
    WHEN MSLNK.TargetSectionCode = @SourceSectionCode THEN 'U'                          
    ELSE MSLNK.LinkTarget                   
    END) AS LinkTarget                          
    ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId                          
    ,MSLNK.IsDeleted AS IsDeleted                          
    ,GETUTCDATE() AS CreateDate                          
    ,@UserId AS CreatedBy                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,MSLNK.SegmentLinkCode as SegmentLinkCode                          
    ,(CASE                          
    WHEN MSLNK.SegmentLinkSourceTypeId = 1 THEN 5                          
    ELSE MSLNK.SegmentLinkSourceTypeId                          
    END) AS SegmentLinkSourceTypeId --INTO #ProjectSegmentLinkTemp                          
    FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)                          
    WHERE (MSLNK.SourceSectionCode = @SourceSectionCode                          
    OR MSLNK.TargetSectionCode = @SourceSectionCode)                          
    AND MSLNK.IsDeleted = 0                          
    AND MSLNK.SourceSectionCode = @SourceSectionCode AND @IsSectionOpen = 0                           
   END                          
   IF (@IsSectionOpen = 1)                          
   BEGIN                          
                            
      INSERT INTO #ProjectSegmentLinkTemp                          
    SELECT                           
    PSL.SourceSectionCode                          
   ,PSL.SourceSegmentStatusCode                          
   ,PSL.SourceSegmentCode                          
   ,PSL.SourceSegmentChoiceCode                          
   ,PSL.SourceChoiceOptionCode                          
   ,PSL.LinkSource                          
   ,PSL.TargetSectionCode                          
   ,PSL.TargetSegmentStatusCode                          
   ,PSL.TargetSegmentCode                          
   ,PSL.TargetSegmentChoiceCode                          
   ,PSL.TargetChoiceOptionCode                          
   ,PSL.LinkTarget                          
   ,PSL.LinkStatusTypeId                          
   ,PSL.IsDeleted                          
   ,PSL.CreateDate                          
   ,PSL.CreatedBy                          
   ,PSL.ModifiedBy                          
   ,PSL.ModifiedDate                          
   ,PSL.ProjectId                          
   ,PSL.CustomerId                          
   ,PSL.SegmentLinkCode                          
        ,(CASE WHEN PSL.SegmentLinkSourceTypeId = 1 THEN 5 ELSE PSL.SegmentLinkSourceTypeId                          
         END) AS SegmentLinkSourceTypeId                                        
   FROM ProjectSegmentLink PSL WITH (NOLOCK)                                
   WHERE PSL.ProjectId = @SourceProjectId                                
   AND (PSL.SourceSectionCode = @SourceSectionCode OR PSL.TargetSectionCode = @SourceSectionCode)                                
   AND PSL.CustomerId = @CustomerId                                
   AND ISNULL(PSL.IsDeleted, 0) = 0                               
   AND PSL.SourceSectionCode = @SourceSectionCode AND @IsSectionOpen = 1                          
   END                          
                                        
   --INSERT ProjectSegmentLink                              
   INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,                                        
   TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,                                        
   LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,                                        
   SegmentLinkCode, SegmentLinkSourceTypeId)                                        
    SELECT                              
     (CASE WHEN SrcPSL.SourceSectionCode = @SourceSectionCode THEN @TargetSectionCode ELSE SrcPSL.SourceSectionCode END) AS SourceSectionCode                                    
    ,SrcPSL.SourceSegmentStatusCode                                        
    ,SrcPSL.SourceSegmentCode                                        
    ,SrcPSL.SourceSegmentChoiceCode                         
    ,SrcPSL.SourceChoiceOptionCode                                        
    ,(CASE WHEN SrcPSL.SourceSectionCode = @SourceSectionCode THEN 'U' ELSE SrcPSL.LinkSource END) AS LinkSource                                
    ,(CASE WHEN SrcPSL.TargetSectionCode = @SourceSectionCode THEN @TargetSectionCode ELSE SrcPSL.TargetSectionCode END) AS TargetSectionCode                                
    ,SrcPSL.TargetSegmentStatusCode                                
    ,SrcPSL.TargetSegmentCode                                        
    ,SrcPSL.TargetSegmentChoiceCode                                        
    ,SrcPSL.TargetChoiceOptionCode                                        
    ,(CASE WHEN (SrcPSL.SourceSectionCode = @SourceSectionCode AND SrcPSL.TargetSectionCode = @SourceSectionCode AND @IsSectionOpen=1) THEN 'U' ELSE SrcPSL.LinkTarget END) AS LinkTarget                                        
    ,SrcPSL.LinkStatusTypeId                                        
    ,SrcPSL.IsDeleted                                        
    ,SrcPSL.CreateDate AS CreateDate                                        
    ,SrcPSL.CreatedBy AS CreatedBy                                        
    ,SrcPSL.ModifiedBy AS ModifiedBy                                        
    ,SrcPSL.ModifiedDate AS ModifiedDate                                        
    ,@TargetProjectId AS ProjectId                                        
    ,@CustomerId AS CustomerId                                        
    ,SrcPSL.SegmentLinkCode                                
    ,SrcPSL.SegmentLinkSourceTypeId                                        
    FROM #ProjectSegmentLinkTemp AS SrcPSL WITH (NOLOCK)                                
       END                                
                  
     BEGIN -- Add record into ProjectDisciplineSection                                  
    INSERT INTO ProjectDisciplineSection (SectionId, Disciplineld, ProjectId, CustomerId, IsActive)                             
    SELECT                                                  
     @TargetSectionId AS SectionId                                                  
    ,MDS.DisciplineId AS Disciplineld                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                         
    ,1 AS IsActive                                                  
    FROM SLCMaster..DisciplineSection MDS WITH (NOLOCK)                                                  
    INNER JOIN LuProjectDiscipline LPD WITH (NOLOCK)                                                  
    ON MDS.DisciplineId = LPD.Disciplineld                                                  
    WHERE MDS.SectionId = @SourceMSectionId                                  
     END                                  
                                  
     BEGIN -- Insert Project and Master notes                                  
    INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,                                        
    CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode)                                                  
     SELECT                                                  
      @TargetSectionId AS SectionId                                  
     ,TrgPSS.SegmentStatusId AS SegmentStatusId                                  
     ,SrcMN.NoteText AS NoteText                         
     ,GETUTCDATE() AS CreateDate                                                  
     ,GETUTCDATE() AS ModifiedDate                                                  
     ,@TargetProjectId AS ProjectId                                                  
     ,@CustomerId AS CustomerId                                                  
     ,'' AS Title                                         
     ,@UserId AS CreatedBy                                                  
     ,@UserId AS ModifiedBy                                                  
     ,@UserName AS CreatedUserName                                                  
     ,@UserName AS ModifiedUserName                                                  
     ,0 AS IsDeleted                                                  
     ,SrcMN.NoteId AS NoteCode                                                  
     FROM SLCMaster..Note SrcMN WITH (NOLOCK)                                                  
     INNER JOIN #TargetSegmentStatus TrgPSS WITH (NOLOCK)                                                
      ON SrcMN.SegmentStatusId = TrgPSS.mSegmentStatusId                                  
     WHERE SrcMN.SectionId = @SourceMSectionId                                  
 AND TrgPSS.SectionId = @TargetSectionId                                                  
     UNION                                  
     SELECT                  
      @TargetSectionId AS SectionId                                                  
     ,TrgPSS.SegmentStatusId AS SegmentStatusId                                                  
     ,SrcPN.NoteText AS NoteText                                                  
     ,GETUTCDATE() AS CreateDate                                                  
     ,GETUTCDATE() AS ModifiedDate                                                  
     ,@TargetProjectId AS ProjectId                                                  
     ,@CustomerId AS CustomerId                      
     ,SrcPN.Title AS Title                                                  
     ,@UserId AS CreatedBy                                                  
     ,@UserId AS ModifiedBy                                                  
     ,@UserName AS CreatedUserName                                                  
     ,@UserName AS ModifiedUserName                                                  
     ,0 AS IsDeleted                                                  
     ,SrcPN.NoteCode AS NoteCode                                                  
     FROM ProjectNote SrcPN WITH (NOLOCK)                                                  
     INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
      ON SrcPN.SegmentStatusId = SrcPSS.SegmentStatusId                                                  
     INNER JOIN #TargetSegmentStatus TrgPSS WITH (NOLOCK)                                  
      ON SrcPSS.SegmentStatusCode = TrgPSS.SegmentStatusCode                                                  
       AND TrgPSS.SectionId = @TargetSectionId                                                  
     WHERE SrcPN.SectionId = @SourceSectionId                                   
     END                                  
                   
     BEGIN -- Insert records into ProjectSegmentRequirementTag                                  
   INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId,                                                  
   CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)                          
    SELECT                                                  
     @TargetSectionId AS SectionId                                                  
    ,PSST.SegmentStatusId AS SegmentStatusId                                                  
    ,MSRT_Template.RequirementTagId AS RequirementTagId                                                  
    ,GETUTCDATE() AS CreateDate                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,@UserId AS CreatedBy                                                  
    ,@UserId AS ModifiedBy                                                  
    FROM SLCMaster..SegmentRequirementTag MSRT_Template WITH (NOLOCK)                                                  
    INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)                                                  
    ON MSRT_Template.SegmentStatusId = PSST.mSegmentStatusId                                                  
    WHERE MSRT_Template.SectionId = @SourceMSectionId                                                  
    AND PSST.SectionId = @TargetSectionId                                                  
    AND @IsSectionOpen = 0                                                 
    UNION                                                  
    SELECT                                                  
     @TargetSectionId AS SectionId                                                  
    ,PSST.SegmentStatusId AS SegmentStatusId                                                  
    ,PSRT_Template.RequirementTagId AS RequirementTagId                                                  
    ,GETUTCDATE() AS CreateDate                        
    ,GETUTCDATE() AS ModifiedDate                                        
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,@UserId AS CreatedBy                                                  
    ,@UserId AS ModifiedBy                                                  
    FROM ProjectSegmentRequirementTag PSRT_Template WITH (NOLOCK)                                  
    INNER JOIN #SourceProjectSegmentStatus PSST_Template WITH (NOLOCK)                                  
    ON PSRT_Template.SegmentStatusId = PSST_Template.SegmentStatusId                                                  
    INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)                                                  
    ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode                                                  
    AND PSST.SectionId = @TargetSectionId                                                  
    WHERE PSRT_Template.SectionId = @SourceSectionId                                                  
    AND @IsSectionOpen = 1                                  
     END                                  
                                  
     BEGIN -- Insert records into ProjectSegmentUserTag                                  
   IF(@IsSectionOpen = 1)                                  
   BEGIN                                  
    INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId,                                                  
    UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)                                                  
     SELECT                            
      @CustomerId AS CustomerId                                                  
     ,@TargetProjectId AS ProjectId                                                  
     ,@TargetSectionId AS SectionId                                   
     ,TrgPSS.SegmentStatusId AS SegmentStatusId                                                  
     ,SrcPSUT.UserTagId AS UserTagId                                                  
     ,GETUTCDATE() AS CreateDate                                                  
     ,@UserId AS CreatedBy                                                  
     ,GETUTCDATE() AS ModifiedDate                                                  
     ,@UserId AS ModifiedBy                                          
     FROM ProjectSegmentUserTag SrcPSUT WITH (NOLOCK)                                                  
     INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                                                  
      ON SrcPSUT.SegmentStatusId = SrcPSS.SegmentStatusId                                                  
     INNER JOIN #TargetSegmentStatus TrgPSS WITH (NOLOCK)                                                  
      ON SrcPSS.SegmentStatusCode = TrgPSS.SegmentStatusCode                                  
    AND TrgPSS.SectionId = @TargetSectionId                                                  
     WHERE SrcPSUT.SectionId = @SourceSectionId                                                  
    END                                  
     END                                  
                                  
     BEGIN -- Insert records into ProjectSegmentGlobalTerm                                  
     INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId,                                                  
     UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)                          
   SELECT                                                  
    @CustomerId AS CustomerId                                                  
   ,@TargetProjectId AS ProjectId                                                  
   ,@TargetSectionId AS SectionId                                                  
   ,PSG.SegmentId AS SegmentId                                                  
   ,NULL AS mSegmentId                                                  
   ,SrcPSGT.UserGlobalTermId AS UserGlobalTermId                              
   ,SrcPSGT.GlobalTermCode AS GlobalTermCode                                                  
   ,SrcPSGT.IsLocked AS IsLocked                                                  
   ,SrcPSGT.LockedByFullName AS LockedByFullName                                                  
   ,SrcPSGT.UserLockedId AS UserLockedId                                             
   ,GETUTCDATE() AS CreatedDate                                                  
   ,@UserId AS CreatedBy                                                  
   ,GETUTCDATE() AS ModifiedDate                                                  
   ,@UserId AS ModifiedBy                                                  
   FROM ProjectSegmentGlobalTerm SrcPSGT WITH (NOLOCK)                                                  
   INNER JOIN #SourceProjectSegment SrcPS WITH (NOLOCK)                                         
    ON SrcPSGT.SegmentId = SrcPS.SegmentId                                             
   INNER JOIN ProjectSegment PSG WITH (NOLOCK)                                  
    ON SrcPS.SegmentCode = PSG.SegmentCode                                                  
     AND PSG.SectionId = @TargetSectionId                                                  
   WHERE SrcPSGT.SectionId = @SourceSectionId                                        
                    
     END                                  
                                  
     BEGIN --Insert  records into ProjectSegmentImage                                  
   INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)                                  
    SELECT                                  
     @TargetSectionId AS SectionId                                                  
    ,SrcPSI.ImageId AS ImageId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,TrgPS.SegmentId AS SegmentId                
    ,SrcPSI.ImageStyle                                  
    FROM ProjectSegmentImage SrcPSI WITH (NOLOCK)                                                  
    INNER JOIN #SourceProjectSegment SrcPS WITH (NOLOCK)                                                  
     ON SrcPSI.SegmentId = SrcPS.SegmentId                                                  
    INNER JOIN ProjectSegment TrgPS WITH (NOLOCK)                                                  
     ON SrcPS.SegmentCode = TrgPS.SegmentCode                                                  
      AND TrgPS.SectionId = @TargetSectionId                                                  
    WHERE SrcPSI.SectionId = @SourceSectionId                                                  
    UNION                                                  
    SELECT                                                  
     @TargetSectionId AS SectionId                                                  
    ,SrcPSI.ImageId AS ImageId                                         
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,SrcPSI.SegmentId AS SegmentId                                    
    ,SrcPSI.ImageStyle                                  
    FROM ProjectSegmentImage SrcPSI WITH (NOLOCK)                                                  
    WHERE SrcPSI.SectionId = @SourceSectionId                                                  
    AND (SrcPSI.SegmentId IS NULL                                  
    OR SrcPSI.SegmentId <= 0)                                  
     END                                  
                                  
     BEGIN -- Insert records into ProjectHyperLink                                  
        print('Copy Hyperlinks');                                  
  --- INSERT ProjectHyperLink                                        
  INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText,                          
  LuHyperLinkSourceTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,A_HyperLinkId)                          
   SELECT                          
    @TargetSectionId AS SectionId                          
   ,PSST.SegmentId AS SegmentId                          
   ,PSST.SegmentStatusId AS SegmentStatusId                          
   ,@TargetProjectId AS ProjectId                                   
   ,@CustomerId as CustomerId                          
   ,MHL_Template.LinkTarget AS LinkTarget                          
   ,MHL_Template.LinkText AS LinkText                          
   ,MHL_Template.LuHyperLinkSourceTypeId AS LuHyperLinkSourceTypeId                          
   ,GETUTCDATE() AS CreateDate                          
   ,@UserId AS CreatedBy                          
   ,GETUTCDATE() AS ModifiedDate                          
   ,@UserId AS ModifiedBy                          
   ,MHL_Template.HyperLinkId AS HyperLinkId                          
   FROM SLCMaster..Note MNT_Template WITH (NOLOCK)                          
   INNER JOIN SLCMaster..HyperLink MHL_Template WITH (NOLOCK)                          
   ON MNT_Template.SegmentStatusId = MHL_Template.SegmentStatusId                          
   INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)                          
   ON MNT_Template.SegmentStatusId = PSST.SegmentStatusCode                          
   AND PSST.SectionId = @TargetSectionId                          
   WHERE MNT_Template.SectionId = @SourceMSectionId                                   
                                        
   -- --Fetch Src Master notes into temp table                          
   --SELECT                          
   -- * INTO #tmp_SrcMasterNote                 
   --FROM SLCMaster..Note WITH (NOLOCK)                          
   --WHERE SectionId = @SourceMSectionId;                          
                          
   ----Fetch tgt project notes into temp table                          
   --SELECT                          
   -- * INTO #tmp_TgtProjectNote                  
   --FROM ProjectNote PNT WITH (NOLOCK)                          
   --WHERE SectionId = @TargetSectionId;                          
                          
   ----UPDATE NEW HyperLinkId IN NoteText                          
   --DECLARE @HyperLinkLoopCount INT = 1;                          
   --DECLARE @HyperLinkTable TABLE (                          
-- RowId INT                          
   --   ,HyperLinkId INT                          
   --   ,MasterHyperLinkId INT                          
   --);                          
                        
   --INSERT INTO @HyperLinkTable (RowId, HyperLinkId, MasterHyperLinkId)                          
   -- SELECT                          
   --  ROW_NUMBER() OVER (ORDER BY PHL.HyperLinkId ASC) AS RowId                                 
   -- ,PHL.HyperLinkId                          
   -- ,PHL.A_HyperLinkId                          
   -- FROM ProjectHyperLink PHL WITH (NOLOCK)                          
   -- WHERE PHL.SectionId = @TargetSectionId;                          
                          
   --declare @HyperLinkTableRowCount INT=(SELECT  COUNT(*)  FROM @HyperLinkTable)                          
   --WHILE (@HyperLinkLoopCount <= @HyperLinkTableRowCount)                          
   --BEGIN                          
   --DECLARE @HyperLinkId INT = 0;                          
   --DECLARE @MasterHyperLinkId INT = 0;                          
                          
   --SELECT                          
   -- @HyperLinkId = HyperLinkId                          
   --   ,@MasterHyperLinkId = MasterHyperLinkId                          
   --FROM @HyperLinkTable                          
   --WHERE RowId = @HyperLinkLoopCount;                          
                          
   --UPDATE PNT                          
   --SET PNT.NoteText =                          
   --REPLACE(PNT.NoteText, '{HL#' + CAST(@MasterHyperLinkId AS NVARCHAR(MAX)) + '}',                          
   --'{HL#' + CAST(@HyperLinkId AS NVARCHAR(MAX)) + '}')                          
   --FROM #tmp_SrcMasterNote MNT_Template WITH (NOLOCK)                          
   --INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)                          
   -- ON MNT_Template.SegmentStatusId = PSST.SegmentStatusCode                              -- AND PSST.SectionId = @TargetSectionId                          
   --INNER JOIN #tmp_TgtProjectNote PNT WITH (NOLOCK)                          
   -- ON PSST.SegmentStatusId = PNT.SegmentStatusId                          
   --WHERE MNT_Template.SectionId = @SourceMSectionId                          
                          
   --SET @HyperLinkLoopCount = @HyperLinkLoopCount + 1;                          
   --END                          
                          
   ----Update NoteText back into original table from temp table                          
   --UPDATE PNT                          
   --SET PNT.NoteText = TMP.NoteText                          
   --FROM ProjectNote PNT WITH (NOLOCK)                          
   --INNER JOIN #tmp_TgtProjectNote TMP WITH (NOLOCK)                          
   -- ON PNT.NoteId = TMP.NoteId                          
   --WHERE PNT.SectionId = @TargetSectionId;                          
   END                                  
                                  
     BEGIN -- Insert records into ProjectNoteImage                                  
   INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)                                                  
    SELECT                                                  
     PN.NoteId AS NoteId                                                  
    ,@TargetSectionId AS SectionId                                                  
    ,SrcPNI.ImageId AS ImageId                                                  
    ,@TargetProjectId AS ProjectId                                                  
    ,@CustomerId AS CustomerId                                                  
    FROM ProjectNoteImage SrcPNI WITH (NOLOCK)                                                  
    INNER JOIN ProjectNote SrcPN WITH (NOLOCK)                                              
     ON SrcPNI.NoteId = SrcPN.NoteId                                                  
    INNER JOIN ProjectNote PN WITH (NOLOCK)                                                  
     ON SrcPN.NoteCode = PN.NoteCode                                                  
      AND PN.SectionId = @TargetSectionId                                  
    WHERE SrcPNI.SectionId = @SourceSectionId                                  
     END                                  
                                  
     BEGIN -- Insert records into Header                                  
   INSERT INTO Header ([ProjectId],[SectionId],[CustomerId],[Description],[IsLocked],                                  
   [LockedByFullName],[LockedBy],[ShowFirstPage],[CreatedBy],[CreatedDate],[ModifiedBy],                                  
   [ModifiedDate],[TypeId],[AltHeader],[FPHeader],[UseSeparateFPHeader],[HeaderFooterCategoryId],                                  
   [DateFormat],[TimeFormat],[HeaderFooterDisplayTypeId],[DefaultHeader],[FirstPageHeader],                                  
   [OddPageHeader],[EvenPageHeader],[DocumentTypeId],[IsShowLineAboveHeader],[IsShowLineBelowHeader])                                  
    SELECT                                                  
     @TargetProjectId AS ProjectId                                                  
    ,@TargetSectionId AS SectionId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,[Description]                                                  
    ,NULL AS IsLocked                                   
    ,NULL AS LockedByFullName                                                  
    ,NULL AS LockedBy                                                  
    ,ShowFirstPage                                                  
    ,@UserId AS CreatedBy        
    ,GETUTCDATE() AS CreatedDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    ,TypeId                                                  
    ,AltHeader                                  
    ,FPHeader                                  
    ,UseSeparateFPHeader                                                  
    ,HeaderFooterCategoryId                                                  
    ,[DateFormat]                                  
    ,TimeFormat                                  
    ,HeaderFooterDisplayTypeId                                  
    ,DefaultHeader                                  
    ,FirstPageHeader                                  
    ,OddPageHeader                                  
    ,EvenPageHeader                                  
    ,DocumentTypeId                                  
    ,IsShowLineAboveHeader                                  
    ,IsShowLineBelowHeader                                  
    FROM Header WITH (NOLOCK)                                  
    WHERE SectionId = @SourceSectionId                                  
     END                                  
                                  
 BEGIN -- Insert records into Footer                                  
   INSERT INTO Footer ([ProjectId],[SectionId],[CustomerId],[Description],[IsLocked],                                 
   [LockedByFullName],[LockedBy],[ShowFirstPage],[CreatedBy],[CreatedDate],[ModifiedBy],                          
   [ModifiedDate],[TypeId],[AltFooter],[FPFooter],[UseSeparateFPFooter],[HeaderFooterCategoryId],                                  
   [DateFormat],[TimeFormat],[HeaderFooterDisplayTypeId],[DefaultFooter],[FirstPageFooter],                                  
   [OddPageFooter],[EvenPageFooter],[DocumentTypeId],[IsShowLineAboveFooter],[IsShowLineBelowFooter])                                  
    SELECT                                                  
     @TargetProjectId AS ProjectId          
    ,@TargetSectionId AS SectionId                                                  
    ,@CustomerId AS CustomerId                                                  
    ,[Description]                                                  
    ,NULL AS IsLocked                            
    ,NULL AS LockedByFullName                                                  
    ,NULL AS LockedBy                                                  
    ,ShowFirstPage                                                  
    ,@UserId AS CreatedBy                                                  
    ,GETUTCDATE() AS CreatedDate                                                  
    ,@UserId AS ModifiedBy                                                  
    ,GETUTCDATE() AS ModifiedDate                                                  
    ,TypeId                
    ,AltFooter                                                  
    ,FPFooter                                                  
    ,UseSeparateFPFooter                                                  
    ,HeaderFooterCategoryId                                                  
    ,[DateFormat]                                  
    ,TimeFormat                                  
    ,HeaderFooterDisplayTypeId                                  
    ,DefaultFooter                                  
    ,FirstPageFooter                                  
    ,OddPageFooter                   
    ,EvenPageFooter                                  
    ,DocumentTypeId                                  
    ,IsShowLineAboveFooter                             
    ,IsShowLineBelowFooter                                  
    FROM Footer WITH (NOLOCK)                                                  
    WHERE SectionId = @SourceSectionId                                              
     END                                  
                                  
   BEGIN -- Insert records into ProjectSegmentReferenceStandard                                  
   INSERT INTO [dbo].[ProjectSegmentReferenceStandard]                                  
     ([SectionId],[SegmentId],[RefStandardId],[RefStandardSource],[mRefStandardId],[CreateDate],                                  
     [CreatedBy],[ModifiedDate],[ModifiedBy],[mSegmentId],[ProjectId],[CustomerId],[RefStdCode],[IsDeleted])                                  
   SELECT                                  
   @TargetSectionId AS SectionId                                  
   ,TrgPSS.[SegmentId]                                  
   ,PSRS.[RefStandardId]                                  
   ,'U' AS RefStandardSource                                  
   ,PSRS.[mRefStandardId]                                  
   ,PSRS.[CreateDate]                                  
   ,PSRS.[CreatedBy]                                  
   ,PSRS.[ModifiedDate]                                  
   ,PSRS.[ModifiedBy]                                  
   ,NULL AS [mSegmentId]                                  
   ,@TargetProjectId AS ProjectId                                  
   ,@CustomerId AS CustomerId                                  
,PSRS.[RefStdCode]                                  
   ,PSRS.[IsDeleted]                                  
   FROM ProjectSegmentReferenceStandard PSRS WITH(NOLOCK)                                  
   INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH(NOLOCK) ON SrcPSS.SegmentId = PSRS.SegmentId                                  
   INNER JOIN #TargetSegmentStatus TrgPSS WITH(NOLOCK) ON TrgPSS.A_SegmentStatusId = SrcPSS.SegmentStatusId                                  
   WHERE PSRS.SectionId = @SourceSectionId AND ISNULL(PSRS.IsDeleted,0) = 0                                  
   UNION                                  
   SELECT                                  
   @TargetSectionId AS SectionId                                  
   ,TrgPSS.[SegmentId]                                  
   ,MSRS.[RefStandardId]                                  
   ,'U' AS RefStandardSource                                  
   ,0 AS mRefStandardId                                  
   ,GETUTCDATE() AS [CreateDate]                
   ,@UserId AS [CreatedBy]                                  
   ,GETUTCDATE() AS [ModifiedDate]                                  
   ,@UserId AS [ModifiedBy]                                  
   ,NULL AS [mSegmentId]                                  
   ,@TargetProjectId AS ProjectId                                  
   ,@CustomerId AS CustomerId                                  
   ,SMRS.RefStdCode AS RefStdCode                                     
   ,CAST(0 AS BIT) AS IsDeleted                                  
   FROM SLCMaster..SegmentReferenceStandard MSRS                                  
   INNER JOIN SLCMaster..ReferenceStandard SMRS WITH (NOLOCK) ON MSRS.RefStandardId = SMRS.RefStdId                                  
   INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH(NOLOCK) ON SrcPSS.mSegmentId = MSRS.SegmentId                                  
   INNER JOIN #TargetSegmentStatus TrgPSS WITH(NOLOCK) ON TrgPSS.A_SegmentStatusId = SrcPSS.SegmentStatusId                                  
   WHERE MSRS.SectionId = @SourceMSectionId      
   END                                  
                                  
     BEGIN -- Insert records into ProjectReferenceStandard                                  
   INSERT INTO [dbo].[ProjectReferenceStandard]([ProjectId],[RefStandardId],[RefStdSource],[mReplaceRefStdId],                                  
     [RefStdEditionId],[IsObsolete],[RefStdCode],[PublicationDate],[SectionId],[CustomerId],[IsDeleted])                                  
   SELECT                                   
   @TargetProjectId AS ProjectId,                                  
   PRS.RefStandardId,                                  
   PRS.RefStdSource,                                  
   PRS.mReplaceRefStdId,                                  
PRS.RefStdEditionId,                                  
   PRS.IsObsolete,                                  
   PRS.RefStdCode,                                  
   PRS.PublicationDate,                                  
   @TargetSectionId AS SectionId,                    
   @CustomerId AS CustomerId,                                  
   PRS.IsDeleted                                  
   FROM ProjectReferenceStandard PRS  WITH(NOLOCK) WHERE PRS.SectionId = @SourceSectionId                                  
     END                                  
                                  
     BEGIN -- Insert records into SegmentComment                                  
    --Copy source Comments in temp table                                                    
     SELECT SC.* INTO #tmp_SrcComment                                  
     FROM SegmentComment SC WITH (NOLOCK)                                        
     WHERE SC.ProjectId = @SourceProjectId                                        
     AND SC.SectionId  = @SourceSectionId                                  
     AND ISNULL(SC.IsDeleted, 0) = 0;                                       
                                  
      --Insert SegmentComment                                  
      INSERT INTO SegmentComment (ProjectId,SectionId,SegmentStatusId,ParentCommentId,CommentDescription,CustomerId,CreatedBy ,CreateDate                                   
     ,ModifiedBy ,ModifiedDate ,CommentStatusId ,IsDeleted ,userFullName,A_SegmentCommentId)                                  
     Select                                    
    @SourceProjectId                                  
      ,@TargetSectionId                                  
      ,SC_Src.SegmentStatusId                                  
      ,SC_Src.ParentCommentId                                  
      ,SC_Src.CommentDescription                                  
      ,SC_Src.CustomerId                                  
      ,SC_Src.CreatedBy                                  
      ,SC_Src.CreateDate                                  
      ,SC_Src.ModifiedBy                                  
      ,SC_Src.ModifiedDate                                  
      ,SC_Src.CommentStatusId                                  
      ,SC_Src.IsDeleted                                  
      ,SC_Src.userFullName                                  
      ,SC_Src.SegmentCommentId AS A_SegmentCommentId                                  
      FROM  #tmp_SrcComment SC_Src WITH(Nolock)                                  
      where SC_Src.ProjectId = @SourceProjectId                                   
      AND SC_Src.SectionId = @SourceSectionId                                  
                                  
      --UPDATE SegmentStatusId in TGT Comment table                                   
      Update SC SET SC.SegmentStatusId = PSS.SegmentStatusId                                  
    FROM ProjectSegmentStatus PSS WITH(Nolock)                                  
    Inner join SegmentComment SC  WITH(Nolock)                                  
   On PSS.A_SegmentStatusId = SC.SegmentStatusId                                   
    WHERE SC.ProjectId = @TargetProjectId                                  
    AND SC.SectionId=@TargetSectionId                                 
    AND PSS.SectionId =@TargetSectionId                                            
                        
      SELECT SegmentCommentId ,A_SegmentCommentId INTO #NewOldCommentIdMapping                                        
    FROM SegmentComment SC WITH (NOLOCK)                                        
     WHERE SC.ProjectId = @SourceProjectId                                  
     AND SC.SectionId =  @TargetSectionId                                    
     AND ISNULL(SC.IsDeleted, 0) = 0;                                      
                                  
      --UPDATE ParentCommentId in Target Comment table                                   
      UPDATE TGT_TMP                                             
      SET TGT_TMP.ParentCommentId = NOSM.SegmentCommentId                                        
     FROM SegmentComment TGT_TMP WITH (NOLOCK)                                        
     INNER JOIN #NewOldCommentIdMapping NOSM WITH (NOLOCK)                                        
      ON TGT_TMP.ParentCommentId = NOSM.A_SegmentCommentId                                        
     WHERE TGT_TMP.ProjectId = @TargetProjectId                                  
     and TGT_TMP.SectionId = @TargetSectionId                                  
     END                                  
    END                                  
                                  
    BEGIN -- Update ProjectSegmentStatus and reset mSegmentStatusId and mSegmentId                                  
      UPDATE PSS                                  
      SET PSS.mSegmentStatusId = NULL, PSS.mSegmentId = NULL                     
      FROM ProjectSegmentStatus PSS WITH (NOLOCK)                                                  
      WHERE PSS.SectionId = @TargetSectionId;                                  
                         
     ---- Upadate SegmentDescription at sequence Number 0                          
  UPDATE PS  SET PS.SegmentDescription = @Description  FROM ProjectSegmentStatus PSS WITH (NOLOCK)                          
  INNER JOIN ProjectSegment PS WITH (NOLOCK) ON  PS.SectionId = @TargetSectionId                         
  AND PSS.SegmentId = PS.SegmentId  WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND     PSS.CustomerId = @CustomerId AND PSS.SequenceNumber = 0 AND PSS.IndentLevel = 0;                          
                          
    END                       
                                 
    SELECT @TargetSectionId AS TargetSectionId, @IsSectionOpen AS IsSectionOpen;                                 
    END                              
    SELECT @ErrorMessage as ErrorMessage,@TargetSectionId as TargetSectionId;                         
                       
END 

GO

ALTER PROCEDURE [dbo].[usp_GetSegmentsForPrint] (                                                              
  @ProjectId INT                                                              
 ,@CustomerId INT                                                              
 ,@SectionIdsString NVARCHAR(MAX)                                                              
 ,@UserId INT                                                              
 ,@CatalogueType NVARCHAR(MAX)                                                              
 ,@TCPrintModeId INT = 1                                                              
 ,@IsActiveOnly BIT = 1                                                            
 ,@IsPrintMasterNote BIT =0                                                     
 ,@IsPrintProjectNote BIT =0                                 
 ,@DocumentTypeId INT =1                             
 )                                                                
AS                                                                
BEGIN                                                                  
SET NOCOUNT ON;                                                              
 DECLARE @PProjectId INT = @ProjectId;                                                                          
 DECLARE @PCustomerId INT = @CustomerId;                                                                          
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                                                                          
 DECLARE @PUserId INT = @UserId;                                                                          
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                                                                          
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                                                                       
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;                                                        
 DECLARE @PIsPrintMasterNote BIT =@IsPrintMasterNote;                                                      
 DECLARE @PIsPrintProjectNote BIT =@IsPrintProjectNote;                                                                        
 DECLARE @IsFalse BIT = 0;                        
 DECLARE @IsTrue BIT = 1;                                                                          
 DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);                                                                          
 DECLARE @STCPrintModeId NVARCHAR(2) = convert(NVARCHAR, @TCPrintModeId);                                                                          
 DECLARE @SIsActiveOnly NVARCHAR(2) = convert(NVARCHAR, @IsActiveOnly);                                                                          
 DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);                                                                          
 DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);                                                                          
 DECLARE @MasterDataTypeId INT = (                                                                          
   SELECT P.MasterDataTypeId                                                                          
   FROM Project P WITH (NOLOCK)                                                                          
   WHERE P.ProjectId = @PProjectId                                                                          
    AND P.CustomerId = @PCustomerId                                                                          
   );                                                                          
 DECLARE @SectionIdTbl TABLE (SectionId INT);                                                                          
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                                                
 DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';            
 DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                                                                         
 DECLARE @Lu_InheritFromSection INT = 1;                         
 DECLARE @Lu_AllWithMarkups INT = 2;                                         
 DECLARE @Lu_AllWithoutMarkups INT = 3;                                                       
 DECLARE @ImagSegment int =1                                           
 DECLARE @ImageHeaderFooter int =3                                                        
 DECLARE @State VARCHAR(50)=''                                                          
 DECLARE @City VARCHAR(50)=''                                                          
                                                                          
 --CONVERT STRING INTO TABLE                                                                                   
 INSERT INTO @SectionIdTbl (SectionId)                                                                          
 SELECT *                                                                          
 FROM dbo.fn_SplitString(@PSectionIdsString, ',');                                                                          
                                                                          
 --CONVERT CATALOGUE TYPE INTO TABLE                                                                                          
 IF @PCatalogueType IS NOT NULL                                                                      
  AND @PCatalogueType != 'FS'                                                                          
 BEGIN                                                                          
  INSERT INTO @CatalogueTypeTbl (TagType)                                                                          
  SELECT *                                                                          
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                                                     
                                                                          
  IF EXISTS (                                                                          
    SELECT *                                                                
    FROM @CatalogueTypeTbl                                                                          
    WHERE TagType = 'OL'                                                       
    )                                                                          
  BEGIN                                                                          
   INSERT INTO @CatalogueTypeTbl                                                               
   VALUES ('UO')                                                                          
  END                                                                          
                                                                          
  IF EXISTS (                                                                          
    SELECT TOP 1 1                                                                          
    FROM @CatalogueTypeTbl                                                                          
    WHERE TagType = 'SF'                                                                          
    )                                                                          
  BEGIN                                                                          
   INSERT INTO @CatalogueTypeTbl                                                     
   VALUES ('US')                                                                          
  END                                                                          
 END                                                                          
                                                          
 IF EXISTS (SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE Projectid=@PProjectId AND PA.StateProvinceId=99999999 AND PA.StateProvinceName IS NULL)                                                          
 BEGIN                                              
  SELECT TOP 1 @State = ISNULL(concat(rtrim(VALUE),','),'') FROM ProjectGlobalTerm  WITH (NOLOCK)                              
  WHERE Projectid = @PProjectId AND (NAME = 'Project Location State' OR Name ='Project Location Province')                                                       
  OPTION (FAST 1)                                                         
 END                                                       
 ELSE                                                          
 BEGIN                               
  SELECT TOP 1 @State = CONCAT(RTRIM(SP.StateProvinceAbbreviation),', ') FROM LuStateProvince SP WITH (NOLOCK)                                        
  INNER JOIN ProjectAddress PA WITH (NOLOCK) ON PA.StateProvinceId = SP.StateProvinceID                                                           
  WHERE ProjectId = @PProjectId                                                       
  OPTION (FAST 1)                                                         
 END                                                          
                                                           
 IF EXISTS(SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND PA.CityId=99999999 AND PA.CityName IS NULL)                                                          
 BEGIN                                                          
SELECT TOP 1 @City =ISNULL(VALUE,'') FROM ProjectGlobalTerm  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND NAME = 'Project Location City'                                                        
  OPTION (FAST 1)                                                        
 END                                                          
 ELSE                                                          
 BEGIN                                                          
  SELECT TOP 1 @City = CITY FROM LuCity C WITH (NOLOCK) INNER JOIN ProjectAddress PA ON PA.CityId = C.CityId WHERE Projectid=@PProjectId                                                        
  OPTION (FAST 1)                                       
 END                                                          
                                                          
                                                                          
 --DROP TEMP TABLES IF PRESENT                                                     
 --DROP TABLE                                                           
                             
 --IF EXISTS #tmp_ProjectSegmentStatus;                         
 CREATE TABLE #tmp_ProjectSegmentStatus (                      
SegmentStatusId BIGINT                                                          
,SectionId INT                                                                        
,ParentSegmentStatusId BIGINT                                                                         
,mSegmentStatusId  BIGINT                      
,mSegmentId INT                                                               
, SegmentId BIGINT                                                                 
,SegmentSource NVARCHAR(10)                                                                     
,SegmentOrigin NVARCHAR(10)                                                             
,IndentLevel INT                                                                         
,SequenceNumber  INT                                                                        
,SegmentStatusTypeId INT                                                                        
,SegmentStatusCode BIGINT                                                                       
,IsParentSegmentStatusActive BIT                                                                         
,IsShowAutoNumber BIT                                              
,FormattingJson NVARCHAR(MAX)                                                                         
,TagType NVARCHAR(50)                                      
,SpecTypeTagId INT                                                                      
,IsRefStdParagraph BIT                                                                   
,IsPageBreak BIT                          
,TrackOriginOrder NVARCHAR(100)                                                                         
,MTrackDescription NVARCHAR(MAX)                                                   
,TrackChangeType NVARCHAR(50)                              
,IsStatusTrack BIT                      
)                                         
                                 
  DROP TABLE                                                                          
                                                                          
 IF EXISTS #tmp_Template;                                                                          
  DROP TABLE                                                                 
                                                                          
 IF EXISTS #tmp_SelectedChoiceOption;                                                                          
  DROP TABLE                                                                          
                                                                          
 IF EXISTS #tmp_ProjectSection;                                                                          
  --FETCH SECTIONS DATA IN TEMP TABLE                                                                                          
  SELECT PS.SectionId                                                                          
   ,PS.ParentSectionId                                                                          
   ,PS.mSectionId                                                                        
   ,PS.ProjectId                                                                          
   ,PS.CustomerId                                                                          
 ,PS.UserId                                                                          
   ,PS.DivisionId                                                              
   ,PS.DivisionCode                                                                          
   ,PS.Description                                 
   ,PS.LevelId                                                                          
   ,PS.IsLastLevel                                                                 
   ,PS.SourceTag                                                                          
   ,PS.Author                                                                          
   ,PS.TemplateId                                                       
   ,PS.SectionCode                                                                          
   ,PS.IsDeleted                                                               
   ,PS.SpecViewModeId                                                                          
   ,PS.IsTrackChanges                                                                          
  INTO #tmp_ProjectSection                                                                          
  FROM ProjectSection PS WITH (NOLOCK)                                                                          
  WHERE PS.ProjectId = @PProjectId                                                                          
   AND PS.CustomerId = @PCustomerId                                                                          
   AND ISNULL(PS.IsDeleted, 0) = 0;                                                                          
                                 
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE WITH TRACK CHANGES                                      
IF ((@PTCPrintModeId = @Lu_AllWithMarkups OR @PTCPrintModeId = @Lu_InheritFromSection) AND @PIsActiveOnly = @IsTrue)                         
BEGIN                          
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE                         
INSERT INTO                     
  #tmp_ProjectSegmentStatus                    
  EXEC usp_GetSegmentStatusDataWithTCForPrint @IsActiveOnly,@TCPrintModeId,@PSectionIdsString,@PCatalogueType,@PProjectId,@PCustomerId                        
    
  --SELECT SEGMENT STATUS DATA                                   
 SELECT SegmentStatusId,SectionId,ParentSegmentStatusId,mSegmentStatusId,mSegmentId,SegmentId,SegmentSource,SegmentOrigin                                                      
 ,IndentLevel,SequenceNumber,SegmentStatusTypeId,isnull(SegmentStatusCode,0) as SegmentStatusCode,IsParentSegmentStatusActive                                                      
 ,IsShowAutoNumber, COALESCE(TagType,'')TagType,isnull(SpecTypeTagId,0)as SpecTypeTagId,COALESCE(FormattingJson,'') as FormattingJson                                 
 ,IsRefStdParagraph,IsPageBreak,COALESCE(TrackOriginOrder,'') AS TrackOriginOrder, @PProjectId as ProjectId                                                      
  ,@PCustomerId as CustomerId ,IsStatusTrack ,TrackChangeType                                    
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                                             
 WHERE @IsActiveOnly = 0 OR TrackChangeType IN ('AddedParagraph', 'RemovedParagraph','Untouched')                                          
 ORDER BY PSST.SectionId                                                                          
  ,PSST.SequenceNumber;                       
                      
END                      
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE WITHOUT TRACK CHANGES                      
ELSE                  
BEGIN                      
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE                        
INSERT INTO #tmp_ProjectSegmentStatus                                                                                           
 SELECT PSST.SegmentStatusId                                                                    
  ,PSST.SectionId                              
  ,PSST.ParentSegmentStatusId                                                                          
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                                                                          
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                                                                          
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId                                                       
  ,PSST.SegmentSource                                                                          
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                                                                          
  ,CASE                                                                           
   WHEN PSST.IndentLevel > 8                    
    THEN CAST(8 AS TINYINT)                                                            
   ELSE PSST.IndentLevel                                                                          
   END AS IndentLevel                                                                          
  ,PSST.SequenceNumber                                                                   
  ,PSST.SegmentStatusTypeId                                                                          
  ,PSST.SegmentStatusCode                                                                          
  ,PSST.IsParentSegmentStatusActive                                                                          
  ,PSST.IsShowAutoNumber                                               
  ,PSST.FormattingJson                                                                          
  ,STT.TagType                                       
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                                                                          
  ,PSST.IsRefStdParagraph                                                                     
  ,PSST.IsPageBreak                                  
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                                                                          
  ,PSST.MTrackDescription                                                      
  ,'' AS TrackChangeType                               
  ,CAST(0 AS BIT) AS IsStatusTrack                                          
 FROM @SectionIdTbl SIDTBL                                                                        
 INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.SectionId = SIDTBL.SectionId                                                                          
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                                                     
 WHERE PSST.ProjectId = @PProjectId                                                                
  AND PSST.CustomerId = @PCustomerId                                                                          
  AND (                                                                          
   PSST.IsDeleted IS NULL                                      
   OR PSST.IsDeleted = 0                                                                          
   )                                                                          
  AND (                                                                          
   @PIsActiveOnly = @IsFalse                                                   
   OR (                                                                          
     PSST.SegmentStatusTypeId>0 AND PSST.SegmentStatusTypeId<6 AND PSST.IsParentSegmentStatusActive=1                                
    )                                                                          
   OR (PSST.IsPageBreak = 1)                                                                          
   )                                                                          
  AND (                                                                          
   @PCatalogueType = 'FS'                      
   OR STT.TagType IN (                                                                          
SELECT TagType                                                                          
    FROM @CatalogueTypeTbl                                                                          
    )                                                                          
   )                                                                         
                      
 --SELECT SEGMENT STATUS DATA                                   
 SELECT SegmentStatusId,SectionId,ParentSegmentStatusId,mSegmentStatusId,mSegmentId,SegmentId,SegmentSource,SegmentOrigin                                                      
 ,IndentLevel,SequenceNumber,SegmentStatusTypeId,isnull(SegmentStatusCode,0) as SegmentStatusCode,IsParentSegmentStatusActive                                                      
 ,IsShowAutoNumber, COALESCE(TagType,'')TagType,isnull(SpecTypeTagId,0)as SpecTypeTagId,COALESCE(FormattingJson,'') as FormattingJson                                                      
 ,IsRefStdParagraph,IsPageBreak,COALESCE(TrackOriginOrder,'') AS TrackOriginOrder, @PProjectId as ProjectId                                                      
  ,@PCustomerId as CustomerId ,IsStatusTrack ,TrackChangeType                                    
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                                             
 ORDER BY PSST.SectionId                                                                  
  ,PSST.SequenceNumber;                            
END                      
                      
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;                                                           
                                                      
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE   
SELECT PSST.SegmentStatusId                                                                      
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                                         
  ,PSST.SectionId                                                                         
 INTO #tmpProjectSegmentStatusForNote                                                                            
 FROM @SectionIdTbl SIDTBL                                                                          
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)  ON PSST.SectionId = SIDTBL.SectionId                                                                           
 --WHERE PSST.ProjectId = @PProjectId                                                           
 --AND PSST.CustomerId = @PCustomerId                                                           
                                                          
 --SELECT SEGMENT DATA                
 SELECT PSST.SegmentId                                                                          
  ,PSST.SegmentStatusId                                                                          
  ,PSST.SectionId                                                                          
  ,(                                                                          
CASE                                             
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups                                                                          
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                                                                          
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups                                                                          
     THEN COALESCE(PSG.SegmentDescription, '')                                                                          
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                                                       
     AND PS.IsTrackChanges = 1                                                                          
     THEN COALESCE(PSG.SegmentDescription, '')                                                                          
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                                                                          
     AND PS.IsTrackChanges = 0                
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                                                                          
    ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                                                                          
    END                                                                          
   ) AS SegmentDescription                                                                          
  ,PSG.SegmentSource                          
  ,ISNULL(PSG.SegmentCode ,0)SegmentCode                                                      
  ,@PProjectId as ProjectId                                                      
  ,@PCustomerId as CustomerId                                                      
 FROM @SectionIdTbl STBL                                                       
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                                                                          
 ON PSST.SectionId = STBL.SectionId                                                      
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                                                           
 AND PS.SectionId  = STBL.SectionId                                                                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId                                                        
 AND PSG.SectionId= STBL.SectionId                                                  
 WHERE PSG.ProjectId = @PProjectId                              
  AND PSG.CustomerId = @PCustomerId                                                                          
 UNION  ALL                                                                      
 SELECT MSG.SegmentId                                                                          
,PSST.SegmentStatusId                                                                          
  ,PSST.SectionId                                                             
  ,CASE                                                                    
   WHEN PSST.ParentSegmentStatusId = 0                AND PSST.SequenceNumber = 0                      
    THEN PS.Description                                                                          
   ELSE ISNULL(MSG.SegmentDescription, '')                                                                          
   END AS SegmentDescription                                                                          
  ,MSG.SegmentSource                                                                          
  ,ISNULL(MSG.SegmentCode ,0)SegmentCode                                          
  ,@PProjectId as ProjectId                                      
  ,@PCustomerId as CustomerId                                                      
 FROM @SectionIdTbl STBL                                                       
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                                                                          
 ON PSST.SectionId = STBL.SectionId AND ISNULL(PSST.mSegmentId,0) > 0                                                      
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                                                        
 AND PS.SectionId  = STBL.SectionId                                                                           
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                                                   
 WHERE PS.ProjectId = @PProjectId                                                                          
  AND PS.CustomerId = @PCustomerId                                                       
   AND ISNULL(PSST.mSegmentId,0) > 0                                                            
                                                              
                                                       
 --FETCH TEMPLATE DATA INTO TEMP TABLE                                                                                              
 SELECT *                                                                          
 INTO #tmp_Template                                                                          
 FROM (                            
  SELECT T.TemplateId                                                                          
   ,T.Name                                                                          
   ,T.TitleFormatId                                                                          
   ,T.SequenceNumbering                                                                          
   ,T.IsSystem                                                                          
   ,T.IsDeleted                                                                          
   ,0 AS SectionId                                                                    
 ,T.ApplyTitleStyleToEOS                                                                      
   ,CAST(1 AS BIT) AS IsDefault                                                                          
  FROM Template T WITH (NOLOCK)                                                                          
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, 1)                                                                          
  WHERE P.ProjectId = @PProjectId                                                                          
   AND P.CustomerId = @PCustomerId                                                                          
                   
  UNION                                                                          
                                                                            
  SELECT T.TemplateId                                                                          
   ,T.Name                                                                          
   ,T.TitleFormatId                                                                          
   ,T.SequenceNumbering                                                       
   ,T.IsSystem                      
   ,T.IsDeleted                               
   ,PS.SectionId                                                                          
,T.ApplyTitleStyleToEOS                                                                      
   ,CAST(0 AS BIT) AS IsDefault                                                                          
  FROM Template T WITH (NOLOCK)                                                                          
  INNER JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON T.TemplateId = PS.TemplateId                                                                          
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                                                                          
  WHERE PS.ProjectId = @PProjectId                                        
   AND PS.CustomerId = @PCustomerId                                                                          
   AND PS.TemplateId IS NOT NULL                                                                          
  ) AS X                                                                          
                                  
 --SELECT TEMPLATE DATA                                                                                              
 SELECT *                                                      
  ,@PCustomerId as CustomerId                                                                          
 FROM #tmp_Template T                                                                          
                                                                          
 --SELECT TEMPLATE STYLE DATA                               
 SELECT TS.TemplateStyleId                                                            
  ,TS.TemplateId                                                                          
  ,TS.StyleId                                                                          
  ,TS.LEVEL                                                       
  ,@PCustomerId as CustomerId                                                      
 FROM TemplateStyle TS WITH (NOLOCK)                                                                      
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                                                                          
                                                                          
 --SELECT STYLE DATA                                                                                              
 SELECT ST.StyleId                                                                          
  ,ST.Alignment                                                                          
  ,ST.IsBold                                                             
  ,ST.CharAfterNumber                                                                          
  ,ST.CharBeforeNumber                                                                          
  ,ST.FontName                                                                          
  ,ST.FontSize                                                                          
  ,ST.HangingIndent                                                                          
  ,ST.IncludePrevious                                                 
  ,ST.IsItalic                      
  ,ST.LeftIndent                                                                          
  ,ST.NumberFormat                                                                 
  ,ST.NumberPosition                                                                  
  ,ST.PrintUpperCase                                                                          
  ,ST.ShowNumber                                                                          
  ,ST.StartAt                                                                 
  ,ST.Strikeout                                                                          
  ,ST.Name                      
  ,ST.TopDistance                                       
  ,ST.Underline                                                                          
  ,ST.SpaceBelowParagraph                                                                   
  ,ST.IsSystem                                                                          
  ,ST.IsDeleted                                                                          
  ,CAST(TS.LEVEL AS INT) AS LEVEL                                                                 
  ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing                                                            
  ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId               
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId                                                    
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId                               
  ,@PCustomerId as CustomerId                                                      
 FROM Style AS ST WITH (NOLOCK)                                                                          
 INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId                                                                          
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                                                        
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId                               
                                                                          
 --SELECT GLOBAL TERM DATA                                                                                              
 SELECT PGT.GlobalTermId                                                                          
  ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                                                    
  ,PGT.Name                                                      
  ,ISNULL(PGT.value, '') AS value                                                                          
  ,PGT.CreatedDate                                                                          
  ,PGT.CreatedBy                  
  ,PGT.ModifiedDate                                                                          
  ,PGT.ModifiedBy                                                
  ,PGT.GlobalTermSource                                                                          
  ,ISNULL(PGT.GlobalTermCode,0) AS GlobalTermCode                                                      
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                                                                          
  ,GlobalTermFieldTypeId AS GTFieldType                                                          
  ,@PProjectId as ProjectId                                          
  ,@PCustomerId as CustomerId                                                     
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                                                                          
 WHERE PGT.ProjectId = @PProjectId                                                                          
  AND PGT.CustomerId = @PCustomerId;                                                                          
                                                      
  DECLARE @PSourceTagFormat NVARCHAR(10)='', @IsPrintReferenceEditionDate BIT, @UnitOfMeasureValueTypeId INT;                                                      
SELECT TOP 1 @PSourceTagFormat= SourceTagFormat                                                      
,@IsPrintReferenceEditionDate = PS.IsPrintReferenceEditionDate                                                       
,@UnitOfMeasureValueTypeId = ISNULL(PS.UnitOfMeasureValueTypeId,0)                                                      
FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.ProjectId = @PProjectId                                                      
                                                                          
 --SELECT SECTIONS DATA                                                                                              
 SELECT S.SectionId AS SectionId                                                                          
  ,ISNULL(S.mSectionId, 0) AS mSectionId                                                                          
  ,S.Description                                                                          
  ,COALESCE(S.Author,'') as Author                                                                         
  ,ISNULL(S.SectionCode ,0)   AS SectionCode                                                                      
  ,COALESCE(S.SourceTag,'') as SourceTag                                                                         
  ,@PSourceTagFormat SourceTagFormat    --PS.SourceTagFormat                                             
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                                                                          
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                                                                          
,ISNULL(D.DivisionId, 0) AS DivisionId                                                                          
  ,ISNULL(S.IsTrackChanges, CONVERT(BIT,0)) AS IsTrackChanges                                                                          
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                             
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId         
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                                                                
 -- AND S.CustomerId = PS.CustomerId                                                                          
 WHERE S.ProjectId = @PProjectId                                                                 
  AND S.CustomerId = @PCustomerId                                                                          
  AND S.IsLastLevel = 1                                                                          
AND ISNULL(S.IsDeleted, 0) = 0              
UNION        
 SELECT S.SectionId AS SectionId                                                                          
  ,ISNULL(S.mSectionId, 0) AS mSectionId                                                                          
  ,S.Description                                                                          
  ,COALESCE(S.Author,'') as Author                                                                         
  ,ISNULL(S.SectionCode ,0)   AS SectionCode                                                                      
  ,COALESCE(S.SourceTag,'') as SourceTag                                                                         
  ,@PSourceTagFormat SourceTagFormat    --PS.SourceTagFormat                                             
  ,ISNULL(CD.DivisionCode, '') AS DivisionCode                                                                          
  ,ISNULL(CD.DivisionTitle, '') AS DivisionTitle                                                                          
,ISNULL(S.DivisionId, 0) AS DivisionId                                                                          
  ,ISNULL(S.IsTrackChanges, CONVERT(BIT,0)) AS IsTrackChanges                                                                          
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)           
 LEFT JOIN CustomerDivision CD WITH (NOLOCK)        
 ON S.DivisionId = CD.DivisionId        
 AND S.CustomerId = CD.CustomerId        
 WHERE S.ProjectId = @PProjectId        
  AND S.CustomerId = @PCustomerId                                                                          
  AND S.IsLastLevel = 1                                                                          
AND ISNULL(S.IsDeleted, 0) = 0  
AND ISNULL(CD.DivisionTitle, '') != ''  
 UNION                                                                          
 SELECT 0 AS SectionId                                                                          
  ,MS.SectionId AS mSectionId                                                                          
  ,MS.Description                                                                          
  ,MS.Author                                                          
  ,MS.SectionCode                                                                          
  ,MS.SourceTag                                                                          
  ,@PSourceTagFormat SourceTagFormat --P.SourceTagFormat                                                                          
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                                                                          
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                                                                          
  ,ISNULL(D.DivisionId, 0) AS DivisionId                                                      
  ,CONVERT(BIT, 0) AS IsTrackChanges                                                                          
 FROM SLCMaster..Section MS WITH (NOLOCK)                                                                          
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                                                                          
 --INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                                                                          
 -- AND P.CustomerId = @PCustomerId                                                                        
 LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON MS.SectionId = PS.mSectionId                                                                          
  AND PS.ProjectId = @PProjectId                    
  AND PS.CustomerId = @PCustomerId                                      
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                                                                          
  AND MS.IsLastLevel = 1                                                                          
  AND PS.SectionId IS NULL                                                                          
 AND ISNULL(PS.IsDeleted, 0) = 0                                                                          
                                                                          
 --SELECT SEGMENT REQUIREMENT TAGS DATA                                                                                              
 SELECT PSRT.SegmentStatusId                                                                          
  ,PSRT.SegmentRequirementTagId                   
  ,PSST.mSegmentStatusId                                                                          
  ,LPRT.RequirementTagId                                                   
  ,LPRT.TagType                                                                          
  ,LPRT.Description AS TagName                                                                          
  ,CASE                                                                           
   WHEN PSRT.mSegmentRequirementTagId IS NULL                                                                          
    THEN CAST(0 AS BIT)                                                                          
   ELSE CAST(1 AS BIT)                                                                          
   END AS IsMasterAppliedTag                                                                          
  ,PSST.SectionId                                     
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                                                    
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                                                                          
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                                                                          
 WHERE PSRT.ProjectId = @PProjectId                                                                          
 AND PSRT.CustomerId = @PCustomerId                                                                          
                                                                               
 --SELECT REQUIRED IMAGES DATA                                                                                              
 SELECT                                                      
  PIMG.SegmentImageId                                                                    
 ,IMG.ImageId                                                                    
 ,IMG.ImagePath                                                                    
 ,COALESCE(PIMG.ImageStyle,'')  as ImageStyle                                                                  
 ,PIMG.SectionId                                                                     
 ,ISNULL(IMG.LuImageSourceTypeId,0) as LuImageSourceTypeId                                                      
                                                                  
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                                                                          
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                                                                          
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId  //To resolved cross section images in headerFooter                                                    
 WHERE PIMG.ProjectId = @PProjectId                                                                          
  AND PIMG.CustomerId = @PCustomerId                                                                          
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)                                                            
UNION ALL -- This union to ge Note images                                                            
 SELECT                                                                     
  0 SegmentImageId                                                                    
 ,PN.ImageId                                                                    
 ,IMG.ImagePath                                                     
 ,'' ImageStyle                                                                    
 ,PN.SectionId                                                                     
 ,ISNULL(IMG.LuImageSourceTypeId,0) as   LuImageSourceTypeId                                                           
 FROM ProjectNoteImage PN  WITH (NOLOCK)                                                                 
INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId                                                            
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId                                                            
 WHERE PN.ProjectId = @PProjectId                                                                          
  AND PN.CustomerId = @PCustomerId                                          
 UNION ALL -- This union to ge Master Note images                        
 select                                                             
  0 SegmentImageId                                                                      
 ,NI.ImageId                                                
 ,MIMG.ImagePath                                                                      
 ,'' ImageStyle                                                                      
 ,NI.SectionId                                                                       
 ,ISNULL(MIMG.LuImageSourceTypeId,0) as    LuImageSourceTypeId                                                           
from slcmaster..NoteImage NI with (nolock)                                                            
INNER JOIN ProjectSection PS with (nolock) on NI.SectionId = PS.mSectionId                                                            
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                                                            
INNER JOIN SLCMaster..Image MIMG WITH (NOLOCK) ON MIMG.ImageId = NI.ImageId                                                          
                                                       
 --SELECT HYPERLINKS DATA                                                                                              
SELECT HLNK.HyperLinkId                                                                          
  ,HLNK.LinkTarget                                                                          
  ,HLNK.LinkText                                                    
  ,'U' AS Source                                                        
  ,HLNK.SectionId                                                                          
 FROM ProjectHyperLink HLNK WITH (NOLOCK)                                                                          
 INNER JOIN @SectionIdTbl SIDTBL ON HLNK.SectionId = SIDTBL.SectionId                                                                          
 WHERE HLNK.ProjectId = @PProjectId                                                         
  AND HLNK.CustomerId = @PCustomerId                                                                          
  UNION ALL -- To get Master Hyperlinks                                                          
  SELECT MLNK.HyperLinkId                                                              
  ,MLNK.LinkTarget                                                                          
  ,MLNK.LinkText                            
  ,'M' AS Source                                                                          
  ,MLNK.SectionId                                                                          
 FROM slcmaster..Hyperlink MLNK WITH (NOLOCK)                                                           
 INNER JOIN #tmpProjectSegmentStatusForNote PSS WITH (NOLOCK) ON  MLNK.SegmentStatusId = PSS.mSegmentStatusId                                                          
                                                                        
 --SELECT SEGMENT USER TAGS DATA                         
SELECT PSUT.SegmentUserTagId                                                                          
  ,PSUT.SegmentStatusId                                                                          
  ,PSUT.UserTagId                                                                          
,PUT.TagType                                                                          
  ,PUT.Description AS TagName                              
  ,PSUT.SectionId                                                                          
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                                                                          
 INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId                                                                          
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                                                                          
 WHERE PSUT.ProjectId = @PProjectId                                                                          
  AND PSUT.CustomerId = @PCustomerId                                                              
                                                            
 --SELECT Project Summary information                                                                                              
 SELECT P.ProjectId AS ProjectId                                                        
  ,P.Name AS ProjectName                                                                          
  ,'' AS ProjectLocation                                                                          
  ,@IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                                                                          
  ,@PSourceTagFormat AS SourceTagFormat                                                                          
  ,CONCAT(@State,@City) AS DbInfoProjectLocationKeyword                                                                          
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                                                                
  ,@UnitOfMeasureValueTypeId AS UnitOfMeasureValueTypeId                                                                          
 FROM Project P WITH (NOLOCK)                                                                          
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                                                      
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                                                                          
 LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK) ON P.ProjectId = PGT.ProjectId                     
  AND PGT.mGlobalTermId = 11                                                                          
 WHERE P.ProjectId = @PProjectId                                                                          
  AND P.CustomerId = @PCustomerId                                                             
                                           
 --SELECT REFERENCE STD DATA                                                                                           
 SELECT MREFSTD.RefStdId as Id                                        
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                                                                          
  ,'M' AS RefStdSource                                                                          
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                                                                          
  ,'M' AS ReplaceRefStdSource                                                 
  ,MREFSTD.IsObsolete AS IsObsolute                                                                          
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                                                                          
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                                          
 WHERE MREFSTD.MasterDataTypeId = CASE                                                                           
WHEN @MasterDataTypeId = 2                                                                          
    OR @MasterDataTypeId = 3                                                                          
THEN 1                                                                          
   ELSE @MasterDataTypeId                                                                          
   END                                                                          
                                                                           
 UNION                                                                          
                                                      
 SELECT PREFSTD.RefStdId  as Id                                                                        
  ,PREFSTD.RefStdName                                                                          
  ,'U' AS RefStdSource     
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                                                
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                                                                          
  ,PREFSTD.IsObsolete as IsObsolute                                                                         
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                                                                          
 FROM ReferenceStandard PREFSTD WITH (NOLOCK)                                                                          
 WHERE PREFSTD.CustomerId = @PCustomerId                                                               
                  
 --SELECT REFERENCE EDITION DATA                         
                 
                 
 DECLARE @table_RefStandardWithEditionId TABLE (                                
    RefStdId int,                                
 RefStdEditionId int                                
);                                
SELECT RefStandardId,RefStdEditionId,CustomerId,RefStdSource INTO #ProjectReferenceStandard                               
FROM ProjectReferenceStandard  PRT  WITH(NOLOCK) where PRT.ProjectId=@PProjectId    and PRT.CustomerId=@PCustomerId and PRT.RefStdSource='U' AND ISNULL(PRT.IsDeleted,0) = 0                             
                                
INSERT INTO  @table_RefStandardWithEditionId                                 
--RS list with edition which is not yet used                                
SELECT RT.RefStdId AS RefStdId                                
   ,MAX(RSE.RefStdEditionId) AS RefStdEditionId                                
  FROM ReferenceStandard RT  WITH(NOLOCK) left outer join #ProjectReferenceStandard  PRT                                 
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource                                
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on RT.RefStdId=RSE.RefStdId                                
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U' AND   ISNULL(RT.IsDeleted,0) = 0  AND                              
PRT.RefStandardId is null                                
GROUP BY RT.RefStdId UNION                               
--RS list with edition which is in used                         
SELECT RT.RefStdId AS RefStdId                                
   ,MAX(PRT.RefStdEditionId) AS RefStdEditionId                                
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN #ProjectReferenceStandard  PRT                                
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource                               
--INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStandardId =RSE.RefStdId                               
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U'  AND   ISNULL(RT.IsDeleted,0) = 0 GROUP BY RT.RefStdId                
                 
                        
 SELECT MREFEDN.RefStdId                                                                          
  ,MREFEDN.RefStdEditionId as Id                                                                         
  ,MREFEDN.RefEdition                                                                          
  ,MREFEDN.RefStdTitle                                            
  ,MREFEDN.LinkTarget                                                                          
  ,'M' AS RefEdnSource                                                                          
 FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)                                                              
 WHERE MREFEDN.MasterDataTypeId = CASE                                                                           
   WHEN @MasterDataTypeId = 2                                                                          
    OR @MasterDataTypeId = 3                     
    THEN 1                                                                          
   ELSE @MasterDataTypeId                                                          
   END                                                                    
                                                                           
 UNION                                                                    
                                                                           
 --SELECT PREFEDN.RefStdId                                                                      
 -- ,PREFEDN.RefStdEditionId as Id                                                                     
 -- ,PREFEDN.RefEdition                                                                      
 -- ,PREFEDN.RefStdTitle                                                                      
 -- ,PREFEDN.LinkTarget                                                                      
 -- ,'U' AS RefEdnSource                                                                      
 --FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)                  
 --INNER JOIN ProjectReferenceStandard PRS   WITH (NOLOCK)                   
 --ON PRS.RefStdEditionId=PREFEDN.RefStdEditionId                                                          
 --WHERE  PRS.ProjectId=@ProjectId  and PREFEDN.CustomerId = @PCustomerId                      
                
SELECT                                
PRSE.RefStdId                                                                      
  ,PRSE.RefStdEditionId as Id                                                                     
  ,PRSE.RefEdition                                                                      
  ,PRSE.RefStdTitle                                                                      
  ,PRSE.LinkTarget                                                                      
  ,'U' AS RefEdnSource                                
FROM ReferenceStandard PRS WITH(NOLOCK)                                
inner join ReferenceStandardEdition PRSE  WITH(NOLOCK)                                
on PRSE.RefStdId = PRS.RefStdId                                
INNER JOIN @table_RefStandardWithEditionId tvn                                
on tvn.RefStdId=prs.RefStdId and tvn.RefStdEditionId=prse.RefStdEditionId                                
where PRS.CustomerId=@PCustomerId and ISNULL(PRS.IsDeleted,0) = 0                 
                
                                    
 --SELECT ProjectReferenceStandard MAPPING DATA                                                                   
 SELECT PREFSTD.RefStandardId                                                                          
  ,PREFSTD.RefStdSource                                                                          
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                                                                          
  ,PREFSTD.RefStdEditionId                                                                          
  ,SIDTBL.SectionId                                                                          
 FROM @SectionIdTbl SIDTBL                                                                          
 INNER JOIN ProjectReferenceStandard PREFSTD WITH (NOLOCK) ON PREFSTD.SectionId = SIDTBL.SectionId                                                         
 WHERE PREFSTD.ProjectId = @PProjectId                                                               
  AND PREFSTD.CustomerId = @PCustomerId                                                                          
                                               
 --SELECT Header/Footer information                                 
 DECLARE @projectLevelValueForHeader BIT              
SET @projectLevelValueForHeader =(SELECT TOP 1              
  1              
 FROM Header H WITH (NOLOCK)              
 WHERE H.ProjectId = @PProjectId              
 AND H.DocumentTypeId = @DocumentTypeId              
 AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)              
 AND (              
 H.SectionId IS NULL              
 OR H.SectionId <= 0))              
              
 SELECT X.HeaderId                                                                          
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                                                                 
  ,ISNULL(X.SectionId, 0) AS SectionId                                                                          
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                                                                          
  ,ISNULL(X.TypeId, 1) AS TypeId                                                      
  ,X.DATEFORMAT                                                                          
  ,X.TimeFormat                                                                          
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                                                                          
  ,REPLACE(ISNULL(X.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                                                                          
  ,REPLACE(ISNULL(X.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                                               
  ,REPLACE(ISNULL(X.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                                                                          
  ,REPLACE(ISNULL(X.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                                                                          
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId                                                             
  ,X.IsShowLineAboveHeader as  IsShowLineAboveHeader                                                            
  ,X.IsShowLineBelowHeader as  IsShowLineBelowHeader                                                                     
 FROM (                                                                          
  SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.            
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.            
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                    
  FROM Header H WITH (NOLOCK)                                                                          
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                  
  WHERE H.ProjectId = @PProjectId                             
   AND H.DocumentTypeId = @DocumentTypeId                                                                          
   AND (                                                                          
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                                                                          
    OR H.HeaderFooterCategoryId = 4                                                                          
    )                                                                          
                                                                            
  UNION                                           
                                                                            
  SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.            
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.            
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                     
  FROM Header H WITH (NOLOCK)                                                              
  WHERE H.ProjectId = @PProjectId                                                     
   AND H.DocumentTypeId = @DocumentTypeId                              
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                                   
   AND (                                                           
    H.SectionId IS NULL                                                                          
    OR H.SectionId <= 0                                                                          
    )                                                                          
                                                                            
  UNION                                                                          
                                                                            
  SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.            
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.            
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                       
  FROM Header H WITH (NOLOCK)                                                                       
  LEFT JOIN Header TEMP                                                                          
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                                                                          
  WHERE H.CustomerId IS NULL                       
   AND TEMP.HeaderId IS NULL                                                                
   AND H.DocumentTypeId = @DocumentTypeId                    
                   
   UNION                
                
 SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.            
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.            
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                      
  FROM Header H WITH (NOLOCK)                                                                          
  WHERE H.CustomerId IS NULL                                                                            
   AND H.ProjectId IS NULL                                                                  
   AND H.DocumentTypeId = @DocumentTypeId                   
   AND ISNULL (@projectLevelValueForHeader ,0)= 0              
  ) AS X                       
                
  DECLARE @projectLevelValueForFooter BIT              
SET @projectLevelValueForFooter =(SELECT TOP 1              
  1              
 FROM Footer F WITH (NOLOCK)              
 WHERE F.ProjectId = @PProjectId              
 AND F.DocumentTypeId = @DocumentTypeId              
 AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)              
 AND (              
 F.SectionId IS NULL              
 OR F.SectionId <= 0))              
              
 SELECT X.FooterId                                                                          
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                                                                          
 ,ISNULL(X.SectionId, 0) AS SectionId                                                                          
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                                                                          
  ,ISNULL(X.TypeId, 1) AS TypeId                                    
  ,X.DATEFORMAT                                                                          
  ,X.TimeFormat                            
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                                                                          
  ,REPLACE(ISNULL(X.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                                                                          
  ,REPLACE(ISNULL(X.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter       
  ,REPLACE(ISNULL(X.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                                                             
  ,REPLACE(ISNULL(X.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                                                                          
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId                                                            
  ,X.IsShowLineAboveFooter as  IsShowLineAboveFooter                                                            
  ,X.IsShowLineBelowFooter as  IsShowLineBelowFooter                                                                          
 FROM (                                                                    
  SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.            
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.            
  IsShowLineAboveFooter,F.IsShowLineBelowFooter                                                                      
  FROM Footer F WITH (NOLOCK)                                                                          
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                                                                          
  WHERE F.ProjectId = @PProjectId                                                                          
   AND F.DocumentTypeId = @DocumentTypeId                                          
   AND (                                                                          
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                                                                          
    OR F.HeaderFooterCategoryId = 4                                                                          
    )                                                                          
                                                                            
  UNION                                                                          
                                                                            
  SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.            
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.            
  IsShowLineAboveFooter,F.IsShowLineBelowFooter            
  FROM Footer F WITH (NOLOCK)                                                                          
  WHERE F.ProjectId = @PProjectId                                                                     
   AND F.DocumentTypeId = @DocumentTypeId                                        
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                                     
   AND (                                                                          
    F.SectionId IS NULL                                    
    OR F.SectionId <= 0                                                                          
    )                                                                          
                                                                            
  UNION                                                                          
               
  SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.            
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.            
  IsShowLineAboveFooter,F.IsShowLineBelowFooter                                                                    
  FROM Footer F WITH (NOLOCK)                                                                          
  LEFT JOIN Footer TEMP                                                                          
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                                                                          
 WHERE F.CustomerId IS NULL                                                                          
   AND F.DocumentTypeId = @DocumentTypeId                                                                          
   AND TEMP.FooterId IS NULL                     
                   
   UNION                
   SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.            
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.            
  IsShowLineAboveFooter,F.IsShowLineBelowFooter                                                                    
  FROM Footer F WITH (NOLOCK)                
  WHERE F.CustomerId IS NULL                                                                            
   AND F.ProjectId IS NULL                                                                  
   AND F.DocumentTypeId = @DocumentTypeId                      
   AND ISNULL(@projectLevelValueForFooter ,0)= 0              
  ) AS X                                                                          
                                                                          
 --SELECT PageSetup INFORMATION                                                                                              
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                                                          
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                                                                          
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                                                                          
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                                                   
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                                                                          
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                                                                         
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                                  
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                                                                          
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                                                          
  ,PageSetting.ProjectId AS ProjectId                                                                          
  ,PageSetting.CustomerId AS CustomerId                                                                          
  ,ISNULL(PaperSetting.PaperName,'A4') AS PaperName                                                                          
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                                                                          
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                                                                          
  ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation               
  ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource                                                                          
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                                                             
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) ON PageSetting.ProjectId = PaperSetting.ProjectId                                                                        
 WHERE PageSetting.ProjectId = @PProjectId                       
                                                            
IF(@IsPrintMasterNote = 1  OR @IsPrintProjectNote =1)                                                      
BEGIN                                                      
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/                                                            
SELECT                                                           
NoteId                                                        
,PN.SectionId                                                            
,isnull(PSS.SegmentStatusId,0)SegmentStatusId                                                            
,PSS.mSegmentStatusId                                                             
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)                                    
 ELSE NoteText END NoteText                                                            
,PN.ProjectId                                
,PN.CustomerId                                                          
,PN.IsDeleted                                                          
,NoteCode ,                                                          
COALESCE(PN.Title,'') as NoteType                                                         
FROM @SectionIdTbl SIDTBL                                       
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PSS.SectionId  = SIDTBL.SectionId                                                
INNER JOIN  ProjectNote PN WITH (NOLOCK)  ON PN.SegmentStatusId = PSS.SegmentStatusId                                                      
AND PN.ProjectId= @PProjectId AND PN.SectionId = PSS.SectionId                                                       
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0                                                            
UNION ALL                                                            
SELECT NoteId                                                            
,0 SectionId      
,PSS.SegmentStatusId                                                             
,isnull(PSS.mSegmentStatusId,0) as mSegmentStatusId                                                             
,NoteText                                                            
,@PProjectId As ProjectId                                                             
,@PCustomerId As CustomerId                                                             
,0 IsDeleted                                                            
,0 NoteCode ,                                                          
'' As NoteType                                                          
 FROM @SectionIdTbl SIDTBL                                                        
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)                                     
ON PSS.SectionId = SIDTBL.SectionId                                                        
INNER JOIN SLCMaster..Note MN  WITH (NOLOCK)   ON                                                      
 ISNULL(PSS.mSegmentStatusId, 0) > 0 and  MN.SegmentStatusId = PSS.mSegmentStatusId                                                       
 AND PSS.SectionId = SIDTBL.SectionId                                                       
 WHERE ISNULL(PSS.mSegmentStatusId, 0) > 0                                                         
                                                          
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/                                                            
End;                                                 
        
--SELECT Sheet Specs Setting                 
if Exists (select top 1 1 from SheetSpecsPageSettings SSPS with (nolock)          
where ProjectId = @PProjectId and CustomerId = @PCustomerId )                     
begin                                                                         
select        
max(case when SSPS.[Name] = 'NumberOfColumns' then value end) NumOfSpecSheetsColumnsSelected,        
max(case when SSPS.[Name] = 'Height' then value end) PaperHeight,        
max(case when SSPS.[Name] = 'Width' then value end) PaperWidth,        
max(PaperSettingKey) as PaperSettingKey,        
max(LSSPS.Name) as PaperName,        
cast(0 as bit) as PaperOrientation,    
max(case when SSPS.[Name] = 'MarginTop' then value end) MarginTop,        
max(case when SSPS.[Name] = 'MarginBottom' then value end) MarginBottom,        
max(case when SSPS.[Name] = 'MarginLeft' then value end) MarginLeft,        
max(case when SSPS.[Name] = 'MarginRight' then value end) MarginRight,    
max(case when SSPS.[Name] = 'IsEqualColumnWidthEnabled' then value end) IsEqualColumnWidthEnabled,    
max(case when SSPS.[Name] = 'IsLineBetweenEnabled' then value end) IsLineBetweenEnabled,    
max(case when SSPS.[Name] = 'ColumnFormatDetails' then value end) ColumnFormatDetails    
from SheetSpecsPageSettings SSPS with (nolock) INNER JOIN LuSpecSheetPaperSize LSSPS        
on SSPS.PaperSettingKey = LSSPS.SpecSheetPaperId         
where ProjectId = @PProjectId and CustomerId = @PCustomerId         
end        
else         
begin        
 select         
 cast('3' as int) AS  NumOfSpecSheetsColumnsSelected,        
 Height AS PaperHeight,        
 Width AS PaperWidth,        
 SpecSheetPaperId as PaperSettingKey,        
 Name as PaperName,        
 cast(0 as bit) PaperOrientation,    
 cast('1' as int) AS MarginTop,        
 cast('1' as int) AS MarginBottom,        
 cast('1' as int) AS MarginLeft,        
 cast('1' as int) AS MarginRight,    
1 as IsEqualColumnWidthEnabled,    
0 as  IsLineBetweenEnabled,    
'[{"id":1,"width":9,"spacing":0.5,"isSpacingDisable":false,"isWidthDisable":false},{"id":2,"width":9,"spacing":0.5,"isSpacingDisable":true,"isWidthDisable":true},{"id":3,"width":9,"spacing":0.5,"isSpacingDisable":true,"isWidthDisable":true}]'   
AS ColumnFormatDetails         
 from LuSpecSheetPaperSize where SpecSheetPaperId = 11        
end        
END 
GO


