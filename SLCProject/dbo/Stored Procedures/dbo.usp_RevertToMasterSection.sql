CREATE PROCEDURE [dbo].[usp_RevertToMasterSection]      
@SectionId  int,          
@ProjectId  int,          
@CustomerId int,             
@UserId int          
AS              
 BEGIN          
 DECLARE @PDescription nvarchar (500) = Null;       
 DECLARE @PLevelID INT =0   
 DECLARE @SectionCode INT=0;   
 DECLARE @TargetSectionId INT=0;  
 BEGIN      
Update  PS      
Set PS.IsDeleted=1      
FROM ProjectSection PS With(NOLOCK)      
where PS.SectionId=@SectionId       
and PS.ProjectId=@ProjectId       
and PS.CustomerId=@CustomerId       
      
      
INSERT INTO ProjectSection(ParentSectionId,mSectionId,ProjectId ,CustomerId ,UserId ,DivisionId ,DivisionCode,Description,LevelId,IsLastLevel,SourceTag,Author,TemplateId,SectionCode,IsDeleted,IsLocked,LockedBy,LockedByFullName,CreateDate,CreatedBy,ModifiedBy,ModifiedDate,FormatTypeId,SLE_FolderID,SLE_ParentID,SLE_DocID,SpecViewModeId,A_SectionId,IsLockedImportSection,IsTrackChanges,IsTrackChangeLock,TrackChangeLockedBy,SortOrder)      
SELECT  ParentSectionId ,mSectionId ,@ProjectId,@CustomerId,@UserId,DivisionId ,DivisionCode,Description,LevelId,IsLastLevel,SourceTag ,Author ,TemplateId ,SectionCode,0,IsLocked ,LockedBy,LockedByFullName,CreateDate,CreatedBy,ModifiedBy,ModifiedDate,FormatTypeId,SLE_FolderID,SLE_ParentID,SLE_DocID,SpecViewModeId,A_SectionId,IsLockedImportSection,0,IsTrackChangeLock,TrackChangeLockedBy,SortOrder      
FROM ProjectSection PS With(NOLOCK)      
where PS.SectionId=@SectionId       
and PS.ProjectId=@ProjectId       
and PS.CustomerId=@CustomerId     
  
SET @TargetSectionId = SCOPE_IDENTITY();   
Update  PS     
Set PS.Description=MS.Description,  
 PS.SourceTag=MS.SourceTag  
FROM ProjectSection PS With(NOLOCK)      
INNER JOIN SLCMaster..section MS With(NOLOCK)   
ON PS.msectionid=MS.SectionId  
where  PS.SectionId=@TargetSectionId  
and PS.ProjectId=@ProjectId       
and PS.CustomerId=@CustomerId   
      
SELECT Top 1 @SectionCode=PS.SectionCode       
FROM [projectSection] PS WITH (NOLOCK)      
where PS.SectionId=@TargetSectionId       
and PS.ProjectId=@ProjectId       
and PS.CustomerId=@CustomerId               
and IsDeleted=1      
END      
----User Segment link deleted  
  
Update  PSL    
Set PSL.IsDeleted=1    
FROM ProjectSegmentLink PSL With(NOLOCK)    
where PSL.ProjectId=@ProjectId     
and PSL.CustomerId=@CustomerId   
and (PSL.SourceSectionCode=@SectionCode   
OR PSL.TargetSectionCode=@SectionCode)  
and PSL.SegmentLinkSourceTypeId=5  
and ISNULL(PSL.IsDeleted,0) = 0  




----Select Revert To master Section      
      
SELECT TOP 1 PS.SectionId,PS.ParentSectionId,PS.mSectionId,PS.ProjectId ,PS.CustomerId,PS.UserId ,PS.DivisionId ,PS.DivisionCode,PS.Description,PS.LevelId,PS.IsLastLevel,PS.SourceTag,PS.Author,PS.TemplateId,PS.SectionCode,PS.IsDeleted,PS.IsLocked,PS.LockedBy,PS.LockedByFullName,PS.CreateDate,PS.CreatedBy,PS.ModifiedBy,PS.ModifiedDate,PS.FormatTypeId,PS.SpecViewModeId,PS.IsLockedImportSection,PS.IsTrackChanges,IsTrackChangeLock,PS.TrackChangeLockedBy      
FROM [projectSection] PS WITH (NOLOCK)      
where PS.SectionId=@TargetSectionId  
and PS.ProjectId=@ProjectId       
and PS.CustomerId=@CustomerId        
and IsDeleted=0  
END
 