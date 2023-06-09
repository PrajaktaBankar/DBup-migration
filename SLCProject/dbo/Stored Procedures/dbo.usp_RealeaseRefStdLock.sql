CREATE PROCEDURE [dbo].[usp_RealeaseRefStdLock]  
	@RefStdId int,  
	@LockedByUserId INT     
AS   
BEGIN
	DECLARE @PrefStdId int = @refStdId;    
	DECLARE @PLockedByUserId int = @LockedByUserId;    
  
	IF (@PrefStdId > 0)  
	BEGIN  
		 UPDATE RS    
		 SET RS.IsLocked = 0    
		   ,RS.IsLockedById = NULL    
		   ,RS.IsLockedByFullName = NULL    
		 FROM ReferenceStandard RS WITH (NOLOCK)    
		 WHERE RS.RefStdId = @PrefStdId AND RS.IsLockedById = @PLockedByUserId AND RS.IsLocked = 1;    
	END
    
	SELECT    
		RefStdId    
	   ,RefStdName    
	   ,RefStdSource    
	   ,ReplaceRefStdId    
	   ,ReplaceRefStdSource    
	   ,mReplaceRefStdId    
	   ,IsObsolete    
	   ,RefStdCode    
	   ,CreateDate    
	   ,CreatedBy    
	   ,ModifiedDate    
	   ,ModifiedBy    
	   ,CustomerId    
	   ,IsDeleted    
	   ,IsLocked    
	   ,IsLockedByFullName    
	   ,IsLockedById    
	FROM ReferenceStandard WITH (NOLOCK)    
	WHERE RefStdId = @PrefStdId;    
    
END;  
