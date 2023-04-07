
CREATE PROCEDURE [dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]
(@InpSegmentLinkJson NVARCHAR(MAX),@CatalogueType NVARCHAR(MAX)='FS')
AS
BEGIN
DECLARE @PInpSegmentLinkJson NVARCHAR(MAX) = @InpSegmentLinkJson;
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
--VARIABLES
DECLARE @P2P INT = 1;
DECLARE @P2C INT = 2;
DECLARE @C2P INT = 3;
DECLARE @C2C INT = 4;
DECLARE @CS INT = 5;

DECLARE @ProjectId INT = 0;
DECLARE @CustomerId INT = 0;
DECLARE @SourceTagFormat VARCHAR(10) = NULL;
DECLARE @MasterDataTypeId INT = NULL;

--CONSTANTS
DECLARE @MasterSegmentLinkSourceTypeId_CNST INT = 1;
DECLARE @UserSegmentLinkSourceTypeId_CNST INT = 5;

--TABLES
--1.Input data into table from json
--NOTE--SET SegmentSource AND ChoiceOptionSource SHOULD BE SAME IN BELOW INP TABLE OF JSON
DROP TABLE IF EXISTS #TempInpSegmentLinkTable
CREATE TABLE #TempInpSegmentLinkTable (
	RowId INT NULL
   ,ProjectId INT NULL
   ,CustomerId INT NULL
   ,SectionId INT NULL
   ,SectionCode INT NULL
   ,SegmentStatusCode BIGINT NULL
   ,SegmentCode BIGINT NULL
   ,SegmentSource CHAR(1) NULL
   ,SegmentChoiceCode BIGINT NULL
   ,SegmentChoiceSource CHAR(1) NULL
   ,ChoiceOptionCode BIGINT NULL
   ,ChoiceOptionSource CHAR(1) NULL
   ,UserId INT NULL
   ,IsFetchSrcLinks BIT NULL
   ,IsFetchTgtLinks BIT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#TempInpSegmentLinkTable_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
ON #TempInpSegmentLinkTable ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--2.All Src and Tgt Links table
DROP TABLE IF EXISTS #TempSegmentLinksTable
CREATE TABLE #TempSegmentLinksTable (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SourceSectionCode INT NULL
   ,SourceSegmentStatusCode BIGINT NULL
   ,SourceSegmentCode BIGINT NULL
   ,SourceSegmentChoiceCode BIGINT NULL
   ,SourceChoiceOptionCode BIGINT NULL
   ,LinkSource NVARCHAR(1) NULL
   ,TargetSectionCode INT NULL
   ,TargetSegmentStatusCode BIGINT NULL
   ,TargetSegmentCode BIGINT NULL
   ,TargetSegmentChoiceCode BIGINT NULL
   ,TargetChoiceOptionCode BIGINT NULL
   ,LinkTarget NVARCHAR(1) NULL
   ,LinkStatusTypeId INT NULL
   ,SegmentLinkCode BIGINT NULL
   ,SegmentLinkSourceTypeId INT NULL
   ,IsSrcLink BIT NULL
   ,IsTgtLink BIT NULL
   ,SegmentLinkType INT NULL
   ,SourceSegmentDescription NVARCHAR(MAX) NULL
   ,TargetSegmentDescription NVARCHAR(MAX) NULL
   ,SourceSequenceNumber DECIMAL(10, 4) NULL
   ,TargetSequenceNumber DECIMAL(10, 4) NULL
   ,SourceSegmentStatusTypeId INT NULL
   ,TargetSegmentStatusTypeId INT NULL
   ,SegmentLinkId BIGINT NULL
   ,SourceIndentLevel INT NULL
   ,TargetIndentLevel INT NULL
   ,SourceSectionSourceTag NVARCHAR(10) NULL
   ,TargetSectionSourceTag NVARCHAR(10) NULL
   ,IsDeleted BIT NULL
);

--3.Distinct SegmentStatus from Src and Tgt Links
DROP TABLE IF EXISTS #DistinctSegmentStatus
CREATE TABLE #DistinctSegmentStatus (
	SectionId INT NULL
	,ProjectId INT NULL
   ,CustomerId INT NULL
   ,SegmentStatusId BIGINT NULL
   ,SegmentStatusCode BIGINT NULL
   ,SegmentSource CHAR(1) NULL
   ,SegmentDescription NVARCHAR(MAX) NULL
   ,SequenceNumber DECIMAL NULL
   ,SegmentStatusTypeId INT NULL
   ,SegmentId BIGINT NULL
   ,mSegmentId INT NULL
   ,IndentLevel INT NULL
   ,SectionCode INT NULL
   ,SourceTag VARCHAR(10) NULL
   ,SegmentCode BIGINT NULL
   ,IsDeleted BIT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#DistinctSegmentStatus_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
ON #DistinctSegmentStatus ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--4.Section's of Project table
DROP TABLE IF EXISTS #SectionsTable
CREATE TABLE #SectionsTable (
	SectionId INT NULL
   ,SectionCode INT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#SectionsTable_SectionCode]
ON #SectionsTable ([SectionCode])

--INSERT JSON DATA INTO TABLE
INSERT INTO #TempInpSegmentLinkTable
	SELECT
		*
	FROM OPENJSON(@PInpSegmentLinkJson)
	WITH (
	RowId INT '$.RowId',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SectionCode INT '$.SectionCode',
	SegmentStatusCode BIGINT '$.SegmentStatusCode',
	SegmentCode BIGINT '$.SegmentCode',
	SegmentSource CHAR(1) '$.SegmentSource',
	SegmentChoiceCode BIGINT '$.SegmentChoiceCode',
	SegmentChoiceSource CHAR(1) '$.SegmentChoiceSource',
	ChoiceOptionCode BIGINT '$.ChoiceOptionCode',
	ChoiceOptionSource CHAR(1) '$.ChoiceOptionSource',
	UserId INT '$.UserId',
	IsFetchSrcLinks BIT '$.IsFetchSrcLinks',
	IsFetchTgtLinks BIT '$.IsFetchTgtLinks'
	)

--GET COMMON DATA
SELECT TOP 1
	@ProjectId = ProjectId
   ,@CustomerId = CustomerId
FROM #TempInpSegmentLinkTable

--SET Proper segment code into table
UPDATE INPTBL
SET INPTBL.SegmentCode = PSSTV.SegmentCode
FROM #TempInpSegmentLinkTable INPTBL WITH (NOLOCK)
INNER JOIN ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	ON INPTBL.ProjectId = PSSTV.ProjectId
	AND INPTBL.CustomerId = PSSTV.CustomerId
	AND INPTBL.SectionCode = PSSTV.SectionCode
	AND INPTBL.SegmentStatusCode = PSSTV.SegmentStatusCode
	AND INPTBL.SegmentSource = PSSTV.SegmentOrigin
	AND PSSTV.IsDeleted = 0
	AND PSSTV.IsSegmentDeleted = 0

--INSERT SOURCE LINKS FROM PROJECT DB
INSERT INTO #TempSegmentLinksTable (ProjectId, CustomerId,
SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode,
TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId,
IsSrcLink, IsTgtLink, SegmentLinkCode, SegmentLinkSourceTypeId, SegmentLinkId, IsDeleted)
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
	   ,PSLNK.SourceSectionCode
	   ,PSLNK.SourceSegmentStatusCode
	   ,PSLNK.SourceSegmentCode
	   ,PSLNK.SourceSegmentChoiceCode
	   ,PSLNK.SourceChoiceOptionCode
	   ,CAST(PSLNK.LinkSource AS NVARCHAR(1)) AS LinkSource
	   ,PSLNK.TargetSectionCode
	   ,PSLNK.TargetSegmentStatusCode
	   ,PSLNK.TargetSegmentCode
	   ,PSLNK.TargetSegmentChoiceCode
	   ,PSLNK.TargetChoiceOptionCode
	   ,CAST(PSLNK.LinkTarget AS NVARCHAR(1)) AS LinkTarget
	   ,PSLNK.LinkStatusTypeId
	   ,1 AS IsSrcLink
	   ,0 AS IsTgtLink
	   ,PSLNK.SegmentLinkCode
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.SegmentLinkId
	   ,PSLNK.IsDeleted
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #TempInpSegmentLinkTable INPJSON WITH (NOLOCK)
		ON PSLNK.TargetSectionCode = INPJSON.SectionCode
			AND PSLNK.TargetSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.TargetSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkTarget = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @ProjectId
	AND PSLNK.CustomerId = @CustomerId

--INSERT TARGET LINKS FROM PROJECT DB
INSERT INTO #TempSegmentLinksTable (ProjectId, CustomerId,
SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode,
TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId,
IsSrcLink, IsTgtLink, SegmentLinkCode, SegmentLinkSourceTypeId, SegmentLinkId, IsDeleted)
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
	   ,PSLNK.SourceSectionCode
	   ,PSLNK.SourceSegmentStatusCode
	   ,PSLNK.SourceSegmentCode
	   ,PSLNK.SourceSegmentChoiceCode
	   ,PSLNK.SourceChoiceOptionCode
	   ,CAST(PSLNK.LinkSource AS NVARCHAR(1)) AS LinkSource
	   ,PSLNK.TargetSectionCode
	   ,PSLNK.TargetSegmentStatusCode
	   ,PSLNK.TargetSegmentCode
	   ,PSLNK.TargetSegmentChoiceCode
	   ,PSLNK.TargetChoiceOptionCode
	   ,CAST(PSLNK.LinkTarget AS NVARCHAR(1)) AS LinkTarget
	   ,PSLNK.LinkStatusTypeId
	   ,0 AS IsSrcLink
	   ,1 AS IsTgtLink
	   ,PSLNK.SegmentLinkCode
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.SegmentLinkId
	   ,PSLNK.IsDeleted
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #TempInpSegmentLinkTable INPJSON WITH (NOLOCK)
		ON PSLNK.SourceSectionCode = INPJSON.SectionCode
			AND PSLNK.SourceSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.SourceSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkSource = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @ProjectId
	AND PSLNK.CustomerId = @CustomerId

--FETCH SECTIONS OF PROJECT IN TEMP TABLE
INSERT INTO #SectionsTable (SectionId, SectionCode)
	SELECT
		PS.SectionId
	   ,PS.SectionCode
	FROM ProjectSection PS WITH (NOLOCK)
	WHERE PS.ProjectId = @ProjectId
	AND PS.CustomerId = @CustomerId
	AND PS.IsLastLevel = 1
	AND PS.IsDeleted = 0

--DELETE THOSE LINKS WHOSE LINK SOURCE TYPE IS NOT MASTER OR USER
DELETE FROM #TempSegmentLinksTable
WHERE SegmentLinkSourceTypeId NOT IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)

--DELETE WHICH ARE SOFT DELETED IN DB
DELETE FROM #TempSegmentLinksTable
WHERE IsDeleted = 1

--DELETE SOURCE LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT
DELETE SLNK
	FROM #TempSegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.SourceSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--DELETE TARGET LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT
DELETE SLNK
	FROM #TempSegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.TargetSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--FETCH DISCTINCT SEGMENT STATUS CODE
INSERT INTO #DistinctSegmentStatus (ProjectId, CustomerId, SegmentStatusCode, SectionCode)
	SELECT DISTINCT
		X.ProjectId
	   ,X.CustomerId
	   ,X.SegmentStatusCode
	   ,X.SectionCode
	FROM (SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.SourceSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.SourceSectionCode AS SectionCode
		FROM #TempSegmentLinksTable SLNKS UNION
		SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.TargetSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.TargetSectionCode AS TargetSectionCode
		FROM #TempSegmentLinksTable SLNKS) AS X

UPDATE DSTSG
SET DSTSG.SegmentDescription = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentDescription
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentDescription
	END)
   ,DSTSG.SequenceNumber = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SequenceNumber
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SequenceNumber
	END)
   ,DSTSG.SegmentStatusTypeId = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentStatusTypeId
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentStatusTypeId
	END)
	,DSTSG.SectionId = (CASE
		WHEN PSSTV.SectionId IS NOT NULL THEN PSSTV.SectionId
		ELSE 0
	END)
	,DSTSG.SegmentStatusId = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentStatusId
		ELSE 0
	END)
   ,DSTSG.SegmentId = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentId
		ELSE 0
	END)
   ,DSTSG.mSegmentId = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.mSegmentId
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentId
		ELSE 0
	END)
   ,DSTSG.IndentLevel = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.IndentLevel
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.IndentLevel
	END)
   ,DSTSG.SourceTag = CAST((CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SourceTag
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SourceTag
	END) AS VARCHAR(10))
   ,DSTSG.SegmentCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentCode
	END)
   ,DSTSG.SegmentSource = CAST((CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentOrigin
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentOrigin
	END) AS CHAR(2))
   ,DSTSG.SectionCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SectionCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SectionCode
	END)
   ,DSTSG.IsDeleted = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.IsDeleted
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.IsDeleted
	END)
FROM #DistinctSegmentStatus DSTSG WITH (NOLOCK)
LEFT JOIN ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	ON DSTSG.SegmentStatusCode = PSSTV.SegmentStatusCode
	AND DSTSG.ProjectId = PSSTV.ProjectId
	AND DSTSG.CustomerId = PSSTV.CustomerId
	AND DSTSG.SectionCode = PSSTV.SectionCode
	AND PSSTV.IsDeleted = 0

LEFT JOIN SLCMaster..SegmentStatusView MSSTV WITH (NOLOCK)
	ON DSTSG.SegmentStatusCode = MSSTV.SegmentStatusCode
	AND MSSTV.IsDeleted = 0

--DELETE UNMATCHED SEGMENT CODE IN SRC AND TGT LINKS AS WELL
DELETE SLNK
	FROM #TempSegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.SourceSectionCode = DSST.SectionCode
		AND SLNK.SourceSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.SourceSegmentCode = DSST.SegmentCode
		AND SLNK.LinkSource = DSST.SegmentSource
WHERE (SLNK.IsSrcLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #TempSegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.TargetSectionCode = DSST.SectionCode
		AND SLNK.TargetSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.TargetSegmentCode = DSST.SegmentCode
		AND SLNK.LinkTarget = DSST.SegmentSource
WHERE (SLNK.IsTgtLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #TempSegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @ProjectId
		AND SCHV.CustomerId = @CustomerId
		AND SLNK.SourceSectionCode = SCHV.SectionCode
		AND SLNK.SourceSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.SourceSegmentCode = SCHV.SegmentCode
		AND SLNK.SourceSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.SourceChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkSource = SCHV.ChoiceOptionSource
WHERE SLNK.IsSrcLink = 1
	AND ISNULL(SLNK.SourceSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.SourceChoiceOptionCode, 0) > 0
	AND SLNK.LinkSource = 'U'
	AND SCHV.SegmentStatusId IS NULL

DELETE SLNK
	FROM #TempSegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceForLinksView SCHV WITH (NOLOCK)
	ON SCHV.ProjectId = @ProjectId
		AND SCHV.CustomerId = @CustomerId
		AND SLNK.TargetSectionCode = SCHV.SectionCode
		AND SLNK.TargetSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.TargetSegmentCode = SCHV.SegmentCode
		AND SLNK.TargetSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.TargetChoiceOptionCode = SCHV.ChoiceOptionCode
		
	LEFT JOIN SelectedChoiceOption SCHOP WITH (NOLOCK) 
	ON SCHOP.ProjectId = SCHV.ProjectId
	AND SCHOP.ProjectId = @ProjectId
	AND SCHV.CustomerId = SCHOP.CustomerId 
	AND SCHV.SectionId = SCHOP.SectionId 
	AND SLNK.LinkTarget = SCHOP.ChoiceOptionSource
	AND SCHV.SegmentChoiceCode = SCHOP.SegmentChoiceCode 
	AND SCHV.ChoiceOptionCode = SCHOP.ChoiceOptionCode 
	AND ISNULL(SCHOP.IsDeleted, 0) = 0

WHERE SLNK.IsTgtLink = 1
	AND ISNULL(SLNK.TargetSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.TargetChoiceOptionCode, 0) > 0
	AND SLNK.LinkTarget = 'U'
	AND SCHV.SegmentStatusId IS NULL

--SET DEFAULT VALUES TO NULL FIELDS
UPDATE SLNKS
SET SLNKS.SourceSegmentChoiceCode = COALESCE(SLNKS.SourceSegmentChoiceCode, 0)
   ,SLNKS.SourceChoiceOptionCode = COALESCE(SLNKS.SourceChoiceOptionCode, 0)
   ,SLNKS.TargetSegmentChoiceCode = COALESCE(SLNKS.TargetSegmentChoiceCode, 0)
   ,SLNKS.TargetChoiceOptionCode = COALESCE(SLNKS.TargetChoiceOptionCode, 0)
   ,SLNKS.SegmentLinkType = (CASE
		WHEN SLNKS.SourceSectionCode != SLNKS.TargetSectionCode THEN @CS
		WHEN SLNKS.SourceChoiceOptionCode IS NULL AND
			SLNKS.TargetChoiceOptionCode IS NULL THEN @P2P
		WHEN SLNKS.SourceChoiceOptionCode IS NULL AND
			SLNKS.TargetChoiceOptionCode IS NOT NULL THEN @P2C
		WHEN SLNKS.SourceChoiceOptionCode IS NOT NULL AND
			SLNKS.TargetChoiceOptionCode IS NULL THEN @C2P
		WHEN SLNKS.SourceChoiceOptionCode IS NOT NULL AND
			SLNKS.TargetChoiceOptionCode IS NOT NULL THEN @C2C
	END)
   ,SLNKS.SourceSegmentDescription = COALESCE(SrcDSTSG.SegmentDescription, '')
   ,SLNKS.SourceSequenceNumber = COALESCE(SrcDSTSG.SequenceNumber, 0)
   ,SLNKS.SourceSegmentStatusTypeId = COALESCE(SrcDSTSG.SegmentStatusTypeId, 0)
   ,SLNKS.TargetSegmentDescription = COALESCE(TgtDSTSG.SegmentDescription, '')
   ,SLNKS.TargetSequenceNumber = COALESCE(TgtDSTSG.SequenceNumber, 0)
   ,SLNKS.TargetSegmentStatusTypeId = COALESCE(TgtDSTSG.SegmentStatusTypeId, 0)
   ,SLNKS.SourceIndentLevel = COALESCE(SrcDSTSG.IndentLevel, 0)
   ,SLNKS.TargetIndentLevel = COALESCE(TgtDSTSG.IndentLevel, 0)
   ,SLNKS.SourceSectionSourceTag = COALESCE(SrcDSTSG.SourceTag, '')
   ,SLNKS.TargetSectionSourceTag = COALESCE(TgtDSTSG.SourceTag, '')
   ,SLNKS.SegmentLinkCode = COALESCE(SLNKS.SegmentLinkCode, 0)
FROM #TempSegmentLinksTable SLNKS
INNER JOIN #DistinctSegmentStatus SrcDSTSG
	ON SLNKS.ProjectId = SrcDSTSG.ProjectId
	AND SLNKS.CustomerId = SrcDSTSG.CustomerId
	AND SLNKS.SourceSegmentStatusCode = SrcDSTSG.SegmentStatusCode
	AND SLNKS.SourceSectionCode = SrcDSTSG.SectionCode
INNER JOIN #DistinctSegmentStatus TgtDSTSG
	ON SLNKS.ProjectId = TgtDSTSG.ProjectId
	AND SLNKS.CustomerId = TgtDSTSG.CustomerId
	AND SLNKS.TargetSegmentStatusCode = TgtDSTSG.SegmentStatusCode
	AND SLNKS.TargetSectionCode = TgtDSTSG.SectionCode

--FETCH SEGMENT LINKS DATA
SELECT
	*
FROM #TempSegmentLinksTable WITH (NOLOCK)

DROP TABLE IF EXISTS #tmpChoiceOptionList

CREATE TABLE #tmpChoiceOptionList (SegmentStatusCode BIGINT null
									, SegmentChoiceCode BIGINT null
									, ChoiceOptionCode BIGINT null
									, SortOrder TINYINT null
									, IsSelected INT null
									, OptionJson NVARCHAR(MAX) null
									, ChoiceTypeId INT null)

--SELECT CHOICE OPTION LIST
INSERT INTO #tmpChoiceOptionList (SegmentStatusCode
   ,SegmentChoiceCode
   ,ChoiceOptionCode
   ,SortOrder
   ,IsSelected
   ,OptionJson
   ,ChoiceTypeId)
SELECT
	DSTSG.SegmentStatusCode
   ,PCH.SegmentChoiceCode
   ,PCHOP.ChoiceOptionCode
   ,PCHOP.SortOrder
   ,SCHOP.IsSelected
   ,PCHOP.OptionJson
   ,PCH.ChoiceTypeId
FROM #DistinctSegmentStatus DSTSG WITH (NOLOCK)
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
	ON DSTSG.SegmentId = PCH.SegmentId
		AND ISNULL(PCH.IsDeleted, 0) = 0
		AND DSTSG.ProjectId = PCH.ProjectId
		AND DSTSG.CustomerId = PCH.CustomerId
		AND DSTSG.SectionId = PCH.SectionId
		--and DSTSG.ProjectId=pch.ProjectId --added this --Ravi 8/26 - This seem to help without the union
		--and DSTSG.CustomerId=pch.CustomerId --added this --Ravi 8/26
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
	ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
		AND ISNULL(PCHOP.IsDeleted, 0) = 0
		and pchop.ProjectId=DSTSG.ProjectId --added this --Ravi 8/26
		and pchop.CustomerId=DSTSG.CustomerId --added this --Ravi 8/26
INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)
	ON 	SCHOP.ProjectId = DSTSG.ProjectId
		AND SCHOP.CustomerId = DSTSG.CustomerId
		AND SCHOP.SectionId = DSTSG.SectionId
		AND PCH.SegmentChoiceCode = SCHOP.SegmentChoiceCode
		AND PCHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
		AND SCHOP.ChoiceOptionSource = 'U'
		AND ISNULL(SCHOP.IsDeleted, 0) = 0
WHERE DSTSG.SegmentSource = 'U'
--UNION

INSERT INTO #tmpChoiceOptionList (SegmentStatusCode
   ,SegmentChoiceCode
   ,ChoiceOptionCode
   ,SortOrder
   ,IsSelected
   ,OptionJson
   ,ChoiceTypeId)
SELECT -- this is where majority of time is spent. How to fine tune this?
	DSTSG.SegmentStatusCode
   ,MCH.SegmentChoiceCode
   ,MCHOP.ChoiceOptionCode
   ,MCHOP.SortOrder
   ,(CASE
		WHEN SCHOP.SelectedChoiceOptionId IS NOT NULL THEN SCHOP.IsSelected
		WHEN MSCHOP.SelectedChoiceOptionId IS NOT NULL THEN MSCHOP.IsSelected
		ELSE 0
	END) AS IsSelected
   ,MCHOP.OptionJson
   ,MCH.ChoiceTypeId
FROM #DistinctSegmentStatus DSTSG WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
	ON DSTSG.mSegmentId = MCH.SegmentId
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
LEFT JOIN SelectedChoiceOption SCHOP WITH (NOLOCK) -- make this temp table filtered by customerid and projectid?
	ON SCHOP.ProjectId = DSTSG.ProjectId
		AND SCHOP.CustomerId = DSTSG.CustomerId
		AND SCHOP.SectionId = DSTSG.SectionId
		AND MCHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
		AND SCHOP.ChoiceOptionSource = 'M'
		AND ISNULL(SCHOP.IsDeleted, 0) = 0
LEFT JOIN SLCMaster..SelectedChoiceOption MSCHOP WITH (NOLOCK) -- make this temp table?
	on MCH.SegmentChoiceCode = MSCHOP.SegmentChoiceCode
	and MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
WHERE DSTSG.SegmentSource = 'M'


select * from #tmpChoiceOptionList

--Fetch Section List
SET @SourceTagFormat = (SELECT TOP 1
		CAST(SourceTagFormat AS VARCHAR(10))
	FROM ProjectSummary
	WHERE ProjectId = @ProjectId);
SET @MasterDataTypeId = (SELECT
		P.MasterDataTypeId
	FROM Project P
	WHERE P.ProjectId = @ProjectId
	AND P.CustomerId = @CustomerId);

SELECT
	PS.SectionCode
   ,PS.SourceTag
   ,CAST(PS.Description AS NVARCHAR(500)) AS Description
   ,@SourceTagFormat AS SourceTagFormat
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @ProjectId
AND PS.CustomerId = @CustomerId
AND PS.IsLastLevel = 1
UNION
SELECT
	MS.SectionCode
   ,MS.SourceTag
   ,CAST(MS.Description AS NVARCHAR(500)) AS Description
   ,@SourceTagFormat AS SourceTagFormat
FROM SLCMaster..Section MS WITH (NOLOCK)
LEFT JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.ProjectId = @ProjectId
		AND PS.CustomerId = @CustomerId
		AND PS.mSectionId = MS.SectionId
WHERE MS.MasterDataTypeId = @MasterDataTypeId
AND MS.IsLastLevel = 1
AND PS.SectionId IS NULL

END
GO


