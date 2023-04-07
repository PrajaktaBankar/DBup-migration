USE [SLCProject]
GO
SET IDENTITY_INSERT [dbo].[ProjectDateFormat] ON
GO
INSERT [dbo].[ProjectDateFormat] ([ProjectDateFormatId], [MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate]) VALUES (1, 1, NULL, NULL, NULL, N'12-hr', N'MM-dd-yyyy', CAST(N'2019-04-20T06:29:41.2033333' AS DateTime2))
GO
INSERT [dbo].[ProjectDateFormat] ([ProjectDateFormatId], [MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate]) VALUES (2, 2, NULL, NULL, NULL, N'12-hr', N'dd-MM-yyyy', CAST(N'2019-04-20T06:29:41.2033333' AS DateTime2))
GO
INSERT [dbo].[ProjectDateFormat] ([ProjectDateFormatId], [MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate]) VALUES (3, 3, NULL, NULL, NULL, N'24-hr', N'dd-MM-yyyy', CAST(N'2019-04-20T06:29:41.2033333' AS DateTime2))
GO
INSERT [dbo].[ProjectDateFormat] ([ProjectDateFormatId], [MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate]) VALUES (4, 4, NULL, NULL, NULL, N'12-hr', N'dd-MM-yyyy', CAST(N'2019-04-20T06:29:41.2033333' AS DateTime2))
GO
SET IDENTITY_INSERT [dbo].[ProjectDateFormat] OFF
GO




