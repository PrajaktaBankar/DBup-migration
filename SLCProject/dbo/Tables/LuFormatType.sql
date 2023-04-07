CREATE TABLE [dbo].[LuFormatType] (
    [FormatTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]         NVARCHAR (50)  NULL,
    [Description]  NVARCHAR (255) NULL,
    [IsActive]     BIT            NULL,
    CONSTRAINT [PK_LUFORMATTYPE] PRIMARY KEY CLUSTERED ([FormatTypeId] ASC)
);

