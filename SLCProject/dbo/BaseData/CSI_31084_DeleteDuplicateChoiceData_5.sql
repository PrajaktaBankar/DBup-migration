--Customer Support Customer Support 31084: CH Errors {CH#}: CH# Errors
--Execute this on Server 3 
  
 
  DROP TABLE IF EXISTS #duplicateProjectSegmentChoice

  DECLARE @ProjectId int=5376

  SELECT DISTINCT SegmentChoiceId	
  ,SectionId	,SegmentStatusId	
  ,SegmentId	 	,ProjectId	
  ,CustomerId	,SegmentChoiceSource	,
  SegmentChoiceCode  INTO #duplicateProjectSegmentChoice FROM(
  SELECT * ,
  ROW_NUMBER()OVER (PARTITION BY SectionId,SegmentId,SegmentStatusId,SegmentId, ProjectId,CustomerId,SegmentChoiceCode ORDER BY SegmentChoiceCode ,isnull(isdeleted,0) Asc)as row_no
  FROM ProjectSegmentChoice WITH(NOLOCK) WHERE SegmentChoiceSource='U'  AND ProjectId=@ProjectId
  )A WHERE A.row_no>1
   
  --Filter duplicate data in ProjectChoiceOption
  DROP TABLE IF EXISTS #duplicateProjectChoiceOption
  
  SELECT PCO.* INTO #duplicateProjectChoiceOption FROM ProjectChoiceOption PCO WITH(NOLOCK) INNER JOIN
  #duplicateProjectSegmentChoice DPSC  ON
  DPSC.ProjectId=PCO.ProjectId AND DPSC.SectionId=PCO.SectionId
  AND DPSC.CustomerId =PCO.CustomerId
  WHERE PCO.SegmentChoiceId=DPSC.SegmentChoiceId
  AND PCO.ChoiceOptionSource=DPSC.SegmentChoiceSource

  ---Filter duplicate data in SelectedChoiceOption
  DROP TABLE IF EXISTS #duplicateSelectedChoiceOption
  SELECT  * INTO #duplicateSelectedChoiceOption  FROM (
  SELECT DISTINCT SCO.*,
  ROW_NUMBER()OVER(PARTITION by SCO.ChoiceOptionCode,SCO.ProjectId,SCO.SectionId,SCO.CustomerId ,SCO.SegmentChoiceCode,DPSC.SegmentStatusId,DPSC.SegmentId order By SCO.SelectedChoiceOptionId)as RowNo
  FROM SelectedChoiceOption SCO WITH(NOLOCK) INNER JOIN
  #duplicateProjectChoiceOption DPCO ON
  SCO.ChoiceOptionCode=DPCO.ChoiceOptionCode AND
  SCO.ProjectId=DPCO.ProjectId AND SCO.SectionId=DPCO.SectionId AND
  SCO.CustomerId=DPCO.CustomerId AND SCO.ChoiceOptionSource=DPCO.ChoiceOptionSource
  INNER JOIN #duplicateProjectSegmentChoice DPSC  ON
  DPSC.ProjectId=DPCO.ProjectId AND DPSC.SectionId=DPCO.SectionId
  AND DPSC.CustomerId =DPCO.CustomerId    
  WHERE DPCO.SegmentChoiceId=DPSC.SegmentChoiceId
  AND DPCO.ChoiceOptionSource=DPSC.SegmentChoiceSource
  AND SCO.SegmentChoiceCode=DPSC.SegmentChoiceCode
  )as A WHERE A.RowNo>1	

-----------------------------------------------------DELETIONS---------------------------------
  
   DELETE SCO FROM SelectedChoiceOption SCO WITH(NOLOCK) INNER JOIN
   #duplicateSelectedChoiceOption DSCO ON
   SCO.ChoiceOptionCode=DSCO.ChoiceOptionCode AND SCO.SelectedChoiceOptionId=DSCO.SelectedChoiceOptionId 
   AND SCO.ProjectId=DSCO.ProjectId AND SCO.SectionId=DSCO.SectionId AND SCO.CustomerId=DSCO.CustomerId
   AND SCO.SegmentChoiceCode=DSCO.SegmentChoiceCode 
   WHERE SCO.ChoiceOptionSource='U' 
   AND SCO.ProjectId=@ProjectId
    
   DELETE PCO FROM ProjectChoiceOption PCO WITH(NOLOCK) INNER JOIN #duplicateProjectChoiceOption DPCO
   ON PCO.ChoiceOptionId=DPCO.ChoiceOptionId AND PCO.SegmentChoiceId=DPCO.SegmentChoiceId
   AND PCO.ChoiceOptionCode=DPCO.ChoiceOptionCode AND PCO.ProjectId=DPCO.ProjectId AND
   PCO.SectionId=DPCO.SectionId AND PCO.CustomerId=DPCO.CustomerId
   WHERE PCO.ChoiceOptionSource='U' 
   AND PCO.ProjectId=@ProjectId
  
   DELETE   PSC   FROM ProjectSegmentChoice PSC WITH(NOLOCK) INNER JOIN
   #duplicateProjectSegmentChoice DPSC ON
   PSC.SegmentChoiceId=DPSC.SegmentChoiceId AND PSC.SectionId=DPSC.SectionId AND
   ISNULL(PSC.SegmentStatusId,0)=ISNULL(DPSC.SegmentStatusId,0) AND PSC.SegmentId=DPSC.SegmentId
   AND PSC.SegmentChoiceCode=DPSC.SegmentChoiceCode AND PSC.ProjectId=DPSC.ProjectId
   AND PSC.CustomerId=DPSC.CustomerId
   WHERE PSC.SegmentChoiceSource='U'
   AND PSC.ProjectId=@ProjectId

   ---IF SelectedChoiceOption record is deletd and it is available in ProjectSegmentChoice and ProjectChoiceOption then insert it into SelectedChoiceOption
 INSERT INTO SelectedChoiceOption
 SELECT 
 psc.SegmentChoiceCode	,pco.ChoiceOptionCode	,pco.ChoiceOptionSource	,smsco.IsSelected	,psc.SectionId	,psc.ProjectId	,psc.CustomerId	,null as OptionJson,0 as 	IsDeleted
 FROM ProjectSegmentChoice  psc  WITH(NOLOCK) INNER JOIN ProjectChoiceOption  pco WITH(NOLOCK)  ON
 psc.SegmentChoiceId=pco.SegmentChoiceId AND pco.ProjectId=psc.ProjectId AND pco.CustomerId=psc.CustomerId 
 AND pco.SectionId=psc.SectionId
 LEFT OUTER JOIN SelectedChoiceOption sco WITH(NOLOCK)  ON sco.ChoiceOptionCode=pco.ChoiceOptionCode AND sco.SegmentChoiceCode=psc.SegmentChoiceCode
 AND pco.ProjectId=sco.ProjectId AND pco.CustomerId=sco.CustomerId AND pco.SectionId=sco.SectionId AND sco.ChoiceOptionSource='U'
 INNER JOIN SelectedChoiceOption smsco WITH(NOLOCK)  ON smsco.ChoiceOptionCode=pco.ChoiceOptionCode
 AND smsco.SegmentChoiceCode=psc.SegmentChoiceCode
 INNER JOIN ProjectSegmentStatus pss WITH(NOLOCK)  ON pss.SectionId=pco.SectionId and pco.CustomerId=pss.CustomerId and pco.ProjectId=pss.ProjectId
 AND pss.SegmentStatusId=psc.SegmentStatusId and psc.SegmentId=pss.SegmentId
 WHERE sco.ProjectId IS NULL AND psc.ProjectId=@ProjectId and isnull(pss.IsDeleted,0)=0 and psc.isdeleted=0 and pco.isdeleted=0 
 