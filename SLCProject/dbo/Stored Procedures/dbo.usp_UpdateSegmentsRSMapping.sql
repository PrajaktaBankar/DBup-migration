CREATE PROCEDURE [dbo].[usp_UpdateSegmentsRSMapping]            
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
  WHERE ProjectId=@PProjectId AND SectionId = @PSectionId AND SegmentId = @PSegmentId
 AND RefStdCode > @MinUserRefStdCode            
 );         
              
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


