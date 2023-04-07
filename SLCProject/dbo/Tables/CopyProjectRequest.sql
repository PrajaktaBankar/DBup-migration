CREATE TABLE [dbo].[CopyProjectRequest] (
    [RequestId]           INT            IDENTITY (1, 1) NOT NULL,
    [SourceProjectId]     INT            NULL,
    [TargetProjectId]     INT            NULL,
    [CreatedById]         INT            NULL,
    [CustomerId]          INT            NULL,
    [CreatedDate]         DATETIME2 (7)  NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [StatusId]            INT            NOT NULL,
    [IsNotify]            BIT            DEFAULT ((0)) NOT NULL,
    [CompletedPercentage] FLOAT (53)     NULL,
    [IsDeleted]           BIT            DEFAULT ((0)) NOT NULL,
    [IsEmailSent]         BIT            NULL,
    [CustomerName]        NVARCHAR (200) NULL,
    [UserName]            NVARCHAR (200) NULL,
	[CopyProjectTypeId]   INT            NOT NULL ,
    [TransferRequestId]	  INT            NULL,
    PRIMARY KEY CLUSTERED ([RequestId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_CopyProjectRequest_LuCopyStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[LuCopyStatus] ([CopyStatusId]),
    CONSTRAINT [FK_CopyProjectRequest_LuCopyProjectType] FOREIGN KEY ([CopyProjectTypeId]) REFERENCES [dbo].[LuCopyProjectType] ([CopyProjectTypeId])

);


GO


GO


GO


GO


GO
CREATE NONCLUSTERED INDEX [IX_CopyProjectRequest_TargetProjectId_StatusId]
    ON [dbo].[CopyProjectRequest]([TargetProjectId] ASC)
    INCLUDE([StatusId]) WITH (FILLFACTOR = 90);

