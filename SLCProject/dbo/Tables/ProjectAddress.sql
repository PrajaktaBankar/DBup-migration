CREATE TABLE [dbo].[ProjectAddress] (
    [AddressId]         INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]         INT            NOT NULL,
    [CustomerId]        INT            NOT NULL,
    [AddressLine1]      NVARCHAR (255) NULL,
    [AddressLine2]      NVARCHAR (255) NULL,
    [CountryId]         INT            NOT NULL,
    [StateProvinceId]   INT            NULL,
    [CityId]            INT            NULL,
    [PostalCode]        NVARCHAR (125) NULL,
    [CreateDate]        DATETIME2 (7)  NOT NULL,
    [CreatedBy]         INT            NOT NULL,
    [ModifiedBy]        INT            NULL,
    [ModifiedDate]      DATETIME2 (7)  NULL,
    [StateProvinceName] NVARCHAR (50)  NULL,
    [CityName]          NVARCHAR (50)  NULL,
    CONSTRAINT [PK_PROJECTADDRESS] PRIMARY KEY CLUSTERED ([AddressId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProjectAddress_LuCity] FOREIGN KEY ([CityId]) REFERENCES [dbo].[LuCity] ([CityId]),
    CONSTRAINT [FK_ProjectAddress_LuCountry] FOREIGN KEY ([CountryId]) REFERENCES [dbo].[LuCountry] ([CountryId]),
    CONSTRAINT [FK_ProjectAddress_LuStateProvince] FOREIGN KEY ([StateProvinceId]) REFERENCES [dbo].[LuStateProvince] ([StateProvinceID]),
    CONSTRAINT [FK_ProjectAddress_Projects] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);

