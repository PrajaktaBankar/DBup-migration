truncate table [dbo].LuFolderType
DBCC CHECKIDENT('LuFolderType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuFolderType] ON 

INSERT [dbo].[LuFolderType] ([FolderTypeId], [FolderName], [IsActive], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate]) VALUES (1, N'Private', 1, 0, CAST(N'2018-06-06T22:20:36.7500000' AS DateTime2), NULL, NULL)
INSERT [dbo].[LuFolderType] ([FolderTypeId], [FolderName], [IsActive], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate]) VALUES (2, N'Public', 1, 0, CAST(N'2018-06-06T22:20:36.7500000' AS DateTime2), NULL, NULL)
SET IDENTITY_INSERT [dbo].[LuFolderType] OFF

DBCC CHECKIDENT('LuFolderType', RESEED, 2)
