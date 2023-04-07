truncate table [dbo].LuTitleFormat
DBCC CHECKIDENT('LuTitleFormat', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuTitleFormat] ON 

INSERT [dbo].[LuTitleFormat] ([TitleFormatId], [Name], [IsActive]) VALUES (1, N'<Section #> - <Section Title>', 1)
INSERT [dbo].[LuTitleFormat] ([TitleFormatId], [Name], [IsActive]) VALUES (2, N'<Section #> <Skip Line> <Section Title>', 1)
INSERT [dbo].[LuTitleFormat] ([TitleFormatId], [Name], [IsActive]) VALUES (3, N'<Section Title>', 1)
INSERT [dbo].[LuTitleFormat] ([TitleFormatId], [Name], [IsActive]) VALUES (4, N'(none)', 1)
SET IDENTITY_INSERT [dbo].[LuTitleFormat] OFF

DBCC CHECKIDENT('LuTitleFormat', RESEED, 4)
