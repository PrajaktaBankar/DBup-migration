/*
Customer Support 42229: SLC section will not print/export
server :3

for references
------[{"OptionTypeId":2,"OptionTypeName":"UnitOfMeasure","SortOrder":1,"Value":null,"DefaultValue":null,"Id":0,"ValueJson":{"Metric":null,"English":null,"MetricEnglish":null,"EnglishMetric":null}}]
select * from ProjectSegmentStatus where SegmentStatusId=562901924 and projectid=9498
select * from SelectedChoiceOption where SegmentChoiceCode=81522 and projectid=9498 and SectionId=10017141
*/



UPDATE SCO 
 set SCO.OptionJson=Null  from  SelectedChoiceOption SCO  WITH (NOLOCK)  where SCO.SelectedChoiceOptionId=1239717170 and SCO.SegmentChoiceCode=81522 and SCO.projectid=9498 and SCO.SectionId=10017141

