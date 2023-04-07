/*
 Server name : SLCProject_SqlSlcOp005 ( Server 05)
 Customer Support 68275: SLC Paragraphs Not Showing in TOC Print Preview
*/


USE SLCProject_SqlSlcOp005
GO

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 7873, 10065946, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF]  4269,7873,10065946, 0;