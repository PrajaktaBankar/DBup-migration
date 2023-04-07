USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectChoiceOption]    Script Date: 5/14/2021 12:49:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectChoiceOption_BigInt](
	[ChoiceOptionId] [bigint] IDENTITY(1,1) NOT NULL,
	[SegmentChoiceId] [bigint] NULL,
	[SortOrder] [tinyint] NOT NULL,
	[ChoiceOptionSource] [char](1) NULL,
	[OptionJson] [nvarchar](max) NULL,
	[ProjectId] [int] NOT NULL,
	[SectionId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[ChoiceOptionCode] [bigint] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[A_ChoiceOptionId] [bigint] NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_PROJECTCHOICEOPTION_BigInt] PRIMARY KEY CLUSTERED 
(
	[ChoiceOptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectChoiceOption_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[ProjectChoiceOption_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectChoiceOption_BigInt_Project] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO

ALTER TABLE [dbo].[ProjectChoiceOption_BigInt] CHECK CONSTRAINT [FK_ProjectChoiceOption_BigInt_Project]
GO

ALTER TABLE [dbo].[ProjectChoiceOption_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectChoiceOption_BigInt_Section] FOREIGN KEY([SectionId])
REFERENCES [dbo].[ProjectSection] ([SectionId])
GO

ALTER TABLE [dbo].[ProjectChoiceOption_BigInt] CHECK CONSTRAINT [FK_ProjectChoiceOption_BigInt_Section]
GO


