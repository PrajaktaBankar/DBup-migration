CREATE PROCEDURE [dbo].[usp_GetSourceTargetLinksCount]  
(@ProjectId INT, @SectionId INT, @CustomerId INT, @SectionCode INT, @MasterDataTypeId TINYINT = 1, @CatalogueType NVARCHAR(100) = 'FS') 
AS    
BEGIN
  
--PARAMETER SNIFFING CARE  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
  
--VARIABLES  
--DECLARE @PMasterDataTypeId INT = ( SELECT  
--  P.MasterDataTypeId  
-- FROM Project P WITH (NOLOCK)  
-- WHERE P.ProjectId = @PProjectId  
-- AND P.CustomerId = @PCustomerId);  
  
--CONSTANTS  
DECLARE @MasterSegmentLinkSourceTypeId_CNST INT = 1;
DECLARE @UserSegmentLinkSourceTypeId_CNST INT = 5;

--TABLES  
--1.SegmentStatus of Section and their SrcLinksCount and TgtLinksCount  
DROP TABLE IF EXISTS #ResultTable
CREATE TABLE #ResultTable (
	Id int Identity(1,1) Primary Key,
	ProjectId INT NOT NULL
   ,SectionId INT NOT NULL
   ,CustomerId INT NOT NULL
   ,SectionCode INT NULL
   ,SegmentStatusCode BIGINT NULL
   ,SegmentCode BIGINT NULL
   ,SegmentSource CHAR(1) NULL
   ,SrcLinksCnt INT NULL
   ,TgtLinksCnt INT NULL
   ,SegmentDescription NVARCHAR(MAX) NULL
   ,SequenceNumber DECIMAL(10, 4) NULL
   ,SegmentStatusId BIGINT NULL
   ,SegmentId BIGINT NULL
   ,mSegmentId INT NULL
   ,IndentLevel INT NULL
   ,SpecTypeTagId INT NULL
);
--CREATE NONCLUSTERED INDEX [TMPIX_#ResultTable_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
--ON #ResultTable ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--2.Lookup SpecTypeTagsId Tables  
DROP TABLE IF EXISTS #SpecTypeTagIdTable
CREATE TABLE #SpecTypeTagIdTable (
	SpecTypeTagId INT
);

--3.Distinct SegmentStatus from Links tables  
DROP TABLE IF EXISTS #DistinctSegmentStatus
CREATE TABLE #DistinctSegmentStatus (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SegmentStatusCode BIGINT NULL
   ,SegmentSource CHAR(1) NULL
   ,SectionCode INT NULL
   ,SegmentCode BIGINT NULL
   ,IsDeleted BIT NULL
);
--CREATE NONCLUSTERED INDEX [TMPIX_#DistinctSegmentStatus_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
--ON #DistinctSegmentStatus ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--4.Section's of Project table  
DROP TABLE IF EXISTS #SectionsTable
CREATE TABLE #SectionsTable (
	SectionId INT NULL
   ,SectionCode INT NULL
);
--CREATE NONCLUSTERED INDEX [TMPIX_#SectionsTable_SectionCode]
--ON #SectionsTable ([SectionCode])

--5.All Src and Tgt Links Table  
DROP TABLE IF EXISTS #SegmentLinksTable
CREATE TABLE #SegmentLinksTable (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SourceSectionCode INT NULL
   ,SourceSegmentStatusCode BIGINT NULL
   ,SourceSegmentCode BIGINT NULL
   ,SourceSegmentChoiceCode BIGINT NULL
   ,SourceChoiceOptionCode BIGINT NULL
   ,LinkSource NVARCHAR(MAX) NULL
   ,TargetSectionCode INT NULL
   ,TargetSegmentStatusCode BIGINT NULL
   ,TargetSegmentCode BIGINT NULL
   ,TargetSegmentChoiceCode BIGINT NULL
   ,TargetChoiceOptionCode BIGINT NULL
   ,LinkTarget NVARCHAR(MAX) NULL
   ,LinkStatusTypeId INT NULL
   ,SegmentLinkCode BIGINT NULL
   ,SegmentLinkSourceTypeId INT NULL
   ,IsSrcLink INT NULL
   ,IsTgtLink INT NULL
   ,IsDeleted BIT NULL
);

--INSERT SEGMENT STATUS IN THIS LIST  
INSERT INTO #ResultTable (ProjectId, SectionId, CustomerId, SegmentStatusCode,
SequenceNumber, SegmentCode, SegmentDescription, SegmentSource, SectionCode,
SrcLinksCnt, TgtLinksCnt, SegmentStatusId, SegmentId, mSegmentId, IndentLevel, SpecTypeTagId)
	SELECT
		PSSTV.ProjectId
	   ,PSSTV.SectionId
	   ,PSSTV.CustomerId
	   ,PSSTV.SegmentStatusCode
	   ,PSSTV.SequenceNumber
	   ,PSSTV.SegmentCode
	   ,PSSTV.SegmentDescription
	   ,CAST(PSSTV.SegmentOrigin AS CHAR(1)) AS SegmentSource
	   ,PSSTV.SectionCode
	   ,0 AS SrcLinksCnt
	   ,0 AS TgtLinksCnt
	   ,PSSTV.SegmentStatusId
	   ,PSSTV.SegmentId
	   ,PSSTV.mSegmentId
	   ,PSSTV.IndentLevel
	   ,(CASE
			WHEN PSSTV.SpecTypeTagId IS NOT NULL THEN PSSTV.SpecTypeTagId
			ELSE 0
		END) AS SpecTypeTagId
	FROM ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	WHERE PSSTV.ProjectId = @PProjectId
	AND PSSTV.SectionId = @PSectionId
	AND PSSTV.CustomerId = @PCustomerId
	AND ISNULL(PSSTV.IsDeleted, 0) = 0

-- To get SpecTypeTagId when entitlement is Outline/ShortForm
DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(10));                
 IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                                  
 BEGIN                                  
  INSERT INTO @CatalogueTypeTbl (TagType)                 
  SELECT splitdata AS TagType FROM fn_SplitString(@PCatalogueType, ',');                
                                  
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'OL')                                  
  BEGIN                                  
   INSERT INTO @CatalogueTypeTbl VALUES ('UO')                                  
  END                                  
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'SF')                                  
  BEGIN                                  
   INSERT INTO @CatalogueTypeTbl VALUES ('US')                                  
  END                                  
 END 

--REMOVE THOSE TO WHOME THERE IS DO NOT HAVE ACCESS DEPENDS UPON CATALOGUE TYPE  
IF @PCatalogueType != 'FS'
BEGIN
INSERT INTO #SpecTypeTagIdTable (SpecTypeTagId)
	SELECT
		SpecTypeTagId
	FROM LuProjectSpecTypeTag WITH (NOLOCK)
	WHERE TagType IN (select TagType from @CatalogueTypeTbl);
	--WHERE TagType IN (SELECT * FROM dbo.fn_SplitString(@PCatalogueType, ','));

DELETE RT
	FROM #ResultTable RT
WHERE RT.SpecTypeTagId NOT IN (SELECT
			TBL.SpecTypeTagId
		FROM #SpecTypeTagIdTable TBL)
END

--TODO--BELOW CODE NEED TO BE MOVE IN COMMON SP  
--INSERT SOURCE AND TARGET LINKS FROM PROJECT DB  
INSERT INTO #SegmentLinksTable (ProjectId, CustomerId,
SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode,
TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId,
IsSrcLink, IsTgtLink, SegmentLinkSourceTypeId, IsDeleted, SegmentLinkCode)
	--INSERT SOURCE LINKS FROM PROJECT DB  
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
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
	   ,1 AS IsSrcLink
	   ,0 AS IsTgtLink
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.IsDeleted
	   ,PSLNK.SegmentLinkCode
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #ResultTable INPJSON WITH (NOLOCK)
		ON PSLNK.TargetSectionCode = INPJSON.SectionCode
			AND PSLNK.TargetSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.TargetSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkTarget = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.SegmentLinkSourceTypeId IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)
	AND ISNULL(PSLNK.IsDeleted, 0) = 0
	UNION
	--INSERT TARGET LINKS FROM PROJECT DB  
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
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
	   ,0 AS IsSrcLink
	   ,1 AS IsTgtLink
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.IsDeleted
	   ,PSLNK.SegmentLinkCode
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #ResultTable INPJSON WITH (NOLOCK)
		ON PSLNK.SourceSectionCode = INPJSON.SectionCode
			AND PSLNK.SourceSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.SourceSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkSource = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.SegmentLinkSourceTypeId IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)
	AND ISNULL(PSLNK.IsDeleted, 0) = 0

--FETCH SECTIONS OF PROJECT IN TEMP TABLE  
INSERT INTO #SectionsTable (SectionId, SectionCode)
	SELECT
		PS.SectionId
	   ,PS.SectionCode
	FROM ProjectSection PS WITH (NOLOCK)
	WHERE PS.ProjectId = @PProjectId
	AND PS.CustomerId = @PCustomerId
	AND PS.IsLastLevel = 1
	AND ISNULL(PS.IsDeleted, 0) = 0

--DELETE THOSE LINKS WHOSE LINK SOURCE TYPE IS NOT MASTER OR USER  
--DELETE FROM #SegmentLinksTable  
--WHERE SegmentLinkSourceTypeId NOT IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)  

--DELETE WHICH ARE SOFT DELETED IN DB  
--DELETE FROM #SegmentLinksTable  
--WHERE IsDeleted = 1  

--DELETE SOURCE LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT  
DELETE SLNK
	FROM #SegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.SourceSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--DELETE TARGET LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT  
DELETE SLNK
	FROM #SegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.TargetSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--FETCH DISTINCT SEGMENT STATUS CODE  
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
		FROM #SegmentLinksTable SLNKS UNION
		SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.TargetSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.TargetSectionCode AS SectionCode
		FROM #SegmentLinksTable SLNKS) AS X

UPDATE DSTSG
SET DSTSG.SegmentCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentCode
	END)
   ,DSTSG.SegmentSource = CAST((CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentOrigin
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentOrigin
	END) AS CHAR(1))
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
	ON DSTSG.ProjectId = PSSTV.ProjectId
	AND DSTSG.CustomerId = PSSTV.CustomerId
	AND DSTSG.SectionCode = PSSTV.SectionCode
	AND DSTSG.SegmentStatusCode = PSSTV.SegmentStatusCode
	AND ISNULL(PSSTV.IsDeleted, 0) = 0

LEFT JOIN SLCMaster..SegmentStatusView MSSTV WITH (NOLOCK)
	ON DSTSG.SegmentStatusCode = MSSTV.SegmentStatusCode
	AND ISNULL(MSSTV.IsDeleted, 0) = 0

--DELETE UNMATCHED SEGMENT CODE IN SRC AND TGT LINKS AS WELL  
DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.SourceSectionCode = DSST.SectionCode
		AND SLNK.SourceSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.SourceSegmentCode = DSST.SegmentCode
		AND SLNK.LinkSource = DSST.SegmentSource
WHERE (SLNK.IsSrcLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.TargetSectionCode = DSST.SectionCode
		AND SLNK.TargetSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.TargetSegmentCode = DSST.SegmentCode
		AND SLNK.LinkTarget = DSST.SegmentSource
WHERE (SLNK.IsTgtLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @PProjectId
		AND SCHV.CustomerId = @PCustomerId
		AND SLNK.SourceSectionCode = SCHV.SectionCode
		AND SLNK.SourceSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.SourceSegmentCode = SCHV.SegmentCode
		AND SLNK.SourceSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.SourceChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkSource = SCHV.ChoiceOptionSource
WHERE SCHV.ProjectId = @PProjectId
	AND SCHV.SectionId = @PSectionId
	AND SLNK.IsSrcLink = 1
	AND ISNULL(SLNK.SourceSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.SourceChoiceOptionCode, 0) > 0
	AND SLNK.LinkSource = 'U'
	AND SCHV.SegmentStatusId IS NULL

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @PProjectId
		AND SCHV.CustomerId = @PCustomerId
		AND SLNK.TargetSectionCode = SCHV.SectionCode
		AND SLNK.TargetSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.TargetSegmentCode = SCHV.SegmentCode
		AND SLNK.TargetSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.TargetChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkTarget = SCHV.ChoiceOptionSource
WHERE SCHV.ProjectId = @PProjectId
	AND SCHV.SectionId = @PSectionId
	AND SLNK.IsTgtLink = 1
	AND ISNULL(SLNK.TargetSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.TargetChoiceOptionCode, 0) > 0
	AND SLNK.LinkTarget = 'U'
	AND SCHV.SegmentStatusId IS NULL

--UPDATE TGT LINKS COUNT  
UPDATE TBL
SET TBL.TgtLinksCnt = X.TgtLinksCnt
FROM #ResultTable TBL
INNER JOIN (SELECT
		SourceSegmentStatusCode
	   ,LinkSource
	   ,COUNT(1) AS TgtLinksCnt
	FROM #SegmentLinksTable
	WHERE IsTgtLink = 1
	GROUP BY SourceSegmentStatusCode
			,LinkSource
			,IsTgtLink) X
	ON TBL.SegmentStatusCode = X.SourceSegmentStatusCode
	AND TBL.SegmentSource = X.LinkSource

--UPDATE SRC LINKS COUNT  
UPDATE TBL
SET TBL.SrcLinksCnt = X.SrcLinksCnt
FROM #ResultTable TBL
INNER JOIN (SELECT
		TargetSegmentStatusCode
	   ,LinkTarget
	   ,COUNT(1) AS SrcLinksCnt
	FROM #SegmentLinksTable
	WHERE IsSrcLink = 1
	GROUP BY TargetSegmentStatusCode
			,LinkTarget
			,IsSrcLink) X
	ON TBL.SegmentStatusCode = X.TargetSegmentStatusCode
	AND TBL.SegmentSource = X.LinkTarget

--DELETE UNWANTED RECORDS FROM RESULT LINKS TABLE  
DELETE FROM #ResultTable
WHERE SrcLinksCnt <= 0
	AND TgtLinksCnt <= 0

SELECT * FROM #ResultTable WITH (NOLOCK)
ORDER BY SequenceNumber ASC

--FETCH CHOICE LIST  
--DROP TABLE IF EXISTS #t  

SELECT
	t.SegmentStatusCode
   ,psc.SegmentChoiceCode
   ,CAST(pco.OptionJson AS NVARCHAR(MAX)) AS OptionJson
   ,psc.ChoiceTypeId
   ,pco.ChoiceOptionCode
   ,pco.SortOrder
   ,CAST(0 AS BIT) AS IsSelected INTO #t
FROM ProjectSegmentChoice psc WITH (NOLOCK)
INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
	ON psc.SegmentChoiceId = pco.SegmentChoiceId
		AND pco.ProjectId = @PProjectId
		AND pco.SectionId = @PSectionId
INNER JOIN #ResultTable t
	ON t.mSegmentId = psc.SegmentId
WHERE psc.ProjectId = @PProjectId
AND psc.CustomerId = @PCustomerId
AND psc.SectionId = @PSectionId;


INSERT INTO #t
	SELECT
		t.SegmentStatusCode
	   ,sc.SegmentChoiceCode
	   ,CAST(co.OptionJson AS NVARCHAR(MAX)) AS OptionJson
	   ,sc.ChoiceTypeId
	   ,co.ChoiceOptionCode
	   ,co.SortOrder
	   ,CAST(0 AS BIT) AS IsSelected
	FROM SLCMaster..SegmentChoice sc WITH (NOLOCK)
	INNER JOIN SLCMaster..ChoiceOption co WITH (NOLOCK)
		ON sc.SegmentChoiceId = co.SegmentChoiceId
	INNER JOIN #ResultTable t
		ON t.mSegmentId = sc.SegmentId;

INSERT INTO #t
	SELECT
		t.SegmentStatusCode
	   ,psc.SegmentChoiceCode
	   ,CAST(pco.OptionJson AS NVARCHAR(MAX)) AS OptionJson
	   ,psc.ChoiceTypeId
	   ,pco.ChoiceOptionCode
	   ,pco.SortOrder
	   ,CAST(0 AS BIT) AS IsSelected
	FROM #ResultTable t
	INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
		ON t.SegmentStatusId = psc.SegmentStatusId
	INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
		ON psc.SegmentChoiceId = pco.SegmentChoiceId
			AND pco.ProjectId = @PProjectId
			AND pco.SectionId = @PSectionId
	WHERE psc.ProjectId = @PProjectId
	AND psc.CustomerId = @PCustomerId
	AND psc.SectionId = @PSectionId
	AND ISNULL(pco.IsDeleted, 0) = 0;

SELECT	* FROM #t;

--UPDATE t
--SET t.IsSelected = sco.IsSelected
--FROM #t t
--INNER JOIN SelectedChoiceOption sco WITH (NOLOCK)
--	ON t.ChoiceOptionCode = sco.ChoiceOptionCode
--WHERE sco.SectionId = @SectionId
--AND ISNULL(sco.IsDeleted, 0) = 0
--AND sco.IsSelected = 1

--SELECT  
-- RT.SegmentStatusCode  
--   ,SCHV.SegmentChoiceCode  
--   ,SCHV.ChoiceOptionCode  
--   ,SCHV.SortOrder  
--   ,SCHV.IsSelected  
--   ,SCHV.OptionJson  
--   ,SCHV.ChoiceTypeId  
--FROM SegmentChoiceView SCHV WITH (NOLOCK)  
--INNER JOIN #ResultTable RT WITH (NOLOCK)  
-- ON SCHV.SegmentStatusId = RT.SegmentStatusId  
--WHERE SCHV.ProjectId = @PProjectId  
--AND SCHV.CustomerId = @PCustomerId  
--AND SCHV.SectionId = @PSectionId  
--AND SCHV.IsSelected = 1  

----Fetch SECTION LIST  
--SELECT
--	PS.SectionCode
--   ,PS.SourceTag
--   ,PS.[Description] AS Description
--FROM ProjectSection PS WITH (NOLOCK)
--WHERE PS.ProjectId = @PProjectId
--AND PS.CustomerId = @PCustomerId
--AND PS.IsLastLevel = 1
--UNION
--SELECT
--	MS.SectionCode
--   ,MS.SourceTag
--   ,CAST(MS.Description AS NVARCHAR(500)) AS Description
--FROM SLCMaster..Section MS WITH (NOLOCK)
--LEFT JOIN ProjectSection PS WITH (NOLOCK)
--	ON PS.ProjectId = @PProjectId
--		AND PS.CustomerId = @PCustomerId
--		AND PS.mSectionId = MS.SectionId
--WHERE MS.MasterDataTypeId = @PMasterDataTypeId
--AND MS.IsLastLevel = 1
--AND PS.SectionId IS NULL
END
GO


