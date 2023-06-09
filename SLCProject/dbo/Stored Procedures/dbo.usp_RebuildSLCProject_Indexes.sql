CREATE PROCEDURE [dbo].[usp_RebuildSLCProject_Indexes]
AS
BEGIN

--Set NOCOUNT ON
SET NOCOUNT ON;
--Rebuil All the indexes from SLCMaster DB
BEGIN TRY
IF EXISTS (SELECT *  FROM sys.indexes  WHERE index_id in (1,2,3,4,7,8,11,21,22,23,24,26,27,28))
BEGIN
ALTER INDEX ALL ON Footer							REBUILD;
ALTER INDEX ALL ON Header							REBUILD;
ALTER INDEX ALL ON LinkedSections					REBUILD;
ALTER INDEX ALL ON LuCity							REBUILD;
ALTER INDEX ALL ON LuCountry						REBUILD;
ALTER INDEX ALL ON LuFacilityType					REBUILD;
ALTER INDEX ALL ON LuFolderType						REBUILD;
ALTER INDEX ALL ON LuFormatType						REBUILD;
ALTER INDEX ALL ON LuHeaderFooterCategory			REBUILD;
ALTER INDEX ALL ON LuHeaderFooterType				REBUILD;
ALTER INDEX ALL ON LuMasterDataType					REBUILD;
ALTER INDEX ALL ON LuProjectChoiceOptionType		REBUILD;
ALTER INDEX ALL ON LuProjectChoiceType				REBUILD;
ALTER INDEX ALL ON LuProjectCost					REBUILD;
ALTER INDEX ALL ON LuProjectImageSourceType			REBUILD;
ALTER INDEX ALL ON LuProjectLinkStatusType			REBUILD;
ALTER INDEX ALL ON LuProjectRequirementTag			REBUILD;
ALTER INDEX ALL ON LuProjectRequirementTagCategory	REBUILD;
ALTER INDEX ALL ON LuProjectSegmentStatusType		REBUILD;
ALTER INDEX ALL ON LuProjectSize					REBUILD;
ALTER INDEX ALL ON LuProjectSpecTypeTag				REBUILD;
ALTER INDEX ALL ON LuProjectTabType					REBUILD;
ALTER INDEX ALL ON LuProjectType					REBUILD;
ALTER INDEX ALL ON LuProjectUoM						REBUILD;
ALTER INDEX ALL ON LuSegmentLinkSourceType			REBUILD;
ALTER INDEX ALL ON LuStateProvince					REBUILD;
ALTER INDEX ALL ON LuTitleFormat					REBUILD;
ALTER INDEX ALL ON MaterialSectionMapping			REBUILD;
ALTER INDEX ALL ON Project							REBUILD;
ALTER INDEX ALL ON ProjectAddress					REBUILD;
ALTER INDEX ALL ON ProjectChoiceOption				REBUILD;
ALTER INDEX ALL ON ProjectGlobalTerm				REBUILD;
ALTER INDEX ALL ON ProjectHyperLink					REBUILD;
ALTER INDEX ALL ON ProjectImage						REBUILD;
ALTER INDEX ALL ON ProjectNote						REBUILD;
ALTER INDEX ALL ON ProjectNoteImage					REBUILD;
ALTER INDEX ALL ON ProjectReferenceStandard			REBUILD;
ALTER INDEX ALL ON ProjectRevitFile					REBUILD;
ALTER INDEX ALL ON ProjectRevitFileMapping			REBUILD;
ALTER INDEX ALL ON ProjectSection					REBUILD;
ALTER INDEX ALL ON ProjectSegment					REBUILD;
ALTER INDEX ALL ON ProjectSegmentChoice				REBUILD;
ALTER INDEX ALL ON ProjectSegmentGlobalTerm			REBUILD;
ALTER INDEX ALL ON ProjectSegmentImage				REBUILD;
ALTER INDEX ALL ON ProjectSegmentLink				REBUILD;
ALTER INDEX ALL ON ProjectSegmentReferenceStandard	REBUILD;
ALTER INDEX ALL ON ProjectSegmentRequirementTag		REBUILD;
ALTER INDEX ALL ON ProjectSegmentStatus				REBUILD;
ALTER INDEX ALL ON ProjectSegmentTab				REBUILD;
ALTER INDEX ALL ON ProjectSegmentTracking			REBUILD;
ALTER INDEX ALL ON ProjectSegmentUserTag			REBUILD;
ALTER INDEX ALL ON ProjectSummary					REBUILD;
ALTER INDEX ALL ON ProjectUserTag					REBUILD;
ALTER INDEX ALL ON ReferenceStandard				REBUILD;
ALTER INDEX ALL ON ReferenceStandardEdition			REBUILD;
ALTER INDEX ALL ON SelectedChoiceOption				REBUILD;
ALTER INDEX ALL ON StandaloneViewerDetails			REBUILD;
ALTER INDEX ALL ON Style							REBUILD;
ALTER INDEX ALL ON Template							REBUILD;
ALTER INDEX ALL ON TemplateStyle					REBUILD;
ALTER INDEX ALL ON UserFolder						REBUILD;
ALTER INDEX ALL ON UserGlobalTerm					REBUILD;
END
END TRY
---Error handling
BEGIN CATCH
SELECT
ERROR_NUMBER() AS ErrorNumber,
ERROR_SEVERITY() AS ErrorSeverity,
ERROR_MESSAGE() AS ErrorMessage,
ERROR_STATE() AS ErrorState

END CATCH;
END
GO
