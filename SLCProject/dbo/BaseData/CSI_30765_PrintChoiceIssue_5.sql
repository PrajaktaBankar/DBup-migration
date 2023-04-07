--Script 5- Execute on Server - 3
--Customer Support 30765: ON DEADLINE: {CH#} showing in sections after making edits again.

use [SLCProject]

UPDATE SCO set ChoiceOptionCode=631223
from SelectedChoiceOption SCO  
WHERE ProjectId = 4041 AND 
ChoiceOptionSource = 'M' AND 
SegmentChoiceCode = 308994; 