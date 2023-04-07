truncate table [dbo].LuFacilityType
DBCC CHECKIDENT('LuFacilityType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuFacilityType] ON 

INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (1, N'Comm', N'Communications', 1, 180)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (2, N'Commerce', N'Commercial or Mercantile', 1, 130)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (3, N'EduOrSci', N'Educational or Scientific', 1, 120)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (4, N'HealthWelf', N'Health and Welfare', 1, 135)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (5, N'HwyStreet', N'Highway and Street', 1, 170)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (6, N'Lodging', N'Lodging', 1, 115)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (7, N'ManufProc', N'Manufacturing and Process', 1, 155)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (8, N'MixedUse', N'Mixed Use', 1, 100)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (9, N'Office', N'Office or Business', 1, 125)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (10, N'Other', N'Other', 1, 99999)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (11, N'Power', N'Power Generation and Transmission', 1, 185)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (12, N'PublicSafety', N'Public Safety', 1, 145)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (13, N'Recreation', N'Recreation, Sports, Amusement', 1, 140)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (14, N'Religious', N'Religious', 1, 150)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (15, N'ResMultiple', N'Residential, Multiple', 1, 110)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (16, N'ResSingle', N'Residence, Single Family Or Duplex', 1, 105)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (17, N'SiteLand', N'Site and Lands', 1, 165)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (18, N'Storage', N'Storage', 1, 160)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (19, N'Transport', N'Transport', 1, 175)
INSERT [dbo].[LuFacilityType] ([FacilityTypeId], [Name], [Description], [IsActive], [SortOrder]) VALUES (20, N'Water', N'Water and Waste Water', 1, 190)
SET IDENTITY_INSERT [dbo].[LuFacilityType] OFF

DBCC CHECKIDENT('LuFacilityType', RESEED, 20)
