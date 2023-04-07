/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 57559: {CH# - Karen Aldrich with Gresham Smith - 21628

 */

DROP TABLE IF EXISTS #ProjectSegmentChoice
DROP TABLE IF EXISTS #ProjectChoiceOption
DROP TABLE IF EXISTS #segmentch10106019 
DROP TABLE IF EXISTS #segmentch12852234 
DROP TABLE IF EXISTS #SelectedChoiceOption
 
select * INTO #ProjectSegmentChoice from ProjectSegmentChoice where ProjectId =8663 and CustomerId= 2626 and SegmentChoiceCode in(
 10040764
,10040765
,10040766
,10040768
,10040769
,10040770
,10040771
,10040772
,10040773)
order by SegmentChoiceCode 

select * into #ProjectChoiceOption from ProjectChoiceOption where ProjectId =8663 and CustomerId= 2626 and SegmentChoiceId IN (
SELECT SegmentChoiceId FROM #ProjectSegmentChoice) ORDER BY SectionId ,SegmentChoiceId


SELECT * into #segmentch10106019 FROM #ProjectSegmentChoice where sectionId = 10106019 order by SectionId ,SegmentChoiceCode 
SELECT * into #segmentch12852234 FROM #ProjectSegmentChoice where sectionId = 12852234 order by SectionId ,SegmentChoiceCode 
--select * from #ProjectSegmentChoice
--SELECT SCH1.SegmentChoiceId AS A_SegmentChoiceId,SCH2.SegmentChoiceId,SCH2.SECTIONID,
--PSO.* FROM  #segmentch10106019 sch1 INNER JOIN #segmentch12852234 sch2 
--on sch1.SegmentChoiceCode = sch2.SegmentChoiceCode
--INNER JOIN #ProjectChoiceOption PSO 
--ON sch1.SegmentChoiceId = PSO.SegmentChoiceId
INSERT INTO ProjectChoiceOption
SELECT 
 sch2.SegmentChoiceId
,PSO.SortOrder
,PSO.ChoiceOptionSource
,PSO.OptionJson
,PSO.ProjectId
,SCH2.SectionId
,PSO.CustomerId
,PSO.ChoiceOptionCode
,PSO.CreatedBy
,GETUTCDATE() AS CreateDate
,PSO.ModifiedBy
,GETUTCDATE() AS ModifiedDate
,PSO.A_ChoiceOptionId
,PSO.IsDeleted from #segmentch10106019 sch1 INNER JOIN #segmentch12852234 sch2 
on sch1.SegmentChoiceCode = sch2.SegmentChoiceCode
INNER JOIN #ProjectChoiceOption PSO 
ON sch1.SegmentChoiceId = PSO.SegmentChoiceId

select * into #SelectedChoiceOption from SelectedChoiceOption where ProjectId =8663 and CustomerId= 2626 and SectionId = 10106019 order by SegmentChoiceCode
--select * from #SelectedChoiceOption
INSERT INTO SelectedChoiceOption 
SELECT 
sch1.SegmentChoiceCode,PSO.ChoiceOptionCode,PSO.ChoiceOptionSource,SCP.IsSelected
,sch2.SectionId,sch2.ProjectId,sch2.CustomerId,SCP.OptionJson,SCP.IsDeleted 
--,SCP.*
FROM  #segmentch10106019 sch1 INNER JOIN #segmentch12852234 sch2 
on sch1.SegmentChoiceCode = sch2.SegmentChoiceCode
INNER JOIN #ProjectChoiceOption PSO 
ON sch1.SegmentChoiceId = PSO.SegmentChoiceId
INNER JOIN #SelectedChoiceOption SCP 
ON SCP.SegmentChoiceCode = SCH2.SegmentChoiceCode


DROP TABLE IF EXISTS #ProjectSegmentChoice
DROP TABLE IF EXISTS #ProjectChoiceOption
DROP TABLE IF EXISTS #segmentch10106019 
DROP TABLE IF EXISTS #segmentch12852234 
DROP TABLE IF EXISTS #SelectedChoiceOption