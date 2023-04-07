CREATE PROCEDURE [dbo].[usp_GetSegmentLinkDetailsForJob] (@InpSegmentLinkJson NVARCHAR(MAX))    
AS    
BEGIN
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--BEGIN TRANSACTION

--TODO--Fetch Src links of TgtOfTgtLinks
--SET NO COUNT ON    
SET NOCOUNT ON;
  
 --DECLARE TYPES OF LINKS    
 DECLARE @P2P INT = 1;
 DECLARE @P2C INT = 2;
 DECLARE @C2P INT = 3;
 DECLARE @C2C INT = 4;
  
 --DECLARE TAGS VARIABLES  
 DECLARE @RS_TAG INT = 22;
 DECLARE @RT_TAG INT = 23;
 DECLARE @RE_TAG INT = 24;
 DECLARE @ST_TAG INT = 25;
  
 --DECLARE LOOPED VARIABLES    
 DECLARE @LoopedSectionId INT = 0;
 DECLARE @LoopedSegmentStatusCode BIGINT = 0;
 DECLARE @LoopedSegmentSource CHAR(1) = '';
  
 --DECALRE COMMON VARIABLES FROM INP JSON  
 DECLARE @ProjectId INT = 0;
 DECLARE @CustomerId INT = 0;
 DECLARE @UserId INT = 0;
  
 --DECLARE FIELD WHICH SHOWS RECORD TYPE  
 DECLARE @SourceOfRecord_Master NVARCHAR(MAX) = 'M';
 DECLARE @SourceOfRecord_Project NVARCHAR(MAX) = 'U';
  
 --DECLARE VARIABLES OF SEGMENT LINK SOURCE TYPES
 DECLARE @LinkManESourceTypeId INT = 4;

 --DECLARE VARIABLES USED IN UNIQUE SECTION CODES COUNT    
 DECLARE @UniqueSectionCodesLoopCnt INT = 1;
 DECLARE @InpSegmentLinkLoopCnt INT = 1;

 --DECLARE INP SEGMENT LINK VAR    
 CREATE TABLE #TempInpSegmentLinkTableVar (
 RowId INT NOT NULL PRIMARY KEY,    
 ProjectId INT NOT NULL,    
 CustomerId INT NOT NULL,    
 SectionId INT NOT NULL,    
 SectionCode INT NOT NULL,    
 SegmentStatusCode BIGINT NULL,    
 SegmentSource CHAR(1) NULL,    
 SegmentChoiceCode BIGINT NULL,    
 SegmentChoiceSource CHAR(1) NULL,    
 ChoiceOptionCode BIGINT NULL,    
 ChoiceOptionSource CHAR(1) NULL,    
 UserId INT NOT NULL,    
 IsFetchSrcLinks BIT NULL,    
 IsFetchTgtLinks BIT NULL,    
 IsFetchChilds BIT NULL    
 );

--CREATE TEMP TABLE TO STORE SEGMENT LINK IN BETWEEN RESULT
CREATE TABLE #temp_SegmentLinkResult
(
	SegmentLinkId BIGINT,
	SourceSectionCode INT,
	SourceSegmentStatusCode BIGINT,
	SourceSegmentCode BIGINT,
	SourceSegmentChoiceCode BIGINT,
	SourceChoiceOptionCode BIGINT,
	LinkSource CHAR(1),
	TargetSectionCode INT,
	TargetSegmentStatusCode BIGINT,
	TargetSegmentCode BIGINT,
	TargetSegmentChoiceCode BIGINT,
	TargetChoiceOptionCode BIGINT,
	LinkTarget CHAR(1),
	LinkStatusTypeId INT,
	SourceOfRecord CHAR(1),
	IsTgtLink BIT,
	IsSrcLink BIT,
	SegmentLinkCode BIGINT,
	SegmentLinkSourceTypeId INT,
	IsDeleted BIT,
	IsSrcLinkOfTgtLink BIT,
	IsTgtLinkOfTgtLink BIT,
	IsSrcLinkOfTgtOfTgtLink BIT
)

--CREATE NON CLUSTERED INDEXES ON TEMP TABLES
CREATE NONCLUSTERED INDEX [TMPIX_#TempInpSegmentLinkTableVar_SectionCode_ProjectId_CustomerId]
ON #TempInpSegmentLinkTableVar ([SectionCode])
INCLUDE ([ProjectId], [CustomerId])

CREATE NONCLUSTERED INDEX [TMPIX_#TempInpSegmentLinkTableVar_SegmentStatusCode_ProjectId_CustomerId]
ON #TempInpSegmentLinkTableVar ([SegmentStatusCode])
INCLUDE ([ProjectId], [CustomerId])

CREATE NONCLUSTERED INDEX [TMPIX_#TempInpSegmentLinkTableVar_SegmentChoiceCode_ProjectId_CustomerId]
ON #TempInpSegmentLinkTableVar ([SegmentChoiceCode])
INCLUDE ([ProjectId], [CustomerId])

CREATE NONCLUSTERED INDEX [TMPIX_#TempInpSegmentLinkTableVar_ChoiceOptionCode_ProjectId_CustomerId]
ON #TempInpSegmentLinkTableVar ([ChoiceOptionCode])
INCLUDE ([ProjectId], [CustomerId])

CREATE NONCLUSTERED INDEX [TMPIX_#temp_SegmentLinkInBetweenResult_SourceSectionCode]
ON #temp_SegmentLinkResult ([SourceSectionCode])

CREATE NONCLUSTERED INDEX [TMPIX_#temp_SegmentLinkInBetweenResult_TargetSectionCode]
ON #temp_SegmentLinkResult ([TargetSectionCode])

--PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE   
IF @InpSegmentLinkJson != ''  
BEGIN
INSERT INTO #TempInpSegmentLinkTableVar
	SELECT
		ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId
	   ,ProjectId
	   ,CustomerId
	   ,SectionId
	   ,SectionCode
	   ,SegmentStatusCode
	   ,SegmentSource
	   ,SegmentChoiceCode
	   ,SegmentChoiceSource
	   ,ChoiceOptionCode
	   ,ChoiceOptionSource
	   ,UserId
	   ,IsFetchSrcLinks
	   ,IsFetchTgtLinks
	   ,IsFetchChilds
	FROM OPENJSON(@InpSegmentLinkJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SectionCode INT '$.SectionCode',
	SegmentStatusCode BIGINT '$.SegmentStatusCode',
	SegmentSource CHAR(1) '$.SegmentSource',
	SegmentChoiceCode BIGINT '$.SegmentChoiceCode',
	SegmentChoiceSource CHAR(1) '$.SegmentChoiceSource',
	ChoiceOptionCode BIGINT '$.ChoiceOptionCode',
	ChoiceOptionSource CHAR(1) '$.ChoiceOptionSource',
	UserId INT '$.UserId',
	IsFetchSrcLinks BIT '$.IsFetchSrcLinks',
	IsFetchTgtLinks BIT '$.IsFetchTgtLinks',
	IsFetchChilds BIT '$.IsFetchChilds'
	);
END

--SET COMMON VARIABLES FROM INP JSON  
SELECT TOP 1
	@ProjectId = ProjectId
   ,@CustomerId = CustomerId
   ,@UserId = UserId
FROM #TempInpSegmentLinkTableVar;

--LOOP INP SEGMENT LINK TABLE TO MAP SEGMENT STATUS AND CHOICES IF SECTION STATUS IS CLICKED  
declare @TempInpSegmentLinkTableVarRowCount int=(SELECT COUNT(1) FROM #TempInpSegmentLinkTableVar)
WHILE @InpSegmentLinkLoopCnt <= @TempInpSegmentLinkTableVarRowCount
BEGIN
IF EXISTS (SELECT TOP 1
			1
		FROM #TempInpSegmentLinkTableVar
		WHERE RowId = @InpSegmentLinkLoopCnt
		AND SegmentStatusCode <= 0
		AND SegmentChoiceCode <= 0
		AND ChoiceOptionCode <= 0)
BEGIN
SET @LoopedSectionId = 0;
SET @LoopedSegmentStatusCode = 0;
SET @LoopedSegmentSource = '';

SELECT
	@LoopedSectionId = SectionId
FROM #TempInpSegmentLinkTableVar
WHERE RowId = @InpSegmentLinkLoopCnt

EXEC dbo.usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;

EXEC dbo.usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;

EXEC dbo.usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId
														,@SectionId = @LoopedSectionId
														,@CustomerId = @CustomerId
														,@UserId = @UserId;

EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId
											  ,@SectionId = @LoopedSectionId
											  ,@CustomerId = @CustomerId
											  ,@UserId = @UserId;

--FETCH TOP MOST SEGMENT STATUS CODE FROM SEGMENT STATUS ITS SOURCE    
SELECT TOP 1
	@LoopedSegmentStatusCode = SegmentStatusCode
   ,@LoopedSegmentSource = SegmentOrigin
FROM ProjectSegmentStatus WITH (NOLOCK)
WHERE SectionId = @LoopedSectionId
AND ProjectId = @ProjectId
AND CustomerId = @CustomerId
AND ParentSegmentStatusId = 0;

UPDATE TMPTBL
SET TMPTBL.SegmentStatusCode = @LoopedSegmentStatusCode
   ,TMPTBL.SegmentSource = @LoopedSegmentSource
FROM #TempInpSegmentLinkTableVar TMPTBL
WHERE TMPTBL.RowId = @InpSegmentLinkLoopCnt
END

SET @InpSegmentLinkLoopCnt = @InpSegmentLinkLoopCnt + 1;
 
END;

--INSERT SEGMENT LINK RESULT IN TEMP TABLE 
INSERT INTO #temp_SegmentLinkResult
	SELECT
		*
	FROM (
		--FETCH TGT LINKS FROM SLCMaster for requested inputs
		SELECT
			MSLNK.SegmentLinkId
		   ,MSLNK.SourceSectionCode
		   ,MSLNK.SourceSegmentStatusCode
		   ,MSLNK.SourceSegmentCode
		   ,MSLNK.SourceSegmentChoiceCode
		   ,MSLNK.SourceChoiceOptionCode
		   ,MSLNK.LinkSource
		   ,MSLNK.TargetSectionCode
		   ,MSLNK.TargetSegmentStatusCode
		   ,MSLNK.TargetSegmentCode
		   ,MSLNK.TargetSegmentChoiceCode
		   ,MSLNK.TargetChoiceOptionCode
		   ,MSLNK.LinkTarget
		   ,MSLNK.LinkStatusTypeId
		   ,@SourceOfRecord_Master AS SourceOfRecord
		   ,CASE
				WHEN TMPTBL_SrcSegment_Master.RowId IS NOT NULL THEN 1
				ELSE 0
			END AS IsTgtLink
		   ,0 AS IsSrcLink
		   ,MSLNK.SegmentLinkCode
		   ,MSLNK.SegmentLinkSourceTypeId
		   ,MSLNK.IsDeleted
		   ,0 AS IsSrcLinkOfTgtLink
		   ,0 AS IsTgtLinkOfTgtLink
		   ,0 AS IsSrcLinkOfTgtOfTgtLink
		FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)

		LEFT JOIN #TempInpSegmentLinkTableVar TMPTBL_SrcSegment_Master
			ON MSLNK.SourceSectionCode = TMPTBL_SrcSegment_Master.SectionCode
			AND MSLNK.SourceSegmentStatusCode = TMPTBL_SrcSegment_Master.SegmentStatusCode
			AND MSLNK.LinkSource = TMPTBL_SrcSegment_Master.SegmentSource
			AND TMPTBL_SrcSegment_Master.SegmentStatusCode > 0
			AND TMPTBL_SrcSegment_Master.IsFetchTgtLinks = 1

		WHERE MSLNK.IsDeleted = 0
		AND MSLNK.SegmentLinkSourceTypeId != @LinkManESourceTypeId
		AND (TMPTBL_SrcSegment_Master.RowId IS NOT NULL)

		UNION
		--FETCH SRC LINKS AND TGT LINKS FROM SLCProject for requested inputs
		SELECT
			PSLNK.SegmentLinkId
		   ,PSLNK.SourceSectionCode
		   ,PSLNK.SourceSegmentStatusCode
		   ,PSLNK.SourceSegmentCode
		   ,PSLNK.SourceSegmentChoiceCode
		   ,PSLNK.SourceChoiceOptionCode
		   ,PSLNK.LinkSource
		   ,PSLNK.TargetSectionCode
		   ,PSLNK.TargetSegmentStatusCode
		   ,PSLNK.TargetSegmentCode
		   ,PSLNK.TargetSegmentChoiceCode
		   ,PSLNK.TargetChoiceOptionCode
		   ,PSLNK.LinkTarget
		   ,PSLNK.LinkStatusTypeId
		   ,@SourceOfRecord_Project AS SourceOfRecord
		   ,CASE
				WHEN TMPTBL_SrcSegment_Project.RowId IS NOT NULL THEN 1
				ELSE 0
			END AS IsTgtLink
		   ,CASE
				WHEN TMPTBL_TgtSegment_Project.RowId IS NOT NULL THEN 1
				ELSE 0
			END AS IsSrcLink
		   ,PSLNK.SegmentLinkCode
		   ,PSLNK.SegmentLinkSourceTypeId
		   ,PSLNK.IsDeleted
		   ,0 AS IsSrcLinkOfTgtLink
		   ,0 AS IsTgtLinkOfTgtLink
		   ,0 AS IsSrcLinkOfTgtOfTgtLink
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)

		LEFT JOIN #TempInpSegmentLinkTableVar TMPTBL_SrcSegment_Project
			ON PSLNK.SourceSectionCode = TMPTBL_SrcSegment_Project.SectionCode
			AND PSLNK.SourceSegmentStatusCode = TMPTBL_SrcSegment_Project.SegmentStatusCode
			AND PSLNK.LinkSource = TMPTBL_SrcSegment_Project.SegmentSource
			AND TMPTBL_SrcSegment_Project.SegmentStatusCode > 0
			AND TMPTBL_SrcSegment_Project.IsFetchTgtLinks = 1

		LEFT JOIN #TempInpSegmentLinkTableVar TMPTBL_TgtSegment_Project
			ON PSLNK.TargetSectionCode = TMPTBL_TgtSegment_Project.SectionCode
			AND PSLNK.TargetSegmentStatusCode = TMPTBL_TgtSegment_Project.SegmentStatusCode
			AND PSLNK.LinkTarget = TMPTBL_TgtSegment_Project.SegmentSource
			AND TMPTBL_TgtSegment_Project.SegmentStatusCode > 0
			AND TMPTBL_TgtSegment_Project.IsFetchSrcLinks = 1

		WHERE PSLNK.ProjectId = @ProjectId
		AND PSLNK.CustomerId = @CustomerId
		AND PSLNK.IsDeleted = 0
		AND PSLNK.SegmentLinkSourceTypeId != @LinkManESourceTypeId
		AND (TMPTBL_SrcSegment_Project.RowId IS NOT NULL
		OR TMPTBL_TgtSegment_Project.RowId IS NOT NULL)) AS SEGLNK

--INSERT SEGMENT LINK RESULT IN TEMP TABLE 
INSERT INTO #temp_SegmentLinkResult
	SELECT
		*
	FROM (
		--INSERT TGT LINKS OF TGT LINKS FROM SLCMaster
		SELECT
			MSEGLNK.SegmentLinkId
		   ,MSEGLNK.SourceSectionCode
		   ,MSEGLNK.SourceSegmentStatusCode
		   ,MSEGLNK.SourceSegmentCode
		   ,MSEGLNK.SourceSegmentChoiceCode
		   ,MSEGLNK.SourceChoiceOptionCode
		   ,MSEGLNK.LinkSource
		   ,MSEGLNK.TargetSectionCode
		   ,MSEGLNK.TargetSegmentStatusCode
		   ,MSEGLNK.TargetSegmentCode
		   ,MSEGLNK.TargetSegmentChoiceCode
		   ,MSEGLNK.TargetChoiceOptionCode
		   ,MSEGLNK.LinkTarget
		   ,MSEGLNK.LinkStatusTypeId
		   ,@SourceOfRecord_Project AS SourceOfRecord
		   ,1 AS IsTgtLink
		   ,0 AS IsSrcLink
		   ,MSEGLNK.SegmentLinkCode
		   ,MSEGLNK.SegmentLinkSourceTypeId
		   ,MSEGLNK.IsDeleted
		   ,0 AS IsSrcLinkOfTgtLink
		   ,1 AS IsTgtLinkOfTgtLink
		   ,0 AS IsSrcLinkOfTgtOfTgtLink
		FROM #temp_SegmentLinkResult TMP
		INNER JOIN SLCMaster..SegmentLink MSEGLNK WITH (NOLOCK)
			ON TMP.TargetSectionCode = MSEGLNK.SourceSectionCode
			AND TMP.TargetSegmentStatusCode = MSEGLNK.SourceSegmentStatusCode
			AND TMP.LinkTarget = MSEGLNK.LinkSource
		WHERE MSEGLNK.IsDeleted = 0
		AND MSEGLNK.SegmentLinkSourceTypeId != @LinkManESourceTypeId
		AND TMP.IsTgtLink = 1
		UNION
		--INSERT TGT AND SRC LINKS OF TGT LINKS FROM SLCProject
		SELECT
			PSEGLNK.SegmentLinkId
		   ,PSEGLNK.SourceSectionCode
		   ,PSEGLNK.SourceSegmentStatusCode
		   ,PSEGLNK.SourceSegmentCode
		   ,PSEGLNK.SourceSegmentChoiceCode
		   ,PSEGLNK.SourceChoiceOptionCode
		   ,PSEGLNK.LinkSource
		   ,PSEGLNK.TargetSectionCode
		   ,PSEGLNK.TargetSegmentStatusCode
		   ,PSEGLNK.TargetSegmentCode
		   ,PSEGLNK.TargetSegmentChoiceCode
		   ,PSEGLNK.TargetChoiceOptionCode
		   ,PSEGLNK.LinkTarget
		   ,PSEGLNK.LinkStatusTypeId
		   ,@SourceOfRecord_Project AS SourceOfRecord
		   ,CASE
				WHEN TMP_Tgt.SegmentLinkId IS NOT NULL THEN 1
				ELSE 0
			END AS IsTgtLink
		   ,CASE
				WHEN TMP_Src.SegmentLinkId IS NOT NULL THEN 1
				ELSE 0
			END AS IsSrcLink
		   ,PSEGLNK.SegmentLinkCode
		   ,PSEGLNK.SegmentLinkSourceTypeId
		   ,PSEGLNK.IsDeleted
		   ,CASE
				WHEN TMP_Src.SegmentLinkId IS NOT NULL THEN 1
				ELSE 0
			END AS IsSrcLinkOfTgtLink
		   ,CASE
				WHEN TMP_Tgt.SegmentLinkId IS NOT NULL THEN 1
				ELSE 0
			END AS IsTgtLinkOfTgtLink
		   ,0 AS IsSrcLinkOfTgtOfTgtLink
		FROM ProjectSegmentLink PSEGLNK WITH (NOLOCK)

		LEFT JOIN #temp_SegmentLinkResult TMP_Tgt WITH (NOLOCK)
			ON TMP_Tgt.TargetSectionCode = PSEGLNK.SourceSectionCode
			AND TMP_Tgt.TargetSegmentStatusCode = PSEGLNK.SourceSegmentStatusCode
			AND TMP_Tgt.LinkTarget = PSEGLNK.LinkSource

		LEFT JOIN #temp_SegmentLinkResult TMP_Src WITH (NOLOCK)
			ON TMP_Src.TargetSectionCode = PSEGLNK.TargetSectionCode
			AND TMP_Src.TargetSegmentStatusCode = PSEGLNK.TargetSegmentStatusCode
			AND TMP_Src.LinkTarget = PSEGLNK.LinkTarget

		WHERE PSEGLNK.ProjectId = @ProjectId
		AND PSEGLNK.CustomerId = @CustomerId
		AND PSEGLNK.IsDeleted = 0
		AND PSEGLNK.SegmentLinkSourceTypeId != @LinkManESourceTypeId
		AND (TMP_Src.IsTgtLink = 1
		OR TMP_Tgt.IsTgtLink = 1)) AS SLNK

--DELETE ALREADY MAPPED MASTER RECORDS INTO PROJECT WHICH ARE ALSO FETCHED FROM MASTER DB  
DELETE MSLNK
	FROM #temp_SegmentLinkResult MSLNK
	INNER JOIN #temp_SegmentLinkResult USLNK
		ON MSLNK.SegmentLinkCode = USLNK.SegmentLinkCode
WHERE MSLNK.SourceOfRecord = @SourceOfRecord_Master
	AND USLNK.SourceOfRecord = @SourceOfRecord_Project

--INSERT UNIQUE SECTION CODES IN TEMP TABLE    
SELECT DISTINCT
	ROW_NUMBER() OVER (ORDER BY X.SectionCode) AS Id
   ,X.SectionCode
   ,PS.SectionId INTO #temp_UniqueSectionCodes
FROM (SELECT DISTINCT
		TargetSectionCode AS SectionCode
	FROM #temp_SegmentLinkResult) AS X
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionCode = X.SectionCode
WHERE PS.ProjectId = @ProjectId
AND PS.CustomerId = @CustomerId
AND PS.mSectionId IS NOT NULL -- STORE ONLY MASTER UNIQUE SECTION CODES ONLY TO MAP SEGMENTSTATUS AND CHOICES  
AND PS.IsLastLevel = 1;

--LOOP UNIQUE SECTION CODES TABLE TO MAP SEGMENT STATUS    
declare @temp_UniqueSectionCodesRowCount INT=(SELECT
		COUNT(1)
	FROM #temp_UniqueSectionCodes)
WHILE @UniqueSectionCodesLoopCnt <= @temp_UniqueSectionCodesRowCount
BEGIN
SET @LoopedSectionId = 0;
SET @LoopedSectionId = (SELECT TOP 1
		SectionId
	FROM #temp_UniqueSectionCodes
	WHERE id = @UniqueSectionCodesLoopCnt);
EXEC dbo.usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;

EXEC dbo.usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;

EXEC dbo.usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId
														,@SectionId = @LoopedSectionId
														,@CustomerId = @CustomerId
														,@UserId = @UserId;

EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId
											  ,@SectionId = @LoopedSectionId
											  ,@CustomerId = @CustomerId
											  ,@UserId = @UserId;

SET @UniqueSectionCodesLoopCnt = @UniqueSectionCodesLoopCnt + 1;
  
END;

--SELECT SEGMENT STATUS RESULT DATASET INTO SEGMENT STATUS RESULT     
SELECT DISTINCT
	@ProjectId AS ProjectId
   ,X.SectionId AS SectionId
   ,@CustomerId AS CustomerId
   ,COALESCE(X.SegmentStatusId, 0) AS SegmentStatusId
   ,COALESCE(X.SegmentStatusCode, 0) AS SegmentStatusCode
   ,X.SegmentStatusTypeId AS SegmentStatusTypeId
   ,X.IsParentSegmentStatusActive AS IsParentSegmentStatusActive
   ,X.ParentSegmentStatusId AS ParentSegmentStatusId
   ,0 AS SectionCode
   ,X.SegmentOrigin AS SegmentSource
   ,0 AS ChildCount
   ,0 AS SrcLinksCnt
   ,0 AS TgtLinksCnt
   ,COALESCE(X.SequenceNumber, 0) AS SequenceNumber
   ,X.mSegmentStatusId AS mSegmentStatusId
   ,0 AS SegmentCode
   ,X.mSegmentId
   ,X.SegmentId
   ,CAST(0 AS BIT) AS IsFetchedDbLinkResult INTO #temp_SegmentStatusResult
FROM (SELECT
		PSST.SectionId
	   ,PSST.SegmentStatusId
	   ,PSST.SegmentStatusCode
	   ,PSST.SegmentStatusTypeId
	   ,PSST.IsParentSegmentStatusActive
	   ,PSST.ParentSegmentStatusId
	   ,PSST.SegmentOrigin
	   ,PSST.SequenceNumber
	   ,PSST.mSegmentStatusId
	   ,PSST.mSegmentId
	   ,PSST.SegmentId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	LEFT JOIN #temp_SegmentLinkResult TMPSLNK_Src
		ON PSST.SegmentStatusCode = TMPSLNK_Src.SourceSegmentStatusCode
	LEFT JOIN #temp_SegmentLinkResult TMPSLNK_Tgt
		ON PSST.SegmentStatusCode = TMPSLNK_Tgt.TargetSegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND (TMPSLNK_Src.SegmentLinkId IS NOT NULL
	OR TMPSLNK_Tgt.SegmentLinkId IS NOT NULL)
	UNION
	SELECT
		PSST.SectionId
	   ,PSST.SegmentStatusId
	   ,PSST.SegmentStatusCode
	   ,PSST.SegmentStatusTypeId
	   ,PSST.IsParentSegmentStatusActive
	   ,PSST.ParentSegmentStatusId
	   ,PSST.SegmentOrigin
	   ,PSST.SequenceNumber
	   ,PSST.mSegmentStatusId
	   ,PSST.mSegmentId
	   ,PSST.SegmentId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN #TempInpSegmentLinkTableVar TMPTBL
		ON PSST.SectionId = TMPTBL.SectionId
		AND PSST.SegmentStatusCode = TMPTBL.SegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	UNION
	SELECT
		PPSST.SectionId
	   ,PPSST.SegmentStatusId
	   ,PPSST.SegmentStatusCode
	   ,PPSST.SegmentStatusTypeId
	   ,PPSST.IsParentSegmentStatusActive
	   ,PPSST.ParentSegmentStatusId
	   ,PPSST.SegmentOrigin
	   ,PPSST.SequenceNumber
	   ,PPSST.mSegmentStatusId
	   ,PPSST.mSegmentId
	   ,PPSST.SegmentId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)
		ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId
	INNER JOIN #TempInpSegmentLinkTableVar TMPTBL
		ON PSST.SectionId = TMPTBL.SectionId
		AND PSST.SegmentStatusCode = TMPTBL.SegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	UNION
	SELECT
		CPSST.SectionId
	   ,CPSST.SegmentStatusId
	   ,CPSST.SegmentStatusCode
	   ,CPSST.SegmentStatusTypeId
	   ,CPSST.IsParentSegmentStatusActive
	   ,CPSST.ParentSegmentStatusId
	   ,CPSST.SegmentOrigin
	   ,CPSST.SequenceNumber
	   ,CPSST.mSegmentStatusId
	   ,CPSST.mSegmentId
	   ,CPSST.SegmentId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)
		ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId
	INNER JOIN #TempInpSegmentLinkTableVar TMPTBL
		ON PSST.SectionId = TMPTBL.SectionId
		AND PSST.SegmentStatusCode = TMPTBL.SegmentStatusCode
		AND TMPTBL.IsFetchChilds = 1
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	UNION
	SELECT
		PPSST.SectionId
	   ,PPSST.SegmentStatusId
	   ,PPSST.SegmentStatusCode
	   ,PPSST.SegmentStatusTypeId
	   ,PPSST.IsParentSegmentStatusActive
	   ,PPSST.ParentSegmentStatusId
	   ,PPSST.SegmentOrigin
	   ,PPSST.SequenceNumber
	   ,PPSST.mSegmentStatusId
	   ,PPSST.mSegmentId
	   ,PPSST.SegmentId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)
		ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId
	INNER JOIN #temp_SegmentLinkResult TMPTBL
		ON PSST.SegmentStatusCode = TMPTBL.TargetSegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND TMPTBL.IsTgtLink = 1
	AND TMPTBL.IsTgtLinkOfTgtLink = 0
	UNION
	SELECT
		CPSST.SectionId
	   ,CPSST.SegmentStatusId
	   ,CPSST.SegmentStatusCode
	   ,CPSST.SegmentStatusTypeId
	   ,CPSST.IsParentSegmentStatusActive
	   ,CPSST.ParentSegmentStatusId
	   ,CPSST.SegmentOrigin
	   ,CPSST.SequenceNumber
	   ,CPSST.mSegmentStatusId
	   ,CPSST.mSegmentId
	   ,CPSST.SegmentId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)
		ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId
	INNER JOIN #temp_SegmentLinkResult TMPTBL
		ON PSST.SegmentStatusCode = TMPTBL.TargetSegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND TMPTBL.IsTgtLink = 1
	AND TMPTBL.IsTgtLinkOfTgtLink = 0) X;

--UPDATE SEGMENT STATUS RESULT TO SET CHILD COUNT    
--OPT
UPDATE ORIGINAL_TMPSST
SET ORIGINAL_TMPSST.ChildCount = DUPLICATE_TMPSST.ChildCount
FROM #temp_SegmentStatusResult ORIGINAL_TMPSST
INNER JOIN (SELECT DISTINCT
		TMPSST.SegmentStatusId
	   ,COUNT(*) AS ChildCount
	FROM #temp_SegmentStatusResult TMPSST
	INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
		ON TMPSST.SegmentStatusId = PSST.ParentSegmentStatusId
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST
	ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;

--UPDATE SEGMENT STATUS RESULT TO SET HAS HAVING SRC LINKS COUNT FROM SLCPROJECT  
--TODO--CHECK WHETHER TO ADD CONDITION TO FETCH SRC OF SEGMENT STATUS BUT NOT OF CHOICE OPTIONS  

--OPT
UPDATE ORIGINAL_TMPSST
SET ORIGINAL_TMPSST.SrcLinksCnt = DUPLICATE_TMPSST.SrcLinksCnt
FROM #temp_SegmentStatusResult ORIGINAL_TMPSST
INNER JOIN (SELECT DISTINCT
		TMPSST.SegmentStatusId
	   ,COUNT(*) SrcLinksCnt
	FROM #temp_SegmentStatusResult TMPSST
	INNER JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
		ON TMPSST.SegmentStatusCode = PSLNK.TargetSegmentStatusCode
		AND TMPSST.SectionCode = PSLNK.TargetSectionCode
		AND TMPSST.SegmentSource = PSLNK.LinkTarget
	LEFT JOIN #temp_SegmentLinkResult TMPSLNK
		ON PSLNK.SegmentLinkId = TMPSLNK.SegmentLinkId
		AND TMPSLNK.SourceOfRecord = @SourceOfRecord_Project
	WHERE PSLNK.ProjectId = @ProjectId
	AND PSLNK.CustomerId = @CustomerId
	AND PSLNK.IsDeleted = 0
	AND TMPSLNK.SegmentLinkId IS NULL
	GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST
	ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;

--UPDATE SEGMENT STATUS RESULT TO SET HAS HAVING TGT LINKS FROM SLCPROJECT  
--TODO--CHECK WHETHER TO ADD CONDITION TO FETCH TGT OF SEGMENT STATUS BUT NOT OF CHOICE OPTIONS  
UPDATE ORIGINAL_TMPSST
SET ORIGINAL_TMPSST.TgtLinksCnt = DUPLICATE_TMPSST.TgtLinksCnt
FROM #temp_SegmentStatusResult ORIGINAL_TMPSST
INNER JOIN (SELECT DISTINCT
		TMPSST.SegmentStatusId
	   ,COUNT(*) TgtLinksCnt
	FROM #temp_SegmentStatusResult TMPSST
	INNER JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
		ON TMPSST.SegmentStatusCode = PSLNK.SourceSegmentStatusCode
		AND TMPSST.SectionCode = PSLNK.SourceSectionCode
		AND TMPSST.SegmentSource = PSLNK.LinkSource
	LEFT JOIN #temp_SegmentLinkResult TMPSLNK
		ON PSLNK.SegmentLinkId = TMPSLNK.SegmentLinkId
		AND TMPSLNK.SourceOfRecord = @SourceOfRecord_Project
	WHERE PSLNK.ProjectId = @ProjectId
	AND PSLNK.CustomerId = @CustomerId
	AND PSLNK.IsDeleted = 0
	AND TMPSLNK.SegmentLinkId IS NULL
	GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST
	ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;

--VIMP: UPDATE PROPER VERSION OF SEGMENT CODE IN PROJECTSEGMENTSTATUS  
UPDATE TMPSST
SET TMPSST.SegmentCode = (CASE
		WHEN PSST_PSG.SegmentId IS NOT NULL THEN COALESCE(PSST_PSG.SegmentCode, 0)
		ELSE COALESCE(PSST_MSG.SegmentCode, 0)
	END)
   ,TMPSST.SectionCode = PS.SectionCode
FROM #temp_SegmentStatusResult TMPSST
INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)
	ON TMPSST.SegmentStatusId = PSST.SegmentStatusId
	AND TMPSST.SectionId = PSST.SectionId
INNER JOIN ProjectSection PS WITH(NOLOCK)
	ON PSST.SectionId = PS.SectionId
LEFT JOIN ProjectSegment PSST_PSG WITH (NOLOCK)
	ON PSST.SegmentId = PSST_PSG.SegmentId
	AND PSST.SegmentOrigin = 'U'
LEFT JOIN SLCMaster..Segment PSST_MSG WITH (NOLOCK)
	ON PSST.mSegmentId = PSST_MSG.SegmentId
	AND PSST.SegmentOrigin = 'M'
WHERE PSST.ProjectId = @ProjectId
AND PSST.CustomerId = @CustomerId

--TODO:DELETE THOSE LINKS WHOSE SEGMENTCODE DOESN'T MATCH AT ALL
DELETE SLNK
	FROM #temp_SegmentLinkResult SLNK
	LEFT JOIN #temp_SegmentStatusResult SST
		ON SLNK.SourceSegmentStatusCode = SST.SegmentStatusCode
		AND SLNK.SourceSegmentCode = SST.SegmentCode
		AND SLNK.SourceSectionCode = SST.SectionCode
WHERE SST.SegmentStatusId IS NULL

DELETE SLNK
	FROM #temp_SegmentLinkResult SLNK
	LEFT JOIN #temp_SegmentStatusResult SST
		ON SLNK.TargetSegmentStatusCode = SST.SegmentStatusCode
		AND SLNK.TargetSegmentCode = SST.SegmentCode
		AND SLNK.TargetSectionCode = SST.SectionCode
WHERE SST.SegmentStatusId IS NULL

--UPDATE IsFetchedDbLinkResult in SegmentStatusResult for those whose targets have been fetched
UPDATE SST
SET SST.IsFetchedDbLinkResult = CAST(1 AS BIT)
FROM #temp_SegmentStatusResult SST
INNER JOIN (SELECT
		SLNK.TargetSectionCode
	   ,SLNK.TargetSegmentStatusCode
	   ,SLNK.TargetSegmentCode
	   ,SLNK.LinkTarget
	FROM #temp_SegmentLinkResult SLNK
	WHERE SLNK.IsSrcLinkOfTgtLink = 0
	AND SLNK.IsTgtLinkOfTgtLink = 0
	AND SLNK.IsTgtLink = 1
	GROUP BY SLNK.TargetSectionCode
			,SLNK.TargetSegmentStatusCode
			,SLNK.TargetSegmentCode
			,SLNK.LinkTarget) AS X
	ON SST.SectionCode = X.TargetSectionCode
	AND SST.SegmentStatusCode = X.TargetSegmentStatusCode
	AND SST.SegmentCode = X.TargetSegmentCode
	AND SST.SegmentSource = X.LinkTarget

UPDATE SST
SET SST.IsFetchedDbLinkResult = CAST(1 AS BIT)
FROM #temp_SegmentStatusResult SST
INNER JOIN #TempInpSegmentLinkTableVar INPTBL
	ON SST.SectionCode = INPTBL.SectionCode
	AND SST.SegmentStatusCode = INPTBL.SegmentStatusCode
	AND SST.SegmentSource = INPTBL.SegmentSource

--SELECT THOSE CHOICE OPTIONS WHICH ARE ONLY IN SRC,TGT OR CLICKED ONE AS INBETWEEN RESULT   
SELECT
	* INTO #temp_ChoiceOptionInBetweenResult
FROM (
	--SELECT TARGET CHOICE OPTIONS FROM LINKS    
	SELECT
		SCHOPT.SelectedChoiceOptionId
	   ,SCHOPT.SegmentChoiceCode
	   ,SCHOPT.ChoiceOptionCode
	   ,SCHOPT.IsSelected
	   ,SCHOPT.ChoiceOptionSource
	   ,SCHOPT.ProjectId
	   ,SCHOPT.CustomerId
	FROM SelectedChoiceOption SCHOPT WITH (NOLOCK)

	LEFT JOIN #temp_SegmentLinkResult SrcTMPSEGLNK
		ON SCHOPT.SegmentChoiceCode = SrcTMPSEGLNK.SourceSegmentChoiceCode
		AND SCHOPT.ChoiceOptionCode = SrcTMPSEGLNK.SourceChoiceOptionCode
		AND SCHOPT.ChoiceOptionSource = SrcTMPSEGLNK.LinkSource

	LEFT JOIN #temp_SegmentLinkResult TgtTMPSEGLNK
		ON SCHOPT.SegmentChoiceCode = TgtTMPSEGLNK.TargetSegmentChoiceCode
		AND SCHOPT.ChoiceOptionCode = TgtTMPSEGLNK.TargetChoiceOptionCode
		AND SCHOPT.ChoiceOptionSource = TgtTMPSEGLNK.LinkTarget

	LEFT JOIN #TempInpSegmentLinkTableVar ClickedTMPTBL
		ON SCHOPT.SegmentChoiceCode = ClickedTMPTBL.SegmentChoiceCode
		AND SCHOPT.ChoiceOptionCode = ClickedTMPTBL.ChoiceOptionCode
		AND SCHOPT.ChoiceOptionSource = ClickedTMPTBL.ChoiceOptionSource

	WHERE SCHOPT.ProjectId = @ProjectId
	AND SCHOPT.CustomerId = @CustomerId
	AND (SrcTMPSEGLNK.SegmentLinkId IS NOT NULL
	OR TgtTMPSEGLNK.SegmentLinkId IS NOT NULL
	OR ClickedTMPTBL.ProjectId IS NOT NULL)) AS X;

SELECT
	* INTO #temp_ChoiceOptionResult
FROM ((--SELECT MASTER CHOICE OPTIONS RESULT DATASET    
	SELECT DISTINCT
		@ProjectId AS ProjectId
	   ,PSST.SectionId
	   ,@CustomerId AS CustomerId
	   ,X.SegmentChoiceCode
	   ,X.SegmentChoiceSource
	   ,X.ChoiceTypeId
	   ,X.ChoiceOptionCode
	   ,X.ChoiceOptionSource
	   ,X.IsSelected
	   ,ISNULL(PSST.SectionCode, 0) AS SectionCode
	   ,0 AS SrcLinksCnt
	   ,0 AS TgtLinksCnt
	   ,PSST.SegmentStatusId
	   ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId
	   ,ISNULL(PSST.SegmentId, 0) AS SegmentId
	   ,X.SelectedChoiceOptionId
	FROM (
		--SELECT EXISTING TEMP CHOICE OPTION DATA    
		SELECT
			TMPCHOPT.SelectedChoiceOptionId
		   ,TMPCHOPT.SegmentChoiceCode
		   ,TMPCHOPT.ChoiceOptionCode
		   ,TMPCHOPT.IsSelected
		   ,TMPCHOPT.ChoiceOptionSource
		   ,MCH.ChoiceTypeId
		   ,MCH.SegmentChoiceSource
		   ,MCH.SegmentId AS mSegmentId
		   ,NULL AS SegmentId
		FROM #temp_ChoiceOptionInBetweenResult TMPCHOPT
		INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
			ON TMPCHOPT.SegmentChoiceCode = MCH.SegmentChoiceCode
			AND TMPCHOPT.ChoiceOptionSource = MCH.SegmentChoiceSource
		UNION
		--SELECT OTHER OPTIONS AS WELL IN CASE OF SINGLE SELECT    
		SELECT
			PSCHOP.SelectedChoiceOptionId
		   ,PSCHOP.SegmentChoiceCode
		   ,PSCHOP.ChoiceOptionCode
		   ,PSCHOP.IsSelected
		   ,PSCHOP.ChoiceOptionSource
		   ,MCH.ChoiceTypeId
		   ,MCH.SegmentChoiceSource
		   ,MCH.SegmentId AS mSegmentId
		   ,NULL AS SegmentId
		FROM #temp_ChoiceOptionInBetweenResult TMPCHOPT
		INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
			ON TMPCHOPT.SegmentChoiceCode = MCH.SegmentChoiceCode
			AND TMPCHOPT.ChoiceOptionSource = MCH.SegmentChoiceSource
		INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
			ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
		INNER JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
			ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
			AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PSCHOP.ChoiceOptionSource = TMPCHOPT.ChoiceOptionSource
		WHERE PSCHOP.ProjectId = @ProjectId
		AND PSCHOP.CustomerId = @CustomerId
		AND MCH.ChoiceTypeId = 1) AS X
	INNER JOIN #temp_SegmentStatusResult PSST WITH (NOLOCK)
		ON PSST.mSegmentId = X.mSegmentId)
	UNION
	(--SELECT USER CHOICE OPTIONS RESULT DATASET    
	SELECT DISTINCT
		@ProjectId AS ProjectId
	   ,PSST.SectionId
	   ,@CustomerId AS CustomerId
	   ,X.SegmentChoiceCode
	   ,X.SegmentChoiceSource
	   ,X.ChoiceTypeId
	   ,X.ChoiceOptionCode
	   ,X.ChoiceOptionSource
	   ,X.IsSelected
	   ,ISNULL(PSST.SectionCode, 0) AS SectionCode
	   ,0 AS SrcLinksCnt
	   ,0 AS TgtLinksCnt
	   ,PSST.SegmentStatusId
	   ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId
	   ,ISNULL(PSST.SegmentId, 0) AS SegmentId
	   ,X.SelectedChoiceOptionId
	FROM (
		--SELECT EXISTING TEMP CHOICE OPTION DATA    
		SELECT
			TMPCHOPT.SelectedChoiceOptionId
		   ,TMPCHOPT.SegmentChoiceCode
		   ,TMPCHOPT.ChoiceOptionCode
		   ,TMPCHOPT.IsSelected
		   ,TMPCHOPT.ChoiceOptionSource
		   ,PCH.ChoiceTypeId
		   ,PCH.SegmentChoiceSource
		   ,NULL AS mSegmentId
		   ,PCH.SegmentId
		FROM #temp_ChoiceOptionInBetweenResult TMPCHOPT
		INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
			ON TMPCHOPT.SegmentChoiceCode = PCH.SegmentChoiceCode
			AND TMPCHOPT.ChoiceOptionSource = PCH.SegmentChoiceSource
		WHERE PCH.ProjectId = @ProjectId
		AND PCH.CustomerId = @CustomerId
		UNION
		--SELECT OTHER OPTIONS AS WELL IN CASE OF SINGLE SELECT    
		SELECT
			PSCHOP.SelectedChoiceOptionId
		   ,PSCHOP.SegmentChoiceCode
		   ,PSCHOP.ChoiceOptionCode
		   ,PSCHOP.IsSelected
		   ,PSCHOP.ChoiceOptionSource
		   ,PCH.ChoiceTypeId
		   ,PCH.SegmentChoiceSource
		   ,NULL AS mSegmentId
		   ,PCH.SegmentId
		FROM #temp_ChoiceOptionInBetweenResult TMPCHOPT
		INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
			ON TMPCHOPT.SegmentChoiceCode = PCH.SegmentChoiceCode
			AND TMPCHOPT.ChoiceOptionSource = PCH.SegmentChoiceSource
		INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
			ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
		INNER JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
			ON PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
			AND PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PSCHOP.ChoiceOptionSource = TMPCHOPT.ChoiceOptionSource
		WHERE PCH.ProjectId = @ProjectId
		AND PCH.CustomerId = @CustomerId
		AND PSCHOP.ProjectId = @ProjectId
		AND PSCHOP.CustomerId = @CustomerId
		AND PCH.ChoiceTypeId = 1) AS X
	INNER JOIN #temp_SegmentStatusResult PSST WITH (NOLOCK)
		ON PSST.SegmentId = X.SegmentId)) AS FinalChoiceOptionResult

--SELECT LINK RESULT  
SELECT
DISTINCT
	SLNK.SegmentLinkId
   ,SLNK.SourceSectionCode
   ,SLNK.SourceSegmentStatusCode
   ,SLNK.SourceSegmentCode
   ,COALESCE(SLNK.SourceSegmentChoiceCode, 0) AS SourceSegmentChoiceCode
   ,COALESCE(SLNK.SourceChoiceOptionCode, 0) AS SourceChoiceOptionCode
   ,SLNK.LinkSource
   ,SLNK.TargetSectionCode
   ,SLNK.TargetSegmentStatusCode
   ,SLNK.TargetSegmentCode
   ,COALESCE(SLNK.TargetSegmentChoiceCode, 0) AS TargetSegmentChoiceCode
   ,COALESCE(SLNK.TargetChoiceOptionCode, 0) AS TargetChoiceOptionCode
   ,SLNK.LinkTarget
   ,SLNK.LinkStatusTypeId
   ,CASE
		WHEN SLNK.SourceSegmentChoiceCode IS NULL AND
			SLNK.TargetSegmentChoiceCode IS NULL THEN @P2P
		WHEN SLNK.SourceSegmentChoiceCode IS NULL AND
			SLNK.TargetSegmentChoiceCode IS NOT NULL THEN @P2C
		WHEN SLNK.SourceSegmentChoiceCode IS NOT NULL AND
			SLNK.TargetSegmentChoiceCode IS NULL THEN @C2P
		WHEN SLNK.SourceSegmentChoiceCode IS NOT NULL AND
			SLNK.TargetSegmentChoiceCode IS NOT NULL THEN @C2C
	END AS SegmentLinkType
   ,SLNK.SourceOfRecord
   ,SLNK.SegmentLinkCode
   ,SLNK.SegmentLinkSourceTypeId
   ,SLNK.IsDeleted
   ,@ProjectId AS ProjectId
   ,@CustomerId AS CustomerId
FROM #temp_SegmentLinkResult AS SLNK

--SELECT TMP SEGMENT STATUS RESULT DATASET    
SELECT
	*
FROM #temp_SegmentStatusResult
ORDER BY SegmentStatusId ASC;

--SELECT CHOICE OPTION RESULT DATASET    
SELECT
	*
FROM #temp_ChoiceOptionResult;

--SELECT SEGMENT REQUIREMENT TAGS LIST  
SELECT
	PSRT.SegmentRequirementTagId AS SegmentRequirementTagId
   ,TSSTR.mSegmentStatusId AS mSegmentStatusId
   ,PSRT.RequirementTagId AS RequirementTagId
   ,TSSTR.SegmentStatusId AS SegmentStatusId
   ,@SourceOfRecord_Project AS SourceOfRecord
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
INNER JOIN #temp_SegmentStatusResult TSSTR
	ON PSRT.SegmentStatusId = TSSTR.SegmentStatusId
WHERE PSRT.ProjectId = @ProjectId
AND PSRT.CustomerId = @CustomerId
AND PSRT.RequirementTagId IN (@RS_TAG, @RT_TAG, @RE_TAG, @ST_TAG)

--SELECT PROJECT SUMMARY DETAILS WHICH CONTAINS COLUMNS FOR RS,RE TAGS LOGIC TO BE APPLY IN LINK ENGINE OR NOT  
SELECT
	PSMRY.ProjectId
   ,PSMRY.CustomerId
   ,PSMRY.IsIncludeRsInSection
   ,PSMRY.IsIncludeReInSection
   ,PSMRY.IsActivateRsCitation
FROM ProjectSummary PSMRY WITH (NOLOCK)
WHERE PSMRY.ProjectId = @ProjectId
AND PSMRY.CustomerId = @CustomerId

--COMMIT TRANSACTION
END;
GO


