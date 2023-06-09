CREATE TABLE PrintRequestDetails
(
PrintRequestId INT IDENTITY(1,1),
FileName NVARCHAR(150),
CustomerId INT,
ProjectId INT,
ProjectName NVARCHAR(100),
SectionName NVARCHAR(100),
PrintTypeId INT,
IsExportAsSingleFile BIT,
IsBeginFromOddPage BIT,
IsIncludeAuthorName BIT,
TrackChangesOption INT,
PrintStatus NVARCHAR(20),
CreatedDate DATETIME,
CreatedBy INT,
ModifiedDate DATETIME,
ModifiedBy INT
CONSTRAINT [PK_PrintRequestDetails] PRIMARY KEY CLUSTERED ([PrintRequestId] ASC),
CONSTRAINT [FK_PrintRequestDetails_LuProjectExportType] FOREIGN KEY ([PrintTypeId]) REFERENCES [dbo].[LuProjectExportType] ([ProjectExportTypeId]),
CONSTRAINT [FK_PrintRequestDetails_LuTCPrintMode] FOREIGN KEY ([TrackChangesOption]) REFERENCES [dbo].[LuTCPrintMode] ([TCPrintModeId])
)