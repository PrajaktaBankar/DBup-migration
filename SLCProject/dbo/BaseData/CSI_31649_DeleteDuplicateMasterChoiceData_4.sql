

DECLARE @ProjectId int =5057
DECLARE @CustomerId int=1663

DELETE  A FROM (

 SELECT  *,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceCode,ChoiceOptionCode,ChoiceOptionSource,SectionId,ProjectId,CustomerId ORDER BY SelectedChoiceOptionId)As RowNo 
 FROM SelectedChoiceOption   WITH(NOLOCK) 
 WHERE ProjectId=@ProjectId AND CustomerId=@CustomerId AND ChoiceOptionSource='M'
)AS A WHERE A.RowNo>1

