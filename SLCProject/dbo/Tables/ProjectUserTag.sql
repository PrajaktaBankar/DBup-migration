CREATE TABLE [dbo].[ProjectUserTag] (
    [UserTagId]    INT            IDENTITY (1, 1) NOT NULL,
    [CustomerId]   INT            NOT NULL,
    [TagType]      NVARCHAR (10)  NOT NULL,
    [Description]  NVARCHAR (255) NULL,
    [SortOrder]    INT            NULL,
    [IsSystemTag]  BIT            NULL,
    [CreateDate]   DATETIME2 (7)  NULL,
    [CreatedBy]    INT            NULL,
    [ModifiedDate] DATETIME2 (7)  NULL,
    [ModifiedBy]   INT            NULL,
    [A_UserTagId]  INT            NULL,
    [IsDeleted] BIT NULL, 
    CONSTRAINT [PK_PROJECTUSERTAG] PRIMARY KEY CLUSTERED ([UserTagId] ASC) WITH (FILLFACTOR = 90)
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectUserTag_ProjectId_CustomerId]
    ON [dbo].[ProjectUserTag]([CustomerId] ASC) WITH (FILLFACTOR = 90);

