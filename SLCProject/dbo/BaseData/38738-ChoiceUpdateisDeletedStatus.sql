/*
Customer Support 38738: SLC {CH#} Issue
server: 2

for references:
already choice data  available all three table.
i update isdeleted=0 in all three table for 2 choice.
select * from ProjectSegmentChoice where SegmentChoiceCode=187022 and segmentid=68689172
and SectionId=9254468 and projectid= 7700
*/


UPDATE PSC
SET PSC.IsDeleted = 0
FROM ProjectSegmentChoice PSC with(nolock) WHERE PSC.SegmentChoiceCode in(187022,186376) and PSC.segmentid in(68689172,68689173)
and PSC.SectionId=9254468 and PSC.projectid= 7700

UPDATE PCO
SET PCO.IsDeleted = 0
FROM ProjectChoiceOption PCO with(nolock) WHERE PCO.SegmentChoiceId in(24095382,24095383)
and PCO.SectionId=9254468 and PCO.projectid= 7700

UPDATE SCO
SET SCO.IsDeleted = 0
FROM SelectedChoiceOption SCO with(nolock) WHERE SCO.SelectedChoiceOptionId in(736321021,736321022,736321013,736321014)
and SCO.SegmentChoiceCode in(187022,186376) and SCO.SectionId=9254468 and SCO.projectid= 7700






