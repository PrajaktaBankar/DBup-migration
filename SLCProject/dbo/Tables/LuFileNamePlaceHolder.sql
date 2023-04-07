
CREATE TABLE LuFileNamePlaceHolder(
Id INT Primary key IDENTITY(1,1),
[Name] NVARCHAR(50),
PlaceHolder NVARCHAR(10),
[Value] NVARCHAR(200),
IsForDocument BIT,
IsForProjectReport BIT
)

