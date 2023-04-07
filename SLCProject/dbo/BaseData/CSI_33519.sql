--Execute this on Server 2 
--Customer Support 33519: SLC Master Paragraph Not Imported with Section


UPDATE PSS
SET PSS.SegmentStatusTypeId = 1
FROM ProjectSegmentStatus PSS with nolock
WHERE PSS.ProjectId = 5722
AND PSS.SegmentStatusId = 283102089

