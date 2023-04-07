
USE [SLCProject]
GO

DECLARE @USG_CustomerId AS INT = 3227
DECLARE @Schneider_CustomerId AS INT = 3810
DECLARE @Prologis_CustomerId AS INT = 4514
DECLARE @CoveTool_CustomerId AS INT = 4558
DECLARE @Dormakaba_CustomerId AS INT = 92

--Update IsPrintMasterNote flag to True so Master notes can be printed with Spec Document generated from Linking Tool

UPDATE ProjectPrintSetting SET IsPrintMasterNote = 0
WHERE CustomerId IS NULL
AND ProjectId IS NULL
AND CreatedBy IS NULL

--Insert record into ProjectPrintSetting with CustomerID as @USG_CustomerId and ProjectIda and CreatedBy as NULL, Master Notes will be printed based on this record whether IsPrintMasterNote set to True
IF NOT EXISTS (SELECT TOP 1 1 FROM ProjectPrintSetting WHERE CustomerId = @USG_CustomerId AND ProjectId IS NULL AND CreatedBy IS NULL)
BEGIN
	INSERT INTO ProjectPrintSetting
	([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments])
	SELECT NULL AS [ProjectId],@USG_CustomerId AS [CustomerId],NULL AS [CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],0 AS [IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments]
	FROM ProjectPrintSetting WITH (NOLOCK) WHERE CustomerId IS NULL AND ProjectId IS NULL AND CreatedBy IS NULL
END


--Insert record into ProjectPrintSetting with CustomerID as @Schneider_CustomerId and ProjectIda and CreatedBy as NULL, Master Notes will be printed based on this record whether IsPrintMasterNote set to True
IF NOT EXISTS (SELECT TOP 1 1 FROM ProjectPrintSetting WHERE CustomerId = @Schneider_CustomerId AND ProjectId IS NULL AND CreatedBy IS NULL)
BEGIN
	INSERT INTO ProjectPrintSetting
	([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments])
	SELECT NULL AS [ProjectId],@Schneider_CustomerId AS [CustomerId],NULL AS [CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],1 AS [IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments]
	FROM ProjectPrintSetting WITH (NOLOCK) WHERE CustomerId IS NULL AND ProjectId IS NULL AND CreatedBy IS NULL
END


--Insert record into ProjectPrintSetting with CustomerID as @Prologis_CustomerId and ProjectIda and CreatedBy as NULL, Master Notes will be printed based on this record whether IsPrintMasterNote set to True
IF NOT EXISTS (SELECT TOP 1 1 FROM ProjectPrintSetting WHERE CustomerId = @Prologis_CustomerId AND ProjectId IS NULL AND CreatedBy IS NULL)
BEGIN
	INSERT INTO ProjectPrintSetting
	([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments])
	SELECT NULL AS [ProjectId],@Prologis_CustomerId AS [CustomerId],NULL AS [CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],0 AS [IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments]
	FROM ProjectPrintSetting WITH (NOLOCK) WHERE CustomerId IS NULL AND ProjectId IS NULL AND CreatedBy IS NULL
END


--Insert record into ProjectPrintSetting with CustomerID as @CoveTool_CustomerId and ProjectIda and CreatedBy as NULL, Master Notes will be printed based on this record whether IsPrintMasterNote set to True
IF NOT EXISTS (SELECT TOP 1 1 FROM ProjectPrintSetting WHERE CustomerId = @CoveTool_CustomerId AND ProjectId IS NULL AND CreatedBy IS NULL)
BEGIN
	INSERT INTO ProjectPrintSetting
	([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments])
	SELECT NULL AS [ProjectId],@CoveTool_CustomerId AS [CustomerId],NULL AS [CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],0 AS [IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments]
	FROM ProjectPrintSetting WITH (NOLOCK) WHERE CustomerId IS NULL AND ProjectId IS NULL AND CreatedBy IS NULL
END


--Insert record into ProjectPrintSetting with CustomerID as @Dormakaba_CustomerId and ProjectIda and CreatedBy as NULL, Master Notes will be printed based on this record whether IsPrintMasterNote set to True
IF NOT EXISTS (SELECT TOP 1 1 FROM ProjectPrintSetting WHERE CustomerId = @Dormakaba_CustomerId AND ProjectId IS NULL AND CreatedBy IS NULL)
BEGIN
	INSERT INTO ProjectPrintSetting
	([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments])
	SELECT NULL AS [ProjectId],@Dormakaba_CustomerId AS [CustomerId],NULL AS [CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage],[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount]
		,[IsIncludeHyperLink],[KeepWithNext],0 AS [IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo],[IsIncludePdfBookmark],[BookmarkLevel],[IsIncludeOrphanParagraph],[IsMarkPagesAsBlank]
		,[IsIncludeHeaderFooterOnBlackPages],[BlankPagesText],[IncludeSectionIdAfterEod],[IncludeEndOfSection],[IncludeDivisionNameandNumber],[IsIncludeAuthorForBookMark],[IsContinuousPageNumber]
		,[IsIncludeAttachedDocuments]
	FROM ProjectPrintSetting WITH (NOLOCK) WHERE CustomerId IS NULL AND ProjectId IS NULL AND CreatedBy IS NULL
END
