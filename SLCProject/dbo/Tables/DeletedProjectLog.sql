CREATE TABLE [dbo].[DeletedProjectLog] (
    [LogId]             INT            IDENTITY (1, 1) NOT NULL,
    [DeletedDate]       DATETIME2 (7)  NULL,
    [DeletedLogHistory] NVARCHAR (MAX) NULL,
    [ActionName]        NVARCHAR (50)  NULL,
    [StartTime]         DATETIME2 (7)  NULL,
    [EndTime]           DATETIME2 (7)  NULL,
    [RecordsDeleted]    BIGINT         NULL,
    [Duration]          AS             (CONVERT([varchar],dateadd(second,datediff(second,[StartTime],[EndTime]),(0)),(108))),
    CONSTRAINT [PK_DeletedProjectLog] PRIMARY KEY CLUSTERED ([LogId] ASC) WITH (FILLFACTOR = 80)
);



