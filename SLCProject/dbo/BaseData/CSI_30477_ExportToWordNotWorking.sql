--Execute this on Server 4--Customer Support 30477: Cannot Print Project to PDF or WordINSERT INTO SelectedChoiceOption(SegmentChoiceCode,ChoiceOptionCode,ChoiceOptionSource, IsSelected,SectionId,ProjectId,CustomerId,OptionJson,IsDeleted) VALUES ( 68013, 166498 ,'M', 1 ,242919 ,214,1431,'[{"OptionTypeId":2,"OptionTypeName":"UnitOfMeasure","SortOrder":1,"Value":null,"DefaultValue":null,"Id":0,"ValueJson":{"Metric":"of 1.2 kPa","English":"of 25 psf","MetricEnglish":"of 1.2 kPa (25 psf)","EnglishMetric":"of 25 psf (1.2 kPa)"}}]',0)
update SCO 
SET SCO.IsDeleted = 1
FROM SelectedChoiceOption SCO WITH (NOLOCK)
where SCO.SegmentChoiceCode = 68013 and SCO.ProjectId = 214 
      and SCO.SectionId = 242919 and SCO.ChoiceOptionCode= 166498 and SCO.CustomerId = 1431
