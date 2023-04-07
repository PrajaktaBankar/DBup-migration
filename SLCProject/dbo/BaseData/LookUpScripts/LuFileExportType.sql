truncate table [dbo].LuFileExportType
DBCC CHECKIDENT('LuFileExportType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuFileExportType] ON 
INSERT [dbo].[LuFileExportType] ([FileExportTypeId], [Name], [Description], [IsActive]) VALUES (1, N'Multiple files', NULL, 1)
INSERT [dbo].[LuFileExportType] ([FileExportTypeId], [Name], [Description], [IsActive]) VALUES (2, N'Single file', NULL, 1)
SET IDENTITY_INSERT [dbo].[LuFileExportType] OFF

DBCC CHECKIDENT('LuFileExportType', RESEED, 2)
