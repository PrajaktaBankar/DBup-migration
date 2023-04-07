CREATE TABLE [dbo].[ProjectSection] (
    [SectionId]             INT            IDENTITY (1, 1) NOT NULL,
    [ParentSectionId]       INT            NULL,
    [mSectionId]            INT            NULL,
    [ProjectId]             INT            NOT NULL,
    [CustomerId]            INT            NOT NULL,
    [UserId]                INT            NOT NULL,
    [DivisionId]            INT            NULL,
    [DivisionCode]          NVARCHAR (500) NULL,
    [Description]           NVARCHAR (500) NULL,
    [LevelId]               INT            NOT NULL,
    [IsLastLevel]           BIT            NOT NULL,
    [SourceTag]             VARCHAR (18)   NULL,
    [Author]                NVARCHAR (500) NULL,
    [TemplateId]            INT            NULL,
    [SectionCode]           INT            CONSTRAINT [Default_ProjectSection_SectionCode] DEFAULT (NEXT VALUE FOR [seq_ProjectSection]) NULL,
    [IsDeleted]             BIT            NOT NULL,
    [IsLocked]              BIT            NULL,
    [LockedBy]              INT            NULL,
    [LockedByFullName]      NVARCHAR (500) NULL,
    [CreateDate]            DATETIME2 (7)  NOT NULL,
    [CreatedBy]             INT            NOT NULL,
    [ModifiedBy]            INT            NULL,
    [ModifiedDate]          DATETIME2 (7)  NULL,
    [FormatTypeId]          INT            DEFAULT ((1)) NULL,
    [SLE_FolderID]          INT            NULL,
    [SLE_ParentID]          INT            NULL,
    [SLE_DocID]             INT            NULL,
    [SpecViewModeId]        INT            DEFAULT ((1)) NULL,
    [A_SectionId]           INT            NULL,
    [IsLockedImportSection] BIT            DEFAULT ((0)) NOT NULL,
    [IsTrackChanges]        BIT            DEFAULT ((0)) NOT NULL,
    [IsTrackChangeLock]     BIT            DEFAULT ((0)) NOT NULL,
    [TrackChangeLockedBy]   INT            NULL,
	[DataMapDateTimeStamp]      DATETIME2 (7)  NULL,
    [IsHidden] BIT NULL, 
    [SortOrder] INT NULL,
    SectionSource INT NULL DEFAULT 1,
    [PendingUpdateCount] INT NULL, 
    CONSTRAINT [PK_PROJECTSECTION] PRIMARY KEY CLUSTERED ([SectionId] ASC),
    CONSTRAINT [FK_ProjectSection_LuFormatType] FOREIGN KEY ([FormatTypeId]) REFERENCES [dbo].[LuFormatType] ([FormatTypeId]),
    CONSTRAINT [FK_ProjectSection_LuSpecificationViewMode] FOREIGN KEY ([SpecViewModeId]) REFERENCES [dbo].[LuSpecificationViewMode] ([SpecViewModeId]),
    CONSTRAINT [FK_ProjectSection_LuSectionSource] FOREIGN KEY (SectionSource) REFERENCES [dbo].LuSectionSource (id)
);




GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSection_ProjectId_CustomerId]
    ON [dbo].[ProjectSection]([ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([mSectionId]);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSection_ProjectId_CustomerId_LockedBy]
    ON [dbo].[ProjectSection]([ProjectId] ASC, [CustomerId] ASC, [LockedBy] ASC);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSection_ProjectId_CustomerId_SectionCode]
    ON [dbo].[ProjectSection]([ProjectId] ASC, [CustomerId] ASC, [SectionCode] ASC) WITH (FILLFACTOR = 90);


GO

