--Execute on server 2
--SLC User Sees {CH# Issue in a Project

UPDATE PSC SET IsDeleted =0 FROM ProjectSegmentChoice psc WITH (NOLOCK) WHERE psc.SegmentStatusId IN(549035481)
UPDATE pco SET IsDeleted =1 FROM ProjectSegmentChoice pco WITH (NOLOCK) WHERE pco.SegmentChoiceId IN (38936162)
UPDATE pco SET IsDeleted =0 FROM ProjectChoiceOption pco WITH (NOLOCK) WHERE pco.ChoiceOptionId IN (1772485116,1772485117,1772485118,1772485119,1772485120)
UPDATE sco SET IsDeleted=0 FROM SelectedChoiceOption sco WITH (NOLOCK) WHERE sco.SelectedChoiceOptionId IN (1309138106,1309138107,1309138108,1309138109,1309138110)


UPDATE PSC SET IsDeleted =0 FROM ProjectSegmentChoice psc WITH (NOLOCK) WHERE psc.SegmentStatusId IN(549035420)
UPDATE pco SET IsDeleted =1 FROM ProjectSegmentChoice pco WITH (NOLOCK) WHERE pco.SegmentChoiceId IN (36561711)
UPDATE pco SET IsDeleted =0 FROM ProjectChoiceOption pco WITH (NOLOCK) WHERE pco.ChoiceOptionId IN (1772332462,1772332463)
UPDATE sco SET IsDeleted=0 FROM SelectedChoiceOption sco WITH (NOLOCK) WHERE sco.SelectedChoiceOptionId IN (1305219790,1305219791)


