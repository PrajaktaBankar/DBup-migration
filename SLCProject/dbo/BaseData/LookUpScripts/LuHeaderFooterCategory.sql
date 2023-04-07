truncate table [dbo].LuHeaderFooterCategory
DBCC CHECKIDENT('LuHeaderFooterCategory', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuHeaderFooterCategory] ON 
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (1, N'Specification ', N'Specification', 1)
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (2, N'Requirements', N'Requirements', 1)
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (3, N'TableOfContents', N'TableOfContents', 1)
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (4, N'CurrentSection', N'CurrentSection', 1)
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (5, N'DefaultSpec', N'DefaultSpec', 1)
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (6, N'DefaultTOC', N'DefaultTOC', 1)
INSERT [dbo].[LuHeaderFooterCategory] ([CategoryId], [CategoryName], [Description], [IsActive]) VALUES (7, N'DefaultReq', N'DefaultReq', 1)
SET IDENTITY_INSERT [dbo].[LuHeaderFooterCategory] OFF

DBCC CHECKIDENT('LuHeaderFooterCategory', RESEED, 7)

