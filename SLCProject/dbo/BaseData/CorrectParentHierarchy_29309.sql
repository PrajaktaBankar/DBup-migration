--Execute it on server 3
--Customer Support 29309: Cannot Update Section

--InCorrect Parents : 
--UPDATE PSS SET  PSS.IndentLevel = 6, PSS.ParentSegmentStatusId = 143634090 FROM [ProjectSegmentStatus] PSS WHERE PSS.SegmentStatusId = 143681975

USE [SLCProject_SqlSlcOp003]
----Correct Parents : 
UPDATE PSS  SET PSS.IndentLevel = 5, PSS.ParentSegmentStatusId = 143603198
FROM ProjectSegmentStatus PSS with (NOLOCK)
WHERE PSS.SegmentStatusId = 143681975

--Seq 0403 - Decrease Indent - Then it will be ready to update
--Seq 0379 - Decrease Branch Indent
--Seq 0379 - Decrease Branch Indent
--Seq 0379 - Increase Indent
--9 Ready to updates/1 Needs Review
-- Accept 9 Updates
-- Seq 0379 - Decrease Indent
-- Seq 0379 - Decrease Indent - Paragraph will come to level 2
-- Go to update mode - Accept 1 update in needs review category