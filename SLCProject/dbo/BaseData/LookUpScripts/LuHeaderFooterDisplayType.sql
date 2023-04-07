truncate table [dbo].LuHeaderFooterDisplayType
DBCC CHECKIDENT('LuHeaderFooterDisplayType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuHeaderFooterDisplayType] ON 

INSERT [dbo].[LuHeaderFooterDisplayType] ([HeaderFooterDisplayTypeId], [HeaderFooterDisplayType], [Description], [IsActive]) VALUES (1, N'DefaultForAllPages', N'Display same header/footer accross all pages', 1)
INSERT [dbo].[LuHeaderFooterDisplayType] ([HeaderFooterDisplayTypeId], [HeaderFooterDisplayType], [Description], [IsActive]) VALUES (2, N'DifferentForFirstPage', N'Display different header/footer on first page and default on other pages', 1)
INSERT [dbo].[LuHeaderFooterDisplayType] ([HeaderFooterDisplayTypeId], [HeaderFooterDisplayType], [Description], [IsActive]) VALUES (3, N'DifferentForFirstOddEvenPages', N'Display different header/footer on first, odd and even pages', 1)
INSERT [dbo].[LuHeaderFooterDisplayType] ([HeaderFooterDisplayTypeId], [HeaderFooterDisplayType], [Description], [IsActive]) VALUES (4, N'DifferentForOddEvenPages', N'Display different header/footer on odd and even pages', 1)
SET IDENTITY_INSERT [dbo].[LuHeaderFooterDisplayType] OFF

DBCC CHECKIDENT('LuHeaderFooterDisplayType', RESEED, 4)
