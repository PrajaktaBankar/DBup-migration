CREATE PROCEDURE [dbo].[usp_SpecDataSetSegmentChoiceOption]
(  
   @SegmentStatusJson NVARCHAR(max)  
)  
AS  
BEGIN

DECLARE @TempMappingtable TABLE (  
 ProjectId INT  
   ,CustomerId INT  
   ,mSectionId INT  
   ,SegmentChoiceId BIGINT  
   ,ChoiceOptionId BIGINT  
   ,SegmentStatusId BIGINT  
   ,OptionJson nvarchar(MAX)  
   ,RowId INT ,
    SectionId INT   
)

INSERT INTO @TempMappingtable
	SELECT DISTINCT
		*
	   ,0
	   ,0

	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	mSectionId INT '$.SectionId',
	SegmentChoiceId BIGINT '$.SegmentChoiceId',
	ChoiceOptionId BIGINT '$.ChoiceOptionId'
	, SegmentStatusId BIGINT '$.SegmentStatusId'
	, OptionJson NVARCHAR(MAX) '$.OptionJson'
	);

DECLARE @CustomerId INT = 0;
DECLARE @ProjectId INT = 0;

SELECT TOP 1
	@CustomerId = CustomerId
   ,@ProjectId = ProjectId
FROM @TempMappingtable


UPDATE tmp
SET tmp.SectionId = ps.SectionId
FROM @TempMappingtable tmp
INNER JOIN ProjectSection ps With(NOLOCK)
	ON ps.mSectionId = tmp.mSectionId
	AND tmp.ProjectId = ps.ProjectId
	AND tmp.CustomerId = ps.CustomerId


DECLARE @SingleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,mSectionId INT
   ,SegmentChoiceId BIGINT
   ,ChoiceOptionId BIGINT
   ,SegmentStatusId BIGINT
   ,OptionJson NVARCHAR(MAX)
)

SELECT DISTINCT
	slcmsc.ChoiceTypeId
   ,slcmsc.SectionId
   ,slcmsc.SegmentChoiceCode
   ,slcmsc.SegmentStatusId
   ,slcmsc.SegmentChoiceId INTO #SlcMasterChoiceTempTable
FROM SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)
INNER JOIN @TempMappingtable TMT
	ON slcmsc.SectionId = TMT.mSectionId
		AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceId 
		AND slcmsc.SegmentStatusId = TMT.SegmentStatusId


INSERT INTO @SingleSelectionChoiceTable (ProjectId, CustomerId, mSectionId, SegmentChoiceId,
ChoiceOptionId, SegmentStatusId, OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.mSectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
	FROM #SlcMasterChoiceTempTable slcmsc
	INNER JOIN @TempMappingtable TMT
		ON slcmsc.SectionId = TMT.mSectionId
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
			AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceId
			AND slcmsc.ChoiceTypeId = 1

DECLARE @SingleSelectionFinalChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,mSectionId INT
   ,SegmentChoiceId BIGINT
   ,ChoiceOptionId BIGINT
   ,SegmentStatusId BIGINT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @SingleSelectionFinalChoiceTable
	SELECT
		ProjectId
	   ,CustomerId
	   ,mSectionId
	   ,SegmentChoiceId
	   ,ChoiceOptionId
	   ,SegmentStatusId
	   ,OptionJson
	FROM (SELECT
			*
		   ,ROW_NUMBER() OVER (PARTITION BY SegmentChoiceId ORDER BY ChoiceOptionId DESC) AS RowNo
		FROM @SingleSelectionChoiceTable) AS X
	WHERE X.RowNo = 1

DECLARE @MultipleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,mSectionId INT
   ,SegmentChoiceId BIGINT
   ,ChoiceOptionId BIGINT
   ,SegmentStatusId BIGINT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @MultipleSelectionChoiceTable (ProjectId, CustomerId, mSectionId, SegmentChoiceId,
ChoiceOptionId, SegmentStatusId, OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.mSectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
	FROM #SlcMasterChoiceTempTable slcmsc
	INNER JOIN @TempMappingtable TMT
		ON slcmsc.SectionId = TMT.mSectionId
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
			AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceId
			AND slcmsc.ChoiceTypeId > 1

DROP TABLE IF EXISTS #ChoiceTempTable

SELECT DISTINCT
	SectionId
   ,ProjectId
   ,CustomerId INTO #SectionTbl
FROM @TempMappingtable

SELECT
	SCO.SelectedChoiceOptionId
   ,SCO.SegmentChoiceCode
   ,SCO.ChoiceOptionCode
   ,SCO.ProjectId
   ,SCO.CustomerId
   ,SCO.SectionId
   ,0 AS IsSelected
   ,SCO.OptionJson INTO #TempSelectedChoiceOption
FROM #SectionTbl t
INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)
	ON t.SectionId = SCO.SectionId
		AND SCO.ProjectId = t.ProjectId
		AND SCO.CustomerId = t.CustomerId
		AND SCO.ChoiceOptionSource = 'M'
		AND ISNULL(SCO.IsDeleted,0)=0
WHERE SCO.ProjectId = @ProjectId
AND SCO.CustomerId = @CustomerId

SELECT DISTINCT
	SCO.SelectedChoiceOptionId
   ,SCO.SegmentChoiceCode
   ,SCO.ChoiceOptionCode
   ,SCO.ProjectId
   ,SCO.CustomerId
   ,SCO.SectionId
   ,SCO.IsSelected
   ,SCO.OptionJson
   ,TMTBL.mSectionId INTO #ChoiceTempTable
FROM @TempMappingtable TMTBL
INNER JOIN #TempSelectedChoiceOption SCO 
	ON SCO.SectionId = TMTBL.SectionId
		AND SCO.ProjectId = TMTBL.ProjectId
		AND SCO.CustomerId = TMTBL.CustomerId
		AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
WHERE SCO.ProjectId = @ProjectId
AND SCO.CustomerId = @CustomerId


IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @SingleSelectionChoiceTable)
	> 0)
BEGIN

UPDATE SCO
SET SCO.IsSelected = 1
   ,SCO.OptionJson = IIF(TMTBL.OptionJson = '', NULL, TMTBL.OptionJson)
FROM #ChoiceTempTable SCO
INNER JOIN @SingleSelectionFinalChoiceTable TMTBL
	ON TMTBL.mSectionId = SCO.mSectionId
	AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId

END

IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @MultipleSelectionChoiceTable)
	> 0)
BEGIN
UPDATE SCO
SET SCO.IsSelected = 1
   ,SCO.OptionJson = IIF(TMTBL.OptionJson = '', NULL, TMTBL.OptionJson)
FROM #ChoiceTempTable SCO WITH (NOLOCK)
INNER JOIN @MultipleSelectionChoiceTable TMTBL
	ON TMTBL.mSectionId = SCO.mSectionId
	AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId

END

UPDATE SCO  
SET SCO.IsSelected = CHT.IsSelected  
   ,SCO.OptionJson = CHT.OptionJson  
FROM #ChoiceTempTable CHT  
INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)  
 ON SCO.SelectedChoiceOptionId = CHT.SelectedChoiceOptionId  
WHERE SCO.SectionId = CHT.SectionId  
AND SCO.ProjectId = @ProjectId  
AND SCO.CustomerId = @CustomerId  

END
GO


