CREATE TABLE [dbo].[IncomingProjectHistory](
	[Id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NULL,
	[Action] [nvarchar](50) NULL,
	[UserId] [int] NULL,
	[CustomerId] [int] NULL,
	[CreatedDate] [datetime2](7) NULL,
	[TransferredRequestId] [int] NULL
);