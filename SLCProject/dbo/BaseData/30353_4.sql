  --execute on server 2
 --Customer Support 30353: CH# Issues in a Project

INSERT INTO SelectedChoiceOption
SELECT 
psc.SegmentChoiceCode	,pco.ChoiceOptionCode	,pco.ChoiceOptionSource,	slcmsco.IsSelected	,pco.SectionId	,pco.ProjectId	,pco.CustomerId	,null as OptionJson	,0 as IsDeleted 
FROM ProjectChoiceOption pco WITH(NOLOCK)
INNER JOIN ProjectSegmentChoice psc WITH(NOLOCK) ON
pco.ProjectId=psc.ProjectId and pco.CustomerId=psc.CustomerId and pco.SectionId=psc.SectionId
AND pco.SegmentChoiceId=psc.SegmentChoiceId
LEFT OUTER JOIN
SelectedChoiceOption sco WITH(NOLOCK) ON sco.ChoiceOptionCode=pco.ChoiceOptionCode 
AND pco.ProjectId=sco.ProjectId AND pco.SectionId=sco.SectionId and pco.CustomerId=sco.CustomerId
AND psc.SegmentChoiceCode=sco.SegmentChoiceCode and sco.ChoiceOptionSource='U'
INNER JOIN 
SLCMaster..SelectedChoiceOption slcmsco WITH(NOLOCK) ON
slcmsco.ChoiceOptionCode=pco.ChoiceOptionCode and psc.SegmentChoiceCode=slcmsco.SegmentChoiceCode
WHERE  psc.ProjectId=4359  and psc.customerId=662 AND sco.ChoiceOptionCode IS NULL


 