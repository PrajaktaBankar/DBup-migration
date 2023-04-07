CREATE TABLE [dbo].[Template] (
    [TemplateId]           INT           IDENTITY (1, 1) NOT NULL,
    [Name]                 VARCHAR (100) NOT NULL,
    [TitleFormatId]        INT           NULL,
    [SequenceNumbering]    BIT           NOT NULL,
    [CustomerId]           INT           NULL,
    [IsSystem]             BIT           NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF__Templates__IsAct__2EDAF651] DEFAULT ((0)) NOT NULL,
    [CreatedBy]            INT           NOT NULL,
    [CreateDate]           DATETIME2 (7) NOT NULL,
    [ModifiedBy]           INT           NULL,
    [ModifiedDate]         DATETIME2 (7) NULL,
    [MasterDataTypeId]     INT           DEFAULT ((1)) NULL,
    [A_TemplateId]         INT           NULL,
    [ApplyTitleStyleToEOS] BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [PK_TEMPLATE] PRIMARY KEY CLUSTERED ([TemplateId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Template_LuMasterDataType] FOREIGN KEY ([MasterDataTypeId]) REFERENCES [dbo].[LuMasterDataType] ([MasterDataTypeId]),
    CONSTRAINT [FK_Templates_LuTitleFormat] FOREIGN KEY ([TitleFormatId]) REFERENCES [dbo].[LuTitleFormat] ([TitleFormatId])
);




GO
CREATE NONCLUSTERED INDEX [IX_Project_Template]
    ON [dbo].[Template]([CustomerId] ASC) WITH (FILLFACTOR = 90);

