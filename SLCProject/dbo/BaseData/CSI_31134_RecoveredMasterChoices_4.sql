--Execute on server 3
--Customer Support 31134: Cannot Print project

use [SLCProject]

UPDATE SCO SET SCO.OptionJson=NULL
from SelectedChoiceOption SCO WITH(NOLOCK) WHERE SCO.SegmentChoiceCode in (68040, 68041, 68043, 68044) and 
SCO.ProjectId = 4856 and SCO.SectionId = 4202304  
AND OptionJson like '%"Metric":null,"English":null,"MetricEnglish":null,"EnglishMetric":null%';

UPDATE SCO SET SCO.OptionJson=NULL
from SelectedChoiceOption SCO WITH(NOLOCK) WHERE SCO.SegmentChoiceCode = 14934 and 
SCO.ProjectId = 4856 and SCO.SectionId = 4202866  
AND OptionJson like '%"Metric":null,"English":null,"MetricEnglish":null,"EnglishMetric":null%';


