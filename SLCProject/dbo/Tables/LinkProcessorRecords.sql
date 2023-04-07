CREATE TABLE [dbo].[LinkProcessorRecords] (
    [Id]               INT            IDENTITY (1, 1) NOT NULL,
    [JsonData]         NVARCHAR (MAX) NOT NULL,
    [CreateDate]       DATETIME       NULL,
    [ModifiedDate]     DATETIME       NULL,
    [ProcessingStatus] INT            CONSTRAINT [DF_LinkProcessorRecords_IsProcessed] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LinkProcessorRecords] PRIMARY KEY CLUSTERED ([Id] ASC)
);

