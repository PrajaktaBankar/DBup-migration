truncate table [dbo].LuProjectSize
DBCC CHECKIDENT('LuProjectSize', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectSize] ON 

INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (1, N'0 - 5,000', 2)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (2, N'5,001 - 25,000', 2)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (3, N'25,001 - 100,000', 2)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (4, N'100,001 - 500,000', 2)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (5, N'500,000+', 2)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (6, N'0 - 500', 1)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (7, N'501 - 2,500', 1)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (8, N'2,501 - 10,000', 1)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (9, N'10,001 - 50,000', 1)
INSERT [dbo].[LuProjectSize] ([SizeId], [SizeDescription], [ProjectUoMId]) VALUES (10, N'50,000+', 1)
SET IDENTITY_INSERT [dbo].[LuProjectSize] OFF

DBCC CHECKIDENT('LuProjectSize', RESEED, 10)
