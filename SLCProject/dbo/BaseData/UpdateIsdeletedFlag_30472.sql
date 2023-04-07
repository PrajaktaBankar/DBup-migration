--1 record affected
update PSC SET PSC.IsDeleted=0 FROM ProjectSegmentChoice PSC WITH(NOLOCK) WHERE  PSC.SectionId=311462  AND PSC.SegmentId=1543130 AND ProjectId=272 AND SegmentChoiceCode=29006
--1 record affected
UPDATE   PS SET  PS.SegmentDescription='<span style="">SCAFCO Corporation{CH#29006}:  www.scafco.com/#sle.</span>'  FROM ProjectSegment PS WITH(NOLOCK) WHERE PS.SegmentId=1543130 AND PS.ProjectId=272 AND PS.CustomerId=1431
--2 records affected
UPDATE PCO SET PCO.IsDeleted =0 FROM ProjectChoiceOption PCO WITH(NOLOCK) WHERE PCO.SegmentChoiceId=4034503 AND PCO.ProjectId=272 AND PCO.CustomerId=1431
--2 records affected
UPDATE SCO SET SCO.IsDeleted=0 from SelectedChoiceOption SCO WITH(NOLOCK) WHERE SCO.SegmentChoiceCode=29006 AND SCO.ProjectId=272 AND SCO.ChoiceOptionSource='U'
--1 row affected
UPDATE PSC SET PSC.SegmentStatusId=28484305,SegmentId=3588635 from ProjectSegmentChoice PSC WITH(NOLOCK) WHERE PSC.SegmentChoiceCode=269013 AND PSC.ProjectId=651 AND PSC.SectionId=747906
   AND PSC.CustomerId=1431