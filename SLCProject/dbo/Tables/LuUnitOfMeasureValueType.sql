CREATE TABLE [dbo].[LuUnitOfMeasureValueType] (
    [UnitOfMeasureValueTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]                     NVARCHAR (256) NOT NULL,
    [Description]              NVARCHAR (256) NOT NULL,
    CONSTRAINT [PK_LUUNITOFMEASUREVALUETYPE] PRIMARY KEY CLUSTERED ([UnitOfMeasureValueTypeId] ASC)
);

