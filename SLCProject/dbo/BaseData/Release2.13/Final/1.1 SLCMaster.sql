USE [SLCMaster]
GO

/**** Object: FullTextCatalog [FTSegment] Script Date: 2020-08-29 10:53:28 ****/
CREATE FULLTEXT CATALOG [FTSegment] WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
GO

/****Instructions - Please add full-text index on 'SLCMaster.dbo.Segment.SegmentDescription' column manually
Reference - 
Msg 7601, Level 16, State 2, Procedure usp_GetReferenceStandardsOfSegments, Line 51 [Batch Start Line 5712]
Cannot use a CONTAINS or FREETEXT predicate on table or indexed view 'SLCMaster.dbo.Segment' because it is not full-text indexed.
/****
