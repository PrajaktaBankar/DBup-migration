
----------------Execute it on Server 01,02,03 ------------------

------Fire this query for test-----------
--SELECT MS.SegmentId, MS2.* FROM [SLCMaster].[dbo].[Segment] MS
--LEFT JOIN [SLCMaster].[dbo].[Segment] MS2 ON MS.SegmentId = MS2.UpdatedId
--WHERE MS.SectionId != MS2.SectionId
------Fire this query for test-----------


UPDATE MS2
SET MS2.UpdatedId = NULL
FROM [SLCMaster].[dbo].[Segment] MS
LEFT JOIN [SLCMaster].[dbo].[Segment] MS2 ON MS.SegmentId = MS2.UpdatedId
WHERE MS.SectionId != MS2.SectionId