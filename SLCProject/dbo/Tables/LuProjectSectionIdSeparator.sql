CREATE TABLE [dbo].[LuProjectSectionIdSeparator] (
    [Id]         INT          IDENTITY (1, 1) NOT NULL,
    [ProjectId]  INT          NULL,
    [CustomerId] INT          NULL,
    [UserId]     INT          NULL,
    [Separator]  CHAR(1) NULL,
    CONSTRAINT [PK_LUPROJECTSECTIONIDSEPARATOR] PRIMARY KEY CLUSTERED ([Id] ASC)
);

