
--VW_SegmentDetails
CREATE VIEW [dbo].[VW_SegmentDetails] AS
SELECT
	MST.SegmentStatusId
   ,MST.SectionId
   ,ParentSegmentStatusId
   ,MST.SegmentId
   ,IndentLevel
   ,MST.SegmentSource
   ,SequenceNumber
   ,SpecTypeTagId
   ,SegmentStatusTypeId
   ,IsParentSegmentStatusActive
   ,SegmentStatusCode
   ,IsShowAutoNumber
   ,FormattingJson
   ,IsRefStdParagraph
   ,IsDeleted
   ,SegmentDescription
   ,[Version]
   ,SegmentCode
   ,MSG.UpdatedId
   ,MCH.SegmentChoiceId
   ,ChoiceTypeId
   ,MasterDataTypeId
   ,MCH.SegmentChoiceCode
   ,SegmentChoiceSource
   ,ChoiceOptionId
   ,SortOrder
   ,OptionJson
   ,MCHOP.ChoiceOptionCode
   ,MCHOP.ChoiceOptionSource
   ,SelectedChoiceOptionId
   ,IsSelected
FROM SLCMaster..SegmentStatus MST WITH (NOLOCK)
INNER JOIN SLCMaster..Segment MSG WITH (NOLOCK)
	ON MST.SegmentId = MSG.SegmentId
INNER JOIN SLCMaster..SegmentChoice AS MCH WITH (NOLOCK)
	ON MCH.SegmentId = MSG.SegmentId
INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceCode = MSCHOP.SegmentChoiceCode
		AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
