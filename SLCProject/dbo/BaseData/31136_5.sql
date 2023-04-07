
--Execute it on server 2
--Customer Support 31136: CH# on word and PDF export only - 29449 Steve Oliver with Powers Brown Architecture Holdings, Inc. - 29449

--10538  rows should affected
     INSERT INTO SelectedChoiceOption
   SELECT DISTINCT PSC.SegmentChoiceCode	,PCO.ChoiceOptionCode	,'U' as ChoiceOptionSource	,
 SLCMSCO.IsSelected	,PCO.SectionId	,PCO.ProjectId	,PCO.CustomerId ,null as 	OptionJson,0 as	IsDeleted
  
   FROM ProjectSegmentChoice PSC WITH(NOLOCK)
  INNER JOIN  ProjectChoiceOption  PCO WITH(NOLOCK) ON PSC.SegmentChoiceId=PCO.SegmentChoiceId AND
 PCO.ProjectId=PSC.ProjectId AND PCO.SectionId=PSC.SectionId AND PCO.CustomerId=PSC.CustomerId
 INNER JOIN SLCMaster..SelectedChoiceOption SLCMSCO WITH(NOLOCK) ON  PCO.ChoiceOptionCode=SLCMSCO.ChoiceOptionCode
 LEFT OUTER JOIN
  SelectedChoiceOption SCO WITH(NOLOCK)
  ON SCO.SegmentChoiceCode=PSC.SegmentChoiceCode AND SCO.SectionId=PSC.SectionId AND SCO.ProjectId=PSC.ProjectId AND
  SCO.CustomerId=PSC.CustomerId and SCO.ChoiceOptionSource='U'   AND PCO.ChoiceOptionCode=SCO.ChoiceOptionCode
  WHERE   PSC.CustomerId=1663 AND SCO.ChoiceOptionCode IS NULL
    
	