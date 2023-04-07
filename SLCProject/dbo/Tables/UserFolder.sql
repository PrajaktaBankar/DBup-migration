CREATE TABLE [dbo].[UserFolder] (
    [UserFolderId]         INT            IDENTITY (1, 1) NOT NULL,
    [FolderTypeId]         INT            NULL,
    [ProjectId]            INT            NOT NULL,
    [UserId]               INT            NOT NULL,
    [LastAccessed]         DATETIME2 (7)  NOT NULL,
    [CustomerId]           INT            NOT NULL,
    [LastAccessByFullName] NVARCHAR (500) NULL,
    CONSTRAINT [PK_USERFOLDER] PRIMARY KEY CLUSTERED ([UserFolderId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_UserFolder_LuFolderType] FOREIGN KEY ([FolderTypeId]) REFERENCES [dbo].[LuFolderType] ([FolderTypeId]),
    CONSTRAINT [FK_UserFolder_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);




GO
CREATE NONCLUSTERED INDEX [IX_UserFolder_ProjectId]
    ON [dbo].[UserFolder]([ProjectId] ASC) WITH (FILLFACTOR = 90);

