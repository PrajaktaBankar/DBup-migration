CREATE PROCEDURE [dbo].[usp_GetChoiceRSAndGTList]    
@CustomerId INT ,
@ProjectId INT ,
@SectionId INT = 0,
@choicesIds NVARCHAR (MAX),
@RSIds NVARCHAR (MAX) NULL,
@GTIds NVARCHAR (MAX) NULL

AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PchoicesIds NVARCHAR (MAX) = @choicesIds;
DECLARE @PRSIds NVARCHAR (MAX) = @RSIds;
DECLARE @PGTIds NVARCHAR (MAX) = @GTIds;

  CREATE TABLE #ProjectSegmentChoiceTemp
(
  SegmentId BIGINT,
  mSegmentId INT,
  ChoiceTypeId INT,
  ChoiceSource NVARCHAR(MAX),
  SegmentChoiceCode BIGINT,
  ChoiceOptionCode BIGINT,
  IsSelected BIT,
  ChoiceOptionSource  CHAR(1),
  OptionJson NVARCHAR(MAX),
  SortOrder INT,
  SegmentChoiceId BIGINT,
  ChoiceOptionId BIGINT,
  SelectedChoiceOptionId BIGINT
);
SELECT DISTINCT
	[Key] AS [Index]
   ,[Value] AS SegmentChoiceCode INTO #TempChoiceCode
FROM OPENJSON(@PchoicesIds)

INSERT INTO #ProjectSegmentChoiceTemp (SegmentId,
mSegmentId,
ChoiceTypeId,
ChoiceSource,
SegmentChoiceCode,
ChoiceOptionCode,
IsSelected,
ChoiceOptionSource,
OptionJson,
SortOrder,
SegmentChoiceId,
ChoiceOptionId,
SelectedChoiceOptionId)
	SELECT
		0 AS SegmentId
	   ,MCH.SegmentId AS mSegmentId
	   ,MCH.ChoiceTypeId
	   ,'M' AS ChoiceSource
	   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
	   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
	   ,PSCHOP.IsSelected
	   ,PSCHOP.ChoiceOptionSource
	   ,MCHOP.OptionJson
	   ,MCHOP.SortOrder
	   ,MCH.SegmentChoiceId
	   ,MCHOP.ChoiceOptionId
	   ,PSCHOP.SelectedChoiceOptionId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
		ON PSST.mSegmentId = MCH.SegmentId
	INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
		ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
	INNER JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
		ON MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PSCHOP.ChoiceOptionSource = 'M'
			AND PSCHOP.ProjectId = PSST.ProjectId
			AND PSCHOP.SectionId = PSST.SectionId
	INNER JOIN #TempChoiceCode T
		ON MCH.SegmentChoiceCode = T.SegmentChoiceCode
	WHERE PSST.ProjectId = @PProjectId
	AND PSST.SectionId = @PSectionId
	AND PSST.CustomerId = @PCustomerId

	--AND MCH.SegmentChoiceCode IN (SELECT
	--		SegmentChoiceCode
	--	FROM #TempChoiceCode)

	UNION

	SELECT
		PCH.SegmentId
	   ,0 AS mSegmentId
	   ,PCH.ChoiceTypeId
	   ,PCH.SegmentChoiceSource AS ChoiceSource
	   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
	   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
	   ,PSCHOP.IsSelected
	   ,PSCHOP.ChoiceOptionSource
	   ,PCHOP.OptionJson
	   ,PCHOP.SortOrder
	   ,PCH.SegmentChoiceId
	   ,PCHOP.ChoiceOptionId
	   ,PSCHOP.SelectedChoiceOptionId

	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
		ON PSST.ProjectId = PCH.ProjectId
			AND PSST.SectionId = PCH.SectionId
			AND PSST.CustomerId = PCH.CustomerId
			AND PSST.SegmentId = PCH.SegmentId
	INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
		ON PSST.ProjectId = PCH.ProjectId
			AND PSST.SectionId = PCH.SectionId
			AND PSST.CustomerId = PCH.CustomerId
			AND PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
	INNER JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
		ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
			AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource
			AND PSCHOP.ProjectId = PSST.ProjectId
			AND PSCHOP.SectionId = PSST.SectionId
	INNER JOIN #TempChoiceCode T
		ON PCH.SegmentChoiceCode = T.SegmentChoiceCode
	WHERE PSST.ProjectId = @PProjectId
	AND PSST.SectionId = @PSectionId
	AND PSST.CustomerId = @PCustomerId
	AND PSCHOP.ChoiceOptionSource = 'U'

--AND PCH.SegmentChoiceCode IN (SELECT
--		SegmentChoiceCode
--	FROM #TempChoiceCode)


--Select All used choices
SELECT
	*
FROM #ProjectSegmentChoiceTemp;

--Join with Reference Standard Master and insert into #ReferenceTemp table	   
WITH RSTemp
AS
(SELECT DISTINCT
		[Key] AS [Index]
	   ,[Value] AS RefStdCode
	FROM OPENJSON(@PRSIds))
SELECT
	RS.RefStdId
   ,RS.RefStdName
   ,RS.ReplaceRefStdId
   ,RS.IsObsolete
   ,RS.RefStdCode
   ,RefEdition.RefStdEditionId
   ,RefEdition.RefEdition
   ,RefEdition.RefStdTitle
   ,RefEdition.LinkTarget
FROM [SLCMaster].dbo.ReferenceStandard RS WITH (NOLOCK)
INNER JOIN RSTemp RST
	ON RST.RefStdCode = RS.RefStdCode
CROSS APPLY (SELECT TOP 1
		RSE.RefStdEditionId
	   ,RSE.RefEdition
	   ,RSE.RefStdTitle
	   ,RSE.LinkTarget
	FROM [SLCMaster].dbo.ReferenceStandardEdition RSE WITH (NOLOCK)
	WHERE RSE.RefStdId = RS.RefStdCode
	ORDER BY RSE.RefStdEditionId DESC) RefEdition
ORDER BY RS.RefStdName;

WITH GTTemp
AS
(SELECT DISTINCT
		[Key] AS [Index]
	   ,[Value] AS GlobalTermCode
	FROM OPENJSON(@PGTIds))
SELECT
	GT.GlobalTermId
   ,GT.mGlobalTermId
   ,GT.ProjectId
   ,GT.CustomerId
   ,GT.Name
   ,GT.value
   ,GT.GlobalTermSource
   ,GT.GlobalTermCode
   ,GT.CreatedDate
   ,GT.CreatedBy
   ,GT.ModifiedDate
   ,GT.ModifiedBy
   ,GT.SLE_GlobalChoiceID
   ,GT.UserGlobalTermId
   ,GT.IsDeleted
   ,GT.A_GlobalTermId
   ,GT.GlobalTermFieldTypeId
   ,GT.OldValue
FROM GTTemp
INNER JOIN [ProjectGlobalTerm] AS GT WITH (NOLOCK)
	ON GTTemp.GlobalTermCode = GT.GlobalTermCode
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId


END
GO


