use SLCPRoject;

--Execute script on Server 003
--Customer Support 33895: SLC - When Printing, Global Terms Become Red

GO


DECLARE @SectionId INT =5292570;
DECLARE @ProjectId INT = 5787;

INSERT INTO SelectedChoiceOption(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource,	IsSelected,	SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
(SELECT SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, @SectionId, @ProjectId, CustomerId, null, 0 
from SelectedChoiceOption WITH(NOLOCK) WHERE SegmentChoiceCode in (10004809, 10004810, 10004811)and ProjectId= 4789 and CustomerId = 375)