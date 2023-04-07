
---Delete duplicate records in ProjectChoiceOption table execute this on SLCProject_SqlSlc003
DECLARE @ProjectId int=4763
DECLARE @CustomerID INt = 546

--You can execute this at this time.bz we are going to softdelete
UPDATE  A SET IsDeleted=1 FROM
(
select 
SegmentChoiceId
,ChoiceOptionId
,SortOrder
,IsDeleted
,ROW_NUMBER() OVER ( PARTITION BY SegmentChoiceId,SortOrder ORDER BY SegmentChoiceId,SortOrder)AS row_num
from ProjectChoiceOption where ProjectId=@ProjectId AND CustomerId=@CustomerID
) A
WHERE row_num >1
--You can execute this at this time.bz we are going to softdelete



--Execute This at out of buisness hours, bz it will cause the deadlock
DELETE A FROM
(
select 
SegmentChoiceId
,ChoiceOptionId
,SortOrder
,ROW_NUMBER() OVER ( PARTITION BY SegmentChoiceId,SortOrder ORDER BY SegmentChoiceId,SortOrder)AS row_num
from ProjectChoiceOption  WHERE ProjectId=@ProjectId AND CustomerId=@CustomerID and IsDeleted = 1
) A
WHERE row_num >1
--Execute This at out of buisness hours, bz it will cause the deadlock


