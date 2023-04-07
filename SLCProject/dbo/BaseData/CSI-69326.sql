/*
 Server name : SLCProject_SqlSlcOp004 ( Server 04)
 Customer Support 69326: SLC: Hierarchy Break Issue/Unable to Activate Paragraph
*/


USE SLCProject_SqlSlcOp004
GO

--Old ParentSegmentStatusId = 613150327
-- New should be 1669995871

UPDATE ProjectSegmentStatus SET ParentSegmentStatusId = 1669995871  WHERE SegmentStatusId IN (
1669995574,
1669995781,
1669995827,
1669995924,
1669995829);

UPDATE ProjectSegmentStatus SET IsParentSegmentStatusActive = 1 WHERE SegmentStatusId IN (
1669995574,
1669995781,
1669995827,
1669995924,
1669995829);

UPDATE ProjectSegmentStatus SET SegmentStatusTypeId = 4 WHERE SegmentStatusId = 1669995871


