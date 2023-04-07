truncate table [dbo].LuProjectImageSourceType
DBCC CHECKIDENT('LuProjectImageSourceType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectImageSourceType] ON 

INSERT [dbo].[LuProjectImageSourceType] ([LuImageSourceTypeId], [ImageSourceType]) VALUES (1, N'Segment')
INSERT [dbo].[LuProjectImageSourceType] ([LuImageSourceTypeId], [ImageSourceType]) VALUES (2, N'Note')
INSERT [dbo].[LuProjectImageSourceType] ([LuImageSourceTypeId], [ImageSourceType]) VALUES (3, N'HeaderFooter')
SET IDENTITY_INSERT [dbo].[LuProjectImageSourceType] OFF


DBCC CHECKIDENT('LuProjectImageSourceType', RESEED, 3)
