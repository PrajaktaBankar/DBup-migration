--Execute on Server 4
--Customer Support 30477: Cannot Print Project to PDF or Word
USE SLCProject
GO

drop table if exists #TempSelectedChoiceOption;

SELECT *  into #TempSelectedChoiceOption FROM SelectedChoiceOption WITH (NOLOCK) WHERE OptionJson like '%Metric":null,"English":null,"MetricEnglish":null,"EnglishMetric":null%' and ChoiceOptionSource='M'

UPDATE SCO SET OptionJson=NULL  FROM SelectedChoiceOption SCO WITH (NOLOCK) INNER JOIN #TempSelectedChoiceOption TSCO
ON SCO.SelectedChoiceOptionId=TSCO.SelectedChoiceOptionId AND SCO.ChoiceOptionCode=TSCO.ChoiceOptionCode AND SCO.SegmentChoiceCode=TSCO.SegmentChoiceCode
AND SCO.ProjectId=TSCO.ProjectId AND SCO.SectionId=TSCO.SectionId AND SCO.CustomerId=TSCO.CustomerId and SCO.ChoiceOptionSource='M'

DROP TABLE #TempSelectedChoiceOption;