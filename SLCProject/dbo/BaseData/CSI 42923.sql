USE SLCProject
 Go
--Customer Support 42923: SLC Duplicate choices - Andrew Goodrich 22595
--EXECUTE On server 5


  DECLARE @CustomerId int=1541
  DECLARE @Count1 int=0
  DECLARE @Count2 int=0
  DECLARE @Count3 int=0

  DROP table if exists #duplicateChoiceOption

  select * into #duplicateChoiceOption from (
  select  ROW_NUMBER()OVER (PARTITION BY SectionId,ProjectId,CustomerId, SegmentChoiceId, SortOrder ORDER BY ChoiceOptionId Asc)as row_no, 
  ChoiceOptionId, optionJson, ChoiceOptionCode, ProjectId, SectionId
 from ProjectChoiceOption with(nolock) where CustomerId=@CustomerId and isnull(isdeleted,0)=0 
   ) as a where a.row_no>1

update u
set u.isDeleted = 1
from ProjectChoiceOption u with(nolock)
inner join #duplicateChoiceOption s on
u.ChoiceOptionId = s.ChoiceOptionId

update a
set a.isDeleted=1 
from SelectedChoiceOption a with(nolock)
inner join #duplicateChoiceOption b on
a.ChoiceOptionCode=b.ChoiceOptionCode
where a.ProjectId=b.ProjectId 
and a.SectionId=b.SectionId 
and ChoiceOptionSource='M'
and IsSelected=0





