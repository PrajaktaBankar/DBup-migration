truncate table [dbo].LuProjectSectionIdSeparator
DBCC CHECKIDENT('LuProjectSectionIdSeparator', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectSectionIdSeparator] ON 

INSERT [dbo].[LuProjectSectionIdSeparator] ([Id], [ProjectId], [CustomerId], [UserId], [Separator]) VALUES (1, NULL, NULL, NULL, N'.')
INSERT [dbo].[LuProjectSectionIdSeparator] ([Id], [ProjectId], [CustomerId], [UserId], [Separator]) VALUES (2, NULL, NULL, NULL, N'-')
INSERT [dbo].[LuProjectSectionIdSeparator] ([Id], [ProjectId], [CustomerId], [UserId], [Separator]) VALUES (3, NULL, NULL, NULL, N',')
SET IDENTITY_INSERT [dbo].[LuProjectSectionIdSeparator] OFF

DBCC CHECKIDENT('LuProjectSectionIdSeparator', RESEED, 3)
