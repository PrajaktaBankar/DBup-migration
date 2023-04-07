CREATE TABLE [dbo].[LuProjectLinkStatusType] (
    [LinkStatusTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [LinkStatusType]   NVARCHAR (255) NULL,
    [Description]      NVARCHAR (500) NULL,
    CONSTRAINT [PK_LUPROJECTLINKSTATUSTYPE] PRIMARY KEY CLUSTERED ([LinkStatusTypeId] ASC)
);

