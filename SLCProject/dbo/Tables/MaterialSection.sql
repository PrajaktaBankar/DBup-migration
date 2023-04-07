CREATE TABLE [dbo].[MaterialSection] (
    [Id]         INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]  INT            NOT NULL,
    [VimId]      INT            NOT NULL,
    [MaterialId] INT            NULL,
    [SectionId]  NVARCHAR (MAX) NULL,
    [CustomerId] INT            NULL
);

