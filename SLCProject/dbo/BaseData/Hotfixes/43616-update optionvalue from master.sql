/*
 server name : SLCProject_SqlSlcOp003
 Customer Support 43616 - SLC Failed Export

 ---For references-----

*/


DECLARE @json NVARCHAR(max);
SET @json=(SELECT OptionJson from SLCMaster..ChoiceOption WITH(NOLOCK) WHERE SegmentChoiceId =81522 AND ChoiceOptionId=201945)

UPDATE SCO SET OptionJson=@json FROM SelectedChoiceOption SCO WITH(NOLOCK)
 WHERE ProjectId=9968
 AND SCO.CustomerId=626
 AND SectionId=10322764
 AND SegmentChoiceCode=81522
 AND ChoiceOptionCode=201945
 AND IsSelected=1
 AND ChoiceOptionSource='M'

UPDATE PCO SET OptionJson=@json FROM ProjectChoiceOption PCO WITH(NOLOCK)
WHERE ProjectId=9968
AND PCO.CustomerId=626
AND SectionId=10322764
AND ChoiceOptionCode=201945