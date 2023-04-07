truncate table [dbo].LuSpecificationViewMode
DBCC CHECKIDENT('LuSpecificationViewMode', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuSpecificationViewMode] ON 

INSERT [dbo].[LuSpecificationViewMode] ([SpecViewModeId], [Name], [SpecViewCode], [Description], [SortOrder], [IsActive]) VALUES (1, N'Full Spec', N'FS', N'Full Spec View', 1, 1)
INSERT [dbo].[LuSpecificationViewMode] ([SpecViewModeId], [Name], [SpecViewCode], [Description], [SortOrder], [IsActive]) VALUES (2, N'Outline Form', N'OL', N'Outline View', 2, 1)
INSERT [dbo].[LuSpecificationViewMode] ([SpecViewModeId], [Name], [SpecViewCode], [Description], [SortOrder], [IsActive]) VALUES (3, N'Short Form', N'SF', N'Short Form View', 3, 1)
SET IDENTITY_INSERT [dbo].[LuSpecificationViewMode] OFF

DBCC CHECKIDENT('LuSpecificationViewMode', RESEED, 3)
