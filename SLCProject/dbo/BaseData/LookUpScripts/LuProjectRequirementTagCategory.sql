truncate table [dbo].LuProjectRequirementTagCategory
DBCC CHECKIDENT('LuProjectRequirementTagCategory', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectRequirementTagCategory] ON 

INSERT [dbo].[LuProjectRequirementTagCategory] ([CategoryId], [CategoryName]) VALUES (1, N'A')
INSERT [dbo].[LuProjectRequirementTagCategory] ([CategoryId], [CategoryName]) VALUES (2, N'B')
INSERT [dbo].[LuProjectRequirementTagCategory] ([CategoryId], [CategoryName]) VALUES (3, N'C')
SET IDENTITY_INSERT [dbo].[LuProjectRequirementTagCategory] OFF

DBCC CHECKIDENT('LuProjectRequirementTagCategory', RESEED, 3)
