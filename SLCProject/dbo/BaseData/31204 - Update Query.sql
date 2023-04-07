/*
Execute Query 1 on all SlcMaster database : SLCMaster_SqlSlcOp001,SLCMaster_SqlSlcOp002,SLCMaster_SqlSlcOp003,SLCMaster_SqlSlcOp004
Customer Support 31204: CHURCH PROJECT: Default choice incorrect in SLCMaster
Row Affected 1
*/
-- Query 1
update sco 
set isselected=1  
from SelectedChoiceOption sco with (nolock)
where SegmentChoiceCode=17740 and SelectedChoiceOptionId=63008


/*
Execute Query 2 on all SlcMasterStaging database : SLCMasterStaging_001,SLCMasterStaging_002,SLCMasterStaging_003,SLCMasterStaging_004
Customer Support 31204: CHURCH PROJECT: Default choice incorrect in SLCMaster
Row Affected 1
*/
-- Query 2
update CO
set IsSelected=1
from ChoiceOptionStaging CO with (nolock)
where SegmentChoiceId=17740 and ChoiceOptionId=28984
