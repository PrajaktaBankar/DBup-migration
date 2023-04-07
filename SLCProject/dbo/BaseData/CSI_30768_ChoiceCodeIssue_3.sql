--Execute it On Server 3
--30768: {CH#} showing in sections after making edits ( Customer ID: 61188 / Admin ID: 211 / SERVER 3 )

use [SLCProject]

DECLARE @ProjectId INT = 3711;
DECLARE @Trgt_SegmentStatusId INT = 219969157;
DECLARE @SegmentChoiceCode INT = 63208;
DECLARE @Src_SegmentStatusId INT = 216596038;
DECLARE @Trgt_SegmentChoiceId INT = null;
DECLARE @Src_SegmentChoiceId INT = 12266435
DECLARE @SectionId INT = 5080711;
DECLARE @SegmentId INT = 34993957;

-- Insert ProjectSegmentChoice Data
insert into ProjectSegmentChoice
SELECT SectionId, @Trgt_SegmentStatusId as SegmentStatusId , @SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, 
SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID,
 A_SegmentChoiceId, IsDeleted
 from ProjectSegmentChoice WITH(NOLOCK) WHERE SegmentChoiceCode = @SegmentChoiceCode and ProjectId = @ProjectId and SegmentStatusId=@Src_SegmentStatusId;
  
-- Get New SegmentChoiceId
SELECT @Trgt_SegmentChoiceId = SegmentChoiceId  from ProjectSegmentChoice WITH(NOLOCK) WHERE SegmentChoiceCode = @SegmentChoiceCode and 
				ProjectId = @ProjectId and SegmentStatusId=@Trgt_SegmentStatusId;

-- Insert ChoiceOptionCode Data
 insert into ProjectChoiceOption
SELECT @Trgt_SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate,
ModifiedBy, ModifiedDate, A_ChoiceOptionId, IsDeleted from ProjectChoiceOption WITH(NOLOCK) WHERE SegmentChoiceId = @Src_SegmentChoiceId;

-- Insert SelectedChoiceOptions Data
 insert into SelectedChoiceOption
SELECT SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted 
from SelectedChoiceOption WITH(NOLOCK) WHERE SegmentChoiceCode = @SegmentChoiceCode and ProjectId = @ProjectId AND SectionId=@SectionId;
 

update PS SET SegmentDescription = 'Glazing Method: ?{CH#10028397}?.' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 34994279;
update PS SET SegmentDescription = 'Glazing Method:  ?{CH#63208}?.' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 34993957;
update PS SET SegmentDescription = 'Glazing Method: {CH#10028397}?.' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 34994278;
