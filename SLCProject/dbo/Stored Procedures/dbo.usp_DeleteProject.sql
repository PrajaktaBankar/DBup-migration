CREATE PROCEDURE [dbo].[usp_DeleteProject](  
 @ProjectIdString NVARCHAR(MAX) = ''
)
AS
begin
DECLARE @PProjectIdString NVARCHAR(MAX) = @ProjectIdString;
BEGIN TRY
BEGIN TRANSACTION

DROP TABLE IF EXISTS TemplateStyleTemp
DROP TABLE IF EXISTS StyleTemp
DROP TABLE IF EXISTS TemplateTemp
DROP TABLE IF EXISTS newTable
DROP TABLE IF EXISTS MyTable
DROP TABLE IF EXISTS _BimFileDetails
DROP TABLE IF EXISTS SelectedChoiceOptionTemp1

ALTER TABLE LinkedSections NOCHECK CONSTRAINT ALL
ALTER TABLE MaterialSection NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentTab NOCHECK CONSTRAINT ALL
ALTER TABLE MaterialSectionMapping NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectRevitFile NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectRevitFileMapping NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentTracking NOCHECK CONSTRAINT ALL
ALTER TABLE HeaderFooterGlobalTermUsage NOCHECK CONSTRAINT ALL
ALTER TABLE HeaderFooterReferenceStandardUsage NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectGlobalTerm NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectHyperLink NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectNote NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectReferenceStandard NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentGlobalTerm NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectNoteImage NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentImage NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentLink NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentReferenceStandard NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentRequirementTag NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentUserTag NOCHECK CONSTRAINT ALL
ALTER TABLE UserGlobalTerm NOCHECK CONSTRAINT ALL
ALTER TABLE Header NOCHECK CONSTRAINT ALL
ALTER TABLE Footer NOCHECK CONSTRAINT ALL
ALTER TABLE SelectedChoiceOption NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectChoiceOption NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentChoice NOCHECK CONSTRAINT ALL
ALTER TABLE PROJECTSEGMENT NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentStatus NOCHECK CONSTRAINT ALL
ALTER TABLE PROJECTSECTION NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectSummary NOCHECK CONSTRAINT ALL
ALTER TABLE UserFolder NOCHECK CONSTRAINT ALL
ALTER TABLE ProjectAddress NOCHECK CONSTRAINT ALL
ALTER TABLE PROJECT NOCHECK CONSTRAINT ALL

SELECT splitdata as ProjectId into #projectIds FROM dbo.fn_SplitString(@PProjectIdString, ',')

DELETE physicalTable
FROM LinkedSections as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable
FROM MaterialSection as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable
FROM ProjectSegmentTab as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable
FROM MaterialSectionMapping as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable
FROM ProjectRevitFile as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable 
FROM ProjectRevitFileMapping as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentTracking as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM HeaderFooterGlobalTermUsage as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM HeaderFooterReferenceStandardUsage as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectGlobalTerm as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectHyperLink as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectNote as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectNoteImage as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectReferenceStandard as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentGlobalTerm as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentImage as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentLink as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentReferenceStandard as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentRequirementTag as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentUserTag as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM UserGlobalTerm as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM Header as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM Footer as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM SelectedChoiceOption as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectChoiceOption as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentChoice as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM PROJECTSEGMENT as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSegmentStatus as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM PROJECTSECTION as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectSummary as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM UserFolder as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM ProjectAddress as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 

DELETE physicalTable FROM PROJECT as physicalTable WITH(NOLOCK) 
inner join #projectIds t
on physicalTable.ProjectId =t.ProjectId 


ALTER TABLE LinkedSections CHECK CONSTRAINT ALL
ALTER TABLE MaterialSection CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentTab CHECK CONSTRAINT ALL
ALTER TABLE MaterialSectionMapping CHECK CONSTRAINT ALL
ALTER TABLE ProjectRevitFile CHECK CONSTRAINT ALL
ALTER TABLE ProjectRevitFileMapping CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentTracking CHECK CONSTRAINT ALL
ALTER TABLE HeaderFooterGlobalTermUsage CHECK CONSTRAINT ALL
ALTER TABLE HeaderFooterReferenceStandardUsage CHECK CONSTRAINT ALL
ALTER TABLE ProjectGlobalTerm CHECK CONSTRAINT ALL
ALTER TABLE ProjectHyperLink CHECK CONSTRAINT ALL
ALTER TABLE ProjectNote CHECK CONSTRAINT ALL
ALTER TABLE ProjectReferenceStandard CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentGlobalTerm CHECK CONSTRAINT ALL
ALTER TABLE ProjectNoteImage CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentImage CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentLink CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentReferenceStandard CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentRequirementTag CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentUserTag CHECK CONSTRAINT ALL
ALTER TABLE UserGlobalTerm CHECK CONSTRAINT ALL
ALTER TABLE Header CHECK CONSTRAINT ALL
ALTER TABLE Footer CHECK CONSTRAINT ALL
ALTER TABLE SelectedChoiceOption CHECK CONSTRAINT ALL
ALTER TABLE ProjectChoiceOption CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentChoice CHECK CONSTRAINT ALL
ALTER TABLE PROJECTSEGMENT CHECK CONSTRAINT ALL
ALTER TABLE ProjectSegmentStatus CHECK CONSTRAINT ALL
ALTER TABLE PROJECTSECTION CHECK CONSTRAINT ALL
ALTER TABLE ProjectSummary CHECK CONSTRAINT ALL
ALTER TABLE UserFolder CHECK CONSTRAINT ALL
ALTER TABLE ProjectAddress CHECK CONSTRAINT ALL
ALTER TABLE PROJECT CHECK CONSTRAINT ALL

COMMIT TRANSACTION -- Transaction Success!
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION --RollBack in case of Error   
END CATCH
END

GO
