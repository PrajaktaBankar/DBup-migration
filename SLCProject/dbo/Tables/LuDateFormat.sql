CREATE TABLE [dbo].[LuDateFormat] (
    [DateFormatId] INT            IDENTITY (1, 1) NOT NULL,
    [DateFormat]   NVARCHAR (100) NULL,
    [SortOrder]    INT            NULL,
    [IsActive]     BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]    BIT            DEFAULT ((0)) NOT NULL,
    [DisplayName]  NVARCHAR (50)  NULL,
    CONSTRAINT [PK_LuDateFormat] PRIMARY KEY CLUSTERED ([DateFormatId] ASC) WITH (FILLFACTOR = 80)
);

