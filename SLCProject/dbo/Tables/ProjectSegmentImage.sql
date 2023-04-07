CREATE TABLE [dbo].[ProjectSegmentImage] (
    [SegmentImageId] INT            IDENTITY (1, 1) NOT NULL,
    [SegmentId]      BIGINT            NULL,
    [SectionId]      INT            NOT NULL,
    [ImageId]        INT            NOT NULL,
    [ProjectId]      INT            NOT NULL,
    [CustomerId]     INT            NOT NULL,
    [ImageStyle]     NVARCHAR (200) NULL,
    CONSTRAINT [PK_PROJECTSEGMENTIMAGE] PRIMARY KEY CLUSTERED ([SegmentImageId] ASC),
    CONSTRAINT [FK_ProjectSegmentImage_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegmentImage_ProjectImage] FOREIGN KEY ([ImageId]) REFERENCES [dbo].[ProjectImage] ([ImageId]),
    CONSTRAINT [FK_ProjectSegmentImage_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectSegmentImage_LuImageSourceTypeId_SegmentId]
    ON [dbo].[ProjectSegmentImage]([SectionId] ASC, [ProjectId] ASC, [SegmentId] ASC) WITH (FILLFACTOR = 90);

