CREATE TABLE [dbo].[LuCity] (
    [CityId]          INT            IDENTITY (1, 1) NOT NULL,
    [City]            NVARCHAR (255) NULL,
    [StateProvinceId] INT            NOT NULL,
    CONSTRAINT [PK_LUCITY] PRIMARY KEY CLUSTERED ([CityId] ASC),
    CONSTRAINT [FK_LuCity_LuStateProvince] FOREIGN KEY ([StateProvinceId]) REFERENCES [dbo].[LuStateProvince] ([StateProvinceID])
);


GO
CREATE NONCLUSTERED INDEX [CIX_LuCity_StateProvinceId]
    ON [dbo].[LuCity]([StateProvinceId] ASC);

