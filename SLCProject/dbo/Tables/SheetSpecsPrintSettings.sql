 CREATE TABLE SheetSpecsPrintSettings (
    CustomerId int NOT NULL,
	ProjectId int,    UserId int ,
    CreatedDate DateTime2,
    CreatedBy int NOT NULL,
	ModifiedDate DateTime2,
    ModifiedBy int,
	IsDeleted BIT ,
	SheetSpecsPrintPreviewLevel INT NOT NULL DEFAULT (0),
   	CONSTRAINT [FK_SheetSpecsPrintSettings_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);
