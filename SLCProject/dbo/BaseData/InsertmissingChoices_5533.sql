--Execute it on server 3
--Customer Support 30405: CH# - Steven Moore with MGMA - 10272

DECLARE @SegmentChoiceId int=0;
DECLARE @SegmentChoiceCode int=83806;
DECLARE @ProjectId int=5533;

--row affected 1
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate,
ModifiedBy, ModifiedDate, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
	SELECT
		SectionId
	   ,210753143 AS SegmentStatusId
	   ,33353456 AS SegmentId
	   ,ChoiceTypeId
	   ,ProjectId
	   ,CustomerId
	   ,SegmentChoiceSource
	   ,@SegmentChoiceCode AS SegmentChoiceCode
	   ,CreatedBy
	   ,CreateDate
	   ,ModifiedBy
	   ,ModifiedDate
	   ,SLE_DocID
	   ,SLE_SegmentID
	   ,SLE_StatusID
	   ,SLE_ChoiceNo
	   ,SLE_ChoiceTypeID
	   ,A_SegmentChoiceId
	   ,IsDeleted
	FROM ProjectSegmentChoice WITH (NOLOCK)
	WHERE segmentchoicecode = 10026632
	AND ProjectId = @ProjectId 

SET @SegmentChoiceId = (SELECT
		SegmentChoiceId
	FROM ProjectSegmentChoice WITH (NOLOCK)
	WHERE ProjectId = @ProjectId 
	AND SegmentStatusId = 210753143
	AND SegmentChoiceCode = @SegmentChoiceCode)

	--rows adffected 5
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode
, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_ChoiceOptionId, IsDeleted)
	SELECT
		@SegmentChoiceId AS SegmentChoiceId
	   ,SortOrder
	   ,ChoiceOptionSource
	   ,OptionJson
	   ,ProjectId
	   ,SectionId
	   ,CustomerId
	   ,ChoiceOptionCode
	   ,CreatedBy
	   ,CreateDate
	   ,ModifiedBy
	   ,ModifiedDate
	   ,A_ChoiceOptionId
	   ,IsDeleted
	FROM ProjectChoiceOption WITH (NOLOCK)
	WHERE SegmentChoiceId = 11648918
	AND ProjectId = @ProjectId 

	--rows affected 5
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
	SELECT
		@SegmentChoiceCode AS SegmentChoiceCode
	   ,ChoiceOptionCode
	   ,ChoiceOptionSource
	   ,IsSelected
	   ,SectionId
	   ,ProjectId
	   ,CustomerId
	   ,OptionJson
	   ,IsDeleted
	FROM SelectedChoiceOption WITH (NOLOCK)
	WHERE SegmentChoiceCode = 10026632
	AND ProjectId = @ProjectId  
	
	
	--rows affected 2	
    INSERT INTO SelectedChoiceOption
    SELECT 
    SegmentChoiceCode,	ChoiceOptionCode,	ChoiceOptionSource,	IsSelected	,4994849 as SectionId	,@ProjectId  as ProjectId	,810 as CustomerId,	OptionJson	,IsDeleted
    FROM SelectedChoiceOption  WITH (NOLOCK) WHERE SegmentChoiceCode=302704 and SectionId =627363 and ProjectId=@ProjectId 
 
	
	
	