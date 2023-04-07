/*
 Server name : SLCProject_SqlSlcOp004 ( Server 04)
 Customer Support 67089: SLC: Incorrect Parent/Child Paragraph Causing Activation Conflict
*/


USE SLCProject_SqlSlcOp004
GO

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 24351, 29609146, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF]  1372,24351,29609146, 0;