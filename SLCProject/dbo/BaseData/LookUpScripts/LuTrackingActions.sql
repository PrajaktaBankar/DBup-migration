truncate table [dbo].LuTrackingActions
DBCC CHECKIDENT('LuTrackingActions', RESEED, 0)

SET IDENTITY_INSERT [dbo].[LuTrackingActions] ON 

INSERT [dbo].[LuTrackingActions] ([TrackActionId], [TrackActions]) VALUES (1, N'Accept')
INSERT [dbo].[LuTrackingActions] ([TrackActionId], [TrackActions]) VALUES (2, N'Reject')
SET IDENTITY_INSERT [dbo].[LuTrackingActions] OFF

DBCC CHECKIDENT('LuTrackingActions', RESEED, 2)
