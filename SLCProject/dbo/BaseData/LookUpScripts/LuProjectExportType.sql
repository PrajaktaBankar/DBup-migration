truncate table [dbo].LuProjectExportType
DBCC CHECKIDENT('LuProjectExportType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectExportType] ON 

INSERT [dbo].[LuProjectExportType] ([ProjectExportTypeId], [Name], [Description], [IsActive]) VALUES (1, N'Project', NULL, 1)
INSERT [dbo].[LuProjectExportType] ([ProjectExportTypeId], [Name], [Description], [IsActive]) VALUES (2, N'Branch', NULL, 1)
INSERT [dbo].[LuProjectExportType] ([ProjectExportTypeId], [Name], [Description], [IsActive]) VALUES (3, N'Report', NULL, 1)
INSERT [dbo].[LuProjectExportType] ([ProjectExportTypeId], [Name], [Description], [IsActive]) VALUES (4, N'TOCReport', NULL, 1)
SET IDENTITY_INSERT [dbo].[LuProjectExportType] OFF

DBCC CHECKIDENT('LuProjectExportType', RESEED, 4)