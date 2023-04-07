CREATE TABLE [dbo].[ProjectDateFormat] (
    [ProjectDateFormatId] INT            IDENTITY (1, 1) NOT NULL,
    [MasterDataTypeId]    INT            NOT NULL,
    [ProjectId]           INT            NULL,
    [CustomerId]          INT            NULL,
    [UserId]              INT            NULL,
    [ClockFormat]         NVARCHAR (20)  NULL,
    [DateFormat]          NVARCHAR (100) NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_ProjectDateFormat] PRIMARY KEY CLUSTERED ([ProjectDateFormatId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_ProjectDateFormat_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);

