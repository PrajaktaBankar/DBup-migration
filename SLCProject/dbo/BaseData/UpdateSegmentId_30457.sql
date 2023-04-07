--Execute it on server 3
--Customer Support 30457: All Choices Made Within the Section Referenced Above are Shown as {CH#32854} - 57026

DROP TABLE if EXISTS #tempProjectSegmentChoice 

SELECT 
PSC.SegmentChoiceId	,PSC.SectionId	,SegmentStatusId	
,SegmentId	,ChoiceTypeId	,PSC.ProjectId
,PSC.CustomerId	,SegmentChoiceSource	,SegmentChoiceCode,PSC.CreatedBy	
,PSC.CreateDate	,PSC.ModifiedBy	,PSC.ModifiedDate into #tempProjectSegmentChoice
FROM ProjectSegmentChoice PSC   WITH(NOLOCK)
WHERE  
 PSC.ProjectId=1643  AND 
 PSC.IsDeleted=0  AND PSC.CustomerId=782

   SELECT *  into #WrongSegment FROM (
  SELECT PSSV.SegmentId, TPSC.SegmentStatusId ,
  iif(PSSV.SegmentId= TPSC.SegmentId,0,1)as  IsWrongSegment
  FROM ProjectSegmentStatusView PSSV  WITH(NOLOCK)
  INNER JOIN #tempProjectSegmentChoice TPSC on TPSC.SectionId=PSSV.SectionId
  AND PSSV.ProjectId=TPSC.ProjectId and  PSSV.SegmentStatusId=TPSC.SegmentStatusId
  WHERE   PSSV.ProjectId	=1643 AND PSSV.CustomerId=782 AND ISNULL(PSSV.IsDeleted,0)=0
  )AS A WHERE A.IsWrongSegment>0
   -- corrected wrong segmentId
  --10 records should be affected
  UPDATE PSC set PSC.SegmentId=WS.SegmentId  
  FROM ProjectSegmentChoice PSC  WITH(NOLOCK) INNER JOIN
  #WrongSegment WS ON
  PSC.SegmentStatusId=WS.SegmentStatusId
  WHERE PSC.ProjectId=1643 and PSC.CustomerId=782
  

  DROP TABLE #tempProjectSegmentChoice 
  
  --Inserted missing choiceoption
   --2 rows should affected
   INSERT INTO ProjectChoiceOption
   select  
    	4582692 as SegmentChoiceId	,SortOrder	,'U' as ChoiceOptionSource	,OptionJson	,1643 as ProjectId	,1779811 as SectionId	,782 as CustomerId,
			ChoiceOptionCode	,0	,getutcdate()as CreatedDate,	0 as ModifiedBy,	getutcdate() as ModifiedDate,	null,	0
    FROM SLCMaster..ChoiceOption  WITH(NOLOCK)
   WHERE ChoiceOptionCode in (SELECT ChoiceOptionCode FROM SelectedChoiceOption  WITH(NOLOCK)
    WHERE SegmentChoiceCode =287850 and ProjectId=1643   and ChoiceOptionSource='U' )  
		
	
--47 records should affected.
 INSERT INTO ProjectChoiceOption
 SELECT 
 PSC.SegmentChoiceId, SLCMCO.SortOrder,'U' as ChoiceOptionSource,SLCMCO.OptionJson,PSC.ProjectId,PSC.SectionId,PSC.CustomerId, SLCMCO.ChoiceOptionCode,PSC.CreatedBy,
 PSC.CreateDate,PSC.ModifiedBy,PSC.ModifiedDate,null as A_ChoiceOptionId,0
  FROM 
 SLCMaster..ChoiceOption SLCMCO WITH(NOLOCK) INNER JOIN
  SelectedChoiceOption SCO  WITH(NOLOCK) ON
  SCO.ChoiceOptionCode=SLCMCO.ChoiceOptionCode
  INNER JOIN
 ProjectSegmentChoice PSC WITH(NOLOCK) ON
 PSC.SegmentChoiceCode=SCO.SegmentChoiceCode AND PSC.ProjectId=SCO.ProjectId AND PSC.SectionId=SCO.SectionId
 AND PSC.CustomerId=SCO.CustomerId
  LEFT OUTER JOIN  ProjectChoiceOption PCO WITH(NOLOCK) ON
  PCO.ProjectId=SCO.ProjectId AND PCO.SectionId=SCO.SectionId AND PCO.CustomerId=SCO.CustomerId
  AND PCO.ChoiceOptionCode=SCO.ChoiceOptionCode AND PCO.ChoiceOptionSource=SCO.ChoiceOptionSource
  WHERE   SCO.ProjectId=1643 and SCO.ChoiceOptionSource='U'
  AND PCO.ChoiceOptionCode IS NULL
  