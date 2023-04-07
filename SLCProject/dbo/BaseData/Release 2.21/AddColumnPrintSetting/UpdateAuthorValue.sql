/*
Bug 74955: Functional: Include Author setting is not appearing 'applied' by default in Legacy Projects
*/
USE SLCPROJECT
Go

UPDATE PS SET PS.IsIncludeAuthorForBookMark = 1 FROM  SLCProject..ProjectPrintSetting PS 
WITH (NOLOCK)  WHERE PS.IsIncludePdfBookmark = 1


