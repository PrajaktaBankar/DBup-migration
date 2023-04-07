USE SLCProject 
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ActionName' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD ActionName  NVARCHAR (50)  NULL
END
ELSE 
Print 'Alread exists ActionName'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'StartTime' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD StartTime   DATETIME2 (7)  NULL
END
ELSE 
Print 'Alread exists StartTime'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'EndTime' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD EndTime  DATETIME2 (7)  NULL
END
ELSE 
Print 'Alread exists EndTime'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'RecordsDeleted' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD RecordsDeleted  BIGINT   NULL
END
ELSE 
Print 'Alread exists RecordsDeleted'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'Duration' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD Duration As (CONVERT([varchar],dateadd(second,datediff(second,[StartTime],[EndTime]),(0)),(108)))
END
ELSE 
Print 'Alread exists Duration'
GO