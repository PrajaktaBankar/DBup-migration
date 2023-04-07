truncate table [dbo].LuProjectChoiceType
DBCC CHECKIDENT('LuProjectChoiceType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectChoiceType] ON 

INSERT [dbo].[LuProjectChoiceType] ([ChoiceTypeId], [ChoiceType]) VALUES (1, N'SingleSelect')
INSERT [dbo].[LuProjectChoiceType] ([ChoiceTypeId], [ChoiceType]) VALUES (2, N'MultipleSelectAND')
INSERT [dbo].[LuProjectChoiceType] ([ChoiceTypeId], [ChoiceType]) VALUES (3, N'MultipleSelectOR')
SET IDENTITY_INSERT [dbo].[LuProjectChoiceType] OFF

DBCC CHECKIDENT('LuProjectChoiceType', RESEED, 3)