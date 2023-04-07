CREATE PROCEDURE [dbo].[usp_SetProjectSettingValue](@ProjectId INT, @CustomerId INT, @Key NVARCHAR(100),@Value NVARCHAR(100), @UserID INT)  
AS            
BEGIN  
 IF EXISTS(SELECT TOP 1 [Value] FROM ProjectSetting WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND [Name] = @Key)  
 BEGIN  
 UPDATE PS   
  SET [Value] = @Value,  
   ModifiedDate = GETUTCDATE(),  
   ModifiedBy = @UserID  
  FROM ProjectSetting PS WITH(NOLOCK) WHERE  
 ProjectId = @ProjectId AND CustomerId = @CustomerId AND [Name] = @Key;  
 END  
 ELSE  
 BEGIN  
 INSERT INTO ProjectSetting (ProjectId, CustomerId, [Name], [Value], CreatedDate, CreatedBy) VALUES  
 (@ProjectId, @CustomerId, @Key, @Value, GETUTCDATE(), @UserID);  
 END;  
END;