truncate table [dbo].LuProjectCost
DBCC CHECKIDENT('LuProjectCost', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectCost] ON 

INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (1, N'0 - 1,000,000', NULL)
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (2, N'1,000,001 - 15,000,000', NULL)
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (3, N'15,000,001 - 100,000,000', NULL)
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (4, N'100,000,001 - 500,000,000', NULL)
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (5, N'500,000,000+', NULL)
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (6, N'0 - 1,500,000', N'CA')
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (7, N'1,500,001 - 20,000,000', N'CA')
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (8, N'20,000,001 - 135,000,000', N'CA')
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (9, N'135,000,001 - 670,000,000', N'CA')
INSERT [dbo].[LuProjectCost] ([CostId], [CostDescription], [CountryCode]) VALUES (10, N'670,000,000+', N'CA')
SET IDENTITY_INSERT [dbo].[LuProjectCost] OFF

DBCC CHECKIDENT('LuProjectCost', RESEED, 10)
