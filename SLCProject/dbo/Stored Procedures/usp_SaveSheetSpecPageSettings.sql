CREATE PROCEDURE  usp_SaveSheetSpecPageSettings                                              
(           
 @SheetSpecColumnJson NVARCHAR(MAX),        
 @SheetSpecsPageSttingsJson NVARCHAR(MAX),        
 @CreatedBy  INT,        
 @ProjectId  INT,        
 @CustomerID INT,    
 @PaperSettingKey INT        
)                                                                
AS                                                                
BEGIN        
DECLARE @PSheetSpecColumnJson NVARCHAR(MAX) = @SheetSpecColumnJson        
DECLARE @PSheetSpecsPageSttingsJson NVARCHAR(MAX) = @SheetSpecsPageSttingsJson        
DECLARE @PCreatedBy  INT = @CreatedBy        
DECLARE @PProjectId  INT = @ProjectId        
DECLARE @PCustomerID INT = @CustomerID        
DECLARE @TempPaperNameValue nvarchar(500) = ''        
        
DECLARE @TeampSheetSpecsPageSettings Table(         
 ProjectId int,        
 CustomerId int,        
 [Name] nvarchar(500),        
 [Value] nvarchar(MAX),       
 CreatedDate datetime2,        
 CreatedBy int,        
 ModifiedDate datetime2,        
 ModifiedBy int        
)        
        
IF @PSheetSpecsPageSttingsJson != ''                                                                
BEGIN                                                        
 INSERT INTO @TeampSheetSpecsPageSettings (ProjectId        
 ,CustomerId        
 ,[Name]        
 ,[Value]        
 ,CreatedDate        
 ,CreatedBy        
 ,ModifiedDate        
 ,ModifiedBy)        
  SELECT         
  @PProjectId        
 ,@PCustomerId        
 ,[key] AS [Name]        
 ,[Value] AS [Value]      
 ,GETUTCDATE()        
 ,@CreatedBy        
 ,NULL        
 ,NULL        
  FROM OPENJSON(@PSheetSpecsPageSttingsJson)          
        
INSERT INTO @TeampSheetSpecsPageSettings(ProjectId        
 ,CustomerId        
 ,[Name]        
 ,[Value]        
 ,CreatedDate        
 ,CreatedBy        
 ,ModifiedDate        
 ,ModifiedBy)      
 SELECT @PProjectId    
 ,@PCustomerId        
 ,'ColumnFormatDetails' AS [Name]        
 ,@PSheetSpecColumnJson AS [Value]      
 ,GETUTCDATE()        
 ,@CreatedBy        
 ,NULL        
 ,NULL       
     
  --Check if Same Page Name exists then update else insert        
 IF exists (select top 1 1 from SheetSpecsPageSettings with (nolock)     
 where CustomerId = @PCustomerId and ProjectId = @PProjectId)        
     BEGIN      
	  -- Check if TitleBlock not exists then insert into table 
	  IF not exists (select top 1 1 from SheetSpecsPageSettings with (nolock) where CustomerId = @PCustomerId and ProjectId = @PProjectId and Name = 'TitleBlock')  
	  BEGIN
		INSERT INTO SheetSpecsPageSettings(        
		  PaperSettingKey        
		  ,ProjectId        
		  ,CustomerId        
		  ,[Name]        
		  ,[Value]        
		  ,CreatedDate        
		  ,CreatedBy        
		  ,ModifiedDate        
		  ,ModifiedBy    
		  ,IsActive    
		  ,IsDeleted)        
		  SELECT         
		  @PaperSettingKey        
		  ,TSSPS.ProjectId        
		  ,TSSPS.CustomerId        
		  ,TSSPS.[Name]        
		  ,TSSPS.[Value]        
		  ,TSSPS.CreatedDate        
		  ,TSSPS.CreatedBy        
		  ,TSSPS.ModifiedDate        
		  ,TSSPS.ModifiedBy    
		  ,1 AS IsActive    
		  ,0 AS IsDeleted    
		 FROM @TeampSheetSpecsPageSettings TSSPS  
		 Where TSSPS.CustomerId = @PCustomerId and TSSPS.ProjectId = @PProjectId 
		 AND TSSPS.Name = 'TitleBlock' 
      END

      UPDATE SSPS SET        
      SSPS.[Value] = TSSPS.[Value],        
      SSPS.ModifiedBy = @PCreatedBy,        
      SSPS.ModifiedDate = GETUTCDATE(),    
      PaperSettingKey = @PaperSettingKey     
      FROM SheetSpecsPageSettings SSPS WITH(NOLOCK) INNER JOIN @TeampSheetSpecsPageSettings TSSPS        
      ON SSPS.CustomerId = TSSPS.CustomerId        
      AND SSPS.ProjectId = TSSPS.ProjectId         
      AND SSPS.[Name] = TSSPS.[Name]    
      
     END        
 ELSE        
    BEGIN        
      INSERT INTO SheetSpecsPageSettings(        
      PaperSettingKey        
      ,ProjectId        
      ,CustomerId        
      ,[Name]        
      ,[Value]        
      ,CreatedDate        
      ,CreatedBy        
      ,ModifiedDate        
      ,ModifiedBy    
      ,IsActive    
      ,IsDeleted)        
      SELECT         
      @PaperSettingKey        
      ,TSSPS.ProjectId        
      ,TSSPS.CustomerId        
      ,TSSPS.[Name]        
      ,TSSPS.[Value]        
      ,TSSPS.CreatedDate        
      ,TSSPS.CreatedBy        
      ,TSSPS.ModifiedDate        
      ,TSSPS.ModifiedBy    
      ,1 AS IsActive    
      ,0 AS IsDeleted    
     FROM @TeampSheetSpecsPageSettings TSSPS     
      LEFT OUTER JOIN SheetSpecsPageSettings SSPS WITH (NOLOCK)                   
      ON SSPS.CustomerId = TSSPS.CustomerId        
      AND SSPS.ProjectId = TSSPS.ProjectId         
    END        
END        
END  