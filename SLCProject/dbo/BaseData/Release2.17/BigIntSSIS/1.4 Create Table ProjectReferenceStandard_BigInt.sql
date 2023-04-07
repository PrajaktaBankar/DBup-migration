USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectReferenceStandard_BigInt]    Script Date: 4/27/2021 6:23:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectReferenceStandard_BigInt](
	[ProjectId] [int] NOT NULL,
	[RefStandardId] [int] NOT NULL,
	[RefStdSource] [char](1) NULL,
	[mReplaceRefStdId] [int] NULL,
	[RefStdEditionId] [int] NOT NULL,
	[IsObsolete] [bit] NOT NULL,
	[RefStdCode] [int] NULL,
	[PublicationDate] [datetime2](7) NULL,
	[SectionId] [int] NULL,
	[CustomerId] [int] NULL,
	[ProjRefStdId] [bigint] IDENTITY(1,1) NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_PROJECTREFERENCESTANDARD_Testing] PRIMARY KEY CLUSTERED 
(
	[ProjRefStdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectReferenceStandard_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO


