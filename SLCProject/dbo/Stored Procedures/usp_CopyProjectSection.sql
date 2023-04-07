
CREATE PROCEDURE [dbo].[usp_CopyProjectSection]
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
     WHERE PSS.SectionId = @SourceSectionId AND PSS.ProjectId = @SourceProjectId AND PSS.CustomerId = @CustomerId
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
    WHERE PSS.SectionId = @SourceSectionId AND PSS.ProjectId = @SourceProjectId AND PSS.CustomerId = @CustomerId
                            
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
     WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND PSS.CustomerId = @CustomerId;
                            
     -- Insert records into ProjectSegment                                            
     INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId,              
     SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId, BaseSegmentDescription)                                  
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
   ,SrcPS.BaseSegmentDescription AS BaseSegmentDescription
   --,SrcPS.SegmentId AS SrcPSSegmentId                            
   --,SrcMS.SegmentId AS SrcMSSegmentId                            
                            
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
   ,PS.BaseSegmentDescription AS BaseSegmentDescription                                            
   FROM SLCMaster..SegmentStatus SrcMSS WITH (NOLOCK)                                            
   INNER JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)                                            
    ON SrcMSS.SegmentId = SrcMS.SegmentId                                            
    LEFT JOIN ProjectSegment PS WITH (NOLOCK) 
   ON PS.CustomerId = @CustomerId 
   AND PS.ProjectId = @SourceProjectId 
   AND PS.SectionId = @SourceMSectionId 
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
    WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND PSS.CustomerId = @CustomerId;
                            
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
    ON PS.ProjectId = PSS.ProjectId AND PS.SectionId = PSS.SectionId AND PS.SegmentStatusId = PSS.SegmentStatusId                            
    WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND PSS.CustomerId = @CustomerId;
               
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
    AND @IsSectionOpen = 0 AND ISNULL(TPSS.IsDeleted, 0) = 0)                            
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
    AND SPSS.SegmentOrigin = 'M' AND ISNULL(TPSS.IsDeleted, 0) = 0
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
     --ON SPSS.SegmentId = SrcPSC.SegmentId
	 ON SPSS.ProjectId = SrcPSC.ProjectId AND SPSS.CustomerId = SrcPSC.CustomerId AND SPSS.SectionId = SrcPSC.SectionId AND SPSS.SegmentId = SrcPSC.SegmentId
    WHERE SrcPSC.ProjectId = @SourceProjectId AND SrcPSC.CustomerId = @CustomerId AND SrcPSC.SectionId = @SourceSectionId AND TPSS.SectionId = @TargetSectionId                                            
    AND SPSS.SegmentOrigin = 'U' AND ISNULL(TPSS.IsDeleted, 0) = 0
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
    --ON TPSS.SegmentId = PCH.SegmentId                                  
	ON TPSS.ProjectId = PCH.ProjectId AND TPSS.CustomerId = PCH.CustomerId AND TPSS.SectionId = PCH.SectionId
    AND SrcMSC.SegmentChoiceCode = PCH.SegmentChoiceCode AND TPSS.SegmentId = PCH.SegmentId
    WHERE PCH.ProjectId = @TargetProjectId AND PCH.CustomerId = @CustomerId AND PCH.SectionId = @TargetSectionId AND TPSS.SectionId = @TargetSectionId                    
    AND @IsSectionOpen = 0 AND ISNULL(TPSS.IsDeleted, 0) = 0)                                           
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
    ON TPSS.mSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId                                            
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                                            
    ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                                            
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                                            
    --ON TPSS.SegmentId = PCH.SegmentId                                            
	ON TPSS.ProjectId = PCH.ProjectId AND TPSS.CustomerId = PCH.CustomerId AND TPSS.SectionId = PCH.SectionId
    AND SrcMSC.SegmentChoiceCode = PCH.SegmentChoiceCode AND TPSS.SegmentId = PCH.SegmentId
    WHERE PCH.ProjectId = @TargetProjectId AND PCH.CustomerId = @CustomerId AND PCH.SectionId = @TargetSectionId AND TPSS.SectionId = @TargetSectionId                                            
    AND SrcPSS.SegmentOrigin = 'M' AND ISNULL(TPSS.IsDeleted, 0) = 0
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
    --ON SrcPSS.SegmentId = SrcPSC.SegmentId                                            
	ON SrcPSS.ProjectId = SrcPSC.ProjectId AND SrcPSS.CustomerId = SrcPSC.CustomerId AND SrcPSS.SectionId = SrcPSC.SectionId AND SrcPSS.SegmentId = SrcPSC.SegmentId
    INNER JOIN ProjectChoiceOption SrcPCO WITH (NOLOCK)                                            
    ON SrcPSC.SegmentChoiceId = SrcPCO.SegmentChoiceId        
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                                            
    --ON TPSS.SegmentId = PCH.SegmentId                                            
	ON TPSS.ProjectId = PCH.ProjectId AND TPSS.CustomerId = PCH.CustomerId AND TPSS.SectionId = PCH.SectionId
    AND SrcPSC.SegmentChoiceCode = PCH.SegmentChoiceCode AND TPSS.SegmentId = PCH.SegmentId
    WHERE SrcPSC.ProjectId = @SourceProjectId AND SrcPSC.CustomerId = @CustomerId AND SrcPSC.SectionId = @SourceSectionId
	AND PCH.ProjectId = @TargetProjectId AND PCH.CustomerId = @CustomerId AND PCH.SectionId = @TargetSectionId 
	AND TPSS.SectionId = @TargetSectionId                                            
    AND SrcPSS.SegmentOrigin = 'U' AND ISNULL(TPSS.IsDeleted, 0) = 0
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
    WHERE TrgPSS.SectionId = @TargetSectionId AND ISNULL(TrgPSS.IsDeleted, 0) = 0
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
     ON SrcMSCO.ProjectId = @SourceProjectId    
   AND SrcMSCO.CustomerId = @CustomerId AND SrcMSCO.SectionId = @SourceSectionId
   AND SrcMSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                                            
      AND SrcMCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                            
      AND SrcMSCO.ChoiceOptionSource = 'M'                                            
    WHERE SrcMSCO.ProjectId = @SourceProjectId AND SrcMSCO.CustomerId = @CustomerId AND SrcMSCO.SectionId = @SourceSectionId AND PSST.SectionId = @TargetSectionId                                            
    AND SrcPSS.SegmentOrigin = 'M' AND ISNULL(PSST.IsDeleted, 0) = 0
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
     --ON SrcPSS.SegmentId = SrcPSC.SegmentId                                            
	 ON SrcPSS.ProjectId = SrcPSC.ProjectId AND SrcPSS.CustomerId = SrcPSC.CustomerId AND SrcPSS.SectionId = SrcPSC.SectionId AND SrcPSS.SegmentId = SrcPSC.SegmentId
    INNER JOIN ProjectChoiceOption SrcPCO WITH (NOLOCK)                                            
     ON SrcPSC.SegmentChoiceId = SrcPCO.SegmentChoiceId                                            
    INNER JOIN SelectedChoiceOption SrcMSCO WITH (NOLOCK)                                            
     ON SrcMSCO.ProjectId = @SourceProjectId AND SrcMSCO.CustomerId = @CustomerId AND SrcMSCO.SectionId = @SourceSectionId
		AND SrcPSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode
		AND SrcPCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode
		AND SrcMSCO.ChoiceOptionSource = 'U'                                            
    WHERE SrcPSC.ProjectId = @SourceProjectId AND SrcPSC.CustomerId = @CustomerId AND SrcPSC.SectionId = @SourceSectionId
	AND SrcMSCO.ProjectId = @SourceProjectId AND SrcMSCO.CustomerId = @CustomerId AND SrcMSCO.SectionId = @SourceSectionId AND SrcPSS.SectionId = @SourceSectionId                                            
    AND SrcPSS.SegmentOrigin = 'U' AND ISNULL(SrcPSS.IsDeleted, 0) = 0
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
  TargetChoiceOptionCode BIGINT,                     
  LinkTarget varchar,                    
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
 AND TrgPSS.SectionId = @TargetSectionId AND ISNULL(TrgPSS.IsDeleted, 0) = 0
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
     WHERE SrcPN.SectionId = @SourceSectionId AND ISNULL(TrgPSS.IsDeleted, 0) = 0
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
    AND @IsSectionOpen = 0 AND ISNULL(PSST.IsDeleted, 0) = 0
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
    WHERE PSRT_Template.ProjectId = @SourceProjectId AND PSRT_Template.SectionId = @SourceSectionId                                            
    AND @IsSectionOpen = 1 AND ISNULL(PSST.IsDeleted, 0) = 0
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
     WHERE SrcPSUT.CustomerId = @CustomerId AND SrcPSUT.ProjectId = @SourceProjectId AND SrcPSUT.SectionId = @SourceSectionId AND ISNULL(TrgPSS.IsDeleted, 0) = 0
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
    ON PSG.ProjectId = @TargetProjectId AND PSG.SectionId = @TargetSectionId AND SrcPS.SegmentCode = PSG.SegmentCode
   WHERE PSG.ProjectId = @TargetProjectId AND PSG.SectionId = @TargetSectionId AND SrcPSGT.ProjectId = @SourceProjectId AND SrcPSGT.SectionId = @SourceSectionId                                  
              
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
     ON TrgPS.ProjectId = @TargetProjectId AND TrgPS.SectionId = @TargetSectionId AND SrcPS.SegmentCode = TrgPS.SegmentCode
    WHERE TrgPS.ProjectId = @TargetProjectId AND TrgPS.SectionId = @TargetSectionId AND SrcPSI.SectionId = @SourceSectionId                                            
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
   WHERE MNT_Template.SectionId = @SourceMSectionId AND ISNULL(PSST.IsDeleted, 0) = 0
                                  
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
   -- ON MNT_Template.SegmentStatusId = PSST.SegmentStatusCode                         
   -- AND PSST.SectionId = @TargetSectionId                    
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
    WHERE SrcPNI.ProjectId = @SourceProjectId AND SrcPNI.SectionId = @SourceSectionId                            
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
   WHERE PSRS.ProjectId = @SourceProjectId AND PSRS.SectionId = @SourceSectionId AND ISNULL(PSRS.IsDeleted,0) = 0 AND ISNULL(TrgPSS.IsDeleted, 0) = 0
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
   WHERE MSRS.SectionId = @SourceMSectionId AND ISNULL(TrgPSS.IsDeleted, 0) = 0
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
   FROM ProjectReferenceStandard PRS  WITH(NOLOCK) WHERE PRS.ProjectId = @SourceProjectId AND PRS.SectionId = @SourceSectionId AND PRS.CustomerId = @CustomerId
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
    AND PSS.SectionId =@TargetSectionId AND PSS.ProjectId = @TargetProjectId AND PSS.CustomerId = @CustomerId;
                  
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

    BEGIN -- Update ProjectSegmentStatus and reset mSegmentStatusId and mSegmentId                            
      UPDATE PSS                            
      SET PSS.mSegmentStatusId = NULL, PSS.mSegmentId = NULL               
      FROM ProjectSegmentStatus PSS WITH (NOLOCK)                                            
      WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND PSS.CustomerId = @CustomerId;
                    
     ---- Upadate SegmentDescription at sequence Number 0                    
  UPDATE PS  SET PS.SegmentDescription = @Description  FROM ProjectSegmentStatus PSS WITH (NOLOCK)                    
  INNER JOIN ProjectSegment PS WITH (NOLOCK) ON  PS.SectionId = @TargetSectionId                   
  AND PSS.SegmentId = PS.SegmentId  WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND PSS.CustomerId = @CustomerId AND PSS.SequenceNumber = 0 AND PSS.IndentLevel = 0;                    
 
   END                 
                           
    SELECT @TargetSectionId AS TargetSectionId, @IsSectionOpen AS IsSectionOpen;                           
    END                        
    SELECT @ErrorMessage as ErrorMessage,@TargetSectionId as TargetSectionId;                   
                 
END
