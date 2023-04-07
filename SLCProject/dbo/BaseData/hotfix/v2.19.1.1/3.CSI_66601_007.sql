
USE SLCProject
GO
exec usp_CorrectHierarchyBasedOnIndentLevel_DF 189,253268,0
GO
exec usp_CorrectParagraphStatus_DF @CustomerId=3946,@projectId=189,@sectionId=253268,@ViewOnly=0
GO
exec usp_UpdateParagraphStatusForDeletedLinks_DF 3946,189,253268,0
GO