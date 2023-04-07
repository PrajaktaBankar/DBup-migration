CREATE TABLE [dbo].[LuFolderType] (
    [FolderTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [FolderName]   NVARCHAR (255) NULL,
    [IsActive]     BIT            NOT NULL,
    [CreatedBy]    INT            NULL,
    [CreateDate]   DATETIME2 (7)  NOT NULL,
    [ModifiedBy]   INT            NULL,
    [ModifiedDate] DATETIME2 (7)  NULL,
    CONSTRAINT [PK_LUFOLDERTYPE] PRIMARY KEY CLUSTERED ([FolderTypeId] ASC)
);

