truncate table [dbo].LuTCPrintMode
DBCC CHECKIDENT('LuTCPrintMode', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuTCPrintMode] ON 

INSERT [dbo].[LuTCPrintMode] ([TCPrintModeId], [Name], [Description], [CreatedBy], [ModifiedBy], [CreateDate], [ModifiedDate], [IsActive]) VALUES (1, N'InheritFromSection', N'Inherit from section', 1, NULL, CAST(N'2019-10-12T02:42:03.8100000' AS DateTime2), NULL, 1)
INSERT [dbo].[LuTCPrintMode] ([TCPrintModeId], [Name], [Description], [CreatedBy], [ModifiedBy], [CreateDate], [ModifiedDate], [IsActive]) VALUES (2, N'AllWithTrackChanges', N'All sections with markup', 1, NULL, CAST(N'2019-10-12T02:42:03.8100000' AS DateTime2), NULL, 1)
INSERT [dbo].[LuTCPrintMode] ([TCPrintModeId], [Name], [Description], [CreatedBy], [ModifiedBy], [CreateDate], [ModifiedDate], [IsActive]) VALUES (3, N'AllWithoutTrackChanges', N'All sections without markup', 1, NULL, CAST(N'2019-10-12T02:42:03.8100000' AS DateTime2), NULL, 1)
SET IDENTITY_INSERT [dbo].[LuTCPrintMode] OFF

DBCC CHECKIDENT('LuTCPrintMode', RESEED, 3)
