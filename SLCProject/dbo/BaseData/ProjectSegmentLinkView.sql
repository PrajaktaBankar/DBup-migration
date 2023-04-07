
CREATE VIEW [dbo].[ProjectSegmentLinkView]  
AS
SELECT  
	SegmentLinkId
	,ProjectId
	,CustomerId
	,SourceSectionCode
	,SourceSegmentStatusCode
	,SourceSegmentCode
	,SourceSegmentChoiceCode
	,SourceChoiceOptionCode
	,LinkSource
	,TargetSectionCode
	,TargetSegmentStatusCode
	,TargetSegmentCode
	,TargetSegmentChoiceCode
	,TargetChoiceOptionCode
	,LinkTarget
	,LinkStatusTypeId
	,IsDeleted
	,SegmentLinkCode
	,SegmentLinkSourceTypeId  
FROM ProjectSegmentLink WITH (NOLOCK)

GO


