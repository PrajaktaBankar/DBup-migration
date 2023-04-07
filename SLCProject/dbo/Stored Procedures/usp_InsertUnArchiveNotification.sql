CREATE PROCEDURE [dbo].[usp_InsertUnArchiveNotification]  
(  
 @ArchiveProjectId INT,  
 @ProdProjectId INT,  
 @SLC_UserId INT,  
 @SLC_CustomerId INT,  
 @ProjectName NVARCHAR(500),  
 @RequestType INT  
)  
AS  
BEGIN  
	--Check wether notification is present and status is Queued/Running
	DECLARE @RequestId INT=(SELECT TOP 1 RequestId from UnArchiveProjectRequest WITH(NOLOCK) where SLC_ArchiveProjectId=@ArchiveProjectId
				AND SLC_CustomerId=@SLC_CustomerId and IsDeleted=0 and StatusId IN(1,2))
	IF(isnull(@RequestId,0)>0)
	BEGIN
		UPDATE APR
		SET APR.StatusId=1,
			APR.ProgressInPercentage=0,
			APR.IsNotify=0,
			APR.RequestDate=GETUTCDATE()
		FROM UnArchiveProjectRequest APR WITH(NOLOCK)
		WHERE APR.RequestId=@RequestId
	END
	ELSE
	BEGIN
		INSERT INTO UnArchiveProjectRequest  
		 (SLC_ArchiveProjectId,SLCProd_ProjectId,SLC_CustomerId,SLC_UserId,  
		 RequestDate,RequestType,StatusId,IsNotify,ProgressInPercentage,  
		 EmailFlag,IsDeleted,ProjectName,ModifiedDate)  
		VALUES(@ArchiveProjectId,@ProdProjectId,@SLC_CustomerId,@SLC_UserId,  
		  GETUTCDATE(),@RequestType,1,0,0,  
		  0,0,@ProjectName,GETUTCDATE())         
	END

END