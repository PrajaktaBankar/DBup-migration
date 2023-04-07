/*
 Server name : SLCProject_SqlSlcOp005 ( Server 05)
 Customer Support 70448: SLC Paragraph Hierarchy 
*/

USE SLCProject_SqlSlcOp005
GO

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 7706, 9843190, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 4156, 7706, 9843190, 0;