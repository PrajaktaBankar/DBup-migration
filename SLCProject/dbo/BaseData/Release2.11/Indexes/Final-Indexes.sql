Use [SLCProject]
GO

CREATE NONCLUSTERED INDEX [IX_Footer_ProjectId_SectionId] ON [dbo].[Footer]
( 
   [ProjectId], [SectionId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO

CREATE NONCLUSTERED INDEX [IX_Header_ProjectId_SectionId] ON [dbo].[Header]
( 
   [ProjectId], [SectionId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO


DROP INDEX CIX_ProjectSegmentRequirementTag_RequirementTagId ON [ProjectSegmentRequirementTag]
GO

CREATE NONCLUSTERED INDEX [IX_PSRT_SegmentStatusId_RequirementTagId] ON [dbo].[ProjectSegmentRequirementTag]
( 
   [SegmentStatusId]
,    [RequirementTagId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO

CREATE NONCLUSTERED INDEX [IX_Project_CustomerId_IsOfficeMaster_IsDeleted] ON [dbo].[Project]
( 
   [CustomerId]
)
INCLUDE
(
	[IsOfficeMaster],[IsDeleted]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO

CREATE NONCLUSTERED INDEX [IX_Project_Template] ON [dbo].[Template]
( 
   [CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO

CREATE NONCLUSTERED INDEX [IX_ProjectPrintSetting_ProjectId] ON [dbo].[ProjectPrintSetting]
( 
   [ProjectId], [CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO

CREATE NONCLUSTERED INDEX [IX_ProjectPageSetting_ProjectId] ON [dbo].[ProjectPaperSetting]
( 
   [ProjectId], [CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO

CREATE NONCLUSTERED INDEX [IX_ProjectPageSetting_ProjectId] ON [dbo].[ProjectPageSetting]
( 
   [ProjectId], [CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);
GO


CREATE NONCLUSTERED INDEX [IX_CopyProjectRequest_TargetProjectId_StatusId] ON [dbo].[CopyProjectRequest]
( 
	[TargetProjectId]
)
INCLUDE
(
	[StatusId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);


CREATE NONCLUSTERED INDEX [IX_UserProjectAccessMapping_ProjectId_UserId] ON [dbo].[UserProjectAccessMapping]
( 
	[ProjectId]
)
INCLUDE
(
	[UserId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_ProjectImage_LuImageSourceTypeId] ON [dbo].[ProjectImage]
( 
	[LuImageSourceTypeId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);


CREATE NONCLUSTERED INDEX [IX_ProjectDisciplineSection_ProjectId_SectionId] ON [dbo].[ProjectDisciplineSection]
( 
	[ProjectId],
	[SectionId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_SegmentComment_ProjectId_SectionId_CreatedBy] ON [dbo].[SegmentComment]
( 
	[ProjectId],
	[SectionId]
)
INCLUDE
(
	[CreatedBy]
)

WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_ImportProjectRequest_TargetProjectId_StatusId] ON [dbo].[ImportProjectRequest]
( 
	[TargetProjectId]
)
INCLUDE
(
	[StatusId]
)

WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_ProjectMigrationException_ProjectId_IsResolved] ON [dbo].[ProjectMigrationException]
( 
   [ProjectId]
)
INCLUDE
(
   [IsResolved]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

DROP INDEX CIX_ProjectSegmentRequirementTag_SectionId_ProjectId_CustomerId ON [ProjectSegmentRequirementTag]

CREATE NONCLUSTERED INDEX [IX_ProjectSegmentRequirementTag_SectionId_SegmentStatusId_ProjectId] ON [dbo].[ProjectSegmentRequirementTag]
( 
   [SectionId], [SegmentStatusId], [ProjectId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_ProjectReferenceStandard_All_Required] ON [dbo].[ProjectReferenceStandard]
( 
   [ProjectId], [SectionId], [CustomerId], [IsDeleted]
,    [RefStdSource]
)
INCLUDE
(
   [RefStandardId], [RefStdEditionId], [RefStdCode]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_ProjectSegmentGlobalTerm_SegmentId_GlobalTermCode] ON [dbo].[ProjectSegmentGlobalTerm]
( 
	[SectionId],
	[ProjectId],
   [SegmentId]
,  [GlobalTermCode]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

CREATE NONCLUSTERED INDEX [IX_ProjectSegmentImage_LuImageSourceTypeId_SegmentId] ON [dbo].[ProjectSegmentImage]
( 
	[SectionId], 
	[ProjectId], 
	[SegmentId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);


CREATE NONCLUSTERED INDEX [IX_CustomerGlobalSetting_CustomerId_UserId] ON [dbo].[CustomerGlobalSetting]
( 
	[CustomerId],[UserId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);


CREATE NONCLUSTERED INDEX [IX_ProjectExport_ProjectId_CustomerId] ON [dbo].[ProjectExport]
( 
	[ProjectId],
	[CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);


CREATE NONCLUSTERED INDEX [IX_ProjectUserTag_ProjectId_CustomerId] ON [dbo].[ProjectUserTag]
( 
	[CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO

CREATE NONCLUSTERED INDEX [IX_ReferenceStandardEdition_RefStdId_CustomerId] ON [dbo].[ReferenceStandardEdition]
( 
	[RefStdId],
	[CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO

CREATE NONCLUSTERED INDEX [IX_TemplateStyle_LevelId] ON [dbo].[TemplateStyle]
( 
	[Level]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO

CREATE NONCLUSTERED INDEX [IX_] ON [dbo].[HeaderFooterGlobalTermUsage]
( 
	[ProjectId],[CustomerId]
)
INCLUDE
(
 [HeaderId], [FooterId]
)

WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO

CREATE NONCLUSTERED INDEX [IX_UserFolder_ProjectId] ON [dbo].[UserFolder]
( 
	[ProjectId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO
CREATE NONCLUSTERED INDEX [IX_HeaderFooterReferenceStandardUsage_ProjectId_ProjRefStdId] ON [dbo].[HeaderFooterReferenceStandardUsage]
( 
	[ProjectId], [ReferenceStandardId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO
CREATE NONCLUSTERED INDEX [IX_UserGlobalTerm_ProjectId_CustomerId] ON [dbo].[UserGlobalTerm]
( 
	[ProjectId], [CustomerId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

GO

DROP INDEX NCIx_ProjectHyperLink ON [ProjectHyperLink]

CREATE NONCLUSTERED INDEX [IX__ProjectHyperLink_ProjectId_SectionId_SegmentStatusId] ON [dbo].[ProjectHyperLink]
( 
   [SectionId], [ProjectId]
)
INCLUDE
(
   [SegmentStatusId]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

