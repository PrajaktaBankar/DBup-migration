
--Execute it on server 3
--Customer Support 30457: All Choices Made Within the Section Referenced Above are Shown as {CH#32854} - 57026

 DROP TABLE IF EXISTS #tempProjectSegmentChoice

SELECT 
PSC.SegmentChoiceId	,PSC.SectionId	,SegmentStatusId	
,SegmentId	,ChoiceTypeId	,PSC.ProjectId
,PSC.CustomerId	,SegmentChoiceSource	,SegmentChoiceCode,PSC.CreatedBy	
,PSC.CreateDate	,PSC.ModifiedBy	,PSC.ModifiedDate into #tempProjectSegmentChoice
FROM ProjectSegmentChoice PSC  WITH(NOLOCK) 
LEFT OUTER JOIN  ProjectChoiceOption PCO   WITH(NOLOCK)
ON PCO.SegmentChoiceId=PSC.SegmentChoiceId  AND PCO.ProjectId=PSC.ProjectId
WHERE PCO.SegmentChoiceId IS NULL AND
 PSC.ProjectId=1643  AND 
 PSC.IsDeleted=0 AND len(PSC.SegmentChoiceCode)=5

 --66 RECORDS SHOULD BE AFFECTED
 	INSERT INTO ProjectChoiceOption
 SELECT 
 TPSC.SegmentChoiceId	,SortOrder	,'U' as ChoiceOptionSource	
	,OptionJson	,ProjectId	,TPSC.SectionId	,CustomerId	,ChoiceOptionCode	
	,TPSC.CreatedBy	,TPSC.CreateDate	,TPSC.ModifiedBy	,TPSC.ModifiedDate	,NULL	,0
  FROM #tempProjectSegmentChoice TPSC INNER JOIN 
 SLCMaster..SegmentChoice SLCMSC  WITH(NOLOCK) ON
 SLCMSC.SegmentChoiceCode =TPSC.SegmentChoiceCode 
 INNER JOIN SLCMaster..ChoiceOption SLCMCO  WITH(NOLOCK) ON SLCMCO.SegmentChoiceId=SLCMSC.SegmentChoiceId
 
 DROP TABLE #tempProjectSegmentChoice