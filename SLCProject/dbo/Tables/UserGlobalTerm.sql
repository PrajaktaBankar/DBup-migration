CREATE TABLE [dbo].[UserGlobalTerm] (
    [UserGlobalTermId]   INT            IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (255) NULL,
    [Value]              NVARCHAR (500) NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [CreatedBy]          INT            NOT NULL,
    [CustomerId]         INT            NULL,
    [ProjectId]          INT            NULL,
    [IsDeleted]          BIT            DEFAULT ((0)) NULL,
    [A_UserGlobalTermId] INT            NULL,
    CONSTRAINT [PK_USERGLOBALTERM] PRIMARY KEY CLUSTERED ([UserGlobalTermId] ASC) WITH (FILLFACTOR = 90)
);




GO
CREATE NONCLUSTERED INDEX [IX_UserGlobalTerm_ProjectId_CustomerId]
    ON [dbo].[UserGlobalTerm]([ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);

