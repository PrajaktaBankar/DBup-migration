CREATE PROCEDURE [dbo].[usp_UnlockedImportedSourceSections]  
 @SectionListJson NVARCHAR(MAX)
AS  
BEGIN
 
 DECLARE @PSectionListJson NVARCHAR(MAX) =  @SectionListJson;
SELECT
	SectionId--ProjectId, SourceTag, Author, CustomerId  
INTO #LockSectionsTbl
FROM OPENJSON(@PSectionListJson)
WITH (
-- CustomerId NVARCHAR(MAX) '$.CustomerId',  
SectionId INT '$.SectionId'
-- ProjectId INT '$.ProjectId',    
-- SourceTag NVARCHAR(MAX) '$.SourceTag',  
--Author NVARCHAR(MAX) '$.Author'  
);

--Lock Source Sections in Source Project  
UPDATE PS
SET PS.IsLockedImportSection = 0
FROM #LockSectionsTbl LST
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = LST.SectionId
END

GO
