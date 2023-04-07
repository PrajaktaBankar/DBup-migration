truncate table [dbo].LuProjectChoiceOptionType
DBCC CHECKIDENT('LuProjectChoiceOptionType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectChoiceOptionType] ON 

INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (1, N'CustomText')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (2, N'UnitOfMeasure')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (3, N'SectionID')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (4, N'FillInBlank')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (5, N'ReferenceStandard')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (6, N'GlobalTerm')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (7, N'ReferenceEditionDate')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (8, N'NoneNA')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (9, N'Deleted')
INSERT [dbo].[LuProjectChoiceOptionType] ([ChoiceOptionTypeId], [ChoiceOptionType]) VALUES (10, N'SectionTitle')
SET IDENTITY_INSERT [dbo].[LuProjectChoiceOptionType] OFF

DBCC CHECKIDENT('LuProjectChoiceOptionType', RESEED, 10)