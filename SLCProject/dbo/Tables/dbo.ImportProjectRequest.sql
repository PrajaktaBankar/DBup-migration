CREATE TABLE [dbo].[ImportProjectRequest] (
    [RequestId]           INT             IDENTITY (1, 1) NOT NULL,
    [SourceProjectId]     INT             NULL,
    [TargetProjectId]     INT             NOT NULL,
    [SourceSectionId]     INT             NULL,
    [TargetSectionId]     INT             NULL,
    [CreatedById]         INT             NOT NULL,
    [CustomerId]          INT             NOT NULL,
    [CreatedDate]         DATETIME2 (7)   NOT NULL,
    [ModifiedDate]        DATETIME2 (7)   NULL,
    [StatusId]            TINYINT         NULL,
    [CompletedPercentage] TINYINT         NOT NULL,
    [Source]              NVARCHAR (200)  NOT NULL,
    [IsNotify]            BIT             NULL,
    [DocumentFilePath]    NVARCHAR (1000) NULL,
    [IsDeleted]           BIT             DEFAULT ((0)) NOT NULL,
    [TargetParentSectionId] INT NULL, 
    [IsCreateFolderStructure] BIT NULL, 
    PRIMARY KEY CLUSTERED ([RequestId] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_ImportProjectRequest_TargetProjectId_StatusId]
    ON [dbo].[ImportProjectRequest]([TargetProjectId] ASC)
    INCLUDE([StatusId]) WITH (FILLFACTOR = 90);

