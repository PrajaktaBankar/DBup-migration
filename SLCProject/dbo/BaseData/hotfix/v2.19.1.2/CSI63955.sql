--- Please execute it on SLCProject_SqlSlcOp004

USE [SLCProject_SqlSlcOp004]
GO

UPDATE SC
SET IsDeleted = 1
 FROM SegmentComment SC WITH (NOLOCK)
WHERE ProjectId = 17612
AND sectionid = 21804994
AND SegmentStatusId = 1230164562