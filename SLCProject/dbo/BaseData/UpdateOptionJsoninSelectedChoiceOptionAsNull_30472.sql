UPDATE SCO SET SCO.OptionJson=null  FROM SelectedChoiceOption SCO WITH(NOLOCK) WHERE SCO.segmentchoicecode=39851 and SCO.ChoiceOptionSource='M'

UPDATE PCO SET  PCO.OptionJson=SLCMCO.OptionJson  FROM SLCMaster..ChoiceOption SLCMCO WITH(NOLOCK)
 INNER JOIN ProjectChoiceOption PCO WITH(NOLOCK) 
ON PCO.ChoiceOptionCode=SLCMCO.ChoiceOptionCode

WHERE PCO.ChoiceOptionCode in (86302,
86303,
86304,
86305,
86306,
86307,
86308) AND PCO.OptionJson LIKE '%FillInBlank%'