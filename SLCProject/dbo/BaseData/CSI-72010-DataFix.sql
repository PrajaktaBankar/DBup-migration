/*
 Server name : SLCProject_SqlSlcOp002 (Server 02)
 Customer Support 72010: Table of Content Section in Office Master has a break in hierarchy - 24005/260
*/

USE SLCProject_SqlSlcOp002
GO

EXEC [usp_CorrectHierarchyBasedOnIndentLevel_DF] 6, 7072, 0;
EXEC [usp_CorrectParagraphStatus_DF] 260, 6, 7072, 0;