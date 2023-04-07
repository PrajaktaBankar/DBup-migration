truncate table [dbo].LuProjectUoM
DBCC CHECKIDENT('LuProjectUoM', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectUoM] ON 
INSERT [dbo].[LuProjectUoM] ([ProjectUoMId], [Description]) VALUES (1, N'Sq.M')
INSERT [dbo].[LuProjectUoM] ([ProjectUoMId], [Description]) VALUES (2, N'Sq.Ft')
SET IDENTITY_INSERT [dbo].[LuProjectUoM] OFF

DBCC CHECKIDENT('LuProjectUoM', RESEED, 2)
