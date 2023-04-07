truncate table [dbo].LuSectionIdSeparator
DBCC CHECKIDENT('LuSectionIdSeparator', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuSectionIdSeparator] ON 

INSERT [dbo].[LuSectionIdSeparator] ([Id], [Separator]) VALUES (1, N'.')
INSERT [dbo].[LuSectionIdSeparator] ([Id], [Separator]) VALUES (2, N'-')
INSERT [dbo].[LuSectionIdSeparator] ([Id], [Separator]) VALUES (3, N',')
SET IDENTITY_INSERT [dbo].[LuSectionIdSeparator] OFF

DBCC CHECKIDENT('LuSectionIdSeparator', RESEED, 3)
