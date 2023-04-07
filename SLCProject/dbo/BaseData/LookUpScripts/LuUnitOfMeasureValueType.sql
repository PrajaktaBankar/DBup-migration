truncate table [dbo].LuUnitOfMeasureValueType
DBCC CHECKIDENT('LuUnitOfMeasureValueType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuUnitOfMeasureValueType] ON 

INSERT [dbo].[LuUnitOfMeasureValueType] ([UnitOfMeasureValueTypeId], [Name], [Description]) VALUES (1, N'English', N'')
INSERT [dbo].[LuUnitOfMeasureValueType] ([UnitOfMeasureValueTypeId], [Name], [Description]) VALUES (2, N'Metric', N'')
INSERT [dbo].[LuUnitOfMeasureValueType] ([UnitOfMeasureValueTypeId], [Name], [Description]) VALUES (3, N'English(Metric)', N'')
INSERT [dbo].[LuUnitOfMeasureValueType] ([UnitOfMeasureValueTypeId], [Name], [Description]) VALUES (4, N'Metric(English)', N'')
SET IDENTITY_INSERT [dbo].[LuUnitOfMeasureValueType] OFF


DBCC CHECKIDENT('LuUnitOfMeasureValueType', RESEED, 4)
