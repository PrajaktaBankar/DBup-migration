CREATE TABLE [dbo].[LuCountry] (
    [CountryId]            INT            IDENTITY (1, 1) NOT NULL,
    [CountryName]          NVARCHAR (255) NULL,
    [CountryCode]          NVARCHAR (255) NULL,
    [DisplayOrder]         INT            NULL,
    [CurrencyAbbreviation] NVARCHAR (255) NULL,
    [CurrencySymbol]       NVARCHAR (255) NULL,
    [IsDeleted]            BIT            DEFAULT ((0)) NOT NULL,
    [CurrencyName]         NVARCHAR (255) NULL,
    [CurrencyDigitalCode]  NVARCHAR (5)   NULL,
    CONSTRAINT [PK_LUCOUNTRY] PRIMARY KEY CLUSTERED ([CountryId] ASC)
);

