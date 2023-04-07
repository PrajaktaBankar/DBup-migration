--EXECUTE ON Sevver 4
--Customer Support 30472: Multiple Fill in the Blank Choice Issues - 18912
 

 --60 records should affected.

   UPDATE SCO SET OptionJson=NULL FROM SelectedChoiceOption SCO WITH(NOLOCK) WHERE  SCO.ChoiceOptionCode in  (
   449796,
   449797,
   449795,
   449798,
   449794,
   449793 
   )
   AND SCO.ChoiceOptionSource='M'
   AND SCO.OptionJson IS NOT NULL
    

	--51 rows should affected
   UPDATE PCO SET PCO.OptionJson=SLCMCO.OptionJson  FROM ProjectChoiceOption PCO WITH(NOLOCK) INNER JOIN
   SLCMaster..ChoiceOption SLCMCO WITH(NOLOCK) ON
   PCO.ChoiceOptionCode=SLCMCO.ChoiceOptionCode 
   WHERE PCO.ChoiceOptionCode  IN(449793,449794,449795)  AND PCO.OptionJson LIKE '%FillInBlank%'
    
 