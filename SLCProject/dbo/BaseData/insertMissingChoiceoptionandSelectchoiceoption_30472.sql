

 -- 387 rows affected
 INSERT into ProjectChoiceOption
select DISTINCT
PSC.SegmentChoiceId	,SLCMCO.SortOrder	,'U' as ChoiceOptionSource	,SLCMCO.OptionJson	,PSC.ProjectId	,PSC.SectionId	,PSC.CustomerId	
,SLCMCO.ChoiceOptionCode	,PSC.CreatedBy	,getutcdate()	,PSC.ModifiedBy	,getutcdate(),null as A_ChoiceOptionId,0 as	IsDeleted
 
 FROM 
SLCMaster..SegmentChoice SLCMSC WITH(NOLOCK) INNER JOIN 
ProjectSegmentChoice PSC WITH(NOLOCK)
ON PSC.SegmentChoiceCode=SLCMSC.SegmentChoiceCode
INNER JOIN SLCMaster..ChoiceOption SLCMCO WITH(NOLOCK) ON
SLCMCO.SegmentChoiceId=SLCMSC.SegmentChoiceId 
LEFT OUTER JOIN ProjectChoiceOption PCO WITH(NOLOCK)
ON PSC.ProjectId=PCO.ProjectId AND PSC.SectionId=PCO.SectionId AND PCO.CustomerId=PSC.CustomerId 
AND PCO.SegmentChoiceId=PSC.SegmentChoiceId 
WHERE PCO.SegmentChoiceId IS NULL AND PSC.ProjectId=651 AND PSC.CustomerId=1431


 
 --163 rows affected
 INSERT INTO SelectedChoiceOption
select 
PSC.SegmentChoiceCode	,SLCMSCO.ChoiceOptionCode	,'U' as ChoiceOptionSource	,SLCMSCO.IsSelected	,PSC.SectionId	,PSC.ProjectId	,PSC.CustomerId	,null as OptionJson	,0 as IsDeleted
 FROM 
SLCMaster..SegmentChoice SLCMSC WITH(NOLOCK) INNER JOIN 
ProjectSegmentChoice PSC  WITH(NOLOCK)
ON PSC.SegmentChoiceCode=SLCMSC.SegmentChoiceCode
INNER JOIN SLCMaster..ChoiceOption SLCMCO WITH(NOLOCK) ON
SLCMCO.SegmentChoiceId=SLCMSC.SegmentChoiceId 
INNER JOIN SLCMaster..SelectedChoiceOption SLCMSCO WITH(NOLOCK) ON SLCMSC.SegmentChoiceCode=SLCMSCO.SegmentChoiceCode
 AND SLCMCO.ChoiceOptionCode=SLCMSCO.ChoiceOptionCode
LEFT OUTER JOIN SelectedChoiceOption SCO WITH(NOLOCK)
ON PSC.ProjectId=SCO.ProjectId AND PSC.SectionId=SCO.SectionId AND SCO.CustomerId=PSC.CustomerId  AND SCO.ChoiceOptionSource='U'
 and  SCO.SegmentChoiceCode=PSC.SegmentChoiceCode
WHERE SCO.SegmentChoiceCode IS NULL AND PSC.ProjectId=651 AND PSC.CustomerId=1431  
