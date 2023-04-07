DROP INDEX CSIx_SelectedChoiceOption_Include_Id ON SelectedChoiceOption;


/****** Object:  Index [CIX_ProjectSection_ProjectId_CustomerId]    Script Date: 10/7/2019 7:09:48 AM ******/
CREATE NONCLUSTERED INDEX [CIX_SelectedChoiceOption_ProjectId_CustomerId] ON [dbo].[SelectedChoiceOption]
(
	SectionId,
	ProjectId,
	CustomerId
)
INCLUDE ([ChoiceOptionCode], ChoiceOptionSource,IsDeleted) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

