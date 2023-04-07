-- Execute on server 4
-- Customer Support 30469: Choice text changed to [CH#XXXXXX] - 18912

use [SLCProject]
DECLARE @ProjectId_1 INT = 214;

--insert into temp table from selectedChoiceOption 
SELECT * into #temp from SelectedChoiceOption WITH (NOLOCK) where ProjectId IN(@ProjectId_1) and isdeleted = 1 

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

UPDATE B SET IsDeleted=0 FROM
(
SELECT SCO.* FROM SelectedChoiceOption SCO WITH(NOLOCK) INNER JOIN #selectedchoicetemp SCT
ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId
where SCT.ProjectId IN(@ProjectId_1)
) B

DROP table #temp	
drop table #selectedchoicetemp