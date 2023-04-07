/*
Customer Support 30527: SLC Customer Seeing {CH#} Issue
Server:3
*/

  INSERT INTO SelectedChoiceOption
SELECT 
psc.SegmentChoiceCode	,pco.ChoiceOptionCode	,pco.ChoiceOptionSource	,smsco.IsSelected	,psc.SectionId	,psc.ProjectId	,psc.CustomerId	,null as OptionJson,0 as 	IsDeleted

 FROM ProjectSegmentChoice psc with(nolock) INNER JOIN ProjectChoiceOption  pco with(nolock) ON
psc.SegmentChoiceId=pco.SegmentChoiceId AND pco.ProjectId=psc.ProjectId and pco.CustomerId=psc.CustomerId 
AND pco.SectionId=psc.SectionId
LEFT OUTER JOIN SelectedChoiceOption sco with(nolock) ON sco.ChoiceOptionCode=pco.ChoiceOptionCode and sco.SegmentChoiceCode=psc.SegmentChoiceCode
AND pco.ProjectId=sco.ProjectId and pco.CustomerId=sco.CustomerId and pco.SectionId=sco.SectionId and sco.ChoiceOptionSource='U'
INNER JOIN SLCMaster.dbo.SelectedChoiceOption smsco with(nolock) ON smsco.ChoiceOptionCode=pco.ChoiceOptionCode
and smsco.SegmentChoiceCode=psc.SegmentChoiceCode
where sco.ProjectId IS NULL AND  pco.CustomerId=1191
