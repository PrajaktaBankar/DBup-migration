/*
Execute on Server 2
Customer Support 30900: SLC Customer Has {CH#} Issue

*/
declare @SegmentChoiceId int=0

insert into ProjectSegmentChoice
select  
2044144 as SectionId	
,64553645 as SegmentStatusId	
,8305179 as SegmentId	
,ChoiceTypeId	
,1664 as ProjectId,	
CustomerId	
,SegmentChoiceSource	
,92730 as SegmentChoiceCode	
,CreatedBy,CreateDate,ModifiedBy,ModifiedDate,SLE_DocID,SLE_SegmentID,SLE_StatusID,SLE_ChoiceNo,SLE_ChoiceTypeID,A_SegmentChoiceId,IsDeleted
from ProjectSegmentChoice with (nolock)
where ProjectId=1664 and SectionId=2044143 and SegmentChoiceCode =10026817
		 
set @SegmentChoiceId = SCOPE_IDENTITY()
	 	 
insert into ProjectChoiceOption
select 
@SegmentChoiceId as SegmentChoiceId	,SortOrder	,ChoiceOptionSource	,OptionJson	,ProjectId	,2044144 as SectionId,	CustomerId	,
ChoiceOptionCode	,CreatedBy	,CreateDate	,ModifiedBy	,ModifiedDate	,A_ChoiceOptionId	,IsDeleted 
from ProjectChoiceOption with (nolock)
where SegmentChoiceId=14872105

insert into SelectedChoiceOption
select 92730 as SegmentChoiceCode	,ChoiceOptionCode	,ChoiceOptionSource	,IsSelected,2044144 as  SectionId	
,ProjectId	,CustomerId	,OptionJson	,IsDeleted 
from SelectedChoiceOption with (nolock)
where ProjectId=1664 and SectionId=2044143 and SegmentChoiceCode =10026817 and ChoiceOptionSource='U'

--***********************************************************************************************************************
	
insert into ProjectSegmentChoice
select  2044144 as SectionId	,64553645 as SegmentStatusId	,8305179 as SegmentId	,ChoiceTypeId	,1664 as ProjectId,	CustomerId	, 
SegmentChoiceSource	,28369 as SegmentChoiceCode	,CreatedBy	,CreateDate	,ModifiedBy	,ModifiedDate	,SLE_DocID
,SLE_SegmentID	,SLE_StatusID	,SLE_ChoiceNo	,SLE_ChoiceTypeID	,A_SegmentChoiceId	,IsDeleted
from ProjectSegmentChoice with (nolock)
where ProjectId=1664 and SectionId=2044143 and SegmentChoiceCode = 239978

set @SegmentChoiceId = SCOPE_IDENTITY()

insert into ProjectChoiceOption
select 
@SegmentChoiceId as SegmentChoiceId	,SortOrder	,ChoiceOptionSource	,OptionJson	,ProjectId	,2044144 as SectionId,	CustomerId	,
ChoiceOptionCode	,CreatedBy	,CreateDate	,ModifiedBy	,ModifiedDate	,A_ChoiceOptionId	,IsDeleted 
from ProjectChoiceOption with (nolock)
where SegmentChoiceId=14872104

insert into SelectedChoiceOption
select 28369 as SegmentChoiceCode	,ChoiceOptionCode	,ChoiceOptionSource	,IsSelected,2044144 as  SectionId	
,ProjectId	,CustomerId	,OptionJson	,IsDeleted 
from SelectedChoiceOption with (nolock)
where ProjectId=1664 and SectionId=2044143 and SegmentChoiceCode = 239978 and ChoiceOptionSource='U'


