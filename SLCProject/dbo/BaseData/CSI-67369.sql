/*
 Server name : SLCProject_SqlSlcOp004 ( Server 04)
 Customer Support 67369: Hierarchy issue - 21628
*/


USE SLCProject_SqlSlcOp004
GO

-- for affected segments CurrentParentSegmentStatusId was 854279983 which was not in currect section and project.

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 1486, 17321908, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 2626, 1486, 17321908, 0;
