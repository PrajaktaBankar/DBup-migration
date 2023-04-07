-- Execute on server 03
-- Customer Support 31209: Deadline Dec. 3! {CH#} Issue in Project "302014 RMLEI Renovation" ( CID = 33307 / Admin ID = 1596 / SERVER 3 )

DECLARE @ProjectId_1 INT = 5286;
--insert into temp table from selectedChoiceOption 
SELECT * into #temp from SelectedChoiceOption WITH (NOLOCK) where ProjectId IN(@ProjectId_1) and isdeleted = 1 

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

--(449 rows should affected) 
UPDATE B SET IsDeleted=0 FROM
(
SELECT SCO.* FROM SelectedChoiceOption SCO WITH(NOLOCK) INNER JOIN #selectedchoicetemp SCT
ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId
where SCT.ProjectId IN(@ProjectId_1)
) B

DROP table #temp	
drop table #selectedchoicetemp

GO

UPDATE sco set sco.IsDeleted = 1 
from SelectedChoiceOption sco WITH(NOLOCK) 
WHERE sco.SelectedChoiceOptionId in (499928588,499928591,499928592,499928593,385665061,385666113,386480869,457392344,499928604,499928605,499928609,499928610);