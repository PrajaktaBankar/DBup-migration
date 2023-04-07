truncate table [dbo].LuProjectLinkStatusType
DBCC CHECKIDENT('LuProjectLinkStatusType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectLinkStatusType] ON 

INSERT [dbo].[LuProjectLinkStatusType] ([LinkStatusTypeId], [LinkStatusType], [Description]) VALUES (1, N'SystemNeutral', NULL)
INSERT [dbo].[LuProjectLinkStatusType] ([LinkStatusTypeId], [LinkStatusType], [Description]) VALUES (2, N'SystemRelevant', NULL)
INSERT [dbo].[LuProjectLinkStatusType] ([LinkStatusTypeId], [LinkStatusType], [Description]) VALUES (3, N'SystemSelect', NULL)
INSERT [dbo].[LuProjectLinkStatusType] ([LinkStatusTypeId], [LinkStatusType], [Description]) VALUES (4, N'SystemExclude', NULL)
SET IDENTITY_INSERT [dbo].[LuProjectLinkStatusType] OFF

DBCC CHECKIDENT('LuProjectLinkStatusType', RESEED, 4)
