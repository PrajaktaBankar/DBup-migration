CREATE PROCEDURE usp_GetTransferProjectViewTypeId          
(         
   @MasterDataTypeId INT =1 ,      
   @SenderProjectViewTypeId INT =1 ,     
   @SenderCustomerId INT ,   
   @RecipientCustomerId INT ,      
   @SpecViewModeId int OUTPUT          
)           
AS           
BEGIN      
      
DECLARE @SenderCatalogueType nvarchar(50)      
,@SenderFeatureValue nvarchar(max)      
,@RecipientCatalogueType nvarchar(50)      
,@RecipientFeatureValue nvarchar(max)      
,@RecipentProjectViewTypeId INT =1      
,@OLSF NVARCHAR(50)='OL/SF'      
,@FS NVARCHAR(50)='FS'      
,@EntitlementFeatureId INT=2--USA      
,@DefaultProjectTypeView INT =3--SF(Sort Form View)      
,@SLCProductId INT=4      
  
--Get entitlement for Master      
SET @EntitlementFeatureId =      
CASE      
 WHEN @MasterDataTypeId = 1 THEN 2  --USA    
 WHEN @MasterDataTypeId = 2 THEN 3  --CANADA    
 WHEN @MasterDataTypeId = 3 THEN 4  --NMS E    
 WHEN @MasterDataTypeId = 4 THEN 5  --NMS F     
 ELSE 2      
END;      
         
SELECT      
 @SenderFeatureValue = CONCAT(N'[', FeatureValue, ']')      
FROM [SLCADMIN].[Authentication].[dbo].CustomerEntitlement CE  WITH(NOLOCK)      
INNER JOIN [SLCADMIN].[Authentication].[dbo].CustomerProductLicense CPL  WITH(NOLOCK)      
 ON CE.CustomerId = CPL.CustomerId      
  AND CE.SubscriptionId = CPL.SubscriptionId      
WHERE CE.CustomerId = @SenderCustomerId      
AND CE.EntitlementFeatureId = @EntitlementFeatureId     
AND CPL.ProductId = @SLCProductId      
AND CPL.IsActive = 1      
      
SELECT      
 @SenderCatalogueType = CatalogueType      
FROM OPENJSON(@SenderFeatureValue)      
WITH (      
CatalogueType NVARCHAR(50) 'strict $.CatalogueType'      
);      
      
SELECT      
 @RecipientFeatureValue = CONCAT(N'[', FeatureValue, ']')      
FROM [SLCADMIN].[Authentication].[dbo].CustomerEntitlement CE WITH(NOLOCK)      
INNER JOIN [SLCADMIN].[Authentication].[dbo].CustomerProductLicense CPL WITH(NOLOCK)      
 ON CE.CustomerId = CPL.CustomerId      
  AND CE.SubscriptionId = CPL.SubscriptionId      
WHERE CE.CustomerId = @RecipientCustomerId       
AND CE.EntitlementFeatureId = @EntitlementFeatureId      
AND CPL.ProductId = @SLCProductId      
AND CPL.IsActive = 1      
      
SELECT      
 @RecipientCatalogueType = CatalogueType      
FROM OPENJSON(@RecipientFeatureValue)      
WITH (      
CatalogueType NVARCHAR(50) 'strict $.CatalogueType'      
);      
      
IF (@SenderCatalogueType = @FS      
 AND @RecipientCatalogueType = @OLSF      
 AND @SenderProjectViewTypeId = 1)      
SET @RecipentProjectViewTypeId = @DefaultProjectTypeView      
--Recipient dose not have Subcription      
ELSE IF (@SenderCatalogueType=@FS AND @RecipientCatalogueType IS NULL)      
SET @RecipentProjectViewTypeId = @DefaultProjectTypeView      
ELSE      
SET @RecipentProjectViewTypeId = @SenderProjectViewTypeId      
      
SET @SpecViewModeId = @RecipentProjectViewTypeId      
      
END      
     