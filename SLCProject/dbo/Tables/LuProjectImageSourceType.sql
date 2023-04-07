CREATE TABLE [dbo].[LuProjectImageSourceType] (
    [LuImageSourceTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [ImageSourceType]     VARCHAR(50) NULL,
    CONSTRAINT [PK_LUPROJECTIMAGESOURCETYPE] PRIMARY KEY CLUSTERED ([LuImageSourceTypeId] ASC)
);

