--Customer Support Customer Support 31084: CH Errors {CH#}: CH# Errors
--Execute this on Server 3 

 SELECT * INTO #duplicatePCO FROM (
SELECT  * ,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceId		,SortOrder	,	ProjectId	,SectionId	,CustomerId ORDER BY ChoiceOptionId)as rowno 
FROM ProjectChoiceOption  WITH(NOLOCK)  WHERE ProjectId=5376
)AS A WHERE A.rowno>1


DELETE sco  FROM selectedChoiceOPtion sco  WITH(NOLOCK) inner join #duplicatePCO dpco ON dpco.ProjectId=sco.projectId	 
and dpco.SectionId	=sco.SectionId and dpco.CustomerId =sco.CustomerId and dpco.ChoiceOptionCode=sco.ChoiceOptionCode
and sco.ChoiceOptionSource='U'
  

 DELETE A   FROM (
SELECT  * ,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceId		,SortOrder	,	ProjectId	,SectionId	,CustomerId ORDER BY ChoiceOptionId)as rowno 
FROM ProjectChoiceOption  WITH(NOLOCK)  WHERE ProjectId=5376
)AS A WHERE A.rowno>1