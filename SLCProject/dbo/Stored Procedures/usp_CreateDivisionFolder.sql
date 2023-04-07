CREATE PROCEDURE usp_CreateDivisionFolder                  
(            
@ActionId int,            
@ProjectId int,                  
@CustomerId int,                  
@UserId int,                  
@SourceTag varchar(10) ,                  
@FolderName nvarchar(500),                  
@ParentSectionId int ,                 
@SectionId int   = 0,        
@SeqSectionIds nvarchar(max) = null         
)                  
AS                  
Begin                  
set NOCOUNT ON;      
Declare @ResponseMessage nvarchar(500);                
           
 --CreateFolder           
 IF @ActionId = 1            
 Begin      
     
 --Check same folder name exist in same division    
 IF not exists (    
 SELECT TOP 1 1     
 FROM ProjectSection WITH (NOLOCK)     
 WHERE ProjectId=@ProjectId     
 AND ParentSectionId = @ParentSectionId    
 AND UPPER(Description) = UPPER(@FolderName)    
 AND ISNULL(IsDeleted,0) = 0    
)    
BEGIN     
   Insert INTO ProjectSection(ParentSectionId,mSectionId,ProjectId,CustomerId,UserId,Description,LevelId,IsLastLevel,SourceTag,Author, TemplateId,SectionCode,IsDeleted, CreateDate,CreatedBy,ModifiedBy,ModifiedDate,                  
  FormatTypeId)                  
 VALUES ( @ParentSectionId, 0, @ProjectId,@CustomerId,@UserId,@FolderName,3,0,@SourceTag,'USER',0,0,0,GETUTCDATE(),@UserId,@UserId,GETUTCDATE(),1)      
     
 SET @ResponseMessage = 'Folder created successfully.';             
END    
ELSE    
BEGIN    
 SET @ResponseMessage = CONCAT(@FolderName ,' folder name already exist in same division');    
END;    
    
    
 End            
 --EditFolder          
 ELSE IF @ActionId = 2            
 BEGIN       
     
 --Check same folder name exist in same division    
 IF not exists (    
 SELECT TOP 1 1     
 FROM ProjectSection WITH (NOLOCK)     
 WHERE ProjectId=@ProjectId     
 AND ParentSectionId = @ParentSectionId    
 AND UPPER(Description) = UPPER(@FolderName)    
 AND ISNULL(IsDeleted,0) = 0    
)    
BEGIN         
 UPDATE PS              
 SET Description = @FolderName              
 FROM ProjectSection PS WITH (NOLOCK)              
 WHERE PS.SectionId = @SectionId;     
     
 SET @ResponseMessage = 'Folder renamed successfully.';     
END    
ELSE    
BEGIN    
    
 SET @ResponseMessage = 'Already folder name exist. Retry with unique folder name.';     
END;    
               
 END            
 --DeleteFolder          
 ELSE IF @ActionId = 3            
 BEGIN            
    UPDATE PS              
 SET IsDeleted = 1              
 FROM ProjectSection PS WITH (NOLOCK)              
 WHERE PS.SectionId = @SectionId;         
     
 SET @ResponseMessage = 'Folder has been deleted successfully.';           
 END            
 --HideMasterFolder/UnHideMasterFolder          
 ELSE IF @ActionId = 4 OR @ActionId = 5            
 BEGIN            
   UPDATE PS              
 SET  IsHidden = CASE WHEN @ActionId = 4 THEN 1 ELSE 0 END             
 FROM ProjectSection PS WITH (NOLOCK)              
 WHERE PS.SectionId = @SectionId;             
            
 UPDATE PS              
 SET  IsHidden = CASE WHEN @ActionId = 4 THEN 1 ELSE 0 END              
 FROM ProjectSection PS WITH (NOLOCK)              
 WHERE PS.ParentSectionId = @SectionId;              
            
 UPDATE PS              
 SET  IsHidden = CASE WHEN @ActionId = 4 THEN 1 ELSE 0 END             
 FROM ProjectSection PS WITH (NOLOCK)              
 WHERE PS.ParentSectionId IN(             
     SELECT SectionId FROM ProjectSection WITH (NOLOCK) WHERE ProjectId=@ProjectId AND ParentSectionId=@SectionId            
 );      
     
 SET @ResponseMessage = CASE WHEN @ActionId = 4 THEN ' hided successfully.' ELSE ' unhided successfully.'  END;              
 END          
 -- CreateNewDivision          
 ELSE IF @ActionId = 6          
 BEGIN          
 INSERT INTO ProjectSection (ParentSectionId,mSectionId,ProjectId,CustomerId,UserId,Description,LevelId,IsLastLevel,SourceTag,Author,TemplateId,SectionCode,IsDeleted,          
 CreateDate,CreatedBy,ModifiedBy,ModifiedDate,FormatTypeId,SpecViewModeId)          
 VALUES(@ParentSectionId,0,@ProjectId,@CustomerId,@UserId,@FolderName,2,0,@SourceTag,'USER',0,0,0,GETUTCDATE(),@UserId,@UserId,GETUTCDATE(),1,1)          
      
  SET @ResponseMessage = 'Division created successfully.';           
 END          
 --UpdateParentIdOfSubDivsOnDragDrop          
 ELSE IF @ActionId = 7          
 BEGIN          
  UPDATE PS              
  SET  ParentSectionId = @ParentSectionId          
  , ModifiedBy = @UserId          
  , ModifiedDate = GETUTCDATE()          
  FROM ProjectSection PS WITH (NOLOCK)              
  WHERE PS.SectionId = @SectionId AND PS.ProjectId = @ProjectId;     
      
  SET @ResponseMessage = 'Sub division drag drop done successfully.';                
 END        
 -- update sortOrder of Divisions        
 ELSE IF @ActionId = 8        
 BEGIN        
 WITH cte        
 AS        
 (SELECT        
   [Key] AS [Sequence]        
     ,[Value] AS SectionId        
  FROM OPENJSON(@SeqSectionIds))        
 UPDATE PS        
 SET PS.SortOrder = cte.Sequence        
 FROM cte WITH (NOLOCK)        
 INNER JOIN ProjectSection AS PS WITH (NOLOCK)        
  ON cte.SectionId = PS.SectionId;      
      
  SET @ResponseMessage = 'Divisions sorting has been done successfully.';      
 END;          
      
  SELECT @ResponseMessage AS ResponseMessage    
             
End; 