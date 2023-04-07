CREATE TABLE [dbo].[ReferenceStandard] (
    [RefStdId]            INT            IDENTITY (1, 1) NOT NULL,
    [RefStdName]          NVARCHAR (MAX) NULL,
    [RefStdSource]        CHAR (1)       NULL,
    [ReplaceRefStdId]     INT            NULL,
    [ReplaceRefStdSource] CHAR (1)       NULL,
    [mReplaceRefStdId]    INT            NULL,
    [IsObsolete]          BIT            NOT NULL,
    [RefStdCode]          INT            CONSTRAINT [Default_ReferenceStandard_RefStdCode] DEFAULT (NEXT VALUE FOR [seq_ReferenceStandard]) NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    [CreatedBy]           INT            NOT NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [ModifiedBy]          INT            NULL,
    [CustomerId]          INT            NULL,
    [IsDeleted]           BIT            DEFAULT ((0)) NOT NULL,
    [IsLocked]            BIT            NULL,
    [IsLockedByFullName]  NVARCHAR (255) NULL,
    [IsLockedById]        INT            NULL,
    [A_RefStdId]          INT            NULL,
    CONSTRAINT [PK_REFERENCESTANDARD] PRIMARY KEY CLUSTERED ([RefStdId] ASC)
);




GO
CREATE NONCLUSTERED INDEX [NCIx_ReferenceStandard]
    ON [dbo].[ReferenceStandard]([RefStdId] ASC)
    INCLUDE([ReplaceRefStdId], [mReplaceRefStdId], [CustomerId]) WITH (FILLFACTOR = 90);


GO

