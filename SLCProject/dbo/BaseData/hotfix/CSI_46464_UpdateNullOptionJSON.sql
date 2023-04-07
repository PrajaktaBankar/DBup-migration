use SLCProject

GO
/*
 Execute below script on Server 003
 Customer Support 46464: SLC cannot print/export

*/

update sco set OptionJSON = null from SelectedChoiceOption sco WITH(NOLOCK) where SectionId = 11675080
and sco.OptionJson = '[{"OptionTypeId":2,"OptionTypeName":"UnitOfMeasure","SortOrder":1,"Value":null,"DefaultValue":null,"Id":0,"ValueJson":{"Metric":null,"English":null,"MetricEnglish":null,"EnglishMetric":null}}]';