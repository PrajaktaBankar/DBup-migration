/*
 Server name : SLCProject_SqlSlcOp002 ( Server 02)
 Customer Support 69982: Data fix needed for TOC section selection issue - 56669/1036
*/

USE SLCProject_SqlSlcOp002
GO

---- Sequence number from 940 to 1094 has incorrect ParentSegmentStatusId in this section

EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 16026, 20077582, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 1036, 16026, 20077582, 0;