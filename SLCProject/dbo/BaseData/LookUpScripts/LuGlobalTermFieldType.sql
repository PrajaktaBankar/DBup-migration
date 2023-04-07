truncate table [dbo].LuGlobalTermFieldType
DBCC CHECKIDENT('LuGlobalTermFieldType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuGlobalTermFieldType] ON 
INSERT [dbo].[LuGlobalTermFieldType] ([GlobalTermFieldTypeId], [Description], [IsActive]) VALUES (1, N'Text', 1)
INSERT [dbo].[LuGlobalTermFieldType] ([GlobalTermFieldTypeId], [Description], [IsActive]) VALUES (2, N'DateTime', 1)
INSERT [dbo].[LuGlobalTermFieldType] ([GlobalTermFieldTypeId], [Description], [IsActive]) VALUES (3, N'DropDown', 1)
SET IDENTITY_INSERT [dbo].[LuGlobalTermFieldType] OFF

DBCC CHECKIDENT('LuGlobalTermFieldType', RESEED, 3)
