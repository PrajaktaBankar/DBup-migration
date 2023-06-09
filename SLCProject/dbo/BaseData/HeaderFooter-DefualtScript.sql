IF not exists (SELECT TOP 1
		1
	FROM Header pdf WITH (NOLOCK)
	WHERE pdf.ProjectId IS NULL
	AND pdf.DocumentTypeId = 1)
BEGIN
INSERT [dbo].[Header] ([IsLocked], [ShowFirstPage], [CreatedBy], [CreatedDate], [ModifiedBy], [TypeId], [HeaderFooterCategoryId], [DateFormat], [TimeFormat], [HeaderFooterDisplayTypeId], [DefaultHeader], [FirstPageHeader], [OddPageHeader], [EvenPageHeader], [DocumentTypeId], [IsShowLineAboveHeader], [IsShowLineBelowHeader])
	VALUES (0, 1, 0, GETUTCDATE(), 0, 1, 1, N'Short', N'Short', 1, N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;"><br></td><td style="width: 33.0000%;text-align:center;"></td><td style="width:33.0000%;text-align:right;"></td></tr></tbody></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;"><br></td><td style="width: 33.0000%;text-align:center;"></td><td style="width:33.0000%;text-align:right;"></td></tr></tbody></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;"><br></td><td style="width: 33.0000%;text-align:center;"></td><td style="width:33.0000%;text-align:right;"></td></tr></tbody></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;"><br></td><td style="width: 33.0000%;text-align:center;"></td><td style="width:33.0000%;text-align:right;"></td></tr></tbody></table>', 1, 0, 0)
END
IF not exists (SELECT TOP 1
		1
	FROM Header pdf WITH (NOLOCK)
	WHERE pdf.ProjectId IS NULL
	AND pdf.DocumentTypeId = 2)
BEGIN
INSERT [dbo].[Header] ([IsLocked], [ShowFirstPage], [CreatedBy], [CreatedDate], [ModifiedBy], [TypeId], [HeaderFooterCategoryId], [DateFormat], [TimeFormat], [HeaderFooterDisplayTypeId], [DefaultHeader], [FirstPageHeader], [OddPageHeader], [EvenPageHeader], [DocumentTypeId], [IsShowLineAboveHeader], [IsShowLineBelowHeader])
	VALUES (0, 1, 0, GETUTCDATE(), 0, 1, 1, N'Short', N'Short', 1, NULL, NULL, NULL, NULL, 2, 0, 0)
END
IF not exists (SELECT TOP 1
		1
	FROM Header pdf WITH (NOLOCK)
	WHERE pdf.ProjectId IS NULL
	AND pdf.DocumentTypeId = 3)
BEGIN
INSERT [dbo].[Header] ([IsLocked], [ShowFirstPage], [CreatedBy], [CreatedDate], [ModifiedBy], [TypeId], [HeaderFooterCategoryId], [DateFormat], [TimeFormat], [HeaderFooterDisplayTypeId], [DefaultHeader], [FirstPageHeader], [OddPageHeader], [EvenPageHeader], [DocumentTypeId], [IsShowLineAboveHeader], [IsShowLineBelowHeader])
	VALUES (0, 1, 0, GETUTCDATE(), 0, 1, 1, N'Short', N'Short', 1, NULL, NULL, NULL, NULL, 3, 0, 0)
END

IF not exists (SELECT TOP 1
		1
	FROM Footer pdf WITH (NOLOCK)
	WHERE pdf.ProjectId IS NULL
	AND pdf.DocumentTypeId = 1)
BEGIN
INSERT [dbo].[Footer] ([IsLocked], [ShowFirstPage], [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [TypeId], [HeaderFooterCategoryId], [DateFormat], [TimeFormat], [HeaderFooterDisplayTypeId], [DefaultFooter], [FirstPageFooter], [OddPageFooter], [EvenPageFooter], [DocumentTypeId], [IsShowLineAboveFooter], [IsShowLineBelowFooter])
	VALUES (0, 1, 0, GETUTCDATE(), 0, CAST(N'2019-02-04T04:42:49.9266667' AS DATETIME2), 1, 1, N'Short', N'Short', 1, N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#SectionID} - {KW#PageNumber}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#SectionName}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#SectionID} - {KW#PageNumber}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#SectionName}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#SectionID} - {KW#PageNumber}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#SectionName}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#SectionID} - {KW#PageNumber}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#SectionName}&nbsp;</td></tr></table>', 1, 0, 0)
END
IF not exists (SELECT TOP 1
		1
	FROM Footer pdf WITH (NOLOCK)
	WHERE pdf.ProjectId IS NULL
	AND pdf.DocumentTypeId = 2)
BEGIN
INSERT [dbo].[Footer] ([IsLocked], [ShowFirstPage], [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [TypeId], [HeaderFooterCategoryId], [DateFormat], [TimeFormat], [HeaderFooterDisplayTypeId], [DefaultFooter], [FirstPageFooter], [OddPageFooter], [EvenPageFooter], [DocumentTypeId], [IsShowLineAboveFooter], [IsShowLineBelowFooter])
	VALUES (0, 1, 0, GETUTCDATE(), 0, CAST(N'2019-08-21T12:56:28.7666667' AS DATETIME2), 1, 1, N'Short', N'Short', 1, N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', 2, 0, 0)
END
IF not exists (SELECT TOP 1
		1
	FROM Footer pdf WITH (NOLOCK)
	WHERE pdf.ProjectId IS NULL
	AND pdf.DocumentTypeId = 3)
BEGIN
INSERT [dbo].[Footer] ([IsLocked], [ShowFirstPage], [CreatedBy], [CreatedDate], [ModifiedBy], [ModifiedDate], [TypeId], [HeaderFooterCategoryId], [DateFormat], [TimeFormat], [HeaderFooterDisplayTypeId], [DefaultFooter], [FirstPageFooter], [OddPageFooter], [EvenPageFooter], [DocumentTypeId], [IsShowLineAboveFooter], [IsShowLineBelowFooter])
	VALUES (0, 1, 0, GETUTCDATE(), 0, CAST(N'2019-11-08T08:00:10.9500000' AS DATETIME2), 1, 1, N'Short', N'Short', 1, N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', N'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>', 3, 0, 0)
END


