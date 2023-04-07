--EXECUTE ON Sevver 4
--Customer Support 30472: Multiple Fill in the Blank Choice Issues - 18912



 SELECT PS.ProjectId,PS.SectionId,PS.CustomerId into #TempProjectSection FROM Project P INNER JOIN ProjectSection PS WITH(NOLOCK)ON
 P.ProjectId=PS.ProjectId AND P.CustomerId=PS.CustomerId 
 where P.CustomerId=1431 AND ISNULL(P.IsDeleted,0)=0
 AND PS.SourceTag='079200'


---132 rows should affected
INSERT INTO SelectedChoiceOption
SELECT SCO.SegmentChoiceCode	, SCO.ChoiceOptionCode	
, SCO.ChoiceOptionSource	, 
SCO.IsSelected	,TPS.SectionId	,
TPS.ProjectId	,TPS.CustomerId,	null,	0 
FROM  SLCMaster..SelectedChoiceOption  SCO WITH(NOLOCK)
CROSS JOIN #TempProjectSection TPS  
WHERE SegmentChoiceCode IN (
312361,312362,312363,312364) ORDER BY TPS.ProjectId
 