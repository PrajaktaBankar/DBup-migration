--Scenario : Data is available in ProjectSegmentChoice and ProjectChoiceOption but deleted=true From SelectedChoiceOption  

--Execute this on Server 2	
--Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275

DECLARE @ProjectId_1 INT = 3308

--insert into temp table from ProjectSegmentChoice and ModifiedDate IS NULL
SELECT * into #temp from  ProjectSegmentChoice WITH (NOLOCK) where ProjectId IN(@ProjectId_1) -- AND SectionId = 4102672
and isdeleted = 1 and ModifiedDate IS NULL

--SELECT * from #temp

SELECT t.* into #ProjectSegmentChoicetemp
FROM #temp t INNEr JOIN
ProjectChoiceOption PCO WITH (NOLOCK)
ON t.ProjectId = pco.ProjectId
and t.CustomerId=pco.CustomerId
and t.SectionId = pco.SectionId 
AND t.SegmentChoiceId = PCO.SegmentChoiceId
INNER JOIN SelectedChoiceOption SCO  WITH (NOLOCK)
ON SCO.ProjectId = PCO.ProjectId
and SCO.CustomerId=PCO.CustomerId
and SCO.SectionId = PCO.SectionId 
AND SCO.ChoiceOptionCode = PCO.ChoiceOptionCode
Where PCO.IsDeleted=0 and SCO.IsDeleted=0


--SELECT* from #ProjectSegmentChoicetemp 

--(1 Row Affected)
UPDATE  B SET IsDeleted=0 FROM
(
SELECT PSC.* FROM ProjectSegmentChoice PSC WITH (NOLOCK) 
INNER JOIN #ProjectSegmentChoicetemp t
ON t.SegmentChoiceId = PSC.SegmentChoiceId
where t.ProjectId IN(@ProjectId_1)
) B

DROP table  #temp	
drop table #ProjectSegmentChoicetemp