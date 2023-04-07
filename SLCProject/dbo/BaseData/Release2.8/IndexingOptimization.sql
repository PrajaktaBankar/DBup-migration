Use [SLCProject]
GO

CREATE NONCLUSTERED INDEX NCI_ProjectId_SegmentId_RefStdCode ON [dbo].[ProjectSegmentReferenceStandard]
( 
   [SegmentId], [ProjectId]
,    [RefStdCode]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);

/*************************************************************************************************************************/

DROP Index NCIx_ProjectNote ON ProjectNote

CREATE NONCLUSTERED INDEX [NCIx_ProjectNote_ProjectId] ON [dbo].[ProjectNote]
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

/*************************************************************************************************************************/

CREATE NONCLUSTERED INDEX NCI_Step_RequestId ON [dbo].[CopyProjectHistory]
( 
   [Step], [RequestId]
,    [CreatedDate]
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF,
   FILLFACTOR = 90
);

/*************************************************************************************************************************/

DROP INDEX CIX_ProjectChoiceOption_ProjectId_CustomerId ON [ProjectChoiceOption]

CREATE NONCLUSTERED INDEX NCI_ProjectChoiceOption_ProjectId ON [dbo].[ProjectChoiceOption]
( 
   [ProjectId], [SectionId], [CustomerId]
)
INCLUDE
(
   SegmentChoiceId
)
WITH
(
   STATISTICS_NORECOMPUTE = OFF, 
   FILLFACTOR = 90
);


