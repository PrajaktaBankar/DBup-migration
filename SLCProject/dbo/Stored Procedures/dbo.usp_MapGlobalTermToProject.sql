CREATE PROCEDURE [dbo].[usp_MapGlobalTermToProject]        
 @ProjectID INT NULL,       
 @CustomerID INT NULL,       
 @UserID INT NULL ,    
 @ProjectName NVARCHAR(MAX) = NULL,    
 @MasterDataTypeId INT =1    
AS        
BEGIN    
---- Map All Global Term    
    
DECLARE @PProjectID INT = @ProjectID;    
DECLARE @PCustomerID INT = @CustomerID;    
DECLARE @PUserID INT = @UserID;    
DECLARE @PProjectName NVARCHAR(MAX) = @ProjectName;    
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;    
DECLARE @StateProvinceName NVARCHAR(100)='', @City NVARCHAR(100)='';    
-- SET City as per selected project    
SET @City = (SELECT TOP 1    
  IIF(LUC.City IS NULL, PADR.CityName, LUC.City) AS City    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuCity LUC WITH (NOLOCK)    
  ON LUC.CityId = PADR.CityId    
 WHERE PADR.ProjectId = @PProjectID    
 AND PADR.CustomerId = @PCustomerID);    
-- SET State as per selected project    
SET @StateProvinceName = (SELECT TOP 1    
  IIF(LUS.StateProvinceName IS NULL, PADR.StateProvinceName, LUS.StateProvinceName) AS StateProvinceName    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuStateProvince LUS WITH (NOLOCK)    
  ON LUS.StateProvinceID = PADR.StateProvinceId    
 WHERE PADR.ProjectId = @PProjectID    
 AND PADR.CustomerId = @PCustomerID);    
    
 --Map master global term    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted, GlobalTermFieldTypeId)    
 SELECT    
  GlobalTermId    
    ,@PProjectID AS ProjectId    
    ,@PCustomerID AS CustomerId    
    ,[Name]    
  --,Value    
    ,CASE    
   WHEN Name = 'Project Name' THEN CAST(@PProjectName AS NVARCHAR(MAX))    
   WHEN Name = 'Project ID' THEN CAST(@PProjectID AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location State' THEN CAST(@StateProvinceName AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location City' THEN CAST(@City AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location Province' THEN CAST(@StateProvinceName AS NVARCHAR(MAX))    
   ELSE [Value]    
  END AS [Value]    
    ,'M'    
    ,GlobalTermCode    
    ,GETUTCDATE()    
    ,@PUserID AS CreatedBy    
    ,GETUTCDATE()    
    ,@PUserID AS ModifiedBy    
    ,NULL    
    ,0 AS IsDeleted    
    ,GlobalTermFieldTypeId    
 FROM SLCMaster..GlobalTerm WITH(NOLOCK)    
 WHERE MasterDataTypeId =    
 CASE    
  WHEN @PMasterDataTypeId = 1 OR    
   @PMasterDataTypeId = 2 OR    
   @PMasterDataTypeId = 3 THEN 1    
  ELSE @PMasterDataTypeId    
 END;    
 -- Map user global term    
 -- declare table variable  
DECLARE @GlobalTermCode TABLE (  
  MinGlobalTermCode int,  
  UserGlobalTermId int  
);  
  
INSERT @GlobalTermCode  
 SELECT MIN(GlobalTermCode) AS MinGlobalTermCode,UserGlobalTermId      
 FROM ProjectGlobalTerm WITH (NOLOCK)    
 WHERE CustomerId =@PCustomerID AND ISNULL(IsDeleted,0)=0     
 AND GlobalTermSource='U' AND  UserGlobalTermId IS NOT NULL
 GROUP BY UserGlobalTermId    
    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value,GlobalTermCode, GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)    
 SELECT    
  NULL AS GlobalTermId    
    ,@PProjectID AS ProjectId    
    ,@PCustomerID AS CustomerId    
    ,Name    
    ,Name    
    ,MGTC.MinGlobalTermCode    
    ,'U'    
    ,GETUTCDATE()    
    ,@PUserID AS CreatedBy    
    ,GETUTCDATE()    
    ,@PUserID AS ModifiedBy    
    ,UGT.UserGlobalTermId AS UserGlobalTermId    
    ,ISNULL(IsDeleted, 0) AS IsDeleted    
 FROM UserGlobalTerm UGT WITH(NOLOCK) INNER JOIN @GlobalTermCode MGTC   
 ON UGT.UserGlobalTermId=MGTC.UserGlobalTermId    
 WHERE CustomerId = @PCustomerID    
 AND IsDeleted = 0    
END 