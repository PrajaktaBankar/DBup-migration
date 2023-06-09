CREATE PROCEDURE [dbo].[usp_CreateHeaderFooter]  /* exec [dbo].[usp_CreateHeaderFooter] '{"HeaderId":0,"ProjectId":12790,"SectionId":null,"CustomerId":8,"Description":"","IsLocked":false,"LockedByFullName":"","LockedBy":0,"ShowFirstPage":false,"CreatedBy":92,"CreatedDate":"2018-12-20T15:06:44Z","ModifiedBy":92,"ModifiedDate":"2018-12-20T15:06:44Z","TypeId":1,"AltHeader":"","FPHeader":"","UseSeparateFPHeader":null,"HeaderFooterCategoryId":null}','{"FooterId":0,"ProjectId":12790,"SectionId":null,"CustomerId":8,"Description":"","IsLocked":false,"LockedByFullName":"","LockedBy":0,"ShowFirstPage":false,"CreatedBy":92,"CreatedDate":"2018-12-20T15:06:44Z","ModifiedBy":92,"ModifiedDate":"2018-12-20T15:06:44Z","TypeId":1,"AltFooter":"","FPFooter":"","UseSeparateFPFooter":null,"HeaderFooterCategoryId":null}'*/
@headerData NVARCHAR (MAX),
@footerData NVARCHAR(max)
AS    
BEGIN
DECLARE @PheaderData NVARCHAR (MAX) = @headerData;
DECLARE @PfooterData NVARCHAR(max) = @footerData;

  print @PheaderData
  print @PfooterData

 CREATE TABLE #TempHeader (
 ProjectId INT NULL,    
 SectionId INT NULL, 
 CustomerId INT NULL,    
 Description nvarchar(max),
 IsLocked BIT NULL,
 LockedBy INT NULL,
 CreatedBy INT NULL,
 CreatedDate DATETIME,
 ModifiedBy INT NULL,
 ModifiedDate DATETIME,
 TypeId INT NULL,
 AltHeader NVARCHAR(MAX),
 FPHeader NVARCHAR(MAX),
 HeaderFooterDisplayTypeId INT NULL,
 DefaultHeader NVARCHAR(MAX),
 FirstPageHeader NVARCHAR(MAX),
 OddPageHeader NVARCHAR(MAX),
 EvenPageHeader NVARCHAR(MAX)
 );

 
 CREATE TABLE #TempFooter (
 ProjectId INT NULL,    
 SectionId INT NULL, 
 CustomerId INT NULL,    
 Description nvarchar(max),
 IsLocked BIT NULL,
 LockedBy INT NULL,
 CreatedBy INT NULL,
 CreatedDate DATETIME,
 ModifiedBy INT NULL,
 ModifiedDate DATETIME,
 TypeId INT NULL,
 AltFooter NVARCHAR(MAX),
 FPFooter NVARCHAR(MAX),
 HeaderFooterDisplayTypeId INT NULL,
 DefaultFooter NVARCHAR(MAX),
 FirstPageFooter NVARCHAR(MAX),
 OddPageFooter NVARCHAR(MAX),
 EvenPageFooter NVARCHAR(MAX)
 );


END


GO
