CREATE TABLE [dbo].[LuProjectRequirementTag] (
    [RequirementTagId] INT            IDENTITY (1, 1) NOT NULL,
    [TagType]          NVARCHAR (255) NULL,
    [Description]      NVARCHAR (500) NULL,
    [SortOrder]        INT            NOT NULL,
    [CategoryId]       INT            NULL,
    [IsActive]         BIT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LUPROJECTREQUIREMENTTAG] PRIMARY KEY CLUSTERED ([RequirementTagId] ASC),
    CONSTRAINT [FK_LuProjectRequirementTag_LuProjectRequirementTagCategory] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[LuProjectRequirementTagCategory] ([CategoryId])
);

