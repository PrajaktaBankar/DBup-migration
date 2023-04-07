
--VW_ProjectSegmentLink
CREATE VIEW [dbo].[VW_ProjectSegmentLink] AS
SELECT
	*
FROM ProjectSegmentLink
WHERE IsDeleted = 0
AND SegmentLinkSourceTypeId != 4
