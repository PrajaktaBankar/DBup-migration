CREATE PROCEDURE [dbo].[usp_MaintainCopyProjectHistory]    
@ProjectId INT,    
@StepName NVARCHAR(500),    
@Description NVARCHAR(500),    
@IsCompleted BIT,    
@Step INT ,  
@RequestId INT  
AS    
BEGIN    
INSERT INTO CopyProjectHistory (ProjectId, StepName, [Description], IsCompleted, CreatedDate, Step,RequestId)    
 VALUES (@ProjectId, @StepName, @Description, @IsCompleted, GETUTCDATE(), @Step,@RequestId);    
END