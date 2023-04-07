truncate table [dbo].LuProjectType
DBCC CHECKIDENT('LuProjectType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectType] ON 

INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (1, N'AddExp', N'Addition/Expansion', 1, 160)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (2, N'CodeRetro', N'Code Retrofit', 1, 140)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (3, N'CommRetro', N'Communications Retrofit', 1, 135)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (4, N'EnergyRetro', N'Energy Conservation Retrofit', 1, 130)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (5, N'FFandE', N'Furniture, Furnishings, and Equipment', 1, 115)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (6, N'HazMatRem', N'Hazardous Material Removal or Remediation', 1, 155)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (7, N'HistoricRest', N'Historic Restoration', 1, 150)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (8, N'HVACReplace', N'HVAC Replacement', 1, 145)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (9, N'NewConst', N'New Construction', 1, 100)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (10, N'NewConstFT', N'New Construction, Fast Tracked', 1, 105)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (11, N'Other', N'Other', 1, 99999)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (12, N'Remodel', N'Remodeling or Renovation', 1, 120)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (13, N'ReRoof', N'Re-Roofing', 1, 125)
INSERT [dbo].[LuProjectType] ([ProjectTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (14, N'TenantFit', N'Tenant Fit-Out', 1, 110)
SET IDENTITY_INSERT [dbo].[LuProjectType] OFF

DBCC CHECKIDENT('LuProjectType', RESEED, 14)
