CREATE PROCEDURE [dbo].[usp_CopyProject]                   
(                          
 @PSourceProjectId  INT 
,@PTargetProjectId INT 
,@PCustomerId INT 	
,@PUserId INT     
,@PRequestId INT 
)                          
AS                          
BEGIN                              
--Handle Parameter Sniffing                              
DECLARE @SourceProjectId INT = @PSourceProjectId;                              
DECLARE @TargetProjectId INT = @PTargetProjectId;                              
DECLARE @CustomerId INT = @PCustomerId;                              
DECLARE @UserId INT = @PUserId;                              
DECLARE @RequestId INT = @PRequestId;                              
DECLARE @DelayFor CHAR(8) = '00:00:05'
--Progress Variables                
DECLARE @CopyStart_Description NVARCHAR(50) = 'Copy Started';                              
DECLARE @CopyGlobalTems_Description NVARCHAR(50) = 'Global Terms Copied';                              
DECLARE @CopySections_Description NVARCHAR(50) = 'Sections Copied';                              
DECLARE @CopySegmentStatus_Description NVARCHAR(50) = 'Segment Status Copied';                              
DECLARE @CopySegments_Description NVARCHAR(50) = 'Segments Copied';                              
DECLARE @CopySegmentChoices_Description NVARCHAR(50) = 'Choices Copied';                              
DECLARE @CopySegmentLinks_Description NVARCHAR(50) = 'Segment Links Copied';                              
DECLARE @CopyNotes_Description NVARCHAR(50) = 'Notes Copied';                              
DECLARE @CopyImages_Description NVARCHAR(50) = 'Images Copied';                              
DECLARE @CopyRefStds_Description NVARCHAR(50) = 'Reference Standards Copied';                              
DECLARE @CopyTags_Description NVARCHAR(50) = 'Segment Tags Copied';                              
DECLARE @CopyHeaderFooter_Description NVARCHAR(50) = 'Header and Footer Copied';                              
DECLARE @CopyProjectHyperLink_Description NVARCHAR(50) = 'Project Hyper Link Copied';                            
DECLARE @CopyTrackSegmentStatus_Description NVARCHAR(50) = 'Project Track Status Copied';                              
DECLARE @CopyDocLibraryMapping_Description NVARCHAR(50) = 'Project DocLibrary Mapping Copied';  
DECLARE @CopyComplete_Description NVARCHAR(50) = 'Copy Completed';                              
DECLARE @CopyFailed_Description NVARCHAR(50) = 'Copy Failed';                              
DECLARE @CustomerName NVARCHAR(20) = '';                              
DECLARE @UserName NVARCHAR(20) = '';                              
                              
DECLARE @CopyStart_Percentage FLOAT = 5;                              
DECLARE @CopyGlobalTems_Percentage FLOAT = 10;                              
DECLARE @CopySections_Percentage FLOAT = 15;                              
DECLARE @CopySegmentStatus_Percentage FLOAT = 35;                              
DECLARE @CopySegments_Percentage FLOAT = 45;                              
DECLARE @CopySegmentChoices_Percentage FLOAT = 55;                              
DECLARE @CopySegmentLinks_Percentage FLOAT = 70;                              
DECLARE @CopyNotes_Percentage FLOAT = 75;                              
DECLARE @CopyImages_Percentage FLOAT = 80;                              
DECLARE @CopyRefStds_Percentage FLOAT = 85;                              
DECLARE @CopyTags_Percentage FLOAT = 90;                              
DECLARE @CopyHeaderFooter_Percentage FLOAT = 95;                              
DECLARE @CopyProjectHyperLink_Percentage FLOAT = 97;                            
DECLARE @CopyTrackSegmentStatus_Percentage FLOAT = 98;                            
DECLARE @CopyDocLibraryMapping_Percentage FLOAT = 99;  
                        
DECLARE @CopyComplete_Percentage FLOAT = 100;                              
DECLARE @CopyFailed_Percentage FLOAT = 100;                              
DECLARE @CopyStart_Step INT = 2;                              
DECLARE @CopyGlobalTems_Step INT = 3;                              
DECLARE @CopySections_Step INT = 4;                              
DECLARE @CopySegmentStatus_Step INT = 5;                              
DECLARE @CopySegments_Step INT = 6;           
DECLARE @CopySegmentChoices_Step INT = 7;                              
DECLARE @CopySegmentLinks_Step INT = 8;                              
DECLARE @CopyNotes_Step INT = 9;                              
DECLARE @CopyImages_Step INT = 10;                              
DECLARE @CopyRefStds_Step INT = 11;                              
DECLARE @CopyTags_Step INT = 12;                           
DECLARE @CopyHeaderFooter_Step INT = 13;                              
DECLARE @CopyProjectHyperLink_Step INT = 14;                        
DECLARE @CopyTrackSegmentStatus_Step INT = 17;  --newly added                             
DECLARE @CopyDocLibraryMapping_Step INT = 18;  --newly added                             
DECLARE @CopyComplete_Step FLOAT = 15;                              
DECLARE @CopyFailed_Step FLOAT = 16;                 
          
                  
                              
--Variables                              
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1                              
  MasterDataTypeId                              
 FROM Project WITH (NOLOCK)                              
 WHERE ProjectId = @SourceProjectId                              
 AND CustomerId = @CustomerId);                              
                              
DECLARE @StateProvinceName NVARCHAR(100) = (SELECT TOP 1                              
  IIF(LUS.StateProvinceName IS NULL, PADR.StateProvinceName, LUS.StateProvinceName) AS StateProvinceName                              
 FROM ProjectAddress PADR WITH (NOLOCK)                              
 LEFT OUTER JOIN LuStateProvince LUS WITH (NOLOCK)                              
  ON LUS.StateProvinceID = PADR.StateProvinceId                              
 WHERE PADR.ProjectId = @TargetProjectId                              
 AND PADR.CustomerId = @CustomerId);                              
                              
DECLARE @City NVARCHAR(100) = (SELECT TOP 1                              
IIF(LUC.City IS NULL, PADR.CityName, LUC.City) AS City                              
 FROM ProjectAddress PADR WITH (NOLOCK)                              
 LEFT OUTER JOIN LuCity LUC WITH (NOLOCK)                              
  ON LUC.CityId = PADR.CityId                              
 WHERE PADR.ProjectId = @TargetProjectId                              
 AND PADR.CustomerId = @CustomerId);                              
                              
--Temp Tables                                  
DROP TABLE IF EXISTS #tmp_SrcSection;                              
DROP TABLE IF EXISTS #tmp_TgtSection;                              
DROP TABLE IF EXISTS #SrcSegmentStatusCPTMP;                              
DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;                              
DROP TABLE IF EXISTS #tmp_SrcSegment;                              
DROP TABLE IF EXISTS #tmp_TgtSegment;                              
DROP TABLE IF EXISTS #tmp_SrcSegmentChoice;                              
DROP TABLE IF EXISTS #tmp_SrcSelectedChoiceOption;                              
DROP TABLE IF EXISTS #tmp_TgtSegmentChoice;                              
DROP TABLE IF EXISTS #tmp_SrcSegmentLink;                              
DROP TABLE IF EXISTS #tmp_TgtProjectNote;                              
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentRequirementTag;                              
DROP TABLE IF EXISTS #NewOldSectionIdMapping;                              
                                   
DECLARE @id_control INT                              
DECLARE @results INT                               
                              
 BEGIN TRY                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyStart_Description                              
     ,@CopyStart_Description                              
     ,1 --IsCompleted                                  
     ,@CopyStart_Step --Step                                 
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId       
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyStart_Percentage --Percent                                  
   ,0 --IsInsertRecord                               
   ,@CustomerName                  
   ,@UserName;                              
                              
--UPDATE TemplateId,ModifiedDate,ModifiedByFullName in target project                                              
UPDATE P                                    
SET P.TemplateId = P_Src.TemplateId,                              
P.IsLocked = P_Src.IsLocked,                              
P.LockedBy = CASE WHEN ISNULL(P_Src.IsLocked,0) = 1 THEN P_Src.LockedBy                              
   ELSE NULL END,                              
P.LockedDate = CASE WHEN ISNULL(P_Src.IsLocked,0) = 1 THEN P_Src.LockedDate                              
   ELSE NULL END                              
--,P.ModifiedBy = P_Src.ModifiedBy                                              
--,P.ModifiedDate = P_Src.ModifiedDate                                              
--,P.ModifiedByFullName = P_Src.ModifiedByFullName                                               
FROM Project P WITH (NOLOCK)                                    
INNER JOIN Project P_Src WITH (NOLOCK)                                    
 ON P_Src.ProjectId = @SourceProjectId                                    
WHERE P.ProjectId = @TargetProjectId;                         
         
--INSERT ProjectGlobalTerm                                  
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode,                              
CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted, GlobalTermFieldTypeId)                              
 SELECT                              
  PGT_Src.mGlobalTermId AS mGlobalTermId                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,PGT_Src.Name AS [Name]                              
    ,(CASE                              
   WHEN PGT_Src.Name = 'Project Name' THEN CAST(P.Name AS NVARCHAR(300))                              
   WHEN PGT_Src.Name = 'Project ID' THEN CAST(P.ProjectId AS NVARCHAR(300))                              
   WHEN (PGT_Src.Name = 'Project Location State' AND                              
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@StateProvinceName AS NVARCHAR(300))                              
   WHEN (PGT_Src.Name = 'Project Location City' AND                              
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@City AS NVARCHAR(300))                              
   WHEN (PGT_Src.Name = 'Project Location Province' AND                              
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@StateProvinceName AS NVARCHAR(500))                              
   ELSE PGT_Src.Value                              
  END) AS [Value]                              
    ,PGT_Src.GlobalTermSource AS GlobalTermSource                              
    ,PGT_Src.GlobalTermCode AS GlobalTermCode                              
    ,PGT_Src.CreatedDate AS CreatedDate                              
    ,PGT_Src.CreatedBy AS CreatedBy                              
    ,PGT_Src.ModifiedDate AS ModifiedDate                                ,PGT_Src.ModifiedBy AS ModifiedBy                              
    ,PGT_Src.UserGlobalTermId AS UserGlobalTermId                              
    ,ISNULL(PGT_Src.IsDeleted, 0) AS IsDeleted                              
    ,PGT_Src.GlobalTermFieldTypeId                              
 FROM ProjectGlobalTerm PGT_Src WITH (NOLOCK)            
 INNER JOIN Project P WITH (NOLOCK)                              
  ON P.ProjectId = @TargetProjectId                              
 WHERE PGT_Src.ProjectId = @SourceProjectId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyGlobalTems_Description                              
     ,@CopyGlobalTems_Description                              
     ,1 --IsCompleted                                  
     ,@CopyGlobalTems_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyGlobalTems_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
 ,@UserName;                              
                              
                          
                               
SET @results = 1                              
SET @id_control = 0                              
            
DECLARE @Records INT = 1;           
DECLARE @TableRows INT;                                 
DECLARE @ProjectSection INT                              
DECLARE @ProjectSegmentStatus  INT                              
DECLARE @ProjectSegment INT                              
DECLARE @ProjectSegmentChoice INT                              
DECLARE @ProjectChoiceOption INT                              
DECLARE @SelectedChoiceOption INT                              
DECLARE @ProjectSegmentLink INT                              
DECLARE @ProjectHyperLink INT                              
DECLARE @ProjectNote INT                              
DECLARE @Start INT = 1;          
DECLARE @End INT;          
                                 
          
IF(EXISTS(SELECT TOP 1 1 FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK) WHERE Servername=@@servername))                              
BEGIN                              
 SELECT TOP 1 @ProjectSection=ProjectSection,                              
  @ProjectSegmentStatus=ProjectSegmentStatus,                              
  @ProjectSegment =ProjectSegment ,                              
  @ProjectSegmentChoice =ProjectSegmentChoice ,                              
  @ProjectChoiceOption =ProjectChoiceOption ,                              
  @SelectedChoiceOption =SelectedChoiceOption ,                              
  @ProjectSegmentLink =ProjectSegmentLink ,                              
  @ProjectHyperLink =ProjectHyperLink ,                              
  @ProjectNote =ProjectNote                               
  FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK)                               
  WHERE Servername=@@servername                              
END                              
ELSE                              
BEGIN                       
 SELECT TOP 1 @ProjectSection=ProjectSection,                              
  @ProjectSegmentStatus=ProjectSegmentStatus,                              
  @ProjectSegment =ProjectSegment ,                              
  @ProjectSegmentChoice =ProjectSegmentChoice ,                              
  @ProjectChoiceOption =ProjectChoiceOption ,                              
  @SelectedChoiceOption =SelectedChoiceOption ,                              
  @ProjectSegmentLink =ProjectSegmentLink ,                              
  @ProjectHyperLink =ProjectHyperLink ,                              
  @ProjectNote =ProjectNote                               
  FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK)                               
  WHERE Servername IS NULL                              
END                 
            
--Copy source sections in temp table                              
SELECT                              
   PS.*,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo INTO #tmp_SrcSection                              
 FROM ProjectSection PS WITH (NOLOCK)                              
 WHERE PS.ProjectId = @SourceProjectId                              
 AND PS.CustomerId = @CustomerId                              
 AND ISNULL(PS.IsDeleted, 0) = 0;              
          
 --INSERT ProjectSection                              
 INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,                              
 Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate, CreatedBy,                              
 ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, A_SectionId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy              
 ,IsHidden, SortOrder,SectionSource, PendingUpdateCount)                              
  SELECT                          
      S.ParentSectionId, S.mSectionId,@TargetProjectId AS ProjectId, @CustomerId AS CustomerId                          
     ,@UserId AS UserId, S.DivisionId,S.DivisionCode,S.[Description],S.LevelId          
     ,S.IsLastLevel,S.SourceTag ,S.Author ,S.TemplateId ,S.SectionCode,S.IsDeleted ,S.CreateDate ,          
  S.CreatedBy  ,S.ModifiedBy ,S.ModifiedDate ,          
  S.FormatTypeId,S.SpecViewModeId ,S.SectionId as A_SectionId ,          
  IsTrackChanges ,IsTrackChangeLock  ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy              
     ,IsHidden ,SortOrder,SectionSource, PendingUpdateCount   FROM #tmp_SrcSection S          
--Copy target sections in temp table                              
SELECT                              
 PS.SectionId                              
   ,PS.ParentSectionId                              
   ,PS.ProjectId                              
   ,PS.CustomerId                              
  ,PS.IsLastLevel                              
   ,PS.SectionCode                              
   ,PS.IsDeleted                              
   ,PS.A_SectionId        
   ,PS.SectionSource                                 
   --,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo                          
   INTO #tmp_TgtSection                              
FROM ProjectSection PS WITH (NOLOCK)                              
WHERE PS.ProjectId = @TargetProjectId                              
AND ISNULL(PS.IsDeleted, 0) = 0;                              
                              
SELECT                              
 SectionId                              
   ,A_SectionId INTO #NewOldSectionIdMapping                              
FROM #tmp_TgtSection                              
                              
--UPDATE ParentSectionId in TGT Section table                              
UPDATE TGT_TMP                              
SET TGT_TMP.ParentSectionId = NOSM.SectionId                              
FROM #tmp_TgtSection TGT_TMP WITH (NOLOCK)                              
INNER JOIN #NewOldSectionIdMapping NOSM WITH (NOLOCK)                              
 ON TGT_TMP.ParentSectionId = NOSM.A_SectionId                              
WHERE TGT_TMP.ProjectId = @TargetProjectId;                              
                              
                              
--UPDATE ParentSectionId in original table                              
UPDATE PS                              
SET PS.ParentSectionId = PS_TMP.ParentSectionId                              
FROM ProjectSection PS WITH (NOLOCK)                              
INNER JOIN #tmp_TgtSection PS_TMP                              
 ON PS.SectionId = PS_TMP.SectionId                              
WHERE PS.ProjectId = @TargetProjectId                              
AND PS.CustomerId = @CustomerId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopySections_Description                              
     ,@CopySections_Description                              
     ,1 --IsCompleted                                  
     ,@CopySections_Step --Step               
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopySections_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;             
         
--Insert data into SectionDocument related Alternate Document      
INSERT INTO SectionDocument          
 (ProjectId          
    ,SectionId       
  ,SectionDocumentTypeId          
  ,DocumentPath          
  ,OriginalFileName          
  ,CreateDate          
  ,CreatedBy)          
SELECT @TargetProjectId      
       ,tgtSect.SectionId      
    ,SD.SectionDocumentTypeId      
    ,REPLACE(SD.DocumentPath,@PSourceProjectId,@PTargetProjectId)      
    ,SD.OriginalFileName      
    ,GETUTCDATE()      
    ,@PUserId      
 FROm SectionDocument SD WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection tgtSect WITH(NOLOCK)      
 ON  SD.ProjectId = @PSourceProjectId      
 AND SD.SectionId = tgtSect.A_SectionId      
 AND tgtSect.SectionSource = 8      
                       
                              
--Copy source segment status in temp table                                  
SELECT                              
 PSST.*                        
 ,ROW_NUMBER() OVER (ORDER BY PSST.SectionId) AS SrNo                     
 INTO #SrcSegmentStatusCPTMP                              
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                        
INNER JOIN #tmp_TgtSection s                          
ON PSST.SectionId=s.A_SectionId                               
AND ISNULL(PSST.IsDeleted, 0) = 0                              
WHERE PSST.ProjectId = @SourceProjectId                        
AND PSST.CustomerId = @CustomerId                              
  
                              
SET @TableRows = @@ROWCOUNT          
  SET @Records = 1          
  SET @Start = 1          
  SET @End = @Start + @ProjectSegmentStatus - 1                            
                              
WHILE @Records <= @TableRows                              
BEGIN                              
 --INSERT ProjectSegmentStatus                         
 INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,                              
 IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,                              
 SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,                              
 ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)                              
  SELECT                              
     PS.SectionId AS SectionId                              
    ,PSST_Src.ParentSegmentStatusId AS ParentSegmentStatusId                              
    ,PSST_Src.mSegmentStatusId AS mSegmentStatusId                              
    ,PSST_Src.mSegmentId AS mSegmentId                              
    ,PSST_Src.SegmentId AS SegmentId                              
    ,PSST_Src.SegmentSource AS SegmentSource                              
    ,PSST_Src.SegmentOrigin AS SegmentOrigin                              
    ,PSST_Src.IndentLevel AS IndentLevel              
    ,PSST_Src.SequenceNumber AS SequenceNumber                              
    ,PSST_Src.SpecTypeTagId AS SpecTypeTagId                              
    ,PSST_Src.SegmentStatusTypeId AS SegmentStatusTypeId                              
    ,PSST_Src.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,PSST_Src.SegmentStatusCode AS SegmentStatusCode                              
    ,PSST_Src.IsShowAutoNumber AS IsShowAutoNIsPageBreakumber                              
    ,PSST_Src.IsRefStdParagraph AS IsRefStdParagraph                              
    ,PSST_Src.FormattingJson AS FormattingJson                           
    ,PSST_Src.CreateDate AS CreateDate                              
    ,PSST_Src.CreatedBy AS CreatedBy                              
    ,PSST_Src.ModifiedBy AS ModifiedBy                              
    ,PSST_Src.ModifiedDate AS ModifiedDate                              
    ,PSST_Src.IsPageBreak AS IsPageBreak                              
    ,PSST_Src.IsDeleted AS IsDeleted                              
    ,PSST_Src.SegmentStatusId AS A_SegmentStatusId                              
  FROM #SrcSegmentStatusCPTMP PSST_Src WITH (NOLOCK)                              
  INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PSST_Src.SectionId = PS.A_SectionId                              
  WHERE PSST_Src.SrNo BETWEEN @Start AND @End                            
   WAITFOR DELAY @Delayfor;  
   SET @Records += @ProjectSegmentStatus;          
   SET @Start = @End + 1 ;          
   SET @End = @Start + @ProjectSegmentStatus - 1;                            
END                              

--Copy target segment status in temp table                                  
SELECT                              
 PSST.SegmentStatusId                              
   ,PSST.SectionId                              
   ,PSST.ParentSegmentStatusId                              
   ,PSST.SegmentId                              
   ,PSST.ProjectId                              
   ,PSST.CustomerId                              
   ,PSST.SegmentStatusCode                              
   ,PSST.IsDeleted                              
   ,PSST.A_SegmentStatusId INTO #tmp_TgtSegmentStatus             
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                              
WHERE PSST.ProjectId = @TargetProjectId                              
AND PSST.CustomerId = @CustomerId                              
AND ISNULL(PSST.IsDeleted, 0) = 0                              
                              
SELECT                              
 SegmentStatusId                              
   ,A_SegmentStatusId INTO #NewOldSegmentStatusIdMapping                              
FROM #tmp_TgtSegmentStatus                              
                              
--UPDATE ParentSegmentStatusId in temp table                                  
UPDATE CPSST                              
SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId                              
FROM #tmp_TgtSegmentStatus CPSST WITH (NOLOCK)                              
INNER JOIN #NewOldSegmentStatusIdMapping PPSST WITH (NOLOCK)            
 ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId                              
WHERE CPSST.ProjectId = @TargetProjectId                         
AND CPSST.CustomerId = @CustomerId;                              
                              
--UPDATE ParentSegmentStatusId in original table                              
UPDATE PSS                              
SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId                              
FROM ProjectSegmentStatus PSS WITH (NOLOCK)                              
INNER JOIN #tmp_TgtSegmentStatus PSS_TMP                              
 ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId                              
 AND PSS.ProjectId = @TargetProjectId                              
WHERE PSS.ProjectId = @TargetProjectId             
AND PSS.CustomerId = @CustomerId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
  ,@CopySegmentStatus_Description                              
     ,@CopySegmentStatus_Description                              
     ,1 --IsCompleted                                  
     ,@CopySegmentStatus_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopySegmentStatus_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--Copy source segments in temp table                         
SELECT PSG.* ,ROW_NUMBER() OVER (ORDER BY PSG.SectionId) AS SrNo                         
INTO #tmp_SrcSegment                        
FROM ProjectSegment PSG WITH (NOLOCK)                        
INNER JOIN #tmp_TgtSection s                        
ON PSG.SectionId=s.A_SectionId                        
AND ISNULL(PSG.IsDeleted, 0) = 0        
WHERE PSG.ProjectId = @SourceProjectId                        
AND PSG.CustomerId = @CustomerId                        
                        
                        
  SET @TableRows = @@ROWCOUNT          
  SET @Records = 1          
  SET @Start = 1          
  SET @End = @Start + @ProjectSegment - 1                               
                              
WHILE @Records <= @TableRows                              
BEGIN                              
 INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,                              
 SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentId, BaseSegmentDescription)                              
  SELECT                              
   PSST.SegmentStatusId AS SegmentStatusId                              
  ,PS.SectionId AS SectionId                              
  ,@TargetProjectId AS ProjectId                              
  ,@CustomerId AS CustomerId                              
  ,PSG_Src.SegmentDescription AS SegmentDescription                              
  ,PSG_Src.SegmentSource AS SegmentSource                              
  ,PSG_Src.SegmentCode AS SegmentCode                              
  ,PSG_Src.CreatedBy AS CreatedBy                          
  ,PSG_Src.CreateDate AS CreateDate                              
  ,PSG_Src.ModifiedBy AS ModifiedBy                              
  ,PSG_Src.ModifiedDate AS ModifiedDate                              
  ,PSG_Src.IsDeleted AS IsDeleted                              
  ,PSG_Src.SegmentId AS A_SegmentId                              
  ,PSG_Src.BaseSegmentDescription AS BaseSegmentDescription                              
  FROM #tmp_SrcSegment PSG_Src WITH (NOLOCK)                              
  INNER JOIN #tmp_tgtSection PS WITH (NOLOCK)                              
  ON PSG_Src.SectionId = PS.A_SectionId                              
  INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)                              
  ON PSG_Src.SegmentStatusId = PSST.A_SegmentStatusId                              
  WHERE PSG_Src.SrNo BETWEEN @Start AND @End          
   WAITFOR DELAY @Delayfor;  
 SET @Records += @ProjectSegment;          
 SET @Start = @End + 1 ;          
 SET @End = @Start + @ProjectSegment - 1;                              
END                              
                     
--Copy target segments in temp table                                  
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
WHERE PSG.ProjectId = @TargetProjectId                              
AND PSG.CustomerId = @CustomerId                              
AND ISNULL(PSG.IsDeleted, 0) = 0                              
                              
--UPDATE SegmentId in temp table                                  
UPDATE PSST                              
SET PSST.SegmentId = PSG.SegmentId                              
FROM #tmp_TgtSegmentStatus PSST WITH (NOLOCK)                              
INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)                              
ON PSST.SectionId = PSG.SectionId                              
AND PSST.SegmentId = PSG.A_SegmentId                              
AND PSST.SegmentId IS NOT NULL                              
                              
----UPDATE ParentSegmentStatusId and SegmentId in original table                                  
UPDATE PSST                              
SET --PSST.ParentSegmentStatusId = PSST_TMP.ParentSegmentStatusId,                                  
PSST.SegmentId = PSST_TMP.SegmentId                              
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                              
INNER JOIN #tmp_TgtSegmentStatus PSST_TMP WITH (NOLOCK)                              
 ON PSST.SegmentStatusId = PSST_TMP.SegmentStatusId                              
 AND PSST.ProjectId = PSST_TMP.ProjectId                              
 AND PSST.SegmentId IS NOT NULL                              
WHERE PSST.ProjectId = @TargetProjectId                              
AND PSST.CustomerId = @CustomerId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopySegments_Description                              
     ,@CopySegments_Description                              
     ,1 --IsCompleted                                  
     ,@CopySegments_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                   
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopySegments_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--Copy source choices in temp table                                  
SELECT                              
 PCH.*                               
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo                              
 INTO #tmp_SrcSegmentChoice                              
FROM ProjectSegmentChoice PCH WITH (NOLOCK)                              
WHERE PCH.ProjectId = @SourceProjectId                              
AND PCH.CustomerId = @CustomerId                              
AND ISNULL(PCH.IsDeleted, 0) = 0                              
          
   SET @TableRows = @@ROWCOUNT                     
SET @Records = 1          
SET @Start = 1          
SET @End = @Start + @ProjectSegmentChoice - 1          
          
WHILE @Records <= @TableRows                       
BEGIN                              
 --INSERT ProjectSegmentChoice                                  
 INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,                              
 SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentCHoiceId)                              
 SELECT PS.SectionId AS SectionId                              
 ,PSG.SegmentStatusId                              
 ,PSG.SegmentId AS SegmentId                              
 ,PCH_Src.ChoiceTypeId AS ChoiceTypeId                              
 ,@TargetProjectId AS ProjectId                              
 ,@CustomerId AS CustomerId                              
 ,PCH_Src.SegmentChoiceSource AS SegmentChoiceSource                              
 ,PCH_Src.SegmentChoiceCode AS SegmentChoiceCode                              
 ,PCH_Src.CreatedBy AS CreatedBy                              
 ,PCH_Src.CreateDate AS CreateDate                              
 ,PCH_Src.ModifiedBy AS ModifiedBy                              
 ,PCH_Src.ModifiedDate AS ModifiedDate                              
 ,PCH_Src.IsDeleted AS IsDeleted                              
 ,PCH_Src.SegmentChoiceId AS A_SegmentCHoiceId                              
 FROM #tmp_SrcSegmentChoice PCH_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
 ON PCH_Src.SectionId = PS.A_SectionId                              
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)                              
 ON PS.SectionId = PSG.SectionId                              
 AND PCH_Src.SegmentId = PSG.A_SegmentId                              
 INNER JOIN #SrcSegmentStatusCPTMP SRCS         
ON PCH_Src.SegmentId = SRCS.SegmentId                           
and ISNULL(SRCS.IsDeleted, 0) = 0                              
WHERE PCH_Src.SrNo BETWEEN @Start AND @End                              
   WAITFOR DELAY @Delayfor;                                                         
  SET @Records += @ProjectSegmentChoice;          
   SET @Start = @End + 1 ;          
   SET @End = @Start + @ProjectSegmentChoice - 1;                               
END                              
                              
--Copy target choices in temp table                                  
SELECT PCH.*                               
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo                              
 INTO #tmp_TgtSegmentChoice                              
FROM ProjectSegmentChoice PCH WITH (NOLOCK)                              
WHERE PCH.ProjectId = @TargetProjectId                              
AND PCH.CustomerId = @CustomerId                              
AND ISNULL(PCH.IsDeleted, 0) = 0             
          
   SET @TableRows = @@ROWCOUNT                           
  SET @Records = 1          
  SET @Start = 1          
  SET @End = @Start + @ProjectChoiceOption - 1                          
                              
WHILE @Records <= @TableRows                              
BEGIN                              
 --INSERT ProjectChoiceOption                                
 INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,                              
 CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_ChoiceOptionId)                              
 SELECT PCH.SegmentChoiceId AS SegmentChoiceId                              
  ,PCHOP_Src.SortOrder AS SortOrder                              
  ,PCHOP_Src.ChoiceOptionSource AS ChoiceOptionSource                              
  ,PCHOP_Src.OptionJson AS OptionJson                              
  ,@TargetProjectId AS ProjectId                              
  ,PCH.SectionId AS SectionId                              
  ,@CustomerId AS CustomerId                              
  ,PCHOP_Src.ChoiceOptionCode AS ChoiceOptionCode                              
  ,PCHOP_Src.CreatedBy AS CreatedBy                              
  ,PCHOP_Src.CreateDate AS CreateDate                              
  ,PCHOP_Src.ModifiedBy AS ModifiedBy                              
  ,PCHOP_Src.ModifiedDate AS ModifiedDate                              
  ,PCHOP_Src.IsDeleted AS IsDeleted                              
  ,PCHOP_Src.ChoiceOptionId AS A_ChoiceOptionId                              
  FROM ProjectChoiceOption PCHOP_Src WITH (NOLOCK)                              
  INNER JOIN #tmp_TgtSegmentChoice PCH WITH (NOLOCK)                              
  ON PCH.A_SegmentChoiceId = PCHOP_Src.SegmentChoiceId                              
  AND ISNULL(PCH.IsDeleted, 0) = ISNULL(PCHOP_Src.IsDeleted, 0)                              
  WHERE PCHOP_Src.ProjectId = @SourceProjectId                              
  AND PCHOP_Src.CustomerId = @CustomerId                              
  AND PCH.SrNo BETWEEN @Start AND @End                              
  WAITFOR DELAY @Delayfor;
   SET @Records += @ProjectChoiceOption;          
   SET @Start = @End + 1 ;          
   SET @End = @Start + @ProjectChoiceOption - 1;                                
END                   
                     
--Copy source choices in temp table                                  
SELECT                              
 SCO_Src.*                       
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo                              
 INTO #tmp_SrcSelectedChoiceOption                              
FROM SelectedChoiceOption SCO_Src WITH (NOLOCK)                            
WHERE SCO_Src.ProjectId = @SourceProjectId                              
AND SCO_Src.CustomerId = @CustomerId                              
AND ISNULL(SCO_Src.IsDeleted, 0) = 0                              
                              
  SET @TableRows = @@ROWCOUNT          
  SET @Records = 1          
  SET @Start = 1          
  SET @End = @Start + @SelectedChoiceOption - 1                              
                              
WHILE @Records <= @TableRows                             
BEGIN                              
 --INSERT SelectedChoiceOption                                  
 INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected,                              
 SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)                              
 SELECT PSCHOP_Src.SegmentChoiceCode AS SegmentChoiceCode                              
 ,PSCHOP_Src.ChoiceOptionCode AS ChoiceOptionCode                              
 ,PSCHOP_Src.ChoiceOptionSource AS ChoiceOptionSource                              
 ,PSCHOP_Src.IsSelected AS IsSelected                              
 ,PSC.SectionId AS SectionId                              
 ,@TargetProjectId AS ProjectId                              
 ,@CustomerId AS CustomerId                              
 ,PSCHOP_Src.OptionJson AS OptionJson                              
 ,PSCHOP_Src.IsDeleted AS IsDeleted                              
 FROM #tmp_SrcSelectedChoiceOption PSCHOP_Src WITH (NOLOCK)                              
 INNER JOIN #NewOldSectionIdMapping PSC WITH (NOLOCK)                              
 ON PSCHOP_Src.Sectionid = PSC.A_SectionId                              
 AND PSCHOP_Src.ProjectId = @SourceProjectId                              
 WHERE PSCHOP_Src.ProjectId = @SourceProjectId                              
 AND PSCHOP_Src.CustomerId = @CustomerId                              
 AND PSCHOP_Src.SrNo BETWEEN @Start AND @End          
 WAITFOR DELAY @Delayfor;                         
 SET @Records += @SelectedChoiceOption;          
 SET @Start = @End + 1 ;          
 SET @End = @Start + @SelectedChoiceOption - 1;                              
     
END                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopySegmentChoices_Description                              
     ,@CopySegmentChoices_Description                              
     ,1 --IsCompleted                             
     ,@CopySegmentChoices_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
,@CustomerId                              
   ,2 --Status                                  
   ,@CopySegmentChoices_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
SELECT *                              
 ,ROW_NUMBER() OVER (ORDER BY TargetSectionCode) AS SrNo                              
 INTO #tmp_SrcSegmentLink                              
FROM ProjectSegmentLink WITH (NOLOCK)                              
WHERE ProjectId = @SourceProjectId                              
AND CustomerId = @CustomerId                              
AND ISNULL(IsDeleted, 0) = 0                              
                              
 SET @TableRows = @@ROWCOUNT          
 SET @Records = 1          
 SET @Start = 1          
 SET @End = @Start + @ProjectSegmentLink - 1                               
                              
WHILE @Records <= @TableRows                              
BEGIN                              
 --INSERT ProjectSegmentLink                                  
 INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,                              
 TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,                              
 LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,                              
 SegmentLinkCode, SegmentLinkSourceTypeId)                              
 SELECT PSL_Src.SourceSectionCode                              
 ,PSL_Src.SourceSegmentStatusCode                              
 ,PSL_Src.SourceSegmentCode                              
 ,PSL_Src.SourceSegmentChoiceCode                              
 ,PSL_Src.SourceChoiceOptionCode               
 ,PSL_Src.LinkSource              
 ,PSL_Src.TargetSectionCode                              
 ,PSL_Src.TargetSegmentStatusCode                              
 ,PSL_Src.TargetSegmentCode                              
 ,PSL_Src.TargetSegmentChoiceCode                              
 ,PSL_Src.TargetChoiceOptionCode                              
 ,PSL_Src.LinkTarget                              
 ,PSL_Src.LinkStatusTypeId                              
 ,PSL_Src.IsDeleted                              
 ,PSL_Src.CreateDate AS CreateDate                              
 ,PSL_Src.CreatedBy AS CreatedBy                              
 ,PSL_Src.ModifiedBy AS ModifiedBy                              
 ,PSL_Src.ModifiedDate AS ModifiedDate                              
 ,@TargetProjectId AS ProjectId                              
 ,@CustomerId AS CustomerId                              
 ,PSL_Src.SegmentLinkCode                              
 ,PSL_Src.SegmentLinkSourceTypeId                              
  FROM #tmp_SrcSegmentLink AS PSL_Src WITH (NOLOCK)                              
  WHERE PSL_Src.SrNo BETWEEN @Start AND @End                              
   WAITFOR DELAY @Delayfor;                       
   SET @Records += @ProjectSegmentLink;          
   SET @Start = @End + 1 ;          
   SET @End = @Start + @ProjectSegmentLink - 1;                               
END              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopySegmentLinks_Description                              
     ,@CopySegmentLinks_Description                                  
     ,1 --IsCompleted                                  
     ,@CopySegmentLinks_Step --Step                     
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopySegmentLinks_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--INSERT ProjectNote                                 
                              
SELECT                              
 PS.SectionId AS SectionId                              
    ,PSST.SegmentStatusId AS SegmentStatusId                              
    ,PNT_Src.NoteText AS NoteText                              
    ,PNT_Src.CreateDate AS CreateDate                 
    ,PNT_Src.ModifiedDate AS ModifiedDate                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
   ,PNT_Src.Title AS Title                              
    ,PNT_Src.CreatedBy AS CreatedBy                              
    ,PNT_Src.ModifiedBy AS ModifiedBy                              
    ,PNT_Src.CreatedUserName                              
    ,PNT_Src.ModifiedUserName                              
    ,PNT_Src.IsDeleted AS IsDeleted                              
    ,PNT_Src.NoteCode AS NoteCode                              
    ,PNT_Src.NoteId AS A_NoteId                              
 ,ROW_NUMBER() OVER (ORDER BY PSST.SegmentStatusId) AS SrNo                              
 into #PN FROM ProjectNote PNT_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PNT_Src.SectionId = PS.A_SectionId                              
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)                              
  ON PNT_Src.SegmentStatusId = PSST.A_SegmentStatusId                              
 WHERE PNT_Src.ProjectId = @SourceProjectId                              
 AND PNT_Src.CustomerId = @CustomerId;                              
   WAITFOR DELAY @Delayfor;
    SET @TableRows = @@ROWCOUNT          
 SET @Records = 1          
 SET @Start = 1          
 SET @End = @Start + @ProjectNote - 1                         
                         
WHILE @Records <= @TableRows                              
BEGIN                              
 INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,                              
 CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode, A_NoteId)                              
 select SectionId,SegmentStatusId,NoteText,CreateDate,ModifiedDate,ProjectId                              
    ,CustomerId,Title,CreatedBy,ModifiedBy,CreatedUserName,ModifiedUserName,IsDeleted,NoteCode,A_NoteId                              
 FROM #PN WHERE SrNo BETWEEN @Start AND @End                              
WAITFOR DELAY @Delayfor;                   
 SET @Records += @ProjectNote;          
 SET @Start = @End + 1 ;          
 SET @End = @Start + @ProjectNote - 1;                               
END                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyNotes_Description                              
     ,@CopyNotes_Description                              
     ,1 --IsCompleted                 
     ,@CopyNotes_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyNotes_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--Insert Target ProjectNote in Temp Table                                  
SELECT                              
 PN.NoteId                              
   ,PN.SectionId                              
   ,PN.ProjectId                              
   ,PN.CustomerId                              
   ,PN.IsDeleted                              
   ,PN.A_NoteId                               
   INTO #tmp_TgtProjectNote                              
FROM ProjectNote PN WITH (NOLOCK)                              
WHERE PN.ProjectId = @TargetProjectId                              
AND PN.CustomerId = @CustomerId                              
AND ISNULL(IsDeleted, 0) = 0                              
                           
 --INSERT ProjectNoteImage                                  
 INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)                      
 SELECT PN.NoteId AS NoteId                              
  ,PS.SectionId AS SectionId                              
  ,PNTI_Src.ImageId AS ImageId                              
  ,@TargetProjectId AS ProjectId                              
  ,@CustomerId AS CustomerId                              
  FROM ProjectNoteImage PNTI_Src WITH (NOLOCK)                              
  INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PNTI_Src.SectionId = PS.A_SectionId                              
  INNER JOIN #tmp_TgtProjectNote PN WITH (NOLOCK)                              
  ON PN.SectionId=PS.SectionId                              
  AND PN.ProjectId = @TargetProjectId                              
  AND PNTI_Src.NoteId = PN.A_NoteId                              
  WHERE PNTI_Src.ProjectId = @SourceProjectId                              
  AND PNTI_Src.CustomerId = @CustomerId                              
                                
--INSERT ProjectSegmentImage                                  
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)                              
 SELECT                              
  PS.SectionId AS SectionId                              
    ,PSI_Src.ImageId AS ImageId                             
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,0 AS SegmentId                                  
 ,PSI_Src.ImageStyle                                  
 FROM ProjectSegmentImage PSI_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
 ON PSI_Src.SectionId = PS.A_SectionId                              
 WHERE PSI_Src.ProjectId = @SourceProjectId                              
 AND PSI_Src.CustomerId = @CustomerId;                             
                                
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                    
     ,@CopyImages_Description                              
     ,@CopyImages_Description                              
     ,1 --IsCompleted                                  
     ,@CopyImages_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                
   ,@CopyImages_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId,                              
IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)                              
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,PRS_Src.RefStandardId AS RefStandardId                              
    ,PRS_Src.RefStdSource AS RefStdSource                              
    ,PRS_Src.mReplaceRefStdId AS mReplaceRefStdId                              
    ,PRS_Src.RefStdEditionId AS RefStdEditionId                              
    ,PRS_Src.IsObsolete AS IsObsolete                              
    ,PRS_Src.RefStdCode AS RefStdCode                              
    ,PRS_Src.PublicationDate AS PublicationDate                              
    ,PS.SectionId AS SectionId                              
    ,@CustomerId AS CustomerId                              
    ,PRS_Src.IsDeleted AS IsDeleted                              
FROM ProjectReferenceStandard PRS_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PRS_Src.SectionId = PS.A_SectionId                              
 WHERE PRS_Src.ProjectId = @SourceProjectId                              
 AND PRS_Src.CustomerId = @CustomerId;                              
                              
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,                              
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId,                              
mSegmentId, RefStdCode, IsDeleted)                              
 SELECT                              
  PS.SectionId AS SectionId                              
    ,PSG.SegmentId AS SegmentId                            
    ,PSRS_Src.RefStandardId AS RefStandardId                              
    ,PSRS_Src.RefStandardSource AS RefStandardSource                              
    ,PSRS_Src.mRefStandardId AS mRefStandardId                              
    ,PSRS_Src.CreateDate AS CreateDate                              
    ,PSRS_Src.CreatedBy AS CreatedBy                              
    ,PSRS_Src.ModifiedDate AS ModifiedDate                              
    ,PSRS_Src.ModifiedBy AS ModifiedBy                              
    ,@CustomerId AS CustomerId                              
    ,@TargetProjectId AS ProjectId                              
    ,PSRS_Src.mSegmentId AS mSegmentId                              
    ,PSRS_Src.RefStdCode AS RefStdCode                              
    ,PSRS_Src.IsDeleted AS IsDeleted                              
 FROM ProjectSegmentReferenceStandard PSRS_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PSRS_Src.SectionId = PS.A_SectionId                              
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)                              
  ON PS.SectionId = PSG.SectionId                              
   AND PSRS_Src.SegmentId = PSG.A_SegmentId                              
 WHERE PSRS_Src.ProjectId = @SourceProjectId                              
 AND PSRS_Src.CustomerId = @CustomerId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyRefStds_Description                              
     ,@CopyRefStds_Description                              
     ,1 --IsCompleted           
     ,@CopyRefStds_Step --Step                 
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                            
   ,@CopyRefStds_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--Copy source ProjectSegmentRequirementTag in temp table                                  
SELECT                              
 PSRT.* INTO #tmp_SrcProjectSegmentRequirementTag                   
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                              
WHERE PSRT.ProjectId = @SourceProjectId                              
AND PSRT.CustomerId = @CustomerId                              
AND ISNULL(PSRT.IsDeleted, 0) = 0                              
                              
--INSERT ProjectSegmentRequirementTag                                  
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate,                              
ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId, IsDeleted)                              
 SELECT                              
  PS.SectionId                              
    ,PSST.SegmentStatusId                              
    ,PSRT_Src.RequirementTagId                              
    ,PSRT_Src.CreateDate                              
    ,PSRT_Src.ModifiedDate                     
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,PSRT_Src.CreatedBy                              
    ,PSRT_Src.ModifiedBy                              
    ,PSRT_Src.mSegmentRequirementTagId                              
    ,PSRT_Src.IsDeleted                              
 FROM #tmp_SrcProjectSegmentRequirementTag PSRT_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PSRT_Src.SectionId = PS.A_SectionId                              
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)                              
  --ON PS.SectionId = PSST.SectionId                                  
  ON PSRT_Src.SegmentStatusId = PSST.A_SegmentStatusId                              
 WHERE PSRT_Src.ProjectId = @SourceProjectId                              
 AND PSRT_Src.CustomerId = @CustomerId;                              
                              
--INSERT ProjectSegmentUserTag                                  
INSERT INTO ProjectSegmentUserTag (SectionId, SegmentStatusId, UserTagId, CreateDate, ModifiedDate,                              
ProjectId, CustomerId, CreatedBy, ModifiedBy, IsDeleted)                              
 SELECT                              
  PS.SectionId                              
    ,PSST.SegmentStatusId                              
    ,PSUT_Src.UserTagId                              
    ,PSUT_Src.CreateDate                              
    ,PSUT_Src.ModifiedDate                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,PSUT_Src.CreatedBy                              
    ,PSUT_Src.ModifiedBy                              
    ,PSUT_Src.IsDeleted                              
 FROM ProjectSegmentUserTag PSUT_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PSUT_Src.SectionId = PS.A_SectionId                              
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)                              
  --ON PS.SectionId = PSST.SectionId                                  
  ON PSUT_Src.SegmentStatusId = PSST.A_SegmentStatusId                              
 WHERE PSUT_Src.ProjectId = @SourceProjectId                              
 AND PSUT_Src.CustomerId = @CustomerId;                              
                              
--INSERT ProjectSegmentGlobalTerm                                  
INSERT INTO ProjectSegmentGlobalTerm (SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode,                              
CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, IsLocked, LockedByFullName,                              
UserLockedId, IsDeleted)                              
 SELECT                              
  PS.SectionId                              
    ,PSG.SegmentId                              
    ,PSGT_Src.mSegmentId                              
    ,PSGT_Src.UserGlobalTermId                              
    ,PSGT_Src.GlobalTermCode                              
    ,PSGT_Src.CreatedDate AS CreatedDate                              
    ,PSGT_Src.CreatedBy AS CreatedBy                              
    ,PSGT_Src.ModifiedDate AS ModifiedDate                              
    ,PSGT_Src.ModifiedBy AS ModifiedBy                              
    ,@CustomerId AS CustomerId                              
    ,@TargetProjectId AS ProjectId                              
    ,PSGT_Src.IsLocked                              
    ,PSGT_Src.LockedByFullName                              
    ,PSGT_Src.UserLockedId                              
    ,PSGT_Src.IsDeleted                              
 FROM ProjectSegmentGlobalTerm PSGT_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PSGT_Src.SectionId = PS.A_SectionId                              
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)                              
 ON PSGT_Src.SegmentId = PSG.A_SegmentId                              
 WHERE PSGT_Src.ProjectId = @SourceProjectId                              
 AND PSGT_Src.CustomerId = @CustomerId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyTags_Description                              
     ,@CopyTags_Description                              
     ,1 --IsCompleted                                  
     ,@CopyTags_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyTags_Percentage --Percent                                 
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--INSERT Header                                  
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId,           
  
    
      
        
          
            
              
                
                  
                   
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId,IsShowLineAboveHeader,IsShowLineBelowHeader)                              
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,NULL AS SectionId                              
    ,@CustomerId AS CustomerId                              
    ,H_Src.Description                              
    ,H_Src.IsLocked                              
    ,H_Src.LockedByFullName                              
    ,H_Src.LockedBy       
    ,H_Src.ShowFirstPage                    
    ,H_Src.CreatedBy AS CreatedBy                              
    ,H_Src.CreatedDate AS CreatedDate                              
    ,H_Src.ModifiedBy AS ModifiedBy                              
    ,H_Src.ModifiedDate AS ModifiedDate                              
    ,H_Src.TypeId                              
    ,H_Src.AltHeader                              
    ,H_Src.FPHeader                              
    ,H_Src.UseSeparateFPHeader                              
    ,H_Src.HeaderFooterCategoryId                              
    ,H_Src.[DateFormat]                              
    ,H_Src.TimeFormat                              
    ,H_Src.HeaderFooterDisplayTypeId                              
    ,H_Src.DefaultHeader                              
    ,H_Src.FirstPageHeader                              
    ,H_Src.OddPageHeader                              
    ,H_Src.EvenPageHeader                              
    ,H_Src.DocumentTypeId                              
 ,H_Src.IsShowLineAboveHeader                                
 ,H_Src.IsShowLineBelowHeader                
 FROM Header H_Src WITH (NOLOCK)                              
 WHERE H_Src.ProjectId = @SourceProjectId                              
 AND ISNULL(H_Src.SectionId, 0) = 0                              
 UNION                              
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,PS.SectionId AS SectionId                              
    ,@CustomerId AS CustomerId                              
    ,H_Src.Description                              
    ,H_Src.IsLocked                              
    ,H_Src.LockedByFullName                              
    ,H_Src.LockedBy                              
    ,H_Src.ShowFirstPage                              
    ,H_Src.CreatedBy AS CreatedBy                              
    ,H_Src.CreatedDate AS CreatedDate                              
    ,H_Src.ModifiedBy AS ModifiedBy                              
    ,H_Src.ModifiedDate AS ModifiedDate                              
    ,H_Src.TypeId                              
    ,H_Src.AltHeader                              
    ,H_Src.FPHeader                              
    ,H_Src.UseSeparateFPHeader                
    ,H_Src.HeaderFooterCategoryId                              
    ,H_Src.[DateFormat]                              
    ,H_Src.TimeFormat                              
    ,H_Src.HeaderFooterDisplayTypeId                              
    ,H_Src.DefaultHeader                              
    ,H_Src.FirstPageHeader                              
    ,H_Src.OddPageHeader                              
    ,H_Src.EvenPageHeader                              
    ,H_Src.DocumentTypeId                              
 ,H_Src.IsShowLineAboveHeader                                
 ,H_Src.IsShowLineBelowHeader                                
 FROM Header H_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON H_Src.SectionId = PS.A_SectionId                              
 WHERE H_Src.ProjectId = @SourceProjectId;                              
           
--INSERT Footer                                  
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId,           
   
   
       
       
          
             
              
                
                  
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,IsShowLineAboveFooter,IsShowLineBelowFooter)                              
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,NULL AS SectionId                              
    ,@CustomerId AS CustomerId                           
    ,F_Src.Description                              
    ,F_Src.IsLocked                              
    ,F_Src.LockedByFullName                              
    ,F_Src.LockedBy                              
    ,F_Src.ShowFirstPage                              
    ,F_Src.CreatedBy AS CreatedBy              
    ,F_Src.CreatedDate AS CreatedDate                              
    ,F_Src.ModifiedBy AS ModifiedBy                              
    ,F_Src.ModifiedDate AS ModifiedDate                              
    ,F_Src.TypeId                              
    ,F_Src.AltFooter                              
    ,F_Src.FPFooter                              
    ,F_Src.UseSeparateFPFooter                              
    ,F_Src.HeaderFooterCategoryId                              
,F_Src.[DateFormat]                              
    ,F_Src.TimeFormat                              
    ,F_Src.HeaderFooterDisplayTypeId                              
    ,F_Src.DefaultFooter                              
    ,F_Src.FirstPageFooter                              
    ,F_Src.OddPageFooter                              
    ,F_Src.EvenPageFooter                              
    ,F_Src.DocumentTypeId                                  
 ,F_Src.IsShowLineAboveFooter                                
 ,F_Src.IsShowLineBelowFooter                                  
 FROM Footer F_Src WITH (NOLOCK)                              
 WHERE F_Src.ProjectId = @SourceProjectId                              
 AND ISNULL(F_Src.SectionId, 0) = 0                              
 UNION                              
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,PS.SectionId AS SectionId                              
    ,@CustomerId AS CustomerId                              
    ,F_Src.Description                              
    ,F_Src.IsLocked                              
    ,F_Src.LockedByFullName                              
    ,F_Src.LockedBy                              
    ,F_Src.ShowFirstPage                              
    ,F_Src.CreatedBy AS CreatedBy                   
    ,F_Src.CreatedDate AS CreatedDate                              
    ,F_Src.ModifiedBy AS ModifiedBy                              
    ,F_Src.ModifiedDate AS ModifiedDate                              
    ,F_Src.TypeId                              
    ,F_Src.AltFooter                              
    ,F_Src.FPFooter                              
    ,F_Src.UseSeparateFPFooter                              
    ,F_Src.HeaderFooterCategoryId                              
    ,F_Src.[DateFormat]                              
    ,F_Src.TimeFormat                              
    ,F_Src.HeaderFooterDisplayTypeId                              
    ,F_Src.DefaultFooter                              
    ,F_Src.FirstPageFooter                              
    ,F_Src.OddPageFooter                              
    ,F_Src.EvenPageFooter                        
    ,F_Src.DocumentTypeId                                   
 ,F_Src.IsShowLineAboveFooter                               
 ,F_Src.IsShowLineBelowFooter                                
 FROM Footer F_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON F_Src.SectionId = PS.A_SectionId                              
 WHERE F_Src.ProjectId = @SourceProjectId;                              
                              
--INSERT HeaderFooterGlobalTermUsage                                  
INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId                         
, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)                              
 SELECT                              
  HeaderId                              
    ,FooterId                              
    ,UserGlobalTermId                              
    ,@CustomerId AS CustomerId                              
    ,@TargetProjectId AS ProjectId                              
    ,HeaderFooterCategoryId                              
    ,CreatedDate                              
    ,CreatedById                              
 FROM HeaderFooterGlobalTermUsage WITH (NOLOCK)                              
 WHERE ProjectId = @SourceProjectId;                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyHeaderFooter_Description                              
     ,@CopyHeaderFooter_Description                              
     ,1 --IsCompleted                               
     ,@CopyHeaderFooter_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyHeaderFooter_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
UPDATE Psmry                              
SET Psmry.SpecViewModeId = Psmry_Src.SpecViewModeId                              
   ,Psmry.IsIncludeRsInSection = Psmry_Src.IsIncludeRsInSection                              
   ,Psmry.IsIncludeReInSection = Psmry_Src.IsIncludeReInSection                              
   ,Psmry.BudgetedCostId = Psmry_Src.BudgetedCostId                              
   ,Psmry.BudgetedCost = Psmry_Src.BudgetedCost                              
   ,Psmry.ActualCost = Psmry_Src.ActualCost                              
   ,Psmry.EstimatedArea = Psmry_Src.EstimatedArea                              
   ,Psmry.SourceTagFormat = Psmry_Src.SourceTagFormat                              
   ,Psmry.IsPrintReferenceEditionDate = Psmry_Src.IsPrintReferenceEditionDate                              
   ,Psmry.IsActivateRsCitation = Psmry_Src.IsActivateRsCitation                              
   ,Psmry.EstimatedSizeId = Psmry_Src.EstimatedSizeId                              
   ,Psmry.EstimatedSizeUoM = Psmry_Src.EstimatedSizeUoM                              
   ,Psmry.UnitOfMeasureValueTypeId = Psmry_Src.UnitOfMeasureValueTypeId                              
   ,Psmry.TrackChangesModeId = Psmry_Src.TrackChangesModeId                
   ,Psmry.IsHiddenAllBsdSections = Psmry_Src.IsHiddenAllBsdSections                        
   ,Psmry.IsLinkEngineEnabled=Psmry_Src.IsLinkEngineEnabled          
FROM ProjectSummary Psmry WITH (NOLOCK)                              
INNER JOIN ProjectSummary Psmry_Src WITH (NOLOCK)                              
 ON Psmry_Src.ProjectId = @SourceProjectId                              
WHERE Psmry.ProjectId = @TargetProjectId;                              
                              
--Insert LuProjectSectionIdSeparator                                  
INSERT INTO LuProjectSectionIdSeparator (ProjectId, CustomerId, UserId, separator)                              
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,UserId                              
    ,LPSIS_Src.separator                              
 FROM LuProjectSectionIdSeparator LPSIS_Src WITH (NOLOCK)                              
 WHERE ProjectId = @SourceProjectId;                              
                              
--Insert ProjectPageSetting                                  
INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId,SectionId,TypeId)                              
 SELECT                              
     PPS_Src.MarginTop                              
    ,PPS_Src.MarginBottom                              
    ,PPS_Src.MarginLeft     
 ,PPS_Src.MarginRight                              
    ,PPS_Src.EdgeHeader                              
    ,PPS_Src.EdgeFooter                              
    ,PPS_Src.IsMirrorMargin                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId          
 ,NULL As SectionId    
 ,PPS_Src.TypeId    
 FROM ProjectPageSetting PPS_Src WITH (NOLOCK)                              
 WHERE PPS_Src.ProjectId = @SourceProjectId    
 AND ISNULL(PPS_Src.SectionId, 0) = 0     
 UNION    
 SELECT                              
 PPS_Src.MarginTop                              
    ,PPS_Src.MarginBottom                              
    ,PPS_Src.MarginLeft     
 ,PPS_Src.MarginRight                              
    ,PPS_Src.EdgeHeader                              
    ,PPS_Src.EdgeFooter                              
    ,PPS_Src.IsMirrorMargin                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId          
 ,PS.SectionId    
 ,PPS_Src.TypeId    
 FROM ProjectPageSetting PPS_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PPS_Src.SectionId = PS.A_SectionId                              
 WHERE PPS_Src.ProjectId = @SourceProjectId;                           
                              
--Insert ProjectPaperSetting                                  
INSERT INTO ProjectPaperSetting (PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId,SectionId)                              
 SELECT                              
     PPS_Src.PaperName                              
    ,PPS_Src.PaperWidth                              
    ,PPS_Src.PaperHeight                              
    ,PPS_Src.PaperOrientation                              
    ,PPS_Src.PaperSource                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId          
 ,NULL SectionId                        
 FROM ProjectPaperSetting PPS_Src WITH (NOLOCK)                              
 WHERE ProjectId = @SourceProjectId    
 AND ISNULL(PPS_Src.SectionId, 0) = 0     
 UNION    
 SELECT                              
   PPS_Src.PaperName                              
    ,PPS_Src.PaperWidth                              
    ,PPS_Src.PaperHeight                              
    ,PPS_Src.PaperOrientation                              
    ,PPS_Src.PaperSource                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId          
 ,PS.SectionId                        
 FROM ProjectPaperSetting PPS_Src WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)                              
  ON PPS_Src.SectionId = PS.A_SectionId                              
 WHERE PPS_Src.ProjectId = @SourceProjectId;                              
                              
--Insert ProjectPrintSetting                                
INSERT INTO ProjectPrintSetting (ProjectId, CustomerId, CreatedBy, CreateDate, ModifiedBy,                              
ModifiedDate, IsExportInMultipleFiles, IsBeginSectionOnOddPage, IsIncludeAuthorInFileName, TCPrintModeId, IsIncludePageCount, IsIncludeHyperLink                                
,KeepWithNext, IsPrintMasterNote, IsPrintProjectNote, IsPrintNoteImage, IsPrintIHSLogo,IsIncludeOrphanParagraph,IsMarkPagesAsBlank,IsIncludeHeaderFooterOnBlackPages,BlankPagesText,IncludeSectionIdAfterEod,  IncludeEndOfSection,    
  IncludeDivisionNameandNumber,IsIncludePdfBookmark,IsIncludeAuthorForBookMark,IsContinuousPageNumber)                
 SELECT                              
  @TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,CreatedBy AS CreatedBy                              
    ,CreateDate AS CreateDate                              
    ,ModifiedBy AS ModifiedBy                              
    ,ModifiedDate AS ModifiedDate                              
    ,IsExportInMultipleFiles                              
    ,IsBeginSectionOnOddPage                              
    ,IsIncludeAuthorInFileName                              
    ,TCPrintModeId                              
    ,IsIncludePageCount                              
    ,IsIncludeHyperLink                                
 ,KeepWithNext                                
 ,IsPrintMasterNote                                  
 ,IsPrintProjectNote                                  
 ,IsPrintNoteImage                                  
 ,IsPrintIHSLogo                          
 ,IsIncludeOrphanParagraph                 
 ,IsMarkPagesAsBlank                        
,IsIncludeHeaderFooterOnBlackPages                        
 ,BlankPagesText                  
 ,IncludeSectionIdAfterEod    
  ,IncludeEndOfSection    
  ,IncludeDivisionNameandNumber       
  ,IsIncludePdfBookmark     
  ,IsIncludeAuthorForBookMark    
  ,IsContinuousPageNumber    
 FROM ProjectPrintSetting WITH (NOLOCK)                              
 WHERE ProjectId = @SourceProjectId                              
 AND CustomerId = @CustomerId;                
        
 --Insert SheetSpecsPageSettings        
 INSERT INTO SheetSpecsPageSettings(PaperSettingKey,ProjectId,CustomerId,Name,Value,CreatedDate,CreatedBy,ModifiedDate,ModifiedBy,IsActive,IsDeleted)        
 SELECT         
 PaperSettingKey,        
 @TargetProjectId AS ProjectId,        
 CustomerId,        
 Name,        
 Value,        
 CreatedDate,        
 CreatedBy,        
 ModifiedDate,        
 ModifiedBy,        
 IsActive,        
 IsDeleted         
 FROM SheetSpecsPageSettings        
 WHERE ProjectId = @SourceProjectId AND CustomerId = @CustomerId        
     
 --Insert SheetSpecsPrintSettings        
 INSERT INTO SheetSpecsPrintSettings (CustomerId,ProjectId,UserId,CreatedDate, CreatedBy, ModifiedDate, ModifiedBy,IsDeleted,SheetSpecsPrintPreviewLevel)                            
 select     
 @CustomerId as CustomerId,    
 @TargetProjectId AS ProjectId,     
 UserId,    
 CreatedDate ,    
 CreatedBy,    
 ModifiedDate,    
 ModifiedBy,    
 IsDeleted,    
 SheetSpecsPrintPreviewLevel    
 from SheetSpecsPrintSettings     
 WHERE ProjectId = @SourceProjectId AND CustomerId = @CustomerId       
            
--Insert ProjectPrintSetting              
INSERT INTO ProjectSetting (ProjectId, CustomerId, [Name], [Value], CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)       
SELECT            
 @TargetProjectId AS ProjectId,            
 @CustomerId as CustomerId,             
 [Name] AS [Name],            
 [Value] AS [Value],             
 CreatedDate AS CreatedDate,            
 CreatedBy AS CreatedBy,                       
 ModifiedDate AS ModifiedDate,            
 ModifiedBy AS ModifiedBy                
 FROM ProjectSetting WITH(NOLOCK)             
WHERE ProjectId = @SourceProjectId AND CustomerId = @CustomerId;           
                   
    
                            
INSERT INTO ProjectDateFormat (MasterDataTypeId, ProjectId, CustomerId, UserId,                              
ClockFormat, DateFormat, CreateDate)                              
 SELECT                              
  @MasterDataTypeId AS MasterDataTypeId                              
    ,@TargetProjectId AS ProjectId                              
    ,@CustomerId AS CustomerId                              
    ,UserId                              
    ,ClockFormat                              
    ,DateFormat                              
    ,CreateDate                              
 FROM ProjectDateFormat WITH (NOLOCK)                              
 WHERE ProjectId = @SourceProjectId;                 
                              
--Make project available to user                                  
UPDATE P                              
SET P.IsDeleted = 0                              
   ,P.IsPermanentDeleted = 0              
FROM Project P WITH (NOLOCK)                              
WHERE P.ProjectId = @TargetProjectId;                              
                              
--- INSERT ProjectHyperLink                              
SELECT                              
  PSS_Target.sectionId                              
    ,PSS_Target.SegmentId                              
    ,PSS_Target.SegmentStatusId                              
    ,PSS_Target.ProjectId                              
    ,PSS_Target.CustomerId                              
    ,LinkTarget                              
    ,LinkText                              
    ,LuHyperLinkSourceTypeId                              
    ,GETUTCDATE() as CreateDate                              
  ,@UserId AS CreatedBy                              
    ,PHL.HyperLinkId                              
 ,ROW_NUMBER() OVER (ORDER BY PSS_Target.SegmentStatusId) AS SrNo                              
 INTO #HL FROM ProjectHyperLink PHL WITH (NOLOCK)                              
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target                              
  ON PHL.SegmentStatusId = PSS_Target.A_SegmentStatusId                              
 WHERE PHL.ProjectId = @PSourceProjectId                              
                              
 SET @TableRows = @@ROWCOUNT          
 SET @Records = 1          
 SET @Start = 1          
 SET @End = @Start + @ProjectHyperLink - 1                              
                               
WHILE @Records <= @TableRows                             
BEGIN                              
 INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,                              
 CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy                              
 , A_HyperLinkId)                              
 SELECT SectionId, SegmentId, SegmentStatusId, ProjectId,                              
 CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy                              
 , HyperLinkId                              
 FROM #HL                              
 WHERE SrNo  BETWEEN @Start AND @End                              
 --WAITFOR DELAY @Delayfor;      
 SET @Records += @ProjectHyperLink;          
 SET @Start = @End + 1 ;          
 SET @End = @Start + @ProjectHyperLink - 1;                         
END                              
---UPDATE NEW HyperLinkId in SegmentDescription                              
DECLARE @MultipleHyperlinkCount INT = 0;                              
SELECT                              
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl                      
FROM ProjectHyperLink WITH (NOLOCK)                              
WHERE ProjectId = @TargetProjectId                              
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
WHERE PHL.ProjectId = @TargetProjectId                              
AND  PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%'                              
AND PS.SegmentDescription LIKE '%{HL#%'                              
SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;                              
END                              
                       
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyProjectHyperLink_Description                              
     ,@CopyProjectHyperLink_Description                              
     ,1 --IsCompleted                                  
     ,@CopyProjectHyperLink_Step  --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,3 --Status                                  
   ,@CopyProjectHyperLink_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                            
--- For Copy from Project Track Status Changes                        
                        
 DECLARE @tempTrackChanges TABLE ( SegmentStatusID BIGINT,SegmentStatusTypeId INT,PrevStatusSegmentStatusTypeId INT                        
 ,InitialStatusSegmentStatusTypeId INT,IsAccepted BIT,UserId INT ,UserFullName NVARCHAR(100),CreatedDate Date,ModifiedById INT,ModifiedByUserFullName NVARCHAR(100)                        
,ModifiedDate Date,TenantId INT,InitialStatus NVARCHAR(50),IsSegmentStatusChangeBySelection NVARCHAR(50),CurrentStatus BIT,SectionId INT)                        
                         
 INSERT INTO @tempTrackChanges                        
 SELECT                        
 TSST.SegmentStatusId                         
,TSST.SegmentStatusTypeId                         
,TSST.PrevStatusSegmentStatusTypeId                         
,TSST.InitialStatusSegmentStatusTypeId                         
,TSST.IsAccepted                         
,TSST.UserId                         
,TSST.UserFullName                         
,TSST.CreatedDate                         
,TSST.ModifiedById                         
,TSST.ModifiedByUserFullName                         
,TSST.ModifiedDate                         
,TSST.TenantId                         
,TSST.InitialStatus                         
,TSST.IsSegmentStatusChangeBySelection                         
,TSST.CurrentStatus                        
,TSST.SectionId                      
FROM TrackSegmentStatusType TSST WITH (NOLOCK)                         
  INNER JOIN #tmp_TgtSection s                          
ON TSST.SectionId=s.A_SectionId                       
                      
WHERE TSST.ProjectId=@SourceProjectId                       
AND TSST.CustomerId=@CustomerId                        
AND ISNULL (TSST.IsAccepted,0)=0                      
                             
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
@TargetProjectId                      
,tss.SectionId-- TargetSectionId,                      
,@CustomerId                      
,tss.SegmentStatusId                         
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
,ttc.CurrentStatus FROM @tempTrackChanges ttc INNER JOIN #tmp_TgtSegmentStatus tss WITH (NOLOCK)                         
ON tss.A_SegmentStatusId=ttc.SegmentStatusId                    
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
    tss.SectionId,                      
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
                      
      EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyTrackSegmentStatus_Description                              
     ,@CopyTrackSegmentStatus_Description                              
     ,1 --IsCompleted                                  
     ,@CopyTrackSegmentStatus_Step  --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyTrackSegmentStatus_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;  
     
  
   --INSERT DocLibraryMapping                                  
INSERT INTO DocLibraryMapping  
    (CustomerId, ProjectId, SectionId, SegmentId, DocLibraryId, SortOrder  
    ,IsActive, IsAttachedToFolder, IsDeleted, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, AttachedByFullName)  
SELECT @CustomerId AS CustomerId  
    ,@TargetProjectId AS ProjectId  
    ,PS.SectionId  
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
INNER JOIN #tmp_TgtSection PS WITH (NOLOCK) ON DLM.SectionId = PS.A_SectionId  
WHERE DLM.CustomerId = @CustomerId AND DLM.ProjectId = @SourceProjectId;  
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyDocLibraryMapping_Description                              
     ,@CopyDocLibraryMapping_Description                      
     ,1 --IsCompleted                               
     ,@CopyDocLibraryMapping_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,2 --Status                                  
   ,@CopyDocLibraryMapping_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;  
  
                      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyComplete_Description                              
     ,@CopyComplete_Description                              
     ,1 --IsCompleted                                  
     ,@CopyComplete_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,3 --Status                                  
   ,@CopyComplete_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                 
END TRY                              
BEGIN CATCH                              
                              
DECLARE @ResultMessage NVARCHAR(MAX);                         
SET @ResultMessage = 'Rollback Transaction. Error Number: ' + CONVERT(VARCHAR(MAX), ERROR_NUMBER()) +                              
'. Error Message: ' + CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) +                              
'. Procedure Name: ' + CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) +                              
'. Error Severity: ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +                              
'. Line Number: ' + CONVERT(VARCHAR(5), ERROR_LINE());                              
                          
--Make unavailable this project from user                                  
UPDATE P         
SET P.IsDeleted = 1                              
   ,P.IsPermanentDeleted = 1                              
FROM Project P WITH (NOLOCK)                              
WHERE P.ProjectId = @TargetProjectId;                              
                              
                              
EXEC usp_MaintainCopyProjectHistory @TargetProjectId                              
     ,@CopyFailed_Description                              
     ,@ResultMessage                              
     ,1 --IsCompleted                                  
     ,@CopyFailed_Step --Step                                  
     ,@RequestId                              
                              
EXEC usp_MaintainCopyProjectProgress @SourceProjectId                              
   ,@TargetProjectId                              
   ,@UserId                              
   ,@CustomerId                              
   ,4 --Status                                  
   ,@CopyFailed_Percentage --Percent                                  
   ,0 --IsInsertRecord                                  
   ,@CustomerName                              
   ,@UserName;                              
                              
--Insert add user into the Project Team Member list                               
DECLARE @IsOfficeMaster bit=0;                              
SELECT TOP 1 @IsOfficeMaster=IsOfficeMaster FROM Project WHERE ProjectId=@TargetProjectId                              
EXEC usp_ApplyProjectDefaultSetting @IsOfficeMaster,@TargetProjectId,@PUserId,@CustomerId         
      
      
                              
EXEC usp_SendEmailCopyProjectFailedJob                              
END CATCH                              
END   