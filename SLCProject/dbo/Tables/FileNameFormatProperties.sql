
CREATE TABLE FileNameFormatProperties(
Id INT Primary key IDENTITY(1,1),
[Name] NVARCHAR(50),
PlaceHolder NVARCHAR(10),
[Value] NVARCHAR(200),
IsForDocument BIT,
IsForProjectReport BIT,
ProjectId INT,
CustomerId INT,
CreatedBy INT,
CreateDate DATETIME2,
ModifiedBy INT,
ModifiedDate DATETIME2
)

