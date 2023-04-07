/*
Customer Support 44013: SLC Unable to Print Section
server :3

 ---For references-----
invalid OptionJson in SelectedChoiceOption
it is master choice it takes OptionJson data always  from  master table only.
select * from  SelectedChoiceOption where SegmentChoiceCode=32712 and  SectionId=10167700 and projectid=9550 
*/


UPDATE SCO
SET SCO.OptionJson = null
FROM SelectedChoiceOption SCO with(nolock) WHERE  SCO.SelectedChoiceOptionId in(1260593035,
1260593036) and SCO.SegmentChoiceCode=32712 and SCO.ProjectId=9550 and SCO.SectionId=10167700 and SCO.CustomerId=626 