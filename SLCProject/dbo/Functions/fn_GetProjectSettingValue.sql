CREATE FUNCTION [dbo].[fn_GetProjectSettingValue](@ProjectId INT, @CustomerId INT, @Key NVARCHAR(100))  
RETURNS NVARCHAR(200)            
AS            
BEGIN            
 DECLARE @SettingValue NVARCHAR(200) = NULL;  
  
 SELECT @SettingValue = [Value] from ProjectSetting WITH(NOLOCK) WHERE   
 ProjectId = @ProjectId AND CustomerId = @CustomerId AND [Name] = @Key;  
  
 RETURN @SettingValue;            
END;