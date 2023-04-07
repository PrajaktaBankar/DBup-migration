CREATE FUNCTION [dbo].[udf_IsAllBsdMasterDivisionHidden](@ProjectId INT, @CustomerId INT)  
RETURNS BIT  
AS              
BEGIN              
 DECLARE @IsAllBsdMasterDivisionHidden BIT = 1;    
 DECLARE @MasterDataTypeId INT = (SELECT MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);  
  
 IF(@MasterDataTypeId = 1 OR @MasterDataTypeId =4) -- BSD Master  
 BEGIN  
 SELECT TOP 1 @IsAllBsdMasterDivisionHidden = 0 FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId  
 AND ISlastLevel = 0  AND ISNULL(mSectionId,0) > 0 AND LevelId = 2 AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsHidden,0) = 0;  
 END  
 ELSE-- NMS Master  
 BEGIN  
 SELECT TOP 1 @IsAllBsdMasterDivisionHidden = 0 FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId   
 AND ISlastLevel = 0 AND ISNULL(mSectionId,0) > 0 AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsHidden,0) = 0  
 AND (LevelId = 1 OR (LevelId = 2 AND Sourcetag IN ('A','B','C','D','E','G')))  
 END;  
    
 RETURN @IsAllBsdMasterDivisionHidden;              
END;  
  