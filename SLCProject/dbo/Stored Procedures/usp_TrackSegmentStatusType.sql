CREATE PROCEDURE  [dbo].[usp_TrackSegmentStatusType]                                          
(                                                        
 @ProjectId INT,                                                         
 @CustomerId INT,                                                         
 @UserId INT,                                                          
 @UserFullName NVARCHAR(200),                                                         
 @SectionId INT,                                                        
 @SegmentStatusTrackListJson NVARCHAR(MAX)                                        
)                                                        
AS                                                        
begin                                        
                                                        
declare @PSegmentStatusListJson  NVARCHAR(MAX)=@SegmentStatusTrackListJson                                                
                                                        
declare @TempSegmentStatusTypeTable TABLE (                                                            
    ProjectId    INT                                                            
    ,SectionId    INT                                                            
    ,CustomerId    INT                                                            
    ,SegmentStatusId      BIGINT                                                            
    ,IsAccepted    BIT                                                            
    ,UserId     INT                                                            
    ,UserFullName   NVARCHAR(200)                                                            
    ,CreatedDate   Datetime2                                                            
    ,SegmentStatusTypeId INT                                                       
    ,PrevStatusSegmentStatusTypeId INT                                            
    ,IsParentSegmentStatusActive BIT                                          
    ,PreviousSegmentStatus BIT                                        
    ,ModifiedById INT                                                        
    ,ModifiedByUserFullName NVARCHAR(200)                                                        
    ,ModifiedDate   Datetime2 ,                                                
    rowId int ,                          
 IsSegmentStatusChangeBySelection bit      ,              
 IsSegmentStatusActive bit                                    
)                                                
                                                        
IF @PSegmentStatusListJson != ''                                                        
BEGIN                                                
                                                
INSERT INTO @TempSegmentStatusTypeTable (ProjectId                                                
, SectionId                                                
, CustomerId                                                
, SegmentStatusId                                                
, IsAccepted                                                
, UserId                                                
, UserFullName                                                
, CreatedDate                                                
, SegmentStatusTypeId                                                
, PrevStatusSegmentStatusTypeId                                              
, IsParentSegmentStatusActive                                         
, PreviousSegmentStatus                                         
, ModifiedById                                                
, ModifiedByUserFullName                                                
, ModifiedDate, rowId,                          
IsSegmentStatusChangeBySelection              
,IsSegmentStatusActive)                                                
 SELECT                                                
     @ProjectId            
    ,SectionId                                                  
    ,@CustomerId                                                
    ,SegmentStatusId              
    ,0 AS IsAccepted                                                
    ,@UserId                                                
    ,@UserFullName                            
    ,GETUTCDATE() AS CreatedDate                                             
    ,SegmentStatusTypeId                                                
    ,PrevStatusSegmentStatusTypeId                             
    --,CASE WHEN IsParentSegmentStatusActive = 1 AND SegmentStatusTypeId < 6 THEN 1 ELSE 0 END  AS InitialStatus                                          
 ,IsParentSegmentStatusActive                                        
 ,PreviousSegmentStatus                                        
    ,NULL AS ModifiedById                                                
    ,NULL AS ModifiedByUserFullName                                               
    ,NULL AS ModifiedDate                                                
    ,ROW_NUMBER() OVER (ORDER BY SegmentStatusId)                            
 ,IsSegmentStatusChangeBySelection                  
 ,IsSegmentStatusActive                               
 FROM OPENJSON(@PSegmentStatusListJson)                                                
 WITH (                                                
 SegmentStatusId BIGINT '$.SegmentStatusId',                                                
 SegmentStatusTypeId INT '$.SegmentStatusTypeId',                                              
 PrevStatusSegmentStatusTypeId INT '$.PrevStatusSegmentStatusTypeId',                                                
 SectionId INT '$.SectionId'     ,                                          
 IsParentSegmentStatusActive bit '$.IsParentSegmentStatusActive',                                          
 PreviousSegmentStatus bit '$.PreviousSegmentStatus',                 
 IsSegmentStatusActive bit '$.IsSegmentStatusActive',                       
 IsSegmentStatusChangeBySelection bit '$.IsSegmentStatusChangeBySelection'                                        
 )                                                
                                                
SELECT DISTINCT                                                
 TSST.SectionId                                                
 ,CASE                                                
 WHEN PSS.TrackChangesModeId = 1 THEN 0                                                
 WHEN PSS.TrackChangesModeId = 2 THEN 1                                                
 ELSE PS.IsTrackChanges                                                
 END AS IsTrackChanges INTO #IsTrackChangesOnSection                                                
FROM ProjectSection PS  WITH(NOLOCK)                                                      
INNER JOIN ProjectSummary PSS WITH(NOLOCK)                                                     
 ON PSS.ProjectId = PS.ProjectId                                                
  AND PSS.CustomerId = PS.CustomerId                                       
INNER JOIN @TempSegmentStatusTypeTable TSST                                                
 ON PS.sectionid = TSST.sectionid                                                
WHERE PS.projectid = @ProjectId                                                
AND PSS.CustomerId = @CustomerId;                                                
                                                
---START:Main logic                                                
UPDATE bsdsst                                                
SET bsdsst.CreatedDate = GETUTCDATE()                                                
   ,bsdsst.SegmentStatusTypeId = tsst.SegmentStatusTypeId                                                
   ,bsdsst.IsAccepted = 0                                                
   ,bsdsst.ModifiedById = @UserId                                                
   ,bsdsst.ModifiedByUserFullName = @UserFullName             
   ,bsdsst.ModifiedDate =    GETUTCDATE()                                             
   ,bsdsst.PrevStatusSegmentStatusTypeId = tsst.PrevStatusSegmentStatusTypeId                                             
   ,bsdsst.InitialStatus = IIF (bsdsst.IsAccepted=1,tsst.PreviousSegmentStatus,bsdsst.InitialStatus )                     
   ,bsdsst.CurrentStatus =   tsst.IsSegmentStatusActive                                  
   ,bsdsst.InitialStatusSegmentStatusTypeId = IIF (bsdsst.IsAccepted=1,tsst.PrevStatusSegmentStatusTypeId,bsdsst.InitialStatusSegmentStatusTypeId )       
   ,bsdsst.SegmentStatusTypeIdBeforeSelection = IIF (tsst.IsSegmentStatusChangeBySelection = 1,tsst.PrevStatusSegmentStatusTypeId  ,bsdsst.SegmentStatusTypeIdBeforeSelection)    
   ,bsdsst.IsSegmentStatusChangeBySelection =             
   CASE WHEN (ISNULL(bsdsst.IsSegmentStatusChangeBySelection,0) =0 )    
  THEN tsst.IsSegmentStatusChangeBySelection         
        WHEN (ISNULL(bsdsst.IsSegmentStatusChangeBySelection,0) =1 AND tsst.IsSegmentStatusChangeBySelection = 1 AND bsdsst.SegmentStatusTypeIdBeforeSelection = tsst.SegmentStatusTypeId)         
        THEN 0                
        ELSE bsdsst.IsSegmentStatusChangeBySelection END          
            
FROM @TempSegmentStatusTypeTable tsst                                        
INNER JOIN TrackSegmentStatusType bsdsst WITH (NOLOCK)                                                
 ON tsst.SegmentStatusId = bsdsst.SegmentStatusId                                                
 AND bsdsst.SectionId = tsst.SectionId                                                
INNER JOIN #IsTrackChangesOnSection TCOS                                                
 ON tsst.SectionId = TCOS.SectionId                                                
WHERE TCOS.IsTrackChanges = 1                                                
                         
INSERT INTO TrackSegmentStatusType (ProjectId                                                
, SectionId                                                
, CustomerId                                                
, SegmentStatusId                                                
, IsAccepted                                                
, UserId                                                
, UserFullName                                                
, CreatedDate                                                
, SegmentStatusTypeId                                                
, PrevStatusSegmentStatusTypeId                                               
, InitialStatusSegmentStatusTypeId                                         
, InitialStatus                               
, CurrentStatus                     
, ModifiedById                                                
, ModifiedByUserFullName                                                
, ModifiedDate                          
,IsSegmentStatusChangeBySelection  
,SegmentStatusTypeIdBeforeSelection)                                                
 SELECT                                                
  tsst.ProjectId                                                
    ,tsst.SectionId                                                
    ,tsst.CustomerId                                                
    ,tsst.SegmentStatusId                                     
    ,tsst.IsAccepted                                                
    ,tsst.UserId                                                
    ,tsst.UserFullName                                                
    ,tsst.CreatedDate                                                
    ,tsst.SegmentStatusTypeId                                                
    ,tsst.PrevStatusSegmentStatusTypeId                                                
    ,tsst.PrevStatusSegmentStatusTypeId  --Only at 1st time insert time                                            
    ,tsst.PreviousSegmentStatus AS InitialStatus                      
    ,tsst.IsSegmentStatusActive AS CurrentStatus    
    ,tsst.ModifiedById               
    ,tsst.ModifiedByUserFullName                                                
    ,tsst.ModifiedDate                             
    ,tsst.IsSegmentStatusChangeBySelection         
    ,IIF(tsst.IsSegmentStatusChangeBySelection = 1,tsst.PrevStatusSegmentStatusTypeId ,NULL)  
 FROM @TempSegmentStatusTypeTable tsst                               
 LEFT OUTER JOIN TrackSegmentStatusType bsdsst WITH (NOLOCK)                                           
 ON tsst.SegmentStatusId = bsdsst.SegmentStatusId                                                
   AND tsst.SegmentStatusTypeId = bsdsst.SegmentStatusTypeId                                                
   AND ISNULL(bsdsst.IsAccepted, 0) = 0                                                
 INNER JOIN #IsTrackChangesOnSection TCOS                                                
  ON tsst.SectionId = TCOS.SectionId                                                
 WHERE bsdsst.SegmentStatusTypeId IS NULL                                                
 AND TCOS.IsTrackChanges = 1                                                
                                                
INSERT INTO BSDLogging..TrackSegmentStatusTypeHistory (ProjectId                                                
, SectionId                                                
, CustomerId                                                
, SegmentStatusId                                                
, IsAccepted                                                
, UserId                                                
, UserFullName                                                
, CreatedDate                                                
, SegmentStatusTypeId                                                
, ModifiedById                                                
, ModifiedByUserFullName                                                
, ModifiedDate)                                                
 SELECT                                                
  tsst.ProjectId                                                
    ,tsst.SectionId                                                
    ,tsst.CustomerId                                                
    ,tsst.SegmentStatusId                                                
    ,tsst.IsAccepted                                                
    ,tsst.UserId                                                
    ,tsst.UserFullName                                                
    ,tsst.CreatedDate                                    
    ,tsst.SegmentStatusTypeId                                                
    ,NULL AS ModifiedById                                                
    ,NULL AS ModifiedByUserFullName                                                
    ,NULL AS ModifiedDate                                                
 FROM @TempSegmentStatusTypeTable tsst                                                
 INNER JOIN #IsTrackChangesOnSection TCOS                                                
  ON tsst.SectionId = TCOS.SectionId                                                
 WHERE TCOS.IsTrackChanges = 1                                                
                                                
---END:Main logic                                                
                                                
END                           
                                                
END 

GO


