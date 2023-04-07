CREATE TABLE [dbo].[ReferenceStandardEdition] (
    [RefStdEditionId]   INT             IDENTITY (1, 1) NOT NULL,
    [RefEdition]        NVARCHAR (255)  NULL,
    [RefStdTitle]       NVARCHAR (1024) NULL,
    [LinkTarget]        NVARCHAR (1024) NULL,
    [CreateDate]        DATETIME2 (7)   NOT NULL,
    [CreatedBy]         INT             NOT NULL,
    [RefStdId]          INT             NULL,
    [CustomerId]        INT             NULL,
    [ModifiedDate]      DATETIME2 (7)   NULL,
    [ModifiedBy]        INT             NULL,
    [A_RefStdEditionId] INT             NULL,
    CONSTRAINT [PK_REFERENCESTANDARDEDITION] PRIMARY KEY CLUSTERED ([RefStdEditionId] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_ReferenceStandardEdition_RefStdId_CustomerId]
    ON [dbo].[ReferenceStandardEdition]([RefStdId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);

