/*
 Server name : SLCProject_SqlSlcOp004 ( Server 04)
 Customer Support 70715: SLC Paragraphs Will Not Turn On 
*/

USE SLCProject_SqlSlcOp004
GO

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 24549, 29884850, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 1636, 24549, 29884850, 0;

