
--Customer Support 31084: CH Errors {CH#}
--Execute this on Server 3 

DECLARE @ProjectId int =5376
DECLARE @CustomerId int=294

DELETE  A FROM (

 SELECT  *,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceCode,ChoiceOptionCode,ChoiceOptionSource,SectionId,ProjectId,CustomerId ORDER BY SelectedChoiceOptionId)As RowNo 
 FROM SelectedChoiceOption  WITH(NOLOCK) 
 WHERE ProjectId=@ProjectId AND CustomerId=@CustomerId AND ChoiceOptionSource='M'
)AS A WHERE A.RowNo>1

