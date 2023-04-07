CREATE TABLE [dbo].[ProjectRevitFile] (
    [RevitFileId]  INT              IDENTITY (1, 1) NOT NULL,
    [FileName]     NVARCHAR (500)   NULL,
    [FileSize]     NVARCHAR (500)   NULL,
    [CustomerId]   INT              NULL,
    [UserId]       INT              NULL,
    [ProjectId]    INT              NULL,
    [UploadedDate] DATETIME2 (7)    NULL,
    [UploadedBy]   INT              NULL,
    [ExtVimId]     INT              NULL,
    [IsDeleted]    BIT              NULL,
    [UniqueId]     UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_PROJECTREVITFILE] PRIMARY KEY CLUSTERED ([RevitFileId] ASC)
);

