/*
 Server name : SLCProject_SqlSlcOp004 ( Server 04)
 CSI 70722: Export of TOC Report to Word generates a corrupt output - 21406/1410
*/

USE SLCProject_SqlSlcOp004
GO

-- Old SpaceBelowParagraph is 1655 which is less that default spacing mentioned in code.
-- So we need to increase it 3096
UPDATE Style SET SpaceBelowParagraph = 3096 WHERE StyleId IN (10718, 10720);
