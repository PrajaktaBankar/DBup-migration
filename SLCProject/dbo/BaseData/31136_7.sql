--Execute it on server 2
--Customer Support 31136: CH# on word and PDF export only - 29449 Steve Oliver with Powers Brown Architecture Holdings, Inc. - 29449

DECLARE @SegmentChoiceId int=0;
DECLARE @SegmentChoiceCode int=51031;
DECLARE @ProjectId int=4016;
DECLARE @CustomerId int=1663
DECLARE @SegmentStatusId int=187134058
DECLARE @SectionId int=4808952
DECLARE @SegmentId int =32457978
DECLARE @segmentChoiceCode1 int=51031
--row affected 1
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate,
ModifiedBy, ModifiedDate, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
	SELECT
		@SectionId as SectionId
	   ,@SegmentStatusId AS SegmentStatusId
	   ,@SegmentId AS SegmentId
	   ,ChoiceTypeId
	   ,@ProjectId AS ProjectId
	   ,@CustomerId AS CustomerId
	   ,'U'as SegmentChoiceSource
	   ,@segmentChoiceCode1 AS SegmentChoiceCode
	   ,12489 as CreatedBy
	   ,GETUTCDATE()
	   ,12489 as ModifiedBy
	   ,GETUTCDATE()
	   ,null as SLE_DocID
	   ,null as SLE_SegmentID
	   ,null as SLE_StatusID
	   ,null as SLE_ChoiceNo
	   ,null as SLE_ChoiceTypeID
	   ,null as A_SegmentChoiceId
	   ,0
	FROM SLCMaster..SegmentChoice WITH (NOLOCK)
	WHERE SegmentChoiceCode = @SegmentChoiceCode 

SET @SegmentChoiceId = (SELECT
top 1	SegmentChoiceId
FROM ProjectSegmentChoice WITH (NOLOCK)
WHERE ProjectId = @ProjectId 
AND SegmentStatusId = @SegmentStatusId
AND SegmentChoiceCode = @segmentChoiceCode1
and SegmentId=@SegmentId
)

	--rows adffected 6
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode
, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_ChoiceOptionId, IsDeleted)
	SELECT
		@SegmentChoiceId AS SegmentChoiceId
	   ,SortOrder
	   ,'U'as ChoiceOptionSource
	   ,OptionJson
	   ,@ProjectId
	   ,@SectionId
	   ,@CustomerId
	   ,ChoiceOptionCode
	   ,12489 as CreatedBy
	   ,CreateDate
	   ,12489 as ModifiedBy
	   ,GETUTCDATE()
	   ,null as A_ChoiceOptionId
	   ,0 as IsDeleted
	FROM SLCMaster..ChoiceOption WITH (NOLOCK)
	WHERE SegmentChoiceId = 51031 

	--rows affected 6
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
	SELECT
		@segmentChoiceCode1 AS SegmentChoiceCode
	   ,ChoiceOptionCode
	   ,'U' as ChoiceOptionSource
	   ,IsSelected
	   ,@SectionId as SectionId
	   ,@ProjectId AS ProjectId
	   ,@CustomerId AS Customer
	   ,NULL as OptionJson
	   ,0 as IsDeleted
	FROM SLCMaster..SelectedChoiceOption WITH (NOLOCK)
	WHERE SegmentChoiceCode = @SegmentChoiceCode
	 
	