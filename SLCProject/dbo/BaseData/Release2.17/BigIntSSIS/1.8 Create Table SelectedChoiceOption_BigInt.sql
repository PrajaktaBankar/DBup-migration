USE [SLCProject]
GO

/****** Object:  Table [dbo].[SelectedChoiceOption]    Script Date: 5/14/2021 1:00:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SelectedChoiceOption_BigInt](
	[SelectedChoiceOptionId] [bigint] IDENTITY(1,1) NOT NULL,
	[SegmentChoiceCode] [bigint] NOT NULL,
	[ChoiceOptionCode] [bigint] NOT NULL,
	[ChoiceOptionSource] [char](1) NULL,
	[IsSelected] [bit] NOT NULL,
	[SectionId] [int] NOT NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[OptionJson] [nvarchar](max) NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_SELECTEDCHOICEOPTION_BigInt] PRIMARY KEY CLUSTERED 
(
	[SelectedChoiceOptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[SelectedChoiceOption_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[SelectedChoiceOption_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_SelectedChoiceOption_BigInt_ProjectSection] FOREIGN KEY([SectionId])
REFERENCES [dbo].[ProjectSection] ([SectionId])
GO

ALTER TABLE [dbo].[SelectedChoiceOption_BigInt] CHECK CONSTRAINT [FK_SelectedChoiceOption_BigInt_ProjectSection]
GO


