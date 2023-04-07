CREATE TABLE [dbo].[LuProjectDiscipline] (
    [Disciplineld]     INT            IDENTITY (1, 1) NOT NULL,
    [Name]             NVARCHAR (255) NULL,
    [IsActive]         BIT            NOT NULL,
    [MasterDataTypeId] INT            NULL,
    [DisplayOrder]     INT            NOT NULL,
    [IsBundle]         BIT            NOT NULL,
    CONSTRAINT [PK_LUPROJECTDISCIPLINE] PRIMARY KEY CLUSTERED ([Disciplineld] ASC),
    CONSTRAINT [FK_LuProjectDiscipline_LuMasterDataType] FOREIGN KEY ([MasterDataTypeId]) REFERENCES [dbo].[LuMasterDataType] ([MasterDataTypeId])
);

