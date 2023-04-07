truncate table [dbo].LuProjectTabType
DBCC CHECKIDENT('LuProjectTabType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectTabType] ON 

INSERT [dbo].[LuProjectTabType] ([TabTypeId], [TabType], [Description]) VALUES (1, 1, N'Left Aligned')
INSERT [dbo].[LuProjectTabType] ([TabTypeId], [TabType], [Description]) VALUES (2, 2, N'Right Aligned')
INSERT [dbo].[LuProjectTabType] ([TabTypeId], [TabType], [Description]) VALUES (3, 3, N'Centered')
INSERT [dbo].[LuProjectTabType] ([TabTypeId], [TabType], [Description]) VALUES (4, 4, N'Decimal Centered')
INSERT [dbo].[LuProjectTabType] ([TabTypeId], [TabType], [Description]) VALUES (5, 5, N'Right Most')
SET IDENTITY_INSERT [dbo].[LuProjectTabType] OFF

DBCC CHECKIDENT('LuProjectTabType', RESEED, 5)
