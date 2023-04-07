--Execute it on server 2
--Customer Support 31136: CH# on word and PDF export only - 29449 Steve Oliver with Powers Brown Architecture Holdings, Inc. - 29449

update ps set  ps.SegmentDescription='Acoustic Insulation:  {RS#776}; preformed glass fiber, friction fit type, unfaced.  Thickness:  {CH#60143}.'  from  ProjectSegment PS with(nolock) WHERE  PS.SegmentStatusId=137894773 AND PS.SegmentId=20905289
UPDATE PS SET PS.SegmentDescription='Outboard Lite:  {CH#193286} float glass, {CH#193287} thick{CH#193288}.' FROM ProjectSegment PS with(nolock) WHERE   PS.ProjectId=2814 AND PS.SegmentStatusId=138366726
UPDATE PSC SET PSC.SegmentId=32458511 FROM ProjectSegmentChoice PSC with(nolock) WHERE PSC.SegmentChoiceCode=193550 and PSC.ProjectId=4016 and PSC.SectionId=4808956 and PSC.SegmentStatusId=187136878


--1 row affected
UPDATE PS SET PS.SegmentDescription='Liquid Densifier/Hardener:  Penetrating chemical compound that reacts with concrete, filling the pores and dustproofing; for application to concrete {CH#163396} set.'  FROM ProjectSegment PS with(nolock) WHERE PS.SegmentId=20893407 and	PS.SegmentStatusId=137699701 and	PS.SectionId=3406564 and 	PS.ProjectId=2804 and	PS.CustomerId=1663
 --2 rows affected
UPDATE SCO SET SCO.IsDeleted=0 FROM SelectedChoiceOption SCO with(nolock) WHERE SCO.SegmentChoiceCode=163396 AND SCO.ProjectId=2804 AND SCO.SectionId=3406564 AND SCO.CustomerId=1663 AND SCO.ChoiceOptionSource='U'
-- 1 row affected
UPDATE PSC SET PSC.IsDeleted=0 from ProjectSegmentChoice PSC with(nolock)	where PSC.SegmentChoiceCode=163396 AND PSC.ProjectId=2804 AND PSC.SectionId=3406564 AND PSC.CustomerId=1663
--2 rows affected
UPDATE PCO SET PCO.IsDeleted=0 FROM ProjectChoiceOption PCO with(nolock) WHERE PCO.SegmentChoiceId=8540772  AND PCO.ProjectId=2804 AND PCO.SectionId=3406564 AND PCO.CustomerId=1663

--3 rows affected
 insert into SelectedChoiceOption
SELECT SegmentChoiceCode,	ChoiceOptionCode + 3 as ChoiceOptionCode,	ChoiceOptionSource,	IsSelected	,SectionId	,ProjectId	,CustomerId	,OptionJson	,IsDeleted
from SelectedChoiceOption with(nolock)  where  SegmentChoiceCode=9679 AND  ProjectId=3021  and  ChoiceOptionSource='U'  and SectionId=3667136

--- 10 rows should affected
 INSERT into ProjectChoiceOption
SELECT 
 psc.SegmentChoiceId	,SLCMCO.SortOrder	,'U' as ChoiceOptionSource,	SLCMCO.OptionJson	,psc.ProjectId	,psc.SectionId	,psc.CustomerId	,SLCMCO.ChoiceOptionCode	,psc.CreatedBy	,psc.CreateDate	,psc.ModifiedBy	,psc.ModifiedDate	,null as A_ChoiceOptionId,cast(0  as bit)as 	IsDeleted
 FROM 
SelectedChoiceOption sco with(nolock)
INNER JOIN ProjectSegmentChoice psc with(nolock)
ON sco.ProjectId=psc.ProjectId AND psc.SectionId=sco.SectionId AND psc.CustomerId=sco.CustomerId AND sco.ChoiceOptionSource='U' and psc.SegmentChoiceCode=sco.SegmentChoiceCode
LEFT OUTER JOIN ProjectChoiceOption pco with(nolock) ON pco.ChoiceOptionCode=sco.ChoiceOptionCode AND pco.ProjectId=sco.ProjectId
AND pco.SectionId=sco.SectionId AND pco.CustomerId=sco.CustomerId 
INNER JOIN SLCMaster..ChoiceOption SLCMCO with(nolock) ON SLCMCO.ChoiceOptionCode=sco.ChoiceOptionCode
WHERE pco.ChoiceOptionCode IS NULL AND psc.ProjectId=2879 AND psc.CustomerId=1663  AND sco.ChoiceOptionSource='U'



				