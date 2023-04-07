CREATE PROCEDURE [dbo].[usp_AddProjectActivity](
@ProjectId INT NULL,
@UserId INT NULL,    
@CustomerId INT NULL,  
@ProjectName NVARCHAR(100) NULL,
@UserEmail  NVARCHAR(100) NULL,
@ProjectActivityTypeId TINYINT  
)
AS 
BEGIN
INSERT INTO ProjectActivity ( 
  ProjectId
, UserId
, CustomerId
, ProjectName
, UserEmail
, ProjectActivityTypeId
, CreatedDate
)
	VALUES (@ProjectId,@UserId,@CustomerId,@ProjectName,@UserEmail,@ProjectActivityTypeId,GETUTCDATE() )
END
