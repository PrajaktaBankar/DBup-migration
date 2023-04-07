CREATE TABLE [dbo].[ProjectUserTagPDF] (
    [UserTagId]    INT            NOT NULL,
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
    CONSTRAINT [PK_PROJECTUSERTAG_PDF] PRIMARY KEY CLUSTERED ([UserTagId] ASC) WITH (FILLFACTOR = 90)
);

