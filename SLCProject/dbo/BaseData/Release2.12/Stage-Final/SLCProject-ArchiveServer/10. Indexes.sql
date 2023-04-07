USE [SLCProject]
GO

CREATE NONCLUSTERED INDEX [CIX_SelectedChoiceOption_ProjectId_CustomerId] ON [dbo].[SelectedChoiceOption]
(
[SectionId] ASC,
[ProjectId] ASC,
[CustomerId] ASC
)
INCLUDE ( [ChoiceOptionCode],
[ChoiceOptionSource],
[IsDeleted]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO


CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include_Id] ON [dbo].[SelectedChoiceOption]
(
[ChoiceOptionCode] ASC,
[ProjectId] ASC,
[CustomerId] ASC
)
INCLUDE ( [SegmentChoiceCode],
[ChoiceOptionSource],
[IsSelected]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO