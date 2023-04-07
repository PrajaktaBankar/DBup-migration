USE SLCProject

GO

/*
Server - Execute or Server 004
Customer Support 66142: Sections out of order in the Divison listing - 12796/3828
*/

DECLARE @ParentSectionId INT = 23784722;
update ProjectSection SET SortOrder = null where projectId = 19102 and ParentSectionId = 23784722;

DROP TABLE IF EXISTS #SectionsToBeSort;
SELECT SectionId, UPPER(dbo.udf_ExpandDigits(SourceTag, 18, '0')) AS T_SourceTag, Author INTO #SectionsToBeSort 
FROM ProjectSection where ParentSectionId = @ParentSectionId and  projectId = 19102;

DROP TABLE IF EXISTS #SortedSections;
SELECT ROW_NUMBER() OVER(ORDER BY T_SourceTag, Author) AS SortOrder, SectionId, Author INTO #SortedSections FROM #SectionsToBeSort order by T_SourceTag, Author;

UPDATE PS SET SortOrder = t.SortOrder FROM ProjectSection PS WITH(NOLOCK) INNER JOIN #SortedSections t 
ON PS.SectionId = t.SectionId 
WHERE PS.ParentSectionId = 23784722 and PS.projectId = 19102;