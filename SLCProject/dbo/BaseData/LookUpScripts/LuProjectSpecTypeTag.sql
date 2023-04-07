truncate table [dbo].LuProjectSpecTypeTag
DBCC CHECKIDENT('LuProjectSpecTypeTag', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectSpecTypeTag] ON 

INSERT [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId], [TagType], [Description], [IsActive], [SortOrder]) VALUES (0, N'DT', N'Deleted', 0, 5)
INSERT [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId], [TagType], [Description], [IsActive], [SortOrder]) VALUES (1, N'SF', N'User Short Form', 1, 1)
INSERT [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId], [TagType], [Description], [IsActive], [SortOrder]) VALUES (2, N'OL', N'User Outline', 1, 2)
INSERT [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId], [TagType], [Description], [IsActive], [SortOrder]) VALUES (3, N'UO', N'User Outline', 1, 3)
INSERT [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId], [TagType], [Description], [IsActive], [SortOrder]) VALUES (4, N'US', N'User Short Form', 1, 4)
SET IDENTITY_INSERT [dbo].[LuProjectSpecTypeTag] OFF

DBCC CHECKIDENT('LuProjectSpecTypeTag', RESEED, 4)
