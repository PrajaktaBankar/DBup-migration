truncate table [dbo].LuFormatType
DBCC CHECKIDENT('LuFormatType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuFormatType] ON 
INSERT [dbo].[LuFormatType] ([FormatTypeId], [Name], [Description], [IsActive]) VALUES (1, N'MasterFormat', N'MasterFormat', 1)
INSERT [dbo].[LuFormatType] ([FormatTypeId], [Name], [Description], [IsActive]) VALUES (2, N'UniFormat', N'UniFormat', 1)
SET IDENTITY_INSERT [dbo].[LuFormatType] OFF

DBCC CHECKIDENT('LuFormatType', RESEED, 2)
