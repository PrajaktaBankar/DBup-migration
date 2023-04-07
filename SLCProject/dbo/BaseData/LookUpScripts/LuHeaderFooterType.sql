truncate table [dbo].LuHeaderFooterType
DBCC CHECKIDENT('LuHeaderFooterType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuHeaderFooterType] ON 

INSERT [dbo].[LuHeaderFooterType] ([TypeId], [Name], [Description]) VALUES (1, N'Project', N'Project Level')
INSERT [dbo].[LuHeaderFooterType] ([TypeId], [Name], [Description]) VALUES (2, N'Section', N'Section Level')
SET IDENTITY_INSERT [dbo].[LuHeaderFooterType] OFF

DBCC CHECKIDENT('LuHeaderFooterType', RESEED, 2)
