/*
 Server name : SLCProject_SqlSlcOp002 ( Server 02)
 Customer Support 69409: Copying Office Master creating hierarchy issues in output - 57044 
*/


USE SLCProject_SqlSlcOp002
GO

-- For Office Master - EJCDC Wesi Standard...  ID: 16390
EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 16390, 20580441, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 1211, 16390, 20580441, 0;

-- For Township of Fairhaven - Lagoon Outlet...  ID 16956 
EXEC [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 16956, 21369813, 0;
EXEC [dbo].[usp_CorrectParagraphStatus_DF] 1211, 16956, 21369813, 0;
