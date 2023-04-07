truncate table [dbo].LuParagraphLineSpaceOption
DBCC CHECKIDENT('LuParagraphLineSpaceOption', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuParagraphLineSpaceOption] ON 

INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (1, N'Single', N'Single', 1)
INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (2, N'1.15', N'1.15', 1)
INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (3, N'1.5', N'1.5', 1)
INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (4, N'Double', N'Double', 1)
INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (5, N'Space Before', N'Space Before', 1)
INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (6, N'Space After', N'Space After', 1)
INSERT [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId], [Name], [Description], [IsActive]) VALUES (7, N'Custom Spacing', N'Custom Spacing', 1)
SET IDENTITY_INSERT [dbo].[LuParagraphLineSpaceOption] OFF

DBCC CHECKIDENT('LuParagraphLineSpaceOption', RESEED, 7)
