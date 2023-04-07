CREATE TABLE [dbo].[UserGlobalTermPDF] (
    [UserGlobalTermId]   INT            IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (255) NULL,
    [Value]              NVARCHAR (500) NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [CreatedBy]          INT            NOT NULL,
    [CustomerId]         INT            NULL,
    [ProjectId]          INT            NULL,
    [IsDeleted]          BIT            NULL,
    [A_UserGlobalTermId] INT            NULL,
    CONSTRAINT [PK_USERGLOBALTERM_PDF] PRIMARY KEY CLUSTERED ([UserGlobalTermId] ASC) WITH (FILLFACTOR = 90)
);

