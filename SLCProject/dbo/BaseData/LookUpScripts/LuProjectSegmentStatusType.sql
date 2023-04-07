truncate table [dbo].LuProjectSegmentStatusType
DBCC CHECKIDENT('LuProjectSegmentStatusType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuProjectSegmentStatusType] ON 

INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (1, N'UserNeutral_SystemSelect')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (2, N'UserSelect_SystemNeutral')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (3, N'UserSelect_SystemSelect')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (4, N'UserSelect_SystemRelevant')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (5, N'UserSelect_SystemExclude')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (6, N'UserNeutral_SystemNeutral')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (7, N'UserNeutral_SystemRelevant')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (8, N'UserNeutral_SystemExclude')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (9, N'UserExclude_SystemNeutral')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (10, N'UserExclude_SystemSelect')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (11, N'UserExclude_SystemRelevant')
INSERT [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId], [StatusName]) VALUES (12, N'UserExclude_SystemExclude')
SET IDENTITY_INSERT [dbo].[LuProjectSegmentStatusType] OFF

DBCC CHECKIDENT('LuProjectSegmentStatusType', RESEED, 12)
