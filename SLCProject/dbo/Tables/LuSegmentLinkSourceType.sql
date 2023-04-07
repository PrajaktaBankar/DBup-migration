CREATE TABLE [dbo].[LuSegmentLinkSourceType] (
    [SegmentLinkSourceTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [SegmentLinkSourceType]   CHAR NULL,
    [Description]             NVARCHAR (500) NULL,
    CONSTRAINT [PK_LUSEGMENTLINKSOURCETYPE] PRIMARY KEY CLUSTERED ([SegmentLinkSourceTypeId] ASC)
);

