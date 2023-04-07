
--Customer Support 32684: SLC User Sees Difference in Imported Section vs. Original
-- Server 4

UPDATE S 
SET S.OptionJson = (SELECT OptionJson from SelectedChoiceOption  WITH(NOLOCK) where ProjectId=692 and SectionId=792724 and SegmentChoiceCode=65804 and ChoiceOptionCode=160937 and ChoiceOptionSource='M' )
from SelectedChoiceOption  S WITH(NOLOCK) where ProjectId=719 and SectionId=1363701 and SegmentChoiceCode=65804 and ChoiceOptionCode=160937 and ChoiceOptionSource='M'

UPDATE S 
SET S.OptionJson = (SELECT OptionJson from SelectedChoiceOption  S WITH(NOLOCK) where ProjectId=692 and SectionId=792724 and SegmentChoiceCode=65757 and ChoiceOptionCode=160818 and ChoiceOptionSource='M' )
from SelectedChoiceOption  S WITH(NOLOCK) where ProjectId=719 and SectionId=1363701 and SegmentChoiceCode=65757 and ChoiceOptionCode=160818 and ChoiceOptionSource='M'

UPDATE S 
SET S.OptionJson = (SELECT OptionJson from SelectedChoiceOption   WITH(NOLOCK) where ProjectId=692 and SectionId=792724 and SegmentChoiceCode=65727 and ChoiceOptionCode=160726 and ChoiceOptionSource='M' )
from SelectedChoiceOption  S WITH(NOLOCK) where ProjectId=719 and SectionId=1363701 and SegmentChoiceCode=65727 and ChoiceOptionCode=160726 and ChoiceOptionSource='M'


