CREATE TABLE [dbo].[ReferenceStandardPDF] (
    [RefStdId]            INT            NOT NULL,
    [RefStdName]          NVARCHAR (MAX) NULL,
    [RefStdSource]        NVARCHAR (255) NULL,
    [ReplaceRefStdId]     INT            NULL,
    [ReplaceRefStdSource] NVARCHAR (255) NULL,
    [mReplaceRefStdId]    INT            NULL,
    [IsObsolete]          BIT            NOT NULL,
    [RefStdCode]          INT            NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    [CreatedBy]           INT            NOT NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [ModifiedBy]          INT            NULL,
    [CustomerId]          INT            NULL,
    [IsDeleted]           BIT            NOT NULL,
    [IsLocked]            BIT            NULL,
    [IsLockedByFullName]  NVARCHAR (255) NULL,
    [IsLockedById]        INT            NULL,
    [A_RefStdId]          INT            NULL,
    CONSTRAINT [PK_REFERENCESTANDARD_PDF] PRIMARY KEY CLUSTERED ([RefStdId] ASC) WITH (FILLFACTOR = 90)
);

