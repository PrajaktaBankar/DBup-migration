truncate table [dbo].LuProjectAccessType
DBCC CHECKIDENT('LuProjectAccessType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectAccessType] ON 

INSERT [dbo].[LuProjectAccessType] ([ProjectAccessTypeId], [Name], [Description], [IsActive]) VALUES (1, N'Public', N'Public', 1)
INSERT [dbo].[LuProjectAccessType] ([ProjectAccessTypeId], [Name], [Description], [IsActive]) VALUES (2, N'Private', N'Private', 1)
INSERT [dbo].[LuProjectAccessType] ([ProjectAccessTypeId], [Name], [Description], [IsActive]) VALUES (3, N'Hidden', N'Hidden', 1)
SET IDENTITY_INSERT [dbo].[LuProjectAccessType] OFF

DBCC CHECKIDENT('LuProjectAccessType', RESEED, 3)
