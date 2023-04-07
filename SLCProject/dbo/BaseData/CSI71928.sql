USE SLCProject
/*
Customer Support 71928: Section selection from the tree not working.
Run this in server 5
*/

UPDATE dbo.ProjectSegmentStatus SET ParentSegmentStatusId=0 WHERE SegmentStatusId=517029673
UPDATE dbo.ProjectSegmentStatus SET ParentSegmentStatusId=0 WHERE SegmentStatusId=517034851


/*
SELECT * FROM dbo.project ps WHERE ps.CustomerId=4119
SELECT * FROM dbo.ProjectSection ps WHERE ps.ProjectId=9050 AND ps.SourceTag LIKE '226712'
SELECT * FROM dbo.ProjectSegmentStatus pss WHERE pss.ProjectId=9050 AND sectionid =11666163 ORDER BY pss.SequenceNumber

SELECT * FROM dbo.ProjectSegmentStatusview pss WHERE pss.ProjectId=9050 AND sectionid =11666163 ORDER BY pss.SequenceNumber

SELECT * FROM dbo.ProjectSection ps WHERE ps.ProjectId=9050 AND ps.SourceTag LIKE '226112'
SELECT * FROM dbo.ProjectSegmentStatusview pss WHERE pss.ProjectId=9050 AND sectionid =11666182 ORDER BY pss.SequenceNumber
*/
