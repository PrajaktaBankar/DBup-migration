--DROP INDEX [dbo].[ProjectSection].ProjectSection_ProjectId_CustomerId
--DROP INDEX [SelectedChoiceOption].CSIx_SelectedChoiceOption_Include
DROP INDEX [dbo].[ProjectSegmentStatus].CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId
DROP INDEX [dbo].[ProjectSegmentStatus].CIX_ProjectSegmentStatus_SegmentStatusTypeId
DROP INDEX [dbo].[ProjectSegmentLink].NCIX_ProjectSegmentLink_CustomerId

/****** Object:  Index [CIX_ProjectSection_ProjectId_CustomerId]    Script Date: 10/7/2019 7:09:48 AM ******/
CREATE NONCLUSTERED INDEX [CIX_SelectedChoiceOption_ProjectId_CustomerId] ON [dbo].[SelectedChoiceOption]
(
	SectionId,
	ProjectId,
	CustomerId
)
INCLUDE ([ChoiceOptionCode], ChoiceOptionSource,IsDeleted) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

--CREATE NONCLUSTERED INDEX [ProjectSection_ProjectId_CustomerId]
--    ON [dbo].[ProjectSection]([ProjectId] ASC, [CustomerId] ASC)
--    INCLUDE([ParentSectionId], [Description], [SourceTag], [Author], [SectionCode]);

CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include_Id]
    ON [dbo].[SelectedChoiceOption]([ChoiceOptionCode] ASC, [ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([SegmentChoiceCode], [ChoiceOptionSource], [IsSelected]) WITH (FILLFACTOR = 90);

--CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include]
--   ON [dbo].[SelectedChoiceOption]([ProjectId] ASC, [CustomerId] ASC)
--   INCLUDE([SegmentChoiceCode], [ChoiceOptionCode], [ChoiceOptionSource], [IsSelected]);