USE SLCProject

/*
Server - Execute on server 004
Customer Support 66275: Divisions showing in the wrong order - 16941/1355
*/
GO

UPDATE PS SET Sortorder = 1 FROM PRojectSection PS WITH(NOLOCK) where SectionId = 25509602 AND  ProjectId = 2078;
UPDATE PS SET Sortorder = 681 FROM PRojectSection PS WITH(NOLOCK) where SectionId = 25509659 AND  ProjectId = 2078;

