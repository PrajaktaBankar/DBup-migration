CREATE TABLE [dbo].[ReferenceStandardEditionPDF] (
    [RefStdEditionId]   INT            NOT NULL,
    [RefEdition]        NVARCHAR (MAX) NULL,
    [RefStdTitle]       NVARCHAR (MAX) NULL,
    [LinkTarget]        NVARCHAR (MAX) NULL,
    [CreateDate]        DATETIME2 (7)  NOT NULL,
    [CreatedBy]         INT            NOT NULL,
    [RefStdId]          INT            NULL,
    [CustomerId]        INT            NULL,
    [ModifiedDate]      DATETIME2 (7)  NULL,
    [ModifiedBy]        INT            NULL,
    [A_RefStdEditionId] INT            NULL,
    CONSTRAINT [PK_REFERENCESTANDARDEDITION_PDF] PRIMARY KEY CLUSTERED ([RefStdEditionId] ASC) WITH (FILLFACTOR = 90)
);

