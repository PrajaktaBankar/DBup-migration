CREATE TABLE [dbo].[LuImportedDocType](
	[ImportedDocTypeId] [int] IDENTITY(1,1) NOT NULL,
	[DocType] [nvarchar](100) NULL,
	[Description] [nvarchar](150) NULL,
 CONSTRAINT [PK_LuImportedDocType] PRIMARY KEY CLUSTERED ([ImportedDocTypeId] ASC) WITH (FILLFACTOR = 80)
);
