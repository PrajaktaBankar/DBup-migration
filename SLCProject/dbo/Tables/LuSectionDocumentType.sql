﻿CREATE TABLE LuSectionDocumentType
(
	SectionDocumentId INT IDENTITY(1,1) NOT NULL,
	 [Type] NVARCHAR(100) NOT NULL,
	[Description] NVARCHAR(150) NOT NULL,
	CONSTRAINT [PK_LuSectionDocumentType] PRIMARY KEY CLUSTERED 
	(
		SectionDocumentId ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]