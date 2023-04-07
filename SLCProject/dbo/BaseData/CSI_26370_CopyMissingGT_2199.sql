--------Server 3--------

USE [SLCProject]
GO

DECLARE @RC int
DECLARE @ProjectID int = 2199
DECLARE @CustomerID int = 546
DECLARE @UserID int = 1292
DECLARE @ProjectName nvarchar(max) ='Gaston Tower'
DECLARE @MasterDataTypeId int = 1


INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)
	SELECT
		GlobalTermId
	   ,@ProjectID AS ProjectId
	  ,@CustomerID AS CustomerId
	   ,[Name]
	   --,Value
	    ,CASE
			WHEN GlobalTermId = 1 THEN CAST(@ProjectName AS NVARCHAR(MAX))
		    WHEN GlobalTermId = 2 THEN CAST(@ProjectID AS NVARCHAR(MAX))
			 ELSE [Value]
		 END AS [Value]
	   ,'M'
	   ,GlobalTermCode
	   ,GETUTCDATE()
	  ,@UserID AS CreatedBy
	   ,GETUTCDATE()
	  ,@UserID AS ModifiedBy
	   ,NUll
	   ,0 AS IsDeleted
	FROM SLCMaster..GlobalTerm(Nolock)
	WHERE MasterDataTypeId = @MasterDataTypeId

