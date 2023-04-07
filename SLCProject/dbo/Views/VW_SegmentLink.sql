
--VW_SegmentLink
CREATE VIEW [dbo].[VW_SegmentLink] AS
SELECT
	*
FROM SLCMaster..SegmentLink
WHERE IsDeleted = 0
AND SegmentLinkSourceTypeId != 4
