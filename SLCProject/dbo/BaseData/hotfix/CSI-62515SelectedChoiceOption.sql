/*
Customer Support 62515: SLC: Choice Text Display

Server:5

------Description---------------

duplicate master choice In selectedchoiceoption table
select * FROM (
 SELECT  *,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceCode,ChoiceOptionCode,ChoiceOptionSource,SectionId,ProjectId,CustomerId ORDER BY SelectedChoiceOptionId)As RowNo 
 FROM SelectedChoiceOption  WITH(NOLOCK) 
 WHERE ProjectId=@ProjectId AND CustomerId=@CustomerId AND ChoiceOptionSource='M'  
)AS A WHERE A.RowNo>1

*/

DECLARE @ProjectId int =3679
DECLARE @CustomerId int=1947

Delete A FROM (
 SELECT  *,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceCode,ChoiceOptionCode,ChoiceOptionSource,SectionId,ProjectId,CustomerId ORDER BY SelectedChoiceOptionId)As RowNo 
 FROM SelectedChoiceOption  WITH(NOLOCK) 
 WHERE ProjectId=@ProjectId AND CustomerId=@CustomerId AND ChoiceOptionSource='M'  
)AS A WHERE A.RowNo>1