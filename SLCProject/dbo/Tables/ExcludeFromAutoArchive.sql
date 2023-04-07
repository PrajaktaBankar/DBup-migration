CREATE TABLE [dbo].[ExcludeFromAutoArchive]
(
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[CreatedDate] [datetime2](7) CONSTRAINT [DF_ExcludeFromAutoArchive_CreatedDate]  DEFAULT (getutcdate()) NOT NULL
);
