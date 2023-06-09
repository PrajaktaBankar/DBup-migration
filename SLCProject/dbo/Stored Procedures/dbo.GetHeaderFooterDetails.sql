CREATE PROCEDURE [dbo].[GetHeaderFooterDetails] --EXEC [dbo].[GetHeaderFooterDetails] 6162,3860558,2,2       
@ProjectId INT NULL,                
@SectionId INT NULL,                
@CustomerId INT NULL,                
@typeId INT NULL ,  
@DocumentTypeId INT = 1                  
AS                
BEGIN  
      
 DECLARE @PProjectId INT = @ProjectId;  
 DECLARE @PSectionId INT = @SectionId;  
 DECLARE @PCustomerId INT = @CustomerId;  
   
 DECLARE @PtypeId INT = @typeId;  
              
 DECLARE @ProjectLevel INT = 1;  
        
 DECLARE @SectionLevel INT = 2;  
      
 DECLARE @HasSectionHF BIT = 1;  
      
 DECLARE @HasProjectHF BIT = 0;  
      
 DECLARE @IsHeaderExists BIT = 0;  
 DECLARE @IsFooterExists BIT = 0;  
 DECLARE @false BIT = 0;  
  
SELECT  
 @HasProjectHF = IIF(DefaultHeader IS NULL AND FirstPageHeader IS NULL AND OddPageHeader IS NULL AND EvenPageHeader IS NULL, 0, 1)  
FROM Header WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND CustomerId = @PCustomerId  
AND DocumentTypeId=@DocumentTypeId   
  
if(@DocumentTypeId=1)  
BEGIN  
--CHECK IF hEADER EXIST OR FOOTER EXXIST--  
IF EXISTS (SELECT TOP 1 1 FROM Header WITH (NOLOCK) WHERE ProjectId = @PProjectId)  
BEGIN  
SET @IsHeaderExists = 1;  
END  
  
IF EXISTS (SELECT TOP 1 1 FROM Footer WITH (NOLOCK) WHERE ProjectId = @PProjectId AND DocumentTypeId=@DocumentTypeId)  
BEGIN  
SET @IsFooterExists = 1;  
END  
      
--If @PtypeId is NULL OR Zero then load Project Header By Default        
IF (@PtypeId IS NULL OR @PtypeId = 0)      
 BEGIN  
SET @HasSectionHF = 0;  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(SectionId, @PSectionId) AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultHeader, '') AS DefaultHeader  
   ,ISNULL(FirstPageHeader, '') AS FirstPageHeader  
   ,ISNULL(EvenPageHeader, '') AS EvenPageHeader  
   ,ISNULL(OddPageHeader, '') AS OddPageHeader 
   ,ISNULL (IsShowLineAboveHeader, @false)AS  IsShowLineAboveHeader 
   ,ISNULL (IsShowLineBelowHeader, @false)AS  IsShowLineBelowHeader  
FROM Header WITH (NOLOCK)  
WHERE  ProjectId = @PProjectId  
AND TypeId = @ProjectLevel  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1)  
AND DocumentTypeId=@DocumentTypeId  
  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(SectionId, @PSectionId) AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultFooter, '') AS DefaultFooter  
   ,ISNULL(FirstPageFooter, '') AS FirstPageFooter  
   ,ISNULL(EvenPageFooter, '') AS EvenPageFooter  
   ,ISNULL(OddPageFooter, '') AS OddPageFooter
   ,ISNULL(IsShowLineAboveFooter , @false) AS IsShowLineAboveFooter 
   ,ISNULL(IsShowLineBelowFooter , @false) AS IsShowLineBelowFooter    
FROM Footer WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
   
AND TypeId = @ProjectLevel  
  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1)  
AND DocumentTypeId=@DocumentTypeId  
END  
ELSE--Else load available header and footer        
BEGIN  
IF EXISTS (SELECT TOP 1  
   1  
  FROM Header WITH (NOLOCK)  
  WHERE ProjectId = @PProjectId  
  AND SectionId = @PSectionId AND DocumentTypeId=@DocumentTypeId)  
BEGIN  
SET @HasSectionHF = 1;  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(SectionId, @PSectionId) AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultHeader, '') AS DefaultHeader  
   ,ISNULL(FirstPageHeader, '') AS FirstPageHeader  
   ,ISNULL(EvenPageHeader, '') AS EvenPageHeader  
   ,ISNULL(OddPageHeader, '') AS OddPageHeader  
   ,ISNULL (IsShowLineAboveHeader,@false)AS  IsShowLineAboveHeader 
   ,ISNULL (IsShowLineBelowHeader ,@false)AS  IsShowLineBelowHeader  
FROM Header WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND SectionId = @PSectionId  
AND TypeId = @SectionLevel  
AND (HeaderFooterCategoryId IS NULL   
OR HeaderFooterCategoryId = 1  
OR HeaderFooterCategoryId = 4)  
AND DocumentTypeId=@DocumentTypeId  
END  
ELSE  
BEGIN  
SET @HasSectionHF = 0;  
  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultHeader, '') AS DefaultHeader  
   ,ISNULL(FirstPageHeader, '') AS FirstPageHeader  
   ,ISNULL(EvenPageHeader, '') AS EvenPageHeader  
   ,ISNULL(OddPageHeader, '') AS OddPageHeader  
   ,ISNULL (IsShowLineAboveHeader,@false)AS  IsShowLineAboveHeader 
   ,ISNULL (IsShowLineBelowHeader ,@false)AS  IsShowLineBelowHeader  
FROM Header WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND TypeId = @ProjectLevel  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1)  
AND DocumentTypeId=@DocumentTypeId 
AND SectionId IS NULL 
UNION  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultHeader, '') AS DefaultHeader  
   ,ISNULL(FirstPageHeader, '') AS FirstPageHeader  
   ,ISNULL(EvenPageHeader, '') AS EvenPageHeader  
   ,ISNULL(OddPageHeader, '') AS OddPageHeader
   ,ISNULL (IsShowLineAboveHeader,@false)AS  IsShowLineAboveHeader 
   ,ISNULL (IsShowLineBelowHeader ,@false)AS  IsShowLineBelowHeader    
FROM Header WITH (NOLOCK)  
WHERE ProjectId IS NULL  
AND CustomerId IS NULL  
AND SectionId IS NULL  
AND @IsHeaderExists = 0  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1)  
AND DocumentTypeId=@DocumentTypeId  
END  
  
IF EXISTS (SELECT TOP 1  
   1  
  FROM Footer WITH (NOLOCK)  
  WHERE ProjectId = @PProjectId  
  AND SectionId = @PSectionId AND DocumentTypeId=@DocumentTypeId)  
BEGIN  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(SectionId, @PSectionId) AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultFooter, '') AS DefaultFooter  
   ,ISNULL(FirstPageFooter, '') AS FirstPageFooter  
   ,ISNULL(EvenPageFooter, '') AS EvenPageFooter  
   ,ISNULL(OddPageFooter, '') AS OddPageFooter
   ,ISNULL (IsShowLineAboveFooter,@false)AS  IsShowLineAboveFooter
   ,ISNULL (IsShowLineBelowFooter ,@false)AS  IsShowLineBelowFooter  
FROM Footer WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND SectionId = @PSectionId  
AND TypeId = @SectionLevel  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1  
OR HeaderFooterCategoryId = 4)  
AND DocumentTypeId=@DocumentTypeId  
END  
ELSE  
BEGIN  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultFooter, '') AS DefaultFooter  
   ,ISNULL(FirstPageFooter, '') AS FirstPageFooter  
   ,ISNULL(EvenPageFooter, '') AS EvenPageFooter  
   ,ISNULL(OddPageFooter, '') AS OddPageFooter
   ,ISNULL (IsShowLineAboveFooter,@false)AS  IsShowLineAboveFooter
   ,ISNULL (IsShowLineBelowFooter ,@false)AS  IsShowLineBelowFooter    
FROM Footer WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND TypeId = @ProjectLevel  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1)  
AND DocumentTypeId=@DocumentTypeId  
AND SectionId IS NULL 
UNION  
SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultFooter, '') AS DefaultFooter  
   ,ISNULL(FirstPageFooter, '') AS FirstPageFooter  
   ,ISNULL(EvenPageFooter, '') AS EvenPageFooter  
   ,ISNULL(OddPageFooter, '') AS OddPageFooter 
   ,ISNULL (IsShowLineAboveFooter,@false)AS  IsShowLineAboveFooter
   ,ISNULL (IsShowLineBelowFooter ,@false)AS  IsShowLineBelowFooter     
FROM Footer WITH (NOLOCK)  
WHERE ProjectId IS NULL  
AND CustomerId IS NULL  
AND SectionId IS NULL  
AND @IsFooterExists = 0  
AND (HeaderFooterCategoryId IS NULL  
OR HeaderFooterCategoryId = 1)  
AND DocumentTypeId=@DocumentTypeId  
END  
END  
END  
ELSE  
BEGIN  
  
IF EXISTS (SELECT TOP 1 1  
  FROM Header WITH (NOLOCK)  
  WHERE ProjectId = @PProjectId AND DocumentTypeId=@DocumentTypeId)  
  BEGIN  
  SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultHeader, '') AS DefaultHeader  
   ,ISNULL(FirstPageHeader, '') AS FirstPageHeader  
   ,ISNULL(EvenPageHeader, '') AS EvenPageHeader  
   ,ISNULL(OddPageHeader, '') AS OddPageHeader
   ,ISNULL (IsShowLineAboveHeader, @false)AS  IsShowLineAboveHeader
   ,ISNULL (IsShowLineBelowHeader , @false)AS  IsShowLineBelowHeader      
FROM Header WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND DocumentTypeId=@DocumentTypeId  
  END  
  ELSE  
  BEGIN  
  SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultHeader, '') AS DefaultHeader  
   ,ISNULL(FirstPageHeader, '') AS FirstPageHeader  
   ,ISNULL(EvenPageHeader, '') AS EvenPageHeader  
   ,ISNULL(OddPageHeader, '') AS OddPageHeader 
   ,ISNULL (IsShowLineAboveHeader,@false)AS  IsShowLineAboveHeader
   ,ISNULL (IsShowLineBelowHeader ,@false)AS  IsShowLineBelowHeader    
FROM Header WITH (NOLOCK)  
WHERE ProjectId IS NULL  
AND CustomerId IS NULL  
AND SectionId IS NULL  
AND DocumentTypeId=@DocumentTypeId  
  END  
IF EXISTS (SELECT TOP 1 1  
      
  FROM Footer WITH (NOLOCK)  
  WHERE ProjectId = @PProjectId AND DocumentTypeId=@DocumentTypeId)  
  BEGIN  
  SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultFooter, '') AS DefaultFooter  
   ,ISNULL(FirstPageFooter, '') AS FirstPageFooter  
   ,ISNULL(EvenPageFooter, '') AS EvenPageFooter  
   ,ISNULL(OddPageFooter, '') AS OddPageFooter 
   ,ISNULL (IsShowLineAboveFooter,@false)AS  IsShowLineAboveFooter
   ,ISNULL (IsShowLineBelowFooter ,@false)AS  IsShowLineBelowFooter  
FROM Footer WITH (NOLOCK)  
WHERE ProjectId = @PProjectId  
AND DocumentTypeId=@DocumentTypeId  
  END  
  ELSE  
  BEGIN  
  SELECT  
 ISNULL(ProjectId, @PProjectId) AS ProjectId  
   ,0 AS SectionId  
   ,ISNULL(CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL([Description], '') AS [Description]  
   ,ISNULL(IsLocked, 0) AS IsLocked  
   ,ISNULL(LockedBy, 0) AS LockedBy  
   ,ISNULL(CreatedBy, 0) AS CreatedBy  
   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
   ,ISNULL(TypeId, 0) AS TypeId  
   ,ISNULL(HeaderFooterDisplayTypeId, 0) AS HeaderFooterDisplayTypeId  
   ,ISNULL(DefaultFooter, '') AS DefaultFooter  
   ,ISNULL(FirstPageFooter, '') AS FirstPageFooter  
   ,ISNULL(EvenPageFooter, '') AS EvenPageFooter  
   ,ISNULL(OddPageFooter, '') AS OddPageFooter 
   ,ISNULL (IsShowLineAboveFooter,@false)AS  IsShowLineAboveFooter
   ,ISNULL (IsShowLineBelowFooter ,@false)AS  IsShowLineBelowFooter  
FROM Footer WITH (NOLOCK)  
WHERE ProjectId IS NULL  
AND CustomerId IS NULL  
AND SectionId IS NULL  
AND DocumentTypeId=@DocumentTypeId  
  END  
  
END  
--Query to check if section and project level header-footer exists             
SELECT  
 @HasProjectHF AS HasProjectHeader  
   ,@HasSectionHF AS HasSectionHeader  
END
GO