 DROP TABLE IF EXISTS #tempDuplocateProjectChoiceOption

 SELECT * INTO #tempDuplocateProjectChoiceOption FROM(
 SELECT DISTINCT pco.ProjectId	,pco.SectionId	,pco.CustomerId,pco.SegmentChoiceId,psc.SegmentChoiceCode ,pco.ChoiceOptionCode
 ,ROW_NUMBER()OVER(PARTITION BY SortOrder,pco.ProjectId	,pco.SectionId	,pco.CustomerId,pco.SegmentChoiceId ORDER BY ChoiceOptionId )AS ROW_NO
 FROM ProjectChoiceOption pco WITH(NOLOCK) INNER  JOIN   ProjectSegmentChoice psc WITH(NOLOCK) ON
 psc.CustomerId=psc.CustomerId AND pco.ProjectId=psc.ProjectId AND pco.SectionId=psc.SectionId
 and psc.SegmentChoiceId=pco.SegmentChoiceId
 WHERE  psc.ProjectId=4359   
 )AS A WHERE A.ROW_NO>1


  DELETE  sco  FROM SelectedChoiceOption sco WITH(NOLOCK) INNER JOIN
  #tempDuplocateProjectChoiceOption tdpco ON sco.CustomerId=tdpco.CustomerId AND
  sco.ProjectId=tdpco.ProjectId and sco.SectionId=tdpco.SectionId and sco.ChoiceOptionCode=tdpco.ChoiceOptionCode 
  and sco.SegmentChoiceCode=tdpco.SegmentChoiceCode AND sco.ChoiceOptionSource='U'


   DELETE  sco  FROM ProjectChoiceOption sco WITH(NOLOCK) INNER JOIN
   #tempDuplocateProjectChoiceOption tdpco ON sco.CustomerId=tdpco.CustomerId AND
   sco.ProjectId=tdpco.ProjectId and sco.SectionId=tdpco.SectionId and sco.ChoiceOptionCode=tdpco.ChoiceOptionCode 
   
 
   INSERT INTO SelectedChoiceOption
   SELECT 
   psc.SegmentChoiceCode	,pco.ChoiceOptionCode	,pco.ChoiceOptionSource	,slcmsco.IsSelected	,psc.SectionId	,psc.ProjectId	,psc.CustomerId	,null as OptionJson	,0 as IsDeleted
    FROM ProjectChoiceOption pco WITH(NOLOCK)
   INNER JOIN ProjectSegmentChoice psc WITH(NOLOCK)
   ON pco.ProjectId=psc.ProjectId and pco.CustomerId=psc.CustomerId and pco.SectionId=psc.SectionId AND
   pco.SegmentChoiceId=psc.SegmentChoiceId 
   LEFT OUTER JOIN SelectedChoiceOption sco WITH(NOLOCK) ON pco.CustomerId=sco.CustomerId and pco.SectionId=sco.SectionId 
   and pco.ProjectId=sco.ProjectId and pco.ChoiceOptionCode=sco.ChoiceOptionCode and psc.SegmentChoiceCode=sco.SegmentChoiceCode
   and sco.ChoiceOptionSource=pco.ChoiceOptionSource
   INNER JOIN SLCMaster..SelectedChoiceOption slcmsco WITH(NOLOCK) ON slcmsco.ChoiceOptionCode=pco.ChoiceOptionCode and slcmsco.SegmentChoiceCode=psc.SegmentChoiceCode
   WHERE psc.ProjectId=4359  
    