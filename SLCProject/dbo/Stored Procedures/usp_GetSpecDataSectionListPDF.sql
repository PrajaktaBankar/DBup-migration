
CREATE PROCEDURE [dbo].[usp_GetSpecDataSectionListPDF]     
(                
 @ProjectId INT        
)                
AS                
BEGIN
                
            
DECLARE @PProjectId INT = @ProjectId;

DROP TABLE IF EXISTS #ProjectInfoTbl;
DROP TABLE IF EXISTS #ActiveSectionsTbl;
DROP TABLE IF EXISTS #DistinctDivisionTbl;
DROP TABLE IF EXISTS #ActiveSectionsIdsTbl;

SELECT
	P.ProjectId
   ,p.CustomerId
   ,p.UserId
   ,P.[Name] AS ProjectName
   ,P.MasterDataTypeId
   ,PS.SourceTagFormat
   ,PS.SpecViewModeId
   ,PS.UnitOfMeasureValueTypeId
   ,P.CreatedBy
   ,P.CreateDate INTO #ProjectInfoTbl
FROM Project P WITH (NOLOCK)
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON PS.ProjectId = P.ProjectId
WHERE P.ProjectId = @PProjectId

SELECT
	PIT.ProjectId
   ,PIT.CustomerId
   ,P.CreatedBy AS CreatedBy
   ,IsNull(P.ModifiedByFullName,'') AS CreatedByFullName
   ,P.CreateDate AS LocalDate
   ,P.[Name] AS ProjectName
   ,PIT.MasterDataTypeId
   ,P.[Description] AS FileName
   ,'' AS FilePath
   ,'In Progress' AS FileStatus
   ,'' AS LocalTime
FROM #ProjectInfoTbl PIT
INNER JOIN Project P WITH (NOLOCK)
	ON P.ProjectId = @PProjectId

SELECT
	SectionId INTO #ActiveSectionsIdsTbl
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PProjectId
AND PSST.SequenceNumber = 0
AND PSST.IndentLevel = 0
AND PSST.SegmentStatusTypeId < 6
AND ISNULL(PSST.IsDeleted, 0) = 0

SELECT
	PS.ProjectId
   ,PS.CustomerId
   ,PS.SectionId
   ,PS.UserId
   ,PS.SourceTag
   ,PS.[Description] AS SectionName
   ,PS.DivisionId
   ,PS.Author INTO #ActiveSectionsTbl
FROM #ActiveSectionsIdsTbl AST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = AST.SectionId


SELECT
	AST.ProjectId
   ,AST.CustomerId
   ,AST.SectionId
   ,AST.UserId
   ,AST.SourceTag
   ,AST.SectionName
   ,AST.DivisionId
   ,AST.Author
   ,PIT.ProjectName
   ,PIT.MasterDataTypeId
   ,PIT.SourceTagFormat
   ,PIT.SpecViewModeId
   ,PIT.UnitOfMeasureValueTypeId
FROM #ActiveSectionsTbl AST
INNER JOIN #ProjectInfoTbl PIT
	ON PIT.ProjectId = AST.ProjectId
ORDER BY AST.SourceTag

IF NOT EXISTS (SELECT TOP 1
			1
		FROM ProjectPrintSetting WITH (NOLOCK)
		WHERE ProjectId = @PProjectId)
BEGIN
SELECT
	@PProjectId AS ProjectId
   ,IsExportInMultipleFiles
   ,IsBeginSectionOnOddPage
   ,IsIncludeAuthorInFileName
   ,TCPrintModeId
   ,IsIncludePageCount
   ,IsIncludeHyperLink
   ,KeepWithNext
   ,IsPrintMasterNote  
   ,IsPrintProjectNote  
   ,IsPrintNoteImage  
   ,IsPrintIHSLogo   
FROM ProjectPrintSettingPDF WITH (NOLOCK)
WHERE CustomerId IS NULL
AND ProjectId IS NULL
AND CreatedBy IS NULL
END
ELSE
BEGIN
SELECT
	@PProjectId AS ProjectId
   ,CustomerId AS CustomerId
   ,CreatedBy AS CreatedBy
   ,IsExportInMultipleFiles
   ,IsBeginSectionOnOddPage
   ,IsIncludeAuthorInFileName
   ,TCPrintModeId
   ,IsIncludePageCount
   ,IsIncludeHyperLink
   ,KeepWithNext
   ,IsNull(IsPrintMasterNote,0) as IsPrintMasterNote  
   ,IsNull(IsPrintProjectNote,0) as IsPrintProjectNote  
   ,IsNull(IsPrintNoteImage,0) as IsPrintNoteImage  
   ,IsNull(IsPrintIHSLogo,0) as IsPrintIHSLogo   
FROM ProjectPrintSetting WITH (NOLOCK)
WHERE ProjectId = @PProjectId

END

END