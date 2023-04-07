CREATE PROC usp_GetAutoArchivedUserPreference  
(  
 @CustomerId INT,  
 @UserId INT=0  
)  
AS  
BEGIN 
DECLARE @PreferenceName NVARCHAR(100)='IsShowArchiveProjectNotification'; 
SELECT CustomerId,UserId,[Name],[value]  FROM UserPreference WITH(NOLOCK) WHERE CustomerId=@CustomerId and [Name]=@PreferenceName and UserId=@UserId
END  
