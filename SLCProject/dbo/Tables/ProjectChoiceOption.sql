CREATE TABLE [dbo].[ProjectChoiceOption] (
    [ChoiceOptionId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [SegmentChoiceId]    BIGINT            NULL,
    [SortOrder]          TINYINT        NOT NULL,
    [ChoiceOptionSource] CHAR (1)       NULL,
    [OptionJson]         NVARCHAR (MAX) NULL,
    [ProjectId]          INT            NOT NULL,
    [SectionId]          INT            NOT NULL,
    [CustomerId]         INT            NOT NULL,
    [ChoiceOptionCode]   BIGINT            CONSTRAINT [Default_ProjectChoiceOption_ChoiceOptionCode] DEFAULT (NEXT VALUE FOR [seq_ProjectChoiceOption]) NULL,
    [CreatedBy]          INT            NOT NULL,
    [CreateDate]         DATETIME2 (7)  NOT NULL,
    [ModifiedBy]         INT            NULL,
    [ModifiedDate]       DATETIME2 (7)  NULL,
    [A_ChoiceOptionId]   BIGINT         NULL,
    [IsDeleted]          BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PROJECTCHOICEOPTION] PRIMARY KEY CLUSTERED ([ChoiceOptionId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_ProjectChoiceOption_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectChoiceOption_ProjectSegmentChoice] FOREIGN KEY ([SegmentChoiceId]) REFERENCES [dbo].[ProjectSegmentChoice] ([SegmentChoiceId]),
    CONSTRAINT [FK_ProjectChoiceOption_Section] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [CIX_ProjectChoiceOption_ChoiceOptionCode]
    ON [dbo].[ProjectChoiceOption]([ChoiceOptionCode] ASC)
    INCLUDE([SegmentChoiceId]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectChoiceOption_SegmentChoiceId]
    ON [dbo].[ProjectChoiceOption]([SegmentChoiceId] ASC)
    INCLUDE([ChoiceOptionCode]) WITH (FILLFACTOR = 90);
GO


GO
CREATE NONCLUSTERED INDEX [NCI_ProjectChoiceOption_ProjectId]
    ON [dbo].[ProjectChoiceOption]([ProjectId] ASC, [SectionId] ASC, [CustomerId] ASC)
    INCLUDE([SegmentChoiceId]) WITH (FILLFACTOR = 90);

