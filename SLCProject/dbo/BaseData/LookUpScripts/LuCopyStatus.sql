truncate table [dbo].[LuCopyStatus]
DBCC CHECKIDENT('LuCopyStatus', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuCopyStatus] ON 

INSERT [dbo].[LuCopyStatus] ([CopyStatusId], [Name], [StatusDescription]) VALUES (1, N'Queued', N'Queued')
INSERT [dbo].[LuCopyStatus] ([CopyStatusId], [Name], [StatusDescription]) VALUES (2, N'InProgress', N'InProgress')
INSERT [dbo].[LuCopyStatus] ([CopyStatusId], [Name], [StatusDescription]) VALUES (3, N'Completed', N'Completed')
INSERT [dbo].[LuCopyStatus] ([CopyStatusId], [Name], [StatusDescription]) VALUES (4, N'Failed', N'Failed')
INSERT [dbo].[LuCopyStatus] ([CopyStatusId], [Name], [StatusDescription]) VALUES (5, N'Aborted', N'Failed')
SET IDENTITY_INSERT [dbo].[LuCopyStatus] OFF

DBCC CHECKIDENT('LuCopyStatus', RESEED, 5)
