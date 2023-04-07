/*
Customer Support 36107: SLC User Duplicate Choice Issue
Server :2

//for references 
select * from ProjectSegment where SegmentDescription like '%{CH#289024}%' and Projectid=5026 and SectionId=6023626
select *  from ProjectSegment where SegmentId in(40115164,40110882) and Projectid=5026
*/


delete  from SelectedChoiceOption   where  ChoiceOptionSource='U' and ChoiceOptionCode in(select ChoiceOptionCode from ProjectChoiceOption where SegmentChoiceId=16651461) and Projectid=5026 and SectionId=6023626
delete  from ProjectChoiceOption  where  SegmentChoiceId=16651461 and  Projectid=5026 and SectionId=6023626
delete  from ProjectSegmentChoice  where  SegmentChoiceCode=289024  and Projectid=5026 and SegmentChoiceId=16651461 and SectionId=6023626



update SCO set isselected=1 from SelectedChoiceOption SCO WITH (NOLOCK)
 where SCO.SelectedChoiceOptionId =463958459 and SCO.SegmentChoiceCode=289024 and SCO.Projectid=5026 and SectionId=6023626