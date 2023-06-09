CREATE PROC usp_RemoveNotification
(  
 @RequestId INT,
 @Source NVARCHAR(50)
)  
AS  
BEGIN  
	IF(@Source='CopyProject')
	BEGIN
		UPDATE CPR  
		SET CPR.IsDeleted=1,  
		ModifiedDate=GETUTCDATE()  
		FROM CopyProjectRequest CPR WITH(NOLOCK)  
		WHERE CPR.StatusId NOT IN(2) AND CPR.RequestId=@RequestId  
	END
	ELSE IF(@Source='unArchiveProject')
	BEGIN
		UPDATE CPR  
		SET CPR.IsDeleted=1,  
		ModifiedDate=GETUTCDATE()  
		FROM UnArchiveProjectRequest CPR WITH(NOLOCK)  
		WHERE CPR.StatusId NOT IN(1,2) AND CPR.RequestId=@RequestId  
	END
	ELSE IF(@Source='SpecAPI')
	BEGIN
		UPDATE CPR  
		SET CPR.IsDeleted=1,  
		ModifiedDate=GETUTCDATE()  
		FROM ImportProjectRequest CPR WITH(NOLOCK)  
		WHERE CPR.StatusId NOT IN(1,2) AND CPR.RequestId=@RequestId  
	END
END