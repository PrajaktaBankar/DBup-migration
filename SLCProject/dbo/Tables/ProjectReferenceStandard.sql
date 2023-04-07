CREATE TABLE [dbo].[ProjectReferenceStandard] (
    [ProjectId]        INT           NOT NULL,
    [RefStandardId]    INT           NOT NULL,
    [RefStdSource]     CHAR (1)      NULL,
    [mReplaceRefStdId] INT           NULL,
    [RefStdEditionId]  INT           NOT NULL,
    [IsObsolete]       BIT           NOT NULL,
    [RefStdCode]       INT           NULL,
    [PublicationDate]  DATETIME2 (7) NULL,
    [SectionId]        INT           NULL,
    [CustomerId]       INT           NULL,
    [ProjRefStdId]     BIGINT           IDENTITY (1, 1) NOT NULL,
    [IsDeleted]        BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PROJECTREFERENCESTANDARD] PRIMARY KEY CLUSTERED ([ProjRefStdId] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectReferenceStandard_All_Required]
    ON [dbo].[ProjectReferenceStandard]([ProjectId] ASC, [SectionId] ASC, [CustomerId] ASC, [IsDeleted] ASC, [RefStdSource] ASC)
    INCLUDE([RefStandardId], [RefStdEditionId], [RefStdCode]) WITH (FILLFACTOR = 90);

