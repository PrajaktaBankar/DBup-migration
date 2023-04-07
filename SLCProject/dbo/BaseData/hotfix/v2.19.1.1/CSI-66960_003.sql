/*
Customer Support 66960: SLC: Missing User Content In Section
Server - 003
*/
USE SLCProject
GO
update PSS Set IsDeleted = 0 FROM ProjectSegmentStatus PSS WITH(NOLOCK) WHERE SegmentStatusId IN (868069866,868069867,868069869,868069871);
update PS Set IsDeleted = 0 FROM ProjectSegment PS WITH(NOLOCK) WHERE SegmentId IN (180441809,180441811, 180441813,180441808);
GO
EXEC usp_CorrectHierarchyBasedOnIndentLevel_DF 13442, 15179246, 0;