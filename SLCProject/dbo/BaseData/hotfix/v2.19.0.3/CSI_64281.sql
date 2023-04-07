
/*
 server name : [SLCProject_SqlSlcOp003]
 Customer Support 64281: SLC: Export Shows Data Jargon

*/
USE [SLCProject_SqlSlcOp003]
GO

UPDATE PS
SET SegmentDescription ='Atas International, Inc; Versa-Lok: www.atas.com/#sle.'
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId=198533589

UPDATE PS
SET SegmentDescription ='Flame Spread Testing: ASTM E84'
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId=210031370

UPDATE PS
SET SegmentDescription ='Flat Lock Tiles:'
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId=210030734

UPDATE PS
SET SegmentDescription ='Tile Shape: Rectangular; [VSL 123]'
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId=210030894