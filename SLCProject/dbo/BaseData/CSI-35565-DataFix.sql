/*
Customer Support 35565: SLC Paragraphs Printing in a Section Tagged to Not Print
Server 2
*/
USE [SLCProject_SqlSlcOp002]
GO

UPDATE PSS
SET PSS.ParentSegmentStatusId = 344711070
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.SegmentStatusId IN (343104316, 326669030)