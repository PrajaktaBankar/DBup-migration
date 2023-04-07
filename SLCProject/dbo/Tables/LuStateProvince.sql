CREATE TABLE [dbo].[LuStateProvince] (
    [StateProvinceID]           INT            IDENTITY (1, 1) NOT NULL,
    [CountryID]                 INT            NOT NULL,
    [StateProvinceAbbreviation] NVARCHAR (100) NULL,
    [StateProvinceName]         NVARCHAR (100) NULL,
    CONSTRAINT [PK_LUSTATEPROVINCE] PRIMARY KEY CLUSTERED ([StateProvinceID] ASC),
    CONSTRAINT [FK_LuStateProvince_LuCountry] FOREIGN KEY ([CountryID]) REFERENCES [dbo].[LuCountry] ([CountryId])
);

