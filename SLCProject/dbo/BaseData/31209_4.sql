 --execute on server 3
 --Customer Support 31209: Deadline Dec. 3! {CH#} Issue in Project "302014 RMLEI Renovation" ( CID = 33307 / Admin ID = 1596 / SERVER 3 )
  
 -- 335 rows should affected
 /*
Customer Support 31209: Deadline Dec. 3! {CH#} Issue in Project "302014 RMLEI Renovation" ( CID = 33307 / Admin ID = 1596 / SERVER 3 )

*/
  INSERT INTO SelectedChoiceOption
  SELECT 
   psc.SegmentChoiceCode	,slcmsco.ChoiceOptionCode	,'U' as ChoiceOptionSource,	slcmsco.IsSelected,	psc.SectionId	,psc.ProjectId	,psc.CustomerId	,NULL as OptionJson,0 as	IsDeleted
   FROM ProjectSegmentChoice psc INNER JOIN ProjectChoiceOption pco ON
  pco.SegmentChoiceId=psc.SegmentChoiceId AND pco.ProjectId=psc.ProjectId 
  AND pco.SectionId=psc.SectionId AND pco.CustomerId=psc.CustomerId 
  INNER JOIN SLCMaster..SelectedChoiceOption slcmsco ON slcmsco.ChoiceOptionCode=pco.ChoiceOptionCode 
  and psc.SegmentChoiceCode=slcmsco.SegmentChoiceCode
  LEFT OUTER JOIN SelectedChoiceOption sco on psc.SegmentChoiceCode=sco.SegmentChoiceCode
  AND pco.ProjectId=sco.ProjectId and pco.SectionId=sco.SectionId and pco.CustomerId=sco.CustomerId
  AND pco.ChoiceOptionCode=sco.ChoiceOptionCode and sco.ChoiceOptionSource='U'
  WHERE sco.SegmentChoiceCode IS NULL and psc.CustomerId=1596
   
	 DELETE   from  SelectedChoiceOption WHERE SegmentChoiceCode=310712 AND ProjectId=6140 and SelectedChoiceOptionId=501195304
	 DELETE   FROM  SelectedChoiceOption WHERE  ChoiceOptionCode=635176 AND ProjectId=6140  AND SegmentChoiceCode=310711

	DELETE   from  SelectedChoiceOption WHERE SegmentChoiceCode=310712 AND ProjectId=5562  and ChoiceOptionSource='M'
	DELETE   FROM  SelectedChoiceOption WHERE  ChoiceOptionCode=635176 AND ProjectId=5562  AND SegmentChoiceCode=310711 and ChoiceOptionSource='M'
	
	DELETE   from  SelectedChoiceOption WHERE SegmentChoiceCode=310712 AND ProjectId=5286  and ChoiceOptionSource='M'
	DELETE   FROM  SelectedChoiceOption WHERE  ChoiceOptionCode=635176 AND ProjectId=5286  AND SegmentChoiceCode=310711 and ChoiceOptionSource='M'
	
	DELETE   from  SelectedChoiceOption WHERE SegmentChoiceCode=310712 AND ProjectId=5206  and ChoiceOptionSource='M'
	DELETE   FROM  SelectedChoiceOption WHERE  ChoiceOptionCode=635176 AND ProjectId=5206  AND SegmentChoiceCode=310711 and ChoiceOptionSource='M'
		
	DELETE   from  SelectedChoiceOption WHERE SegmentChoiceCode=310712 AND ProjectId=2260  and ChoiceOptionSource='M'
	DELETE   FROM  SelectedChoiceOption WHERE  ChoiceOptionCode=635176 AND ProjectId=2260  AND SegmentChoiceCode=310711 and ChoiceOptionSource='M'


	 DELETE A FROM(
   SELECT  
   *,ROW_NUMBER()OVER(PARTITION BY ChoiceOptionCode,SegmentChoiceCode,ProjectId,SectionId,CustomerId ORDER BY SelectedChoiceOptionId DESC)as row_no
    FROM SelectedChoiceOption WHERE ChoiceOptionSource='M' and CustomerId=1596
	)AS A WHERE A.row_no>1
 
