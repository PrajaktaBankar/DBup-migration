USE SLCProject
GO

--Customer Support 31795: Missing Choices - ProjectID 6243, 4745 - Admin ID 383
--EXECUTE On server 3


INSERT INTO SelectedChoiceOption
SELECT 
psc.SegmentChoiceCode,	pco.ChoiceOptionCode,	pco.ChoiceOptionSource,slcmsco.IsSelected	
,psc.SectionId	,psc.ProjectId,	psc.CustomerId	,null as OptionJson ,0 as	IsDeleted
 FROM ProjectSegmentChoice psc WITH(NOLOCK) INNER JOIN ProjectChoiceOption pco WITH(NOLOCK) ON
pco.SectionId=psc.SectionId AND pco.CustomerId=psc.CustomerId and pco.ProjectId=psc.ProjectId 
and pco.SegmentChoiceId=psc.SegmentChoiceId
LEFT OUTER JOIN SelectedChoiceOption sco WITH(NOLOCK) on  pco.SectionId=sco.SectionId and pco.ProjectId=sco.ProjectId 
and pco.CustomerId=sco.CustomerId
and pco.ChoiceOptionCode=sco.ChoiceOptionCode and psc.SegmentChoiceCode=sco.SegmentChoiceCode and sco.ChoiceOptionSource='U'
INNER JOIN SelectedChoiceOption slcmsco WITH(NOLOCK) on slcmsco.ChoiceOptionCode=pco.ChoiceOptionCode
WHERE sco.SegmentChoiceCode IS NULL and pco.ProjectId=6243


 

  