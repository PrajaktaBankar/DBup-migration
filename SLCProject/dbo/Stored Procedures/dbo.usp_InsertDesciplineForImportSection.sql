CREATE PROCEDURE [dbo].[usp_InsertDesciplineForImportSection]  
@SectionId INT,
@ProjectId INT,
@CustomerId INT
AS
BEGIN

DECLARE @PSectionId INT = @SectionId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;

DECLARE @DefaultDisciplinesTbl TABLE (
DisciplineId INT
);

INSERT INTO @DefaultDisciplinesTbl (DisciplineId)
	VALUES (2), (3), (4), (5), (6), (7), (9)

INSERT INTO [ProjectDisciplineSection] (SectionId
, Disciplineld
, ProjectId
, CustomerId,
IsActive)
	SELECT
		@PSectionId
	   ,TBL.DisciplineId
	   ,@PProjectId
	   ,@PCustomerId
	   ,1 AS Active
	FROM @DefaultDisciplinesTbl TBL
END

GO
