CREATE TABLE [dbo].[ProjectMigrationException] (
    [MigrationExceptionId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerId]            INT            NOT NULL,
    [ProjectId]             INT            NOT NULL,
    [SectionId]             INT            NOT NULL,
    [SegmentId]             BIGINT            NOT NULL,
    [SegmentStatusId]       BIGINT            NULL,
    [SegmentSource]         CHAR (1)       NULL,
    [SegmentCode]           BIGINT            NULL,
    [SegmentDescription]    NVARCHAR (MAX) NULL,
    [CycleID]               BIGINT         NULL,
    [IsClientNotified]      BIT            NULL,
    [BrokenPlaceHolderType] VARCHAR (50)   NULL,
    [IsResolved]            BIT            DEFAULT ((0)) NULL,
    [ModifiedBy]            INT            DEFAULT (NULL) NULL,
    [ModifiedDate]          DATETIME2 (7)  DEFAULT (NULL) NULL,
    CONSTRAINT [PK_ProjectMigrationException] PRIMARY KEY CLUSTERED ([MigrationExceptionId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProjectMigrationException_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectMigrationException_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectMigrationException_ProjectSegment] FOREIGN KEY ([SegmentId]) REFERENCES [dbo].[ProjectSegment] ([SegmentId]),
    CONSTRAINT [FK_ProjectMigrationException_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectMigrationException_ProjectId_IsResolved]
    ON [dbo].[ProjectMigrationException]([ProjectId] ASC)
    INCLUDE([IsResolved]) WITH (FILLFACTOR = 90);

