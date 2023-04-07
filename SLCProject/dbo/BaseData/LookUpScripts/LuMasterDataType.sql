truncate table [dbo].LuMasterDataType
DBCC CHECKIDENT('LuMasterDataType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuMasterDataType] ON 

INSERT [dbo].[LuMasterDataType] ([MasterDataTypeId], [Name], [Description], [LanguageCode], [LanguageName]) VALUES (1, N'BSD Master (USA)', N'BSD Master (USA)', N'en_US', N'American English')
INSERT [dbo].[LuMasterDataType] ([MasterDataTypeId], [Name], [Description], [LanguageCode], [LanguageName]) VALUES (2, N'NMS Master (English)', N'NMS Master (English)', N'en_CA', N'Canadian English')
INSERT [dbo].[LuMasterDataType] ([MasterDataTypeId], [Name], [Description], [LanguageCode], [LanguageName]) VALUES (3, N'NMS Master (French)', N'NMS Master (French)', N'fr_CA', N'Canadian French')
INSERT [dbo].[LuMasterDataType] ([MasterDataTypeId], [Name], [Description], [LanguageCode], [LanguageName]) VALUES (4, N'BSD Master (Canada)', N'BSD Master (Canada)', N'en_CA', N'Canadian English')
SET IDENTITY_INSERT [dbo].[LuMasterDataType] OFF

DBCC CHECKIDENT('LuMasterDataType', RESEED, 4)
