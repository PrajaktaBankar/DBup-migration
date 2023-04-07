CREATE TABLE [dbo].[StandaloneViewerDetails] (
    [Id]           INT           IDENTITY (1, 1) NOT NULL,
    [CustomerId]   INT           NULL,
    [UserId]       INT           NULL,
    [Workstation]  NVARCHAR (50) NULL,
    [IsActive]     BIT           NULL,
    [CreatedDate]  DATETIME      NULL,
    [CreatedBy]    INT           NULL,
    [ModifiedDate] DATETIME      NULL,
    [ModifiedBy]   INT           NULL,
    CONSTRAINT [PK_STANDALONEVIEWERDETAILS] PRIMARY KEY CLUSTERED ([Id] ASC)
);

