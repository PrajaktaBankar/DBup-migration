truncate table [dbo].LuHeaderFooterDocumentType
DBCC CHECKIDENT('LuHeaderFooterDocumentType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuHeaderFooterDocumentType] ON 

INSERT [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId], [DocumentTypeName]) VALUES (1, N'Project Specifications')
INSERT [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId], [DocumentTypeName]) VALUES (2, N'Requirements Reports')
INSERT [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId], [DocumentTypeName]) VALUES (3, N'TOC Report')
SET IDENTITY_INSERT [dbo].[LuHeaderFooterDocumentType] OFF

DBCC CHECKIDENT('LuHeaderFooterDocumentType', RESEED, 3)
