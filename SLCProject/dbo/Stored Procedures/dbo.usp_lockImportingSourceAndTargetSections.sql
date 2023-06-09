CREATE PROCEDURE [dbo].[usp_lockImportingSourceAndTargetSections]  
 @SectionListJson NVARCHAR(MAX),  
 @TargetProjectId INT  
AS  
BEGIN  
 DECLARE @PSectionListJson NVARCHAR(MAX) = @SectionListJson;
 DECLARE @PTargetProjectId INT = @TargetProjectId;

  SELECT SectionId, ProjectId, SourceTag, Author, CustomerId  
  INTO #LockSectionsTbl  
  FROM OPENJSON(@PSectionListJson)  
  WITH (  
   CustomerId NVARCHAR(MAX) '$.CustomerId',  
   SectionId INT '$.SectionId',    
   ProjectId INT '$.ProjectId',    
   SourceTag VARCHAR(10) '$.SourceTag',  
   Author NVARCHAR(MAX) '$.Author'  
  );  
  
  --Lock Source Sections in Source Project  
  UPDATE PS   
  SET PS.IsLockedImportSection = 1  
  FROM #LockSectionsTbl LST  
  INNER JOIN ProjectSection PS   with (nolock)
  ON PS.SectionId = LST.SectionId  
  
  --TODO Move this query to ImportSectionFromProject
  ----Lock Target Sections in Target Project  
  --UPDATE PS   
  --SET PS.IsLockedImportSection = 1  
  --FROM #LockSectionsTbl LST  
  --INNER JOIN ProjectSection PS  with (nolock)
  --ON PS.SourceTag = LST.SourceTag AND PS.Author = LST.Author  
  --WHERE PS.ProjectId = @PTargetProjectId AND PS.IsLastLevel = 1  

  
END

GO
