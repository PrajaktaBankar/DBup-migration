CREATE PROCEDURE [dbo].[usp_GetDivisionSectionForComments] 
(                          
	@ProjectId INT,                          
	@CustomerId INT                                                
)      
AS
BEGIN

DECLARE @PProjectId INT;
DECLARE @PCustomerId INT;
DECLARE @SourceTagFormat VARCHAR(10) = '999999';     
SET @PProjectId = @ProjectId;
SET @PCustomerId = @CustomerId;
 
SET @SourceTagFormat = (SELECT TOP 1 PS.SourceTagFormat FROM ProjectSummary PS WITH(NOLOCK) 
						WHERE PS.CustomerId = @PCustomerId AND PS.ProjectId = @PProjectId);

--Select Section Data
 SELECT 
 	DISTINCT(PS.SectionId),
 	PS.[Description] AS SectionName,
	PS.SourceTag,
	PS.Author,
	PS.DivisionId,
	PS.CustomerId,
	@SourceTagFormat AS SourceTagFormat
 INTO #SectionsInfoTable 
 FROM ProjectSection PS WITH (NOLOCK)
 INNER JOIN SegmentComment SC WITH (NOLOCK)
 ON PS.ProjectId = SC.ProjectId
 AND PS.SectionId = SC.SectionId
 AND ISNULL(SC.IsDeleted,0) = 0
 INNER JOIN ProjectSegmentStatus PSS WITH(NOLOCK)
	ON SC.CustomerId = PSS.CustomerId AND SC.ProjectId = PSS.ProjectId AND SC.SectionId = PSS.SectionId AND SC.SegmentStatusId = PSS.SegmentStatusId AND ISNULL(PSS.IsDeleted, 0) = 0
 WHERE PS.CustomerId = @PCustomerId
 AND PS.ProjectId = @PProjectId
 AND ISNULL(PS.IsDeleted, 0) = 0
 AND ISNULL(PS.IsHidden, 0) = 0

--Select Division Data
 SELECT DISTINCT                                                
     SIT.DivisionId                                                
    ,PS3.SourceTag AS DivisionCode                                                
    ,PS3.[Description] AS DivisionName
	INTO #DivisionInfoTable                                                	
	FROM #SectionsInfoTable SIT                                              
	INNER JOIN Projectsection PS1 WITH (NOLOCK)
	ON SIT.SectionId = PS1.SectionId
	INNER JOIN ProjectSection PS2 WITH (NOLOCK) 
	ON PS1.CustomerId = PS2.CustomerId AND PS1.ProjectId = PS2.ProjectId AND PS1.ParentSectionId = PS2.SectionId
	INNER JOIN ProjectSection PS3 WITH (NOLOCK)
	ON PS2.CustomerId = PS3.CustomerId AND PS2.ProjectId = PS3.ProjectId AND PS2.ParentSectionId = PS3.SectionId
	WHERE PS1.CustomerId = @PCustomerId
	AND PS1.ProjectId = @PProjectId

  UPDATE #DivisionInfoTable SET DivisionCode = '99' WHERE DivisionName = 'Administration'
	    
--Final Output
 SELECT * FROM #SectionsInfoTable ORDER BY SourceTag
 SELECT * FROM #DivisionInfoTable
 SELECT 
 IsIncludeAuthor, 
 IsIncludeParagraphText 
 FROM ProjectReportExportSetting 
 WHERE CustomerId = @PCustomerId 
 AND ProjectId = @PProjectId
 AND ISNULL(IsDeleted,0) = 0

END
GO