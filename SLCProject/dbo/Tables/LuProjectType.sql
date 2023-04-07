CREATE TABLE [dbo].[LuProjectType] (
    [ProjectTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (255) NULL,
    [Description]   NVARCHAR (500) NULL,
    [IsActive]      BIT            NOT NULL,
    [SortOrder]     INT            NULL,
    CONSTRAINT [PK_LUPROJECTTYPE] PRIMARY KEY CLUSTERED ([ProjectTypeId] ASC)
);

