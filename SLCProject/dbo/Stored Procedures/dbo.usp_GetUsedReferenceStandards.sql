
CREATE PROCEDURE [dbo].[usp_GetUsedReferenceStandards] (
@ProjectId INT,
@SectionId INT,
@CustomerId INT,
@MasterDataTypeId INT = NULL
) AS 
BEGIN

DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;

if(@PMasterDataTypeId in(2,3))
BEGIN
SET @PMasterDataTypeId = 1
END

DECLARE @mSectionid int = ( SELECT
top 1 mSectionId
FROM ProjectSection WITH (NOLOCK)
WHERE SectionId = @PSectionId)

CREATE TABLE #TmpRefStd (
RefStdId INT NULL
,RefStdName NVARCHAR(MAX) NULL
,ReplaceRefStdId INT NULL
,IsObsolete BIT
,RefStdCode INT
,RefStdEditionId INT
,RefEdition NVARCHAR(255)
,RefStdTitle NVARCHAR(1024)
,LinkTarget NVARCHAR(1024)
,RefStdSource CHAR(1)
) --SELECT * INTO #TmpRefStd FROM (

SELECT DISTINCT	MAX(RefStdEditionId) AS RefStdEditionId,
RefStdId
INTO #TM FROM SLCMaster.dbo.ReferenceStandardEdition  WITH (NOLOCK)
GROUP BY RefStdId


INSERT INTO #TmpRefStd
SELECT
MREF.RefStdId
,MREF.RefStdName
,ISNULL(MREF.ReplaceRefStdId, 0) AS ReplaceRefStdId
,MREF.IsObsolete
,MREF.RefStdCode
,M.RefStdEditionId
,M.RefEdition
,M.RefStdTitle
,M.LinkTarget
,CAST('M' AS CHAR(1)) AS RefStdSource
FROM SLCMaster.dbo.ReferenceStandard MREF WITH (NOLOCK)
--OUTER APPLY (SELECT
--	TOP 1
--	ISNULL(MREFEDN.RefStdEditionId, 0) AS RefStdEditionId
--	,MREFEDN.RefEdition
--	,MREFEDN.RefStdTitle
--	,MREFEDN.LinkTarget
--	FROM SLCMaster.dbo.ReferenceStandardEdition MREFEDN WITH (NOLOCK)
--	WHERE MREFEDN.RefStdId = MREF.RefStdId
--	ORDER BY MREFEDN.RefStdEditionId DESC) 
LEFT JOIN #TM T
ON T.RefStdId = MREF.RefStdId
LEFT JOIN SLCMaster.dbo.ReferenceStandardEdition M WITH (NOLOCK)
ON T.RefStdId=M.RefStdId AND T.RefStdEditionId=M.RefStdEditionId
WHERE MREF.MasterDataTypeId = @PMasterDataTypeId
--OPTION (FORCE ORDER) --NOW UPDATE EDITION ID ACCORDING TO ProjectReferenceStandard

--MasterRefStd
SELECT PRSTD.RefStandardId,
EDN.RefStdEditionId,
EDN.RefEdition,
EDN.RefStdTitle,
EDN.LinkTarget INTO #masterRefStd 
FROM ProjectReferenceStandard PRSTD WITH (NOLOCK) 
INNER JOIN SLCMaster.dbo.ReferenceStandardEdition EDN WITH (NOLOCK)
ON PRSTD.RefStdEditionId = EDN.RefStdEditionId
WHERE PRSTD.CustomerId = @PCustomerId
AND PRSTD.ProjectId = @PProjectId
AND PRSTD.IsDeleted = 0

UPDATE TMP
SET TMP.RefStdEditionId = PRSTD.RefStdEditionId
,TMP.RefEdition = PRSTD.RefEdition
,TMP.RefStdTitle = PRSTD.RefStdTitle
,TMP.LinkTarget = PRSTD.LinkTarget
FROM #TmpRefStd TMP
INNER JOIN #masterRefStd PRSTD WITH (NOLOCK)
ON TMP.RefStdId = PRSTD.RefStandardId
--AND PRSTD.ProjectId = @PProjectId --AND PRSTD.SectionId = @PSectionId
--AND PRSTD.CustomerId = @PCustomerId
--AND TMP.RefStdSource = 'M'
--INNER JOIN SLCMaster.dbo.ReferenceStandardEdition EDN WITH (NOLOCK)
--	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId --AND EDN.MasterDataTypeId=@PMasterDataTypeId
WHERE TMP.RefStdSource = 'M'

--AND PRSTD.CustomerId = @PCustomerId
--AND PRSTD.ProjectId = @PProjectId
--AND PRSTD.IsDeleted = 0

IF EXISTS (SELECT
--COUNT(DISTINCT PS.SectionId)
top 1 1
FROM SLCMaster.dbo.SegmentReferenceStandard SRS WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
ON SRS.SectionId = PS.mSectionId
WHERE PS.ProjectId = @PProjectId
AND ps.IsDeleted = 0
AND ps.IsLastLevel = 1
AND ps.SectionId = @PSectionId)
BEGIN

SELECT DISTINCT	MAX(RefStdEditionId) AS RefStdEditionId,
RefStdId
INTO #TP FROM ReferenceStandardEdition WITH (NOLOCK)
GROUP BY RefStdId



--INSERT INTO #TmpRefStd
SELECT
PREF.RefStdId
,PREF.RefStdName
,ISNULL(PREF.ReplaceRefStdId, 0) AS ReplaceRefStdId
,PREF.IsObsolete
,PREF.RefStdCode
,U.RefStdEditionId
,U.RefEdition
,U.RefStdTitle
,U.LinkTarget
,CAST('U' AS CHAR(1)) AS RefStdSource
into #tmpRefStdPrj FROM ReferenceStandard PREF WITH (NOLOCK)
--CROSS APPLY (SELECT
--	TOP 1
--	ISNULL(PREFEDN.RefStdEditionId, 0) AS RefStdEditionId
--	,PREFEDN.RefEdition
--	,PREFEDN.RefStdTitle
--	,PREFEDN.LinkTarget
--	FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)
--	WHERE PREFEDN.RefStdId = PREF.RefStdId
--	ORDER BY PREFEDN.RefStdEditionId DESC) AS U
LEFT JOIN #TP T WITH (NOLOCK)
ON T.RefStdId= PREF.RefStdId
LEFT JOIN ReferenceStandardEdition U WITH (NOLOCK)
ON T.RefStdId= U.RefStdId AND T.RefStdEditionId=U.RefStdEditionId
WHERE PREF.CustomerId = @PCustomerId
OPTION (FORCE ORDER)


--ProjectRefStd

SELECT PRSTD.RefStdEditionId,EDN.RefEdition,EDN.RefStdTitle,EDN.LinkTarget,PRSTD.RefStandardId
into #prjRefStd FROM ProjectReferenceStandard PRSTD WITH (NOLOCK)
INNER JOIN ReferenceStandardEdition EDN WITH (NOLOCK)
ON PRSTD.RefStdEditionId = EDN.RefStdEditionId
WHERE PRSTD.CustomerId = @PCustomerId
AND PRSTD.ProjectId = @PProjectId
AND PRSTD.IsDeleted = 0


UPDATE TMP
SET TMP.RefStdEditionId = PRSTD.RefStdEditionId
,TMP.RefEdition = PRSTD.RefEdition
,TMP.RefStdTitle = PRSTD.RefStdTitle
,TMP.LinkTarget = PRSTD.LinkTarget
FROM #tmpRefStdPrj TMP WITH (NOLOCK)
INNER JOIN #prjRefStd PRSTD WITH (NOLOCK)
ON TMP.RefStdId = PRSTD.RefStandardId
WHERE TMP.RefStdSource = 'U'

insert into #TmpRefStd
select * from #tmpRefStdPrj WITH (NOLOCK)

END

SELECT
RefStdId
,ISNULL(RefStdName,'') AS RefStdName
,ISNULL(ReplaceRefStdId,0) AS ReplaceRefStdId
,ISNULL(IsObsolete,0) AS IsObsolete
,ISNULL(RefStdCode,0) AS RefStdCode
,ISNULL(RefStdEditionId,0) AS RefStdEditionId
,ISNULL(RefEdition,'') AS RefEdition
,ISNULL(RefStdTitle,'') AS RefStdTitle
,ISNULL(LinkTarget,'') AS LinkTarget
,ISNULL(RefStdSource,'M') AS RefStdSource
FROM #TmpRefStd WITH (NOLOCK)
END