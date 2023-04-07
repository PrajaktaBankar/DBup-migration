CREATE PROCEDURE [dbo].[usp_MaintainImportProjectHistory]        
@ProjectId INT,        
@StepName NVARCHAR(500),        
@Description NVARCHAR(500),        
@IsCompleted BIT,        
@Step TINYINT ,      
@RequestId INT      
AS        
BEGIN        
INSERT INTO ImportProjectHistory(ProjectId, StepName, [Description], IsCompleted, CreatedDate, Step,RequestId)        
 VALUES (@ProjectId, @StepName, @Description, @IsCompleted, GETUTCDATE(), @Step,@RequestId);        
END