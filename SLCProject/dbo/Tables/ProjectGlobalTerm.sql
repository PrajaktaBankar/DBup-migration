CREATE TABLE [dbo].[ProjectGlobalTerm] (
    [GlobalTermId]          INT            IDENTITY (1, 1) NOT NULL,
    [mGlobalTermId]         INT            NULL,
    [ProjectId]             INT            NOT NULL,
    [CustomerId]            INT            NOT NULL,
    [Name]                  NVARCHAR (500) NULL,
    [value]                 NVARCHAR (500) NULL,
    [GlobalTermSource]      CHAR (1)       NULL,
    [GlobalTermCode]        INT            CONSTRAINT [Default_ProjectGlobalTerm_GlobalTermCode] DEFAULT (NEXT VALUE FOR [seq_ProjectGlobalTerm]) NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [CreatedBy]             INT            NOT NULL,
    [ModifiedDate]          DATETIME2 (7)  NULL,
    [ModifiedBy]            INT            NULL,
    [SLE_GlobalChoiceID]    INT            NULL,
    [UserGlobalTermId]      INT            NULL,
    [IsDeleted]             BIT            DEFAULT ((0)) NULL,
    [A_GlobalTermId]        INT            NULL,
    [GlobalTermFieldTypeId] SMALLINT       DEFAULT ((1)) NOT NULL,
    [OldValue]              NVARCHAR (500) NULL,
    CONSTRAINT [PK_PROJECTGLOBALTERM] PRIMARY KEY CLUSTERED ([GlobalTermId] ASC),
    CONSTRAINT [FK_ProjectGlobalTerm_LuGlobalTermFieldType_GlobalTermFieldTypeId] FOREIGN KEY ([GlobalTermFieldTypeId]) REFERENCES [dbo].[LuGlobalTermFieldType] ([GlobalTermFieldTypeId]),
    CONSTRAINT [FK_ProjectGlobalTerm_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectGlobalTerm_UserGlobalTerm] FOREIGN KEY ([UserGlobalTermId]) REFERENCES [dbo].[UserGlobalTerm] ([UserGlobalTermId])
);




GO
CREATE NONCLUSTERED INDEX [NCIx_ProjectGlobalTerm]
    ON [dbo].[ProjectGlobalTerm]([GlobalTermId] ASC, [ProjectId] ASC)
    INCLUDE([mGlobalTermId], [SLE_GlobalChoiceID], [UserGlobalTermId]);

