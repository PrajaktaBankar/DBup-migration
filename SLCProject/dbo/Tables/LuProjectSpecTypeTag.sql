CREATE TABLE [dbo].[LuProjectSpecTypeTag] (
    [SpecTypeTagId] INT           IDENTITY (1, 1) NOT NULL,
    [TagType]       NVARCHAR (10) NOT NULL,
    [Description]   NVARCHAR (50) NOT NULL,
    [IsActive]      INT           CONSTRAINT [DF_LuProjectSpecTypeTag_IsActive] DEFAULT ((1)) NOT NULL,
    [SortOrder]     INT           NOT NULL,
    CONSTRAINT [PK_LUPROJECTSPECTYPETAG] PRIMARY KEY CLUSTERED ([SpecTypeTagId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIx_LuProjectSpecTypeTag]
    ON [dbo].[LuProjectSpecTypeTag]([SpecTypeTagId] ASC);

