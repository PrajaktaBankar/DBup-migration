CREATE TABLE [dbo].[ProjectSummary] (
    [ProjectSummaryId]            INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]                   INT            NOT NULL,
    [CustomerId]                  INT            NOT NULL,
    [UserId]                      INT            NOT NULL,
    [ProjectTypeId]               INT            NULL,
    [FacilityTypeId]              INT            NULL,
    [SizeUoM]                     INT            NOT NULL,
    [IsIncludeRsInSection]        BIT            DEFAULT ((1)) NOT NULL,
    [IsIncludeReInSection]        BIT            DEFAULT ((1)) NOT NULL,
    [SpecViewModeId]              INT            DEFAULT ((1)) NULL,
    [UnitOfMeasureValueTypeId]    INT            DEFAULT ((3)) NULL,
    [SourceTagFormat]             VARCHAR (10)   CONSTRAINT [DF__ProjectSu__Sourc__7D0E9093] DEFAULT ('99 9999') NOT NULL,
    [IsPrintReferenceEditionDate] BIT            DEFAULT ((1)) NOT NULL,
    [IsActivateRsCitation]        BIT            DEFAULT ((0)) NOT NULL,
    [LastMasterUpdate]            DATETIME       NULL,
    [BudgetedCostId]              INT            NULL,
    [BudgetedCost]                NVARCHAR (256) NULL,
    [ActualCost]                  NVARCHAR (256) NULL,
    [EstimatedArea]               NVARCHAR (256) NULL,
    [SpecificationIssueDate]      DATETIME2 (7)  NULL,
    [SpecificationModifiedDate]   DATETIME2 (7)  NULL,
    [ActualCostId]                INT            DEFAULT ((1)) NULL,
    [ActualSizeId]                INT            DEFAULT ((1)) NULL,
    [EstimatedSizeId]             INT            NULL,
    [EstimatedSizeUoM]            INT            NULL,
    [Cost]                        DECIMAL (18)   DEFAULT ((1)) NOT NULL,
    [Size]                        INT            DEFAULT ((1)) NOT NULL,
    [ProjectAccessTypeId]         INT            DEFAULT ((1)) NOT NULL,
    [OwnerId]                     INT            NULL,
    [TrackChangesModeId]          TINYINT        NULL,
    [IsHiddenAllBsdSections]      BIT            NULL, 
	IsLinkEngineEnabled BIT NOT NULL DEFAULT 1
    CONSTRAINT [PK_PROJECTSUMMARY] PRIMARY KEY CLUSTERED ([ProjectSummaryId] ASC),
    CONSTRAINT [FK_ProjectSummary_LuFacilityType] FOREIGN KEY ([FacilityTypeId]) REFERENCES [dbo].[LuFacilityType] ([FacilityTypeId]),
    CONSTRAINT [FK_ProjectSummary_LuProjectCost_ActualCostId] FOREIGN KEY ([ActualCostId]) REFERENCES [dbo].[LuProjectCost] ([CostId]),
    CONSTRAINT [FK_ProjectSummary_LuProjectCost_BudgetedCostId] FOREIGN KEY ([BudgetedCostId]) REFERENCES [dbo].[LuProjectCost] ([CostId]),
    CONSTRAINT [FK_ProjectSummary_LuProjectSize_ActualSizeId] FOREIGN KEY ([ActualSizeId]) REFERENCES [dbo].[LuProjectSize] ([SizeId]),
    CONSTRAINT [FK_ProjectSummary_LuProjectSize_EstimatedSizeId] FOREIGN KEY ([EstimatedSizeId]) REFERENCES [dbo].[LuProjectSize] ([SizeId]),
    CONSTRAINT [FK_ProjectSummary_LuProjectType] FOREIGN KEY ([ProjectTypeId]) REFERENCES [dbo].[LuProjectType] ([ProjectTypeId]),
    CONSTRAINT [FK_ProjectSummary_LuProjectUoM_EstimatedSizeUoM] FOREIGN KEY ([EstimatedSizeUoM]) REFERENCES [dbo].[LuProjectUoM] ([ProjectUoMId]),
    CONSTRAINT [FK_ProjectSummary_LuSpecificationViewMode] FOREIGN KEY ([SpecViewModeId]) REFERENCES [dbo].[LuSpecificationViewMode] ([SpecViewModeId]),
    CONSTRAINT [FK_ProjectSummary_LuUnitOfMeasureValueType] FOREIGN KEY ([UnitOfMeasureValueTypeId]) REFERENCES [dbo].[LuUnitOfMeasureValueType] ([UnitOfMeasureValueTypeId]),
    CONSTRAINT [FK_ProjectSummary_Projects] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);


GO

CREATE NONCLUSTERED INDEX [NCIx_ProjectSummary_ProjectId_CustomerId]
    ON [dbo].[ProjectSummary]([ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([ProjectSummaryId], [UserId], [ProjectTypeId]) WITH (FILLFACTOR = 90);
GO
