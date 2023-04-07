--Execute it on server 2
--Customer Support 31136: CH# on word and PDF export only - 29449 Steve Oliver with Powers Brown Architecture Holdings, Inc. - 29449

SELECT  * into #tempSelectedChoiceOption FROM SelectedChoiceOption WITH(NOLOCK)
WHERE CustomerId=1663 AND ChoiceOptionSource='U'

---4743  rows should affected
INSERT INTO SelectedChoiceOption
 SELECT PSC.SegmentChoiceCode	,PCO.ChoiceOptionCode	,'U' as ChoiceOptionSource	,
 SLCMSCO.IsSelected	,PCO.SectionId	,PCO.ProjectId	,PCO.CustomerId ,null as 	OptionJson,0 as	IsDeleted
 FROM ProjectSegmentChoice PSC WITH(NOLOCK) INNER JOIN 
 ProjectChoiceOption PCO WITH(NOLOCK) ON PSC.SegmentChoiceId=PCO.SegmentChoiceId AND
 PCO.ProjectId=PSC.ProjectId AND PCO.SectionId=PSC.SectionId AND PCO.CustomerId=PSC.CustomerId
 AND PCO.IsDeleted=PSC.IsDeleted
 LEFT OUTER JOIN SelectedChoiceOption SCO WITH(NOLOCK) ON
 SCO.ChoiceOptionCode=PCO.ChoiceOptionCode AND PCO.SectionId=SCO.SectionId 
 AND PCO.ProjectId=SCO.ProjectId AND PCO.CustomerId=SCO.CustomerId AND SCO.ChoiceOptionSource='U'
 INNER JOIN SLCMaster..SelectedChoiceOption SLCMSCO WITH(NOLOCK) ON
 PCO.ChoiceOptionCode=SLCMSCO.ChoiceOptionCode AND PSC.SegmentChoiceCode=SLCMSCO.SegmentChoiceCode
 WHERE SCO.ChoiceOptionCode IS NULL AND ISNULL(PSC.IsDeleted,0)=0
 AND PSC.CustomerId=1663  
 ORDER BY PSC.SegmentChoiceCode

  