USE SLCProject
GO
--Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275
--execute on server 02
DROP TABLE IF EXISTS #duplicateChoiceOptions

SELECT
	* INTO #duplicateChoiceOptions
FROM (SELECT
		ROW_NUMBER() OVER (PARTITION BY pco.SegmentChoiceId, SortOrder, pco.ProjectId, pco.SectionId ORDER BY ChoiceOptionCode ASC) AS rowid
	   ,ChoiceOptionId
	   ,ChoiceOptionCode
	   ,pco.ProjectId
	   ,pco.SectionId
	   ,pco.CustomerId
	   ,psc.SegmentChoiceCode
	FROM ProjectChoiceOption pco WITH (NOLOCK)
	INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
		ON psc.SegmentChoiceId = pco.SegmentChoiceId
	WHERE pco.ProjectId = 5026) AS X
WHERE X.rowid > 1


UPDATE pco SET pco.IsDeleted=1
FROM ProjectChoiceOption pco WITH (NOLOCK)
INNER JOIN #duplicateChoiceOptions dpco
	ON pco.ChoiceOptionId = dpco.ChoiceOptionId
		AND pco.ChoiceOptionCode = dpco.ChoiceOptionCode
		AND pco.SectionId = dpco.SectionId
		AND pco.ProjectId = dpco.ProjectId
		AND pco.CustomerId = dpco.CustomerId

UPDATE sco SET sco.IsDeleted=1
FROM SelectedChoiceOption sco WITH (NOLOCK)
INNER JOIN #duplicateChoiceOptions dpco
	ON sco.ChoiceOptionCode = dpco.ChoiceOptionCode
		AND sco.SegmentChoiceCode = dpco.SegmentChoiceCode
		AND sco.SectionId = dpco.SectionId
		AND sco.ProjectId = dpco.ProjectId
		AND sco.CustomerId = dpco.CustomerId

 