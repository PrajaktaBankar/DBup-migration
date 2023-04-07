CREATE PROCEDURE [dbo].[usp_CreateSectionFromAlternateDoc]    
(      
    @ProjectId int,      
    @UserId int ,      
    @UserName NVARCHAR(500) null=null,      
    @ParentSectionId int,      
    @CustomerId int,      
    @Description nvarchar(500)null=null,      
    @SourceTag varchar(18)null=null,      
    @Author nvarchar(100)null=null ,    
    @OriginalFileName NVARCHAR(150)null=null,
	@DocumentPath NVARCHAR(150)null=null
)              
AS      
BEGIN          
    DECLARE @PProjectId int = @ProjectId;          
    DECLARE @PUserId int = @UserId;          
    DECLARE @PUserName NVARCHAR(500) = @UserName;          
    DECLARE @PParentSectionId int = @ParentSectionId;          
    DECLARE @PCustomerId int = @CustomerId;          
    DECLARE @PDescription nvarchar(500) = @Description;          
    DECLARE @PSourceTag varchar(18) = @SourceTag;          
    DECLARE @PAuthor nvarchar(100) = @Author;          
    DECLARE @PCreatedBy int = @UserId;          
    DECLARE @SectionSource int =8          
    DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@PProjectId, @PCustomerId, @PParentSectionId, @PSourceTag, @PAuthor);        
    DECLARE @SectionDocumentTypeId  INT = 1;  
                
    UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK)   
	WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId  AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;                
                
    INSERT INTO ProjectSection (ParentSectionId          
    , mSectionId          
    , ProjectId          
    , CustomerId          
    , UserId          
    , DivisionId          
    , DivisionCode          
    , Description          
    , LevelId          
    , IsLastLevel          
    , SourceTag          
    , Author          
    , TemplateId          
    , IsDeleted          
    , IsLocked          
    , LockedBy          
    , LockedByFullName          
    , CreateDate          
    , CreatedBy          
    , ModifiedBy          
    , ModifiedDate          
    , FormatTypeId          
    , SLE_FolderID          
    , SLE_ParentID          
    , SLE_DocID          
    , SectionSource          
    , IsLockedImportSection          
    , A_SectionId                
    , SortOrder)          
     VALUES (@PParentSectionId, NULL, @PProjectId, @PCustomerId, @PUserId, null, null, @PDescription, 3, 1, @PSourceTag, @PAuthor,   
	 NULL, 0, 0, NULL, NULL, GETUTCDATE(), @PUserId, NULL, GETUTCDATE(), 1, NULL, NULL, NULL, @SectionSource, 0, NULL, @SortOrder  
    
      
        
);          
            
    DECLARE @NewSectionId INT = SCOPE_IDENTITY();                 
              
    INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,                
        IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,--SegmentStatusCode,           
        IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,                
        ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)                
         SELECT                
          @NewSectionId AS SectionId                
            ,0 AS ParentSegmentStatusId                
            ,0 AS mSegmentStatusId                
            ,0 AS mSegmentId                
            ,null AS SegmentId                
            ,'U' AS SegmentSource                
            ,'U' AS SegmentOrigin                
            ,0 AS IndentLevel                
            ,0 AS SequenceNumber                
            ,1 AS SpecTypeTagId                
            ,6 AS SegmentStatusTypeId                
            ,1 AS IsParentSegmentStatusActive                
            ,@PProjectId AS ProjectId                
            ,@PCustomerId AS CustomerId                
            --,null AS SegmentStatusCode                
            ,0 AS IsShowAutoNIsPageBreakumber                
            ,0 AS IsRefStdParagraph                
            ,null AS FormattingJson                
            ,GETUTCDate() AS CreateDate                
            ,@UserId AS CreatedBy                
            ,@UserId AS ModifiedBy                
            ,GETUTCDate() AS ModifiedDate                
			,0 AS IsPageBreak                
            ,0 AS IsDeleted                
            ,0 AS A_SegmentStatusId                
                   
         DECLARE @SegmentStatusId BIGINT =SCOPE_IDENTITY();                
          
         INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,SegmentSource, --SegmentCode,           
         CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentId, BaseSegmentDescription)                                
         SELECT               
           @SegmentStatusId AS SegmentStatusId                                
          ,@NewSectionId AS SectionId                                
          ,@PProjectId AS ProjectId                                
          ,@PCustomerId AS CustomerId                                
          ,@Description AS SegmentDescription                                
          ,'U' AS SegmentSource                                
          --,PSG_Src.SegmentCode AS SegmentCode                                
          ,@UserId AS CreatedBy                                
          ,GETUTCDATE() AS CreateDate                                
          ,@UserId AS ModifiedBy                                
          ,GETUTCDATE() AS ModifiedDate                                
          ,0 AS IsDeleted                                
          ,0 AS A_SegmentId                                
          ,'' AS BaseSegmentDescription                                
          
          DECLARE @SegmentId BIGINT=SCOPE_IDENTITY();                 
          
          UPDATE PS          
          SET PS.SegmentId=@SegmentId          
          FROM ProjectSegmentStatus PS WITH(NOLOCK)          
          WHERE PS.SegmentStatusId=@SegmentStatusId          
          
        exec usp_SetDivisionIdForUserSection @PProjectId,@NewSectionId,@PCustomerId          
          
  INSERT INTO SectionDocument        
      (ProjectId    
    ,SectionId        
    ,SectionDocumentTypeId        
    ,DocumentPath        
    ,OriginalFileName        
    ,CreateDate        
    ,CreatedBy)        
  VALUES(@ProjectId    
        ,@NewSectionId        
  ,@SectionDocumentTypeId        
  ,@DocumentPath        
  ,@OriginalFileName        
  ,GETUTCDATE()        
  ,@UserId        
      )        
        
        SELECT          
         SectionCode          
           ,SectionId     
        FROM ProjectSection WITH (NOLOCK)          
        WHERE SectionId = @NewSectionId          
END 