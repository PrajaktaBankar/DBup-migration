﻿CREATE TABLE [dbo].[Project] (
    [ProjectId]          INT            IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (500) NULL,
    [IsOfficeMaster]     BIT            CONSTRAINT [DF_Project_IsOfficeMaster] DEFAULT ((0)) NOT NULL,
    [Description]        NVARCHAR (500) NULL,
    [TemplateId]         INT            CONSTRAINT [DF__Projects__Templa__1F98B2C1] DEFAULT ((1)) NULL,
    [MasterDataTypeId]   INT            NULL,
    [UserId]             INT            NOT NULL,
    [CustomerId]         INT            NOT NULL,
    [CreateDate]         DATETIME2 (7)  NOT NULL,
    [CreatedBy]          INT            NOT NULL,
    [ModifiedBy]         INT            NULL,
    [ModifiedDate]       DATETIME2 (7)  NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF__Project__IsDelet__44EA3301] DEFAULT ((0)) NOT NULL,
    [IsNamewithHeld]     BIT            CONSTRAINT [DF__Project__IsNamew__45DE573A] DEFAULT ((1)) NOT NULL,
    [IsMigrated]         BIT            NULL,
    [IsLocked]           BIT            CONSTRAINT [DF__Project__IsLocke__46D27B73] DEFAULT ((0)) NOT NULL,
    [A_ProjectId]        INT            NULL,
    [IsProjectMoved]     BIT            CONSTRAINT [DF__Project__IsProje__47C69FAC] DEFAULT ((0)) NULL,
    [GlobalProjectID]    NVARCHAR (36) NULL,
    [IsPermanentDeleted] BIT            NULL,
    [ModifiedByFullName] NVARCHAR (500) NULL,
    [MigratedDate]       DATETIME2 (7)  DEFAULT ('19900101') NOT NULL,
	[IsArchived]         BIT            CONSTRAINT [DF__Projects__IsArchived] DEFAULT ((0)) NOT NULL,  
	[IsShowMigrationPopup]    BIT DEFAULT ((0)) NOT NULL,
	[LockedBy] NVARCHAR(500) Default Null,
	[LockedDate]  DateTime2 (7) Default Null,
	[LockedById] INT Default Null,
	[IsIncomingProject] BIT Default Null,
	[TransferredDate] DateTime2 (7) Default Null,
    CONSTRAINT [PK_PROJECT] PRIMARY KEY CLUSTERED ([ProjectId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Project_LuMasterDataType] FOREIGN KEY ([MasterDataTypeId]) REFERENCES [dbo].[LuMasterDataType] ([MasterDataTypeId]),
    CONSTRAINT [FK_Projects_Templates] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[Template] ([TemplateId])
);

