CREATE TABLE [dbo].[UserProjectAccessMapping] (
    [MappingId]    INT           IDENTITY (1, 1) NOT NULL,
    [ProjectId]    INT           NOT NULL,
    [UserId]       INT           NOT NULL,
    [CustomerId]   INT           NOT NULL,
    [CreatedBy]    INT           NULL,
    [CreateDate]   DATETIME2 (7) NULL,
    [ModifiedBy]   INT           NULL,
    [ModifiedDate] DATETIME2 (7) NULL,
    [IsActive]     BIT           DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_UserProjectAccessMapping] PRIMARY KEY CLUSTERED ([MappingId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_UserProjectAccessMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);




GO
CREATE NONCLUSTERED INDEX [IX_UserProjectAccessMapping_ProjectId_UserId]
    ON [dbo].[UserProjectAccessMapping]([ProjectId] ASC)
    INCLUDE([UserId]) WITH (FILLFACTOR = 90);

