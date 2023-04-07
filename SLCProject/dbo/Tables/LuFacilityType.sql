CREATE TABLE [dbo].[LuFacilityType] (
    [FacilityTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]           NVARCHAR (255) NULL,
    [Description]    NVARCHAR (255) NULL,
    [IsActive]       BIT            NOT NULL,
    [SortOrder]      INT            NULL,
    CONSTRAINT [PK_LUFACILITYTYPE] PRIMARY KEY CLUSTERED ([FacilityTypeId] ASC)
);

