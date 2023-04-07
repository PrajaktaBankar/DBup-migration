CREATE TABLE [dbo].[SelectedChoiceOption] (
    [SelectedChoiceOptionId] BIGINT            IDENTITY (1, 1) NOT NULL,
    [SegmentChoiceCode]      BIGINT            NOT NULL,
    [ChoiceOptionCode]       BIGINT            NOT NULL,
    [ChoiceOptionSource]     CHAR NULL,
    [IsSelected]             BIT            NOT NULL,
    [SectionId]              INT            NOT NULL,
    [ProjectId]              INT            NOT NULL,
    [CustomerId]             INT            NOT NULL,
    [OptionJson]             NVARCHAR (MAX) NULL,
    [IsDeleted]              BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SELECTEDCHOICEOPTION] PRIMARY KEY CLUSTERED ([SelectedChoiceOptionId] ASC),
    CONSTRAINT [FK_SelectedChoiceOption_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);
GO

CREATE NONCLUSTERED INDEX [CIX_SelectedChoiceOption_ProjectId_CustomerId]
    ON [dbo].[SelectedChoiceOption]([SectionId] ASC, [ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([ChoiceOptionCode], [ChoiceOptionSource], [IsDeleted]) WITH (FILLFACTOR = 80);
GO


GO
CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include_Id]
    ON [dbo].[SelectedChoiceOption]([ChoiceOptionCode] ASC, [ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([SegmentChoiceCode], [ChoiceOptionSource], [IsSelected]) WITH (FILLFACTOR = 90);

