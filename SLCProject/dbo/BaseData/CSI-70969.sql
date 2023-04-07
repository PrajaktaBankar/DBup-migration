/*
 Server name : SLCProject_SqlSlcOp003 (Server 03)
 Customer Support 70969: SLC: Unable To Permanently Remove Text Field
*/

USE SLCProject_SqlSlcOp003
GO

UPDATE PS 
	SET PS.SegmentDescription = REPLACE (PS.SegmentDescription, '<!--[if !supportFields]-->', '')
FROM ProjectSegment PS WITH(NOLOCK) 
WHERE CustomerId = 2204 AND ISNULL(Isdeleted, 0) = 0 AND ProjectId IN (17138, 13442)
AND SegmentDescription LIKE '%if !supportFields%';
GO

UPDATE PS 
	SET PS.SegmentDescription = REPLACE (PS.SegmentDescription, '[if !supportFields]', '')
FROM ProjectSegment PS WITH(NOLOCK) 
WHERE CustomerId = 2204 AND ISNULL(Isdeleted, 0) = 0 AND ProjectId IN (17138, 13442)
AND SegmentDescription LIKE '%if !supportFields%';
GO

UPDATE PS 
	SET PS.SegmentDescription = REPLACE (PS.SegmentDescription, '<!--[if !supportLists]-->', '')
FROM ProjectSegment PS WITH(NOLOCK) 
WHERE CustomerId = 2204 AND ISNULL(Isdeleted, 0) = 0 AND ProjectId IN (17138, 13442)
AND SegmentDescription LIKE '%if !supportLists%';
GO

UPDATE PS 
	SET PS.SegmentDescription = REPLACE (PS.SegmentDescription, '[if !supportLists]', '')
FROM ProjectSegment PS WITH(NOLOCK) 
WHERE CustomerId = 2204 AND ISNULL(Isdeleted, 0) = 0 AND ProjectId IN (17138, 13442)
AND SegmentDescription LIKE '%if !supportLists%';
GO
