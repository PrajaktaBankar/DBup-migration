--Scenario : Data is available in ProjectSegmentChoice and ProjectChoiceOption but deleted=true From SelectedChoiceOption  


--Execute this on Server 2
--Customer Support 30056: SLC - [CH#] Errors Issue - PPL 41812

DECLARE @ProjectId_1 INT = 3188


--DROP table  #temp	
--drop table #selectedchoicetemp

--insert into temp table from selectedChoiceOption 
SELECT * into #temp from  SelectedChoiceOption WITH (NOLOCK) where ProjectId IN(@ProjectId_1) 
and isdeleted = 1 

--SELECT * from #temp

--select data from ProjectChoiceOption and ProjectSegmentChoice where isdeleted=0 and insert into #selectedchoicetemp
SELECT t.* into #selectedchoicetemp from 
ProjectChoiceOption pco WITH (NOLOCK) 
inner JOIN #temp t on t.ProjectId = pco.ProjectId
and t.CustomerId=pco.CustomerId
and t.SectionId = pco.SectionId 
and t.ChoiceOptionCode = pco.ChoiceOptionCode
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK) 
ON pco.ProjectId = psc.ProjectId
and pco.CustomerId=psc.CustomerId
and pco.SectionId = psc.SectionId
and pco.SegmentChoiceId = psc.SegmentChoiceId
where pco.IsDeleted=0 and psc.IsDeleted=0 
and psc.ProjectId IN(@ProjectId_1)
ORDER BY t.ProjectId

 --select * FROM #selectedchoicetemp 

--(194 rows affected)
UPDATE  B SET IsDeleted=0 FROM
(
SELECT SCO.* FROM SelectedChoiceOption SCO with (NOLOCK) INNER JOIN #selectedchoicetemp SCT
ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId
where SCT.ProjectId IN(@ProjectId_1)
) B
