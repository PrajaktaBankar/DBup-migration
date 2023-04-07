CREATE PROCEDURE usp_GetTransferProjectDefaultPrivacySetting     
(    
   @CustomerId int,    
   @UserId int,    
   @IsOfficeMaster bit,    
   @ProjectAccessTypeId int OUTPUT,    
   @ProjectOwnerId int OUTPUT    
)     
AS     
BEGIN     
    
 DECLARE @PCustomerId int = @CustomerId;    
 DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;    
 DECLARE @ProjectOrigineType int = 3; -- Transferred Project    
 DECLARE @ProjectOwnerTypeId int = null;    
    
 SELECT    
    PPS.CustomerId,    
    PPS.ProjectAccessTypeId,    
    PPS.ProjectOwnerTypeId,    
    PPS.ProjectOriginTypeId,    
    PPS.IsOfficeMaster     
 INTO #ProjDefaultPrivacySetting    
 FROM ProjectDefaultPrivacySetting PPS WITH(NOLOCK)    
 WHERE PPS.CustomerId = 0    
    AND PPS.ProjectOriginTypeId = @ProjectOrigineType    
    AND PPS.IsOfficeMaster = @PIsOfficeMaster;    
    
 UPDATE PPS    
 SET PPS.ProjectAccessTypeId = PDPS.ProjectAccessTypeId,    
     PPS.ProjectOwnerTypeId = PDPS.ProjectOwnerTypeId    
 FROM #ProjDefaultPrivacySetting PPS WITH(NOLOCK)    
 JOIN ProjectDefaultPrivacySetting PDPS WITH(NOLOCK) ON PPS.IsOfficeMaster = PDPS.IsOfficeMaster    
             AND PPS.ProjectOriginTypeId = PDPS.ProjectOriginTypeId    
             AND PDPS.CustomerId = @PCustomerId;    
    
 SELECT TOP 1 @ProjectAccessTypeId = ProjectAccessTypeId, @ProjectOwnerTypeId = ProjectOwnerTypeId    
 FROM #ProjDefaultPrivacySetting WITH(NOLOCK);    
     
 IF(@ProjectOwnerTypeId = 2)    
  SET @ProjectOwnerId = @UserId;    
END     