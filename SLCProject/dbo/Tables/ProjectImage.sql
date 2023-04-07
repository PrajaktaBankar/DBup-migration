CREATE TABLE [dbo].[ProjectImage] (
    [ImageId]             INT            IDENTITY (10000000, 1) NOT NULL,
    [ImagePath]           NVARCHAR (500) NULL,
    [LuImageSourceTypeId] INT            NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [CustomerId]          INT            NULL,
    [SLE_ProjectID]       INT            NULL,
    [SLE_DocID]           INT            NULL,
    [SLE_StatusID]        INT            NULL,
    [SLE_SegmentID]       INT            NULL,
    [SLE_ImageNo]         TINYINT        NULL,
    [SLE_ImageID]         INT            NULL,
    [A_ImageId]           INT            NULL,
    [SLE_GUID]            NVARCHAR (100) NULL,
    CONSTRAINT [PK_PROJECTIMAGE] PRIMARY KEY CLUSTERED ([ImageId] ASC),
    CONSTRAINT [FK_ProjectImage_LuProjectImageSourceType] FOREIGN KEY ([LuImageSourceTypeId]) REFERENCES [dbo].[LuProjectImageSourceType] ([LuImageSourceTypeId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectImage_LuImageSourceTypeId]
    ON [dbo].[ProjectImage]([LuImageSourceTypeId] ASC) WITH (FILLFACTOR = 90);

