CREATE TABLE [dbo].[ApplyMasterUpdateLog] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [ProjectId]      INT           NULL,
    [LastUpdateDate] DATETIME2 (7) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

