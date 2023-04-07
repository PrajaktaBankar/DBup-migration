/*
 Server name : SLCProject_SqlSlcOp003 ( Server 03)
 Customer Support 69475: SLC: Broken Hierarchy Not Allowing Activating Paragraphs
*/

USE SLCProject_SqlSlcOp003
GO

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 15868, 18093552, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 235, 15868, 18093552, 0;
