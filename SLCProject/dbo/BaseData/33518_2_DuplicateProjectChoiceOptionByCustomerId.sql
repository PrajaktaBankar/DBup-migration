use SLCProject;
--Execute on server 3
--Customer Support 33518: SLC Showing "Changes you made may not be saved"


  DECLARE @CustomerId int=383

DELETE X FROM (
SELECT * ,
ROW_NUMBER()OVER(PARTITION BY SegmentChoiceId,	SortOrder,ProjectId,	
SectionId	,CustomerId	,ChoiceOptionCode ORDER BY ChoiceOptionId ASC)as rowid
from ProjectChoiceOption WITH(NOLOCK) WHERE   CustomerId =@CustomerId
)as X WHERE X.rowid>1;

DELETE X FROM (
SELECT *,
ROW_NUMBER()OVER(PARTITION BY	SegmentChoiceCode,	ChoiceOptionCode	, 	 	SectionId	,ProjectId	,CustomerId ORDER BY SelectedChoiceOptionId desc)as rowid
 from SelectedChoiceOption WITH(NOLOCK) WHERE   CustomerId =@CustomerId AND ChoiceOptionSource='U'
 )AS X WHERE X.rowid>1;
