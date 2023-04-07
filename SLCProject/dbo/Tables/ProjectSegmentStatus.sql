CREATE TABLE [dbo].[ProjectSegmentStatus] (
    [SegmentStatusId]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [SectionId]                   INT             NOT NULL,
    [ParentSegmentStatusId]       BIGINT             NOT NULL,
    [mSegmentStatusId]            INT             NULL,
    [mSegmentId]                  INT             NULL,
    [SegmentId]                   BIGINT             NULL,
    [SegmentSource]               CHAR  NULL,
    [SegmentOrigin]               CHAR(1)  NULL,
    [IndentLevel]                 TINYINT         NOT NULL,
    [SequenceNumber]              DECIMAL (18, 4) NOT NULL,
    [SpecTypeTagId]               INT             NULL,
    [SegmentStatusTypeId]         INT             NULL,
    [IsParentSegmentStatusActive] BIT             NULL,
    [ProjectId]                   INT             NOT NULL,
    [CustomerId]                  INT             NOT NULL,
    [SegmentStatusCode]           BIGINT             CONSTRAINT [Default_ProjectSegmentStatus_SegmentStatusCode] DEFAULT (NEXT VALUE FOR [seq_ProjectSegmentStatus]) NULL,
    [IsShowAutoNumber]            BIT             NULL,
    [IsRefStdParagraph]           BIT             DEFAULT ((0)) NOT NULL,
    [FormattingJson]              NVARCHAR (255)  NULL,
    [CreateDate]                  DATETIME2 (7)   NOT NULL,
    [CreatedBy]                   INT             NOT NULL,
    [ModifiedDate]                DATETIME2 (7)   NULL,
    [ModifiedBy]                  INT             NULL,
    [IsPageBreak]                 BIT             DEFAULT ((0)) NOT NULL,
    [SLE_DocID]                   INT             NULL,
    [SLE_ParentID]                INT             NULL,
    [SLE_SegmentID]               INT             NULL,
    [SLE_ProjectSegID]            INT             NULL,
    [SLE_StatusID]                INT             NULL,
    [A_SegmentStatusId]           BIGINT             NULL,
    [IsDeleted]                   BIT             NULL,
	[TrackOriginOrder]			  NVARCHAR(2)	  NULL,
	[MTrackDescription]			  NVARCHAR(MAX)   NULL
    CONSTRAINT [PK_PROJECTSEGMENTSTATUS] PRIMARY KEY CLUSTERED ([SegmentStatusId] ASC),
    CONSTRAINT [FK_ProjectSegmentStatus_LuProjectSegmentStatusType] FOREIGN KEY ([SegmentStatusTypeId]) REFERENCES [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId]),
    CONSTRAINT [FK_ProjectSegmentStatus_LuProjectSpecTypeTag] FOREIGN KEY ([SpecTypeTagId]) REFERENCES [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId])
);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentStatus_ProjectId_CustomerId]
    ON [dbo].[ProjectSegmentStatus]([ParentSegmentStatusId] ASC, [ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId]
    ON [dbo].[ProjectSegmentStatus]([SectionId] ASC, [ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentStatus_SegmentId_SectionId]
    ON [dbo].[ProjectSegmentStatus]([ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([SegmentStatusId], [SectionId], [mSegmentId], [SegmentId]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentStatus_SegmentStatusTypeId]
    ON [dbo].[ProjectSegmentStatus]([ParentSegmentStatusId] ASC, [SegmentStatusTypeId] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [SIX_ProjectSegmentStatus_SegmentStatusCode_ProjectId_CustomerId]
    ON [dbo].[ProjectSegmentStatus]([SegmentStatusCode] ASC)
    INCLUDE([ProjectId], [CustomerId]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IDX_ProjectSegmentStatus_ProjectId_CustomerId_SegmentStatusTypeId]
    ON [dbo].[ProjectSegmentStatus]([ProjectId] ASC, [CustomerId] ASC, [SegmentStatusTypeId] ASC)
    INCLUDE([SectionId]) WITH (FILLFACTOR = 90);

