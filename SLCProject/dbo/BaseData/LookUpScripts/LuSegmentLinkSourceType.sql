truncate table [dbo].LuSegmentLinkSourceType
DBCC CHECKIDENT('LuSegmentLinkSourceType', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuSegmentLinkSourceType] ON 

INSERT [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId], [SegmentLinkSourceType], [Description]) VALUES (1, N'M', N'Master')
INSERT [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId], [SegmentLinkSourceType], [Description]) VALUES (2, N'R', N'Reference Standards')
INSERT [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId], [SegmentLinkSourceType], [Description]) VALUES (3, N'S', N'Related Requirements')
INSERT [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId], [SegmentLinkSourceType], [Description]) VALUES (4, N'L', N'LinkMan-E')
INSERT [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId], [SegmentLinkSourceType], [Description]) VALUES (5, N'U', N'User')
SET IDENTITY_INSERT [dbo].[LuSegmentLinkSourceType] OFF

DBCC CHECKIDENT('LuSegmentLinkSourceType', RESEED, 5)