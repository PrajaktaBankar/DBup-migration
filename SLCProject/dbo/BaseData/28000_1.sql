
USE SLCProject
 Go
 
 --Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275
--EXECUTE On server 2


 UPDATE ps SET ps.SegmentDescription='<span style=""><span class="fr-marker" data-id="0" data-type="true" style="display: none; line-height: 0;">​</span><mark data-markjs="true" class="currentMatch">Installer Qualifications</mark><span class="fr-marker" data-id="0" data-type="false" style="display: none; line-height: 0;">​</span>:  Company specializing in performing work of the type specified and with at least {CH#10000601} years of{CH#10000602} experience{CH#10000603}.</span>'
 from ProjectSegment ps WITH(NOLOCK) where ps.SegmentStatusId=246479131   and ProjectId=5026

 DELETE FROM ProjectSegmentChoice WHERE SegmentChoiceCode=71204 and  ProjectId=5026 and SectionId=6023784

UPDATE psc SET psc.IsDeleted=0 FROM ProjectSegmentChoice psc WITH(NOLOCK) WHERE psc.SegmentChoiceCode=10000601 and  psc.ProjectId=5026 and psc.SectionId=6023784
UPDATE pco SET pco.IsDeleted=0 FROM ProjectChoiceOption pco WITH(NOLOCK) WHERE pco.SegmentChoiceId=15377512 and  pco.ProjectId=5026 and pco.SectionId=6023784
UPDATE sco SET sco.IsDeleted=0 FROM SelectedChoiceOption sco  WITH(NOLOCK) WHERE sco.SegmentChoiceCode=10000601 and  sco.ProjectId=5026 and sco.SectionId=6023784

UPDATE psc SET psc.IsDeleted=0 FROM ProjectSegmentChoice psc WITH(NOLOCK) WHERE psc.SegmentChoiceCode=10000603 and  psc.ProjectId=5026 and psc.SectionId=6023784
UPDATE pco SET pco.IsDeleted=0 FROM ProjectChoiceOption pco WITH(NOLOCK) WHERE pco.SegmentChoiceId=15377514 and  pco.ProjectId=5026 and pco.SectionId=6023784
UPDATE sco SET sco.IsDeleted=0 FROM SelectedChoiceOption sco WITH(NOLOCK) WHERE sco.SegmentChoiceCode=10000603 and  sco.ProjectId=5026 and sco.SectionId=6023784

UPDATE psc SET psc.IsDeleted=0 FROM ProjectSegmentChoice psc WITH(NOLOCK) WHERE psc.SegmentChoiceCode=10000602 and  psc.ProjectId=5026 and psc.SectionId=6023784
UPDATE pco SET pco.IsDeleted=0 FROM ProjectChoiceOption pco WITH(NOLOCK) WHERE pco.SegmentChoiceId=15377513 and  pco.ProjectId=5026 and pco.SectionId=6023784
UPDATE sco SET sco.IsDeleted=0 FROM SelectedChoiceOption sco WITH(NOLOCK) WHERE sco.SegmentChoiceCode=10000602 and  sco.ProjectId=5026 and sco.SectionId=6023784