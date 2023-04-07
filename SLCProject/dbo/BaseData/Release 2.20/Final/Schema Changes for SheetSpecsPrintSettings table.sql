USE [SLCProject]
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'SheetSpecsPrintSettings'))
BEGIN
CREATE TABLE SheetSpecsPrintSettings
(
	CustomerId int NOT NULL,
	ProjectId int,    UserId int ,
    CreatedDate DateTime2,
    CreatedBy int NOT NULL,
	ModifiedDate DateTime2,
    ModifiedBy int,
	IsDeleted BIT ,
	SheetSpecsPrintPreviewLevel INT NOT NULL DEFAULT (0),
   	CONSTRAINT [FK_SheetSpecsPrintSettings_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
)
PRINT 'SheetSpecsPrintSettings table created successfully.';
END
ELSE
PRINT 'SheetSpecsPrintSettings table already exists.';