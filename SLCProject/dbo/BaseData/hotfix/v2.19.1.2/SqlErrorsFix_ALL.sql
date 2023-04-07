--SQL
--1. 547
--2. 515
--3. 8152
--4. 13609

--frond end la micro node jsss

--547 - Constraint conflict
--	System.Data.SqlClient.SqlException (0x80131904): The INSERT statement conflicted with 
--	the FOREIGN KEY constraint "FK__ProjectLe__Privi__06F9CA0F". The conflict occurred 
--	in database "SLCProject", table "dbo.LuTrackChangesMode", column 'TcModeId'.

--4. 515 - Cannot insert NULL
--	1. usp_UpdateSegmentsGTAndRSMapping
--	1. System.Data.SqlClient.SqlException (0x80131904): Cannot insert the value NULL 
--	into column 'RefStdEditionId', table 'SLCProject.dbo.ProjectReferenceStandard'; 
--	column does not allow nulls. INSERT fails.

--9. 8152 - String or binary data would be truncated
--	1. usp_MoveSubFolderInParentFolder
--	System.Data.SqlClient.SqlException (0x80131904): String or binary data would be truncated.
--	The statement has been terminated.
--	-- Issue fixed - whenever user trying to move subfolder and @SourceTag IS NULL OR @SourceTag = '' then will get 8152 - String or binary data would be truncated error.

--8. 13609 - JSON text is not properly formatted
--	1. usp_GetSectionReferencesCount	
--		DECLARE @OptionJson NVARCHAR(MAX)='';
--		SELECT CASE WHEN @OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(@OptionJson, '[', ''), ']', ''), '$.OptionTypeName') end  AS OptionTypeName 

ALTER PROCEDURE [dbo].[usp_GetSectionReferencesCount]
@ProjectId INT NULL=NULL,  
@CustomerId INT NULL, 
@SectionId INT NULL
 
AS    
BEGIN
  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSectionId INT = @SectionId;

SELECT
	SegmentChoiceId
   ,ChoiceOptionId
   ,SectionId
   --,JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.OptionTypeName') AS OptionTypeName  
   --,JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Id') AS ReferSectionId  
   --,JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Value') AS SectionName INTO #Temp  
   ,CASE WHEN ISJSON(OptionJson) !=0 AND OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.OptionTypeName') end  AS OptionTypeName  
   ,CASE WHEN ISJSON(OptionJson) !=0 AND OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Id') end AS ReferSectionId  
   ,CASE WHEN ISJSON(OptionJson) !=0 AND OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Value') end AS SectionName INTO #Temp  
FROM ProjectChoiceOption WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId


SELECT
	COUNT(1) AS SectionCount
FROM (SELECT DISTINCT
		T.SectionId
	FROM #Temp T
	JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
		ON T.SegmentChoiceId = PSC.SegmentChoiceId
	INNER JOIN ProjectSection ps WITH (NOLOCK)
		ON T.SectionId = ps.SectionID
	INNER JOIN SLCMaster..Section MS WITH (NOLOCK)
		ON ps.mSectionId = MS.SectionID
	WHERE PSC.IsDeleted = 0
	AND T.OptionTypeName LIKE '%SectionId%'
	AND T.ReferSectionId = @PSectionId
	AND T.ReferSectionId != PSC.SectionId
	AND MS.Isdeleted = 0) AS dt;

END

GO

ALTER PROCEDURE usp_MoveSubFolderInParentFolder            
(             
@ProjectId INT,            
@CustomerId INT,                   
@UserId INT  ,          
@SubFolderSectionId INT,                                              
@ParentSectionId INT,            
@Description NVARCHAR(1000),           
@IsAddOnTop INT,                                            
@SourceTag NVARCHAR(18) = NULL ,      
@IsNonNumberedParent   BIT       
)            
AS                                              
BEGIN                 
              
DECLARE @SortOrder INT;                                                            
DECLARE @ResponseId INT = 0;                                                         
--DECLARE @AddSubDivisionSettingValue NVARCHAR(50) = NULL;                
DECLARE @DivisionId INT = NULL ;              
DECLARE @DivisionCode NVARCHAR(500) = NULL;         
DECLARE @MasterDataTypeId INT = (SELECT TOP 1 MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);           
              
IF (@SourceTag IS NOT NULL AND @SourceTag <> '')                    
BEGIN                    
 IF(EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId                        
                AND ISNULL(IsDeleted,0) = 0 AND TRIM(UPPER(SourceTag)) = TRIM(UPPER(@SourceTag))))                          
    SET @ResponseId = -1;                        
END                        
ELSE IF EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId                        
        AND ISNULL(IsDeleted,0) = 0 AND TRIM(UPPER([Description])) = TRIM(UPPER(@Description)) AND (SourceTag IS NULL OR SourceTag = ''))                        
BEGIN                        
    SET @ResponseId = -2;                        
END               
              
IF(@ResponseId = 0)                                                            
BEGIN                                            
 IF(@IsAddOnTop = 1)                                            
 BEGIN                                            
  SET @SortOrder = (SELECT ISNULL(MIN(SortOrder)-1,1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId               
                    AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0);                                            
  --SET @AddSubDivisionSettingValue = 'Top';                                            
 END                                            
 ELSE IF(@IsAddOnTop = 0)                                            
 BEGIN                                            
  SET @SortOrder = (SELECT ISNULL(MAX(SortOrder)+1,1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId               
                    AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0);                                            
  --SET @AddSubDivisionSettingValue = 'Bottom';                                            
 END                                            
 ELSE IF(@IsAddOnTop = -1)                                            
 BEGIN                                            
  DROP TABLE IF EXISTS #subDivisions;                                                          
  CREATE TABLE #subDivisions(                                                        
   [Description] NVARCHAR(MAX),                                                        
   [T_Description] NVARCHAR(MAX),                                                        
   [SourceTag] VARCHAR(18) NULL,                                                        
   [T_SourceTag] VARCHAR(400) NULL,                                                        
   [SortOrder] INT                                                        
  );                   
                
                                               
  IF(@SourceTag IS NULL OR @SourceTag = '')                                            
   INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder) VALUES (@Description, '', @SourceTag, '', -1);                       
  ELSE                                            
   INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder) VALUES (@Description, '', @SourceTag, '', -1);                                                                                
  INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder)                                      
(SELECT [Description], '', SourceTag, '', SortOrder FROM ProjectSection WITH(NOLOCK)                               
   WHERE ProjectId = @ProjectId               
   AND ParentSectionId = @ParentSectionId               
   AND ISNULL(IsDeleted,0) = 0      AND SourceTag IS NOT NULL AND LEN(SourceTag) > 0);                 
                 
  UPDATE SD SET T_SourceTag = UPPER(dbo.udf_ExpandDigits(SD.SourceTag, 18, '0'))              
              --,T_Description = UPPER(dbo.udf_ExpandDigits(SD.Description, 20, '0'))              
   FROM #subDivisions SD;                
                                        
                                          
  DROP TABLE IF EXISTS #sortedSubDivisions;                                                          
  SELECT ROW_NUMBER() OVER( ORDER BY T_SourceTag) AS RowId, [Description], [T_Description], SourceTag, [T_SourceTag], SortOrder INTO #sortedSubDivisions from #subDivisions order by T_SourceTag;                                            
                                              
  DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM #sortedSubDivisions);                                                          
  DECLARE @NewSubDivRowId INT = (SELECT TOP 1 RowId FROM #sortedSubDivisions WHERE [Description] = @Description AND [SourceTag] = @SourceTag);                                            
                                              
  IF(@MaxRowId = 1)                                            
   SET @SortOrder = 1;                                            
  ELSE IF(@MaxRowId = @NewSubDivRowId)                                                          
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #sortedSubDivisions);                                                          
  ELSE                                                           
   SET @SortOrder = (SELECT SortOrder FROM #sortedSubDivisions WHERE RowId = (@NewSubDivRowId + 1)); -- Update the Sort order of other SubDiv                  
                 
    UPDATE PS SET SortOrder = SortOrder + 1               
 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId               
 AND ParentSectionId = @ParentSectionId               
 AND ISNULL(ISDeleted,0) = 0               
 AND SortOrder >= @SortOrder;                                                             
 END -- END IF(@IsAddOnTop = -1)                      
          
   IF EXISTS(SELECT TOP 1 SectionCode FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @ParentSectionId AND ProjectId = @ProjectId AND ISNULL(mSectionId,0) >0)           
   BEGIN                                            
 SELECT @DivisionId = MD.DivisionId,@DivisionCode = MD.DivisionCode FROM SLCMaster..Division MD WITH (NOLOCK) INNER JOIN ProjectSection PS WITH (NOLOCK)       
 ON MD.DivisionCode = PS.SourceTag Where PS.SectionId = @ParentSectionId AND PS.ProjectId = @ProjectId AND MD.MasterDataTypeId = @MasterDataTypeId;              
   END      
   ELSE      
 SELECT @DivisionId = CD.DivisionId,@DivisionCode = CD.DivisionCode FROM CustomerDivision CD WITH (NOLOCK) INNER JOIN ProjectSection PS WITH (NOLOCK)       
 ON CD.DivisionId = PS.DivisionId Where PS.SectionId = @ParentSectionId AND PS.ProjectId = @ProjectId;           
              
 IF(@IsNonNumberedParent!=1)          
   BEGIN          
     UPDATE PS SET PS.SortOrder = @SortOrder,               
          PS.ParentSectionId = @ParentSectionId,              
          PS.DivisionId = @DivisionId,              
          PS.DivisionCode = @DivisionCode              
        FROM ProjectSection PS WITH(NOLOCK)               
        WHERE PS.SectionId = @SubFolderSectionId AND PS.ProjectId = @ProjectId AND PS.CustomerId = @CustomerId            
   END          
    ELSE          
   BEGIN          
    UPDATE PS SET PS.SortOrder = @SortOrder,               
          PS.ParentSectionId = @ParentSectionId,             
    PS.SourceTag=NULL,           
          PS.DivisionId = @DivisionId,              
          PS.DivisionCode = @DivisionCode              
        FROM ProjectSection PS WITH(NOLOCK)               
        WHERE PS.SectionId = @SubFolderSectionId AND PS.ProjectId = @ProjectId AND PS.CustomerId = @CustomerId            
               
   END           
          
  -- Added for Bug 64342: Moved folder is not displaying as per tree order for Reporting and TOC output        
  UPDATE PS        
  SET PS.DivisionId = @DivisionId        
  ,PS.DivisionCode = @DivisionCode        
  FROM ProjectSection PS WITH (NOLOCK)        
  WHERE PS.ParentSectionId = @SubFolderSectionId        
  AND PS.ProjectId = @ProjectId        
  AND PS.CustomerId = @CustomerId          
              
              
END -- END IF(@SectionId = 0)               
SELECT @ResponseId as ResponseId;                
END  

GO

ALTER PROCEDURE [dbo].[usp_UpdateSegmentsRSMapping]            
(            
 @SegmentStatusId BIGINT NULL = 0,            
 @IsDeleted INT NULL = 0,            
 @ProjectId INT = NULL,            
 @SectionId INT = NULL,            
 @CustomerId INT = NULL,            
 @UserId INT = NULL,            
 @SegmentId BIGINT = NULL,            
 @MSegmentId INT = NULL,            
 @SegmentDescription NVARCHAR(MAX) = NULL            
)            
AS            
BEGIN              
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;              
 DECLARE @PIsDeleted INT = @IsDeleted;              
 DECLARE @PProjectId INT = @ProjectId;              
 DECLARE @PSectionId INT = @SectionId;              
 DECLARE @PCustomerId INT = @CustomerId;              
 DECLARE @PUserId INT = @UserId;              
 DECLARE @PSegmentId BIGINT = @SegmentId;              
 DECLARE @PMSegmentId INT = @MSegmentId;              
 DECLARE @PSegmentDescription NVARCHAR(MAX) = @SegmentDescription;              
              
SET NOCOUNT ON;              
                         
              
 DECLARE @SegmentRS TABLE(RSCode INT NULL);              
 CREATE TABLE #UserSegmentRS (              
     CustomerId INT NULL,              
  ProjectId INT NULL,              
  SectionId INT NULL,              
  SegmentId BIGINT NULL,              
  mSegmentId INT NULL,              
  RefStandardId INT NULL,              
  RefStandardSource CHAR(1) NULL,              
  RefStdCode INT NULL,                 
  mRefStandardId INT NULL,              
  CreatedDate DATETIME NULL,              
  CreatedBy INT NULL,               
  ModifiedDate DATETIME NULL,              
  ModifiedBy INT NULL              
 );              
              
 IF @PIsDeleted = 1 AND @PSegmentStatusId > 0 -- Only proceed if SegmentStatusId is not zero              
 BEGIN              
SET @PSegmentDescription = '';              
--SELECT              
-- @PProjectId = ProjectId              
--   ,@PSectionId = SectionId              
--   ,@PCustomerId = CustomerId              
--   ,@PUserId = 0              
--   ,@PSegmentId = SegmentId              
--   ,@PMSegmentId = MSegmentId              
--FROM ProjectSegmentStatus WITH (NOLOCK)              
--WHERE SegmentStatusId = @PSegmentStatusId              
END              
 BEGIN TRY              
  INSERT INTO @SegmentRS              
  SELECT              
   *              
  FROM (SELECT              
    [value] AS RSCode              
   FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@PSegmentDescription, '{RS#'), ',')              
   UNION ALL              
   SELECT              
    *              
   FROM dbo.[udf_GetRSUsedInChoice](@PSegmentDescription, @PProjectId, @PSectionId)) AS SegmentRSTbl              
 END TRY              
 BEGIN CATCH              
  insert into BsdLogging..AutoSaveLogging              
  values('usp_UpdateSegmentsRSMapping',              
  getdate(),              
  ERROR_MESSAGE(),              
  ERROR_NUMBER(),              
  ERROR_Severity(),              
  ERROR_LINE(),              
  ERROR_STATE(),              
  ERROR_PROCEDURE(),              
  concat('SELECT * FROM dbo.[udf_GetRSUsedInChoice](',@PSegmentDescription,',',@PProjectId,',',@PSectionId,')'),              
  @PSegmentDescription              
 )              
 END CATCH              
--Use below variable to find ref std's which are USER CREATED by checking RefStdCode column              
DECLARE @MinUserRefStdCode INT = 10000000;              
              
--Calculate count of user ref std's which came from UI segment description              
DECLARE @RefStdCount_UI INT = (SELECT              
  COUNT(1)              
 FROM @SegmentRS              
 WHERE RSCode > @MinUserRefStdCode);              
              
--Calculate count of user ref std's which are in mapping table for that segment in DB              
DECLARE @RefStdCount_MPTBL INT = (SELECT              
  COUNT(1)              
 FROM ProjectSegmentReferenceStandard WITH (NOLOCK)              
 WHERE ProjectId=@PProjectId              
 AND RefStdCode > @MinUserRefStdCode              
 AND SegmentId = @PSegmentId);              
              
--Call below logic if data is available in either UI segment's description or in mapping table              
IF (@RefStdCount_UI > 0              
 OR @RefStdCount_MPTBL > 0)              
BEGIN              
INSERT INTO #UserSegmentRS              
 SELECT              
  @PCustomerId AS CustomerId        
    ,@PProjectId AS ProjectId              
    ,@PSectionId AS SectionId              
    ,@PSegmentId AS SegmentId              
    ,@PMSegmentId AS mSegmentId              
    ,RS.RefStdId AS RefStandardId              
    ,RS.RefStdSource AS RefStandardSource              
    ,RS.RefStdCode AS RefStdCode              
    ,0 AS mRefStandardId              
    ,GETUTCDATE() AS CreatedDate              
    ,@PUserId AS CreatedBy              
    ,NULL AS ModifiedDate              
    ,NULL AS ModifiedBy                    
 FROM @SegmentRS SRS              
 LEFT JOIN ReferenceStandard RS WITH (NOLOCK)              
  ON RS.RefStdCode = SRS.RSCode              
  and RS.CustomerId  = @PCustomerId              
 WHERE RS.CustomerId = @PCustomerId     AND RS.RefStdSource = 'U'              
 AND ISNULL(RS.IsDeleted,0) = 0              
 UNION              
 SELECT              
  @PCustomerId AS CustomerId              
    ,@PProjectId AS ProjectId              
    ,@PSectionId AS SectionId              
    ,@PSegmentId AS SegmentId              
    ,@PMSegmentId AS mSegmentId              
    ,0 AS RefStandardId              
    ,'M' AS RefStandardSource              
    ,MRS.RefStdCode AS RefStdCode              
    ,MRS.RefStdId AS mRefStandardId              
    ,GETUTCDATE() AS CreatedDate              
    ,@PUserId AS CreatedBy              
    ,NULL AS ModifiedDate              
    ,NULL AS ModifiedBy              
 FROM @SegmentRS SRS              
 INNER JOIN SLCMaster..ReferenceStandard MRS WITH (NOLOCK)              
  ON MRS.RefStdCode = SRS.RSCode              
   AND MRS.RefStdCode IS NOT NULL              
              
--Delete Unsed RS for Segment              
              
UPDATE PSRS              
SET PSRS.IsDeleted = 1              
FROM ProjectSegmentReferenceStandard PSRS  WITH (NOLOCK)              
LEFT JOIN #UserSegmentRS URS WITH (NOLOCK)              
 ON PSRS.RefStdCode = URS.RefStdCode              
 AND PSRS.ProjectId = URS.ProjectId              
WHERE PSRS.ProjectId = @PProjectId              
AND PSRS.SectionId = @PSectionId              
AND (PSRS.SegmentId = @PSegmentId              
OR PSRS.mSegmentId = @PMSegmentId              
OR PSRS.SegmentId = 0)              
AND ISNULL(PSRS.IsDeleted,0) = 0              
              
IF @PIsDeleted = 0--Only proceed if IsDeleted is zero              
BEGIN              
--Insert Used Reference Standard for Segment              
INSERT INTO ProjectSegmentReferenceStandard (SectionId,              
SegmentId,              
RefStandardId,              
RefStandardSource,              
mRefStandardId,              
CreateDate,              
CreatedBy,              
ModifiedDate,              
ModifiedBy,              
CustomerId,              
ProjectId,              
mSegmentId,              
RefStdCode)              
 SELECT DISTINCT              
  URS.SectionId              
    ,URS.SegmentId              
    ,URS.RefStandardId              
    ,URS.RefStandardSource              
    ,URS.mRefStandardId              
    ,GETUTCDATE() AS CreatedDate              
    ,URS.CreatedBy              
    ,GETUTCDATE() AS ModifiedDate              
    ,URS.ModifiedBy              
    ,URS.CustomerId              
    ,URS.ProjectId              
    ,URS.mSegmentId              
    ,URS.RefStdCode              
 FROM #UserSegmentRS URS with (nolock)              
 WHERE URS.SectionId = @PSectionId              
 AND URS.ProjectId = @PProjectId              
              
SELECT DISTINCT MAX(RefStdEditionId) AS RefStdEditionId,              
 RefStdId INTO #TM FROM SLCMaster.dbo.ReferenceStandardEdition WITH (NOLOCK)              
 GROUP BY RefStdId              
              
 SELECT DISTINCT MAX(RefStdEditionId) AS RefStdEditionId,              
 RefStdId INTO #TP FROM ReferenceStandardEdition WITH (NOLOCK)              
 GROUP BY RefStdId              
              
              
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)              
 SELECT DISTINCT              
  FinalPRS.*              
 FROM (SELECT              
   PSRS.ProjectId              
     ,PSRS.mRefStandardId AS RefStandardId              
     ,PSRS.RefStandardSource AS RefStdSource              
     ,ISNULL(MREFSTD.ReplaceRefStdId, 0) AS mReplaceRefStdId              
     ,(CASE              
    WHEN PRS.ProjRefStdId IS NOT NULL THEN ISNULL(PRS.RefStdEditionId,0)
    ELSE ISNULL(M.RefStdEditionId,0)
   END) AS RefStdEditionId              
     ,CAST(0 AS BIT) AS IsObsolete              
     ,PSRS.RefStdCode              
     ,GETUTCDATE() AS PublicationDate              
     ,PSRS.SectionId              
     ,PSRS.CustomerId              
  FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)              
  INNER JOIN SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)              
   ON PSRS.mRefStandardId = MREFSTD.RefStdId              
  LEFT JOIN ProjectReferenceStandard PRS  WITH (NOLOCK)              
   ON PSRS.ProjectId = PRS.ProjectId              
   AND PSRS.CustomerId = PRS.CustomerId              
   --AND PSRS.SectionId = PRS.SectionId              
   AND PSRS.mRefStandardId = PRS.RefStandardId              
   AND PRS.RefStdSource = 'U'              
   AND PRS.IsDeleted = 0              
              
  LEFT JOIN #TM T              
   ON T.RefStdId = PSRS.mRefStandardId              
  LEFT JOIN SLCMaster.dbo.ReferenceStandardEdition M WITH (NOLOCK)              
   ON T.RefStdId=M.RefStdId AND T.RefStdEditionId=M.RefStdEditionId              
              
  --CROSS APPLY (SELECT              
  -- TOP 1              
  --  RSE.RefStdEditionId              
  -- FROM SLCMaster..ReferenceStandardEdition RSE WITH (NOLOCK)              
  -- WHERE RSE.RefStdId = PSRS.mRefStandardId              
  -- ORDER BY RSE.RefStdEditionId DESC) AS MREFEDN              
              
  WHERE              
  PSRS.SectionId = @PSectionId              
  AND PSRS.ProjectId =  @PProjectId              
  AND PSRS.RefStandardSource = 'U'              
  AND PSRS.CustomerId = @PCustomerId              
  AND PSRS.IsDeleted = 0              
  UNION              
  SELECT              
   PSRS.ProjectId              
     ,PSRS.RefStandardId              
     ,PSRS.RefStandardSource AS RefStdSource              
     ,0 AS mReplaceRefStdId              
     ,(CASE              
    WHEN PRS.ProjRefStdId IS NOT NULL THEN ISNULL(PRS.RefStdEditionId ,0)             
    ELSE ISNULL(U.RefStdEditionId,0)             
   END) AS RefStdEditionId              
     ,CAST(0 AS BIT) AS IsObsolete              
     ,PSRS.RefStdCode              
     ,GETUTCDATE() AS PublicationDate              
     ,PSRS.SectionId              
     ,PSRS.CustomerId              
  FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)              
              
  INNER JOIN ReferenceStandard UREFSTD WITH (NOLOCK)              
   ON PSRS.RefStandardId = UREFSTD.RefStdId              
              
  LEFT JOIN ProjectReferenceStandard PRS WITH (NOLOCK)              
   ON PSRS.ProjectId = PRS.ProjectId              
   AND PSRS.CustomerId = PRS.CustomerId              
   AND PRS.IsDeleted = 0              
   --AND PSRS.SectionId = PRS.SectionId              
   AND PSRS.RefStandardId = PRS.RefStandardId              
   AND PRS.RefStdSource = 'U'              
              
  LEFT JOIN #TP T               
  ON T.RefStdId= PSRS.RefStandardId              
  LEFT JOIN ReferenceStandardEdition U WITH (NOLOCK)              
  ON T.RefStdId= U.RefStdId AND T.RefStdEditionId=U.RefStdEditionId              
  WHERE PSRS.SectionId = @PSectionId              
  AND PSRS.ProjectId =  @PProjectId              
  AND PSRS.RefStandardSource = 'U'              
  AND PSRS.CustomerId = @PCustomerId              
  AND PSRS.IsDeleted = 0) AS FinalPRS              
              
 LEFT JOIN ProjectReferenceStandard TEMPPRS WITH (NOLOCK)              
  ON FinalPRS.ProjectId = TEMPPRS.ProjectId              
   AND FinalPRS.RefStandardId = TEMPPRS.RefStandardId              
   AND FinalPRS.RefStdSource = TEMPPRS.RefStdSource              
   AND FinalPRS.RefStdEditionId = TEMPPRS.RefStdEditionId          
   AND FinalPRS.RefStdCode = TEMPPRS.RefStdCode              
   AND FinalPRS.SectionId = TEMPPRS.SectionId              
   AND FinalPRS.CustomerId = TEMPPRS.CustomerId              
   AND TEMPPRS.IsDeleted = 0              
              
 WHERE TEMPPRS.ProjRefStdId IS NULL              
END              
            
--UPDATE PRS              
--SET PRS.IsDeleted = 1              
-- FROM ProjectReferenceStandard PRS  WITH (NOLOCK)              
-- LEFT JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)              
--  ON PSRS.SectionId = PRS.SectionId              
--  AND PSRS.ProjectId = PRS.ProjectId              
-- AND PSRS.RefStdCode = PRS.RefStdCode              
--WHERE PRS.SectionId = @PSectionId              
-- AND PRS.CustomerId = @PCustomerId              
-- AND PRS.ProjectId = @PProjectId              
-- AND PSRS.RefStdCode IS NULL              
            
DROP TABLE if EXISTS #PSRSData            
SELECT             
PRS.ProjectId            
,PRS.RefStandardId            
,PRS.RefStdSource            
,PRS.mReplaceRefStdId            
,PRS.RefStdEditionId            
,PRS.IsObsolete            
,PRS.RefStdCode            
,PRS.PublicationDate            
,PRS.SectionId            
,PRS.CustomerId            
,PRS.ProjRefStdId            
,PRS.IsDeleted,PSRS.IsDeleted AS SegIsDeleted            
INTO #PSRSData            
FROM ProjectReferenceStandard PRS WITH (NOLOCK)              
left JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)              
ON PSRS.SectionId = PRS.SectionId              
AND PSRS.RefStdCode = PRS.RefStdCode             
WHERE PRS.SectionId = @PSectionId              
AND PRS.ProjectId = @PProjectId              
AND PRS.CustomerId = @PCustomerId                
AND ISNULL(PRS.IsDeleted,0)=0              
            
IF NOT EXISTS(select 1,1 from #PSRSData WHERE SegIsDeleted=0)            
BEGIN            
 UPDATE PRS set PRS.IsDeleted=1            
 FROM ProjectReferenceStandard PRS  WITH (NOLOCK)  INNER JOIN #PSRSData D ON D.SectionId = PRS.SectionId              
 AND D.RefStdCode = PRS.RefStdCode             
END            
            
            
END              
END  

GO

ALTER PROCEDURE [dbo].[usp_ProjectLevelTrackChangesLogging](
@UserId INT NULL,  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@UserEmail  NVARCHAR(100) ='NA',  
@PriviousTrackChangeModeId INT NULL ,
@CurrentTrackChangeModeId INT NULL 
)
AS 
BEGIN
DECLARE @PPriviousTrackChangeModeId INT = CASE WHEN ISNULL(@PriviousTrackChangeModeId,0) = 0 OR @PriviousTrackChangeModeId = 0 THEN 3 ELSE @PriviousTrackChangeModeId END;
DECLARE @P@CurrentTrackChangeModeId INT = CASE WHEN ISNULL(@CurrentTrackChangeModeId,0) = 0 OR @CurrentTrackChangeModeId = 0 THEN 3 ELSE @CurrentTrackChangeModeId END;

INSERT INTO ProjectLevelTrackChangesLogging ( UserId  
, ProjectId  
, CustomerId  
, UserEmail  
, PriviousTrackChangeModeId  
, CurrentTrackChangeModeId  
, CreatedDate  
)  
 VALUES ( @UserId,@ProjectId, @CustomerId, @UserEmail,@PPriviousTrackChangeModeId,@P@CurrentTrackChangeModeId,GETUTCDATE() )  
END  

