CREATE TABLE [dbo].[LuProjectSegmentStatusType] (
    [SegmentStatusTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [StatusName]          VARCHAR(50) NULL,
    CONSTRAINT [PK_LUPROJECTSEGMENTSTATUSTYPE] PRIMARY KEY CLUSTERED ([SegmentStatusTypeId] ASC)
);

