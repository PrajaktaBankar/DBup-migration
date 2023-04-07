--Execute this on Server 4
--Customer Support 78000: SLC Hierarchy issue in two projects
--Record will be affected 14 for each project
--ProjectId, SectionId, ViewOnly (1 = Show records have issue, 0 = Update records and make correction)

Exec [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 32494, 40873774, 0
Exec [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 8167, 38535520, 0
Exec [dbo].[usp_CorrectHierarchyBasedOnIndentLevel_DF] 30456, 37943274, 0