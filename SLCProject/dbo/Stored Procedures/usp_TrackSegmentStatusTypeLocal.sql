CREATE PROCEDURE  [dbo].[usp_TrackSegmentStatusTypeLocal]  
(    
  @CustomerId INT,  
  @ProjectId INT,  
  @SectionId INT,  
  @UserId INT,   
  @UserFullName NVARCHAR(200)  
)    
AS    
BEGIN   
 CREATE TABLE #TempSegmentStatusTypeTable(   
  RowId int IDENTITY(1,1)  
  ,CustomerId INT  
  ,UserId INT  
  ,UserFullName NVARCHAR(100)  
  ,ProjectId INT  
  ,SectionId INT  
  ,SegmentStatusId  BIGINT    
  ,SegmentStatusTypeId INT   
  ,PrevStatusSegmentStatusTypeId INT    
  ,IsParentSegmentStatusActive BIT  
  ,PreviousSegmentStatus BIT    
  ,IsSegmentStatusChangeBySelection bit  
  ,IsSegmentStatusActive bit   
  ,IsAccepted BIT   
 )   
   
 INSERT INTO #TempSegmentStatusTypeTable(CustomerId,UserId,UserFullName,ProjectId,SectionId,SegmentStatusId,SegmentStatusTypeId,  
    PrevStatusSegmentStatusTypeId,IsParentSegmentStatusActive,PreviousSegmentStatus,IsSegmentStatusChangeBySelection,IsSegmentStatusActive,IsAccepted)  
 SELECT @CustomerId,@UserId,@UserFullName,@ProjectId,@SectionId,p.SegmentStatusId,p.SegmentStatusTypeId,  
 b.SegmentStatusTypeId,p.IsParentSegmentStatusActive,0,b.IsSegmentStatusChangeBySelection,0,0  
 FROM #SegmentStatusBackUp b INNER JOIN ProjectSegmentStatus p WITH(NOLOCK)  
 ON p.SegmentStatusId=b.SegmentStatusId  
   
 UPDATE #TempSegmentStatusTypeTable  
 SET IsSegmentStatusActive=IIF(SegmentStatusTypeId BETWEEN 1 AND 5 AND IsParentSegmentStatusActive=1,1,0)  
  
 UPDATE t  
 SET t.PreviousSegmentStatus=IIF(b.SegmentStatusTypeId<6 and b.IsParentSegmentStatusActive=1,1,0)
 FROM #TempSegmentStatusTypeTable t  INNER JOIN  #SegmentStatusBackUp b
 ON t.SegmentStatusId=b.SegmentStatusId
  
	
 UPDATE bsdsst  
 SET bsdsst.CreatedDate = GETUTCDATE()  
 ,bsdsst.SegmentStatusTypeId = tsst.SegmentStatusTypeId  
 ,bsdsst.IsAccepted = 0  
 ,bsdsst.ModifiedById = @UserId  
 ,bsdsst.ModifiedByUserFullName = @UserFullName   
 ,bsdsst.ModifiedDate = GETUTCDATE()  
 ,bsdsst.PrevStatusSegmentStatusTypeId = tsst.PrevStatusSegmentStatusTypeId  
 ,bsdsst.InitialStatus = IIF (bsdsst.IsAccepted=1,tsst.PreviousSegmentStatus,bsdsst.InitialStatus )  
 ,bsdsst.CurrentStatus =tsst.IsSegmentStatusActive   
 ,bsdsst.InitialStatusSegmentStatusTypeId = IIF (bsdsst.IsAccepted=1,tsst.PrevStatusSegmentStatusTypeId,bsdsst.InitialStatusSegmentStatusTypeId )   
 ,bsdsst.SegmentStatusTypeIdBeforeSelection = IIF (tsst.IsSegmentStatusChangeBySelection = 1,tsst.PrevStatusSegmentStatusTypeId  ,bsdsst.SegmentStatusTypeIdBeforeSelection)   
 ,bsdsst.IsSegmentStatusChangeBySelection =   
 CASE WHEN (ISNULL(bsdsst.IsSegmentStatusChangeBySelection,0) =0 )   
   THEN tsst.IsSegmentStatusChangeBySelection  
   WHEN (ISNULL(bsdsst.IsSegmentStatusChangeBySelection,0) =1 AND tsst.IsSegmentStatusChangeBySelection = 1 AND bsdsst.SegmentStatusTypeIdBeforeSelection = tsst.SegmentStatusTypeId)  
   THEN 0   
   ELSE bsdsst.IsSegmentStatusChangeBySelection END    
 FROM #TempSegmentStatusTypeTable tsst   
 INNER JOIN TrackSegmentStatusType bsdsst WITH (NOLOCK)  
  ON tsst.SegmentStatusId = bsdsst.SegmentStatusId  
  WHERE bsdsst.SectionId = @SectionId  
   
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
  SELECT DISTINCT  
   tsst.ProjectId  
  ,tsst.SectionId  
  ,tsst.CustomerId  
  ,tsst.SegmentStatusId   
  ,tsst.IsAccepted  
  ,tsst.UserId  
  ,tsst.UserFullName  
  ,GETUTCDATE()  
  ,tsst.SegmentStatusTypeId  
  ,tsst.PrevStatusSegmentStatusTypeId  
  ,tsst.PrevStatusSegmentStatusTypeId  --Only at 1st time insert time    
  ,tsst.PreviousSegmentStatus AS InitialStatus   
  ,tsst.IsSegmentStatusActive AS CurrentStatus   
  ,@UserId  
  ,@UserFullName  
  ,GETUTCDATE()    
  ,tsst.IsSegmentStatusChangeBySelection  
  ,IIF(tsst.IsSegmentStatusChangeBySelection = 1,tsst.PrevStatusSegmentStatusTypeId ,NULL)    
  FROM #TempSegmentStatusTypeTable tsst   
  LEFT OUTER JOIN TrackSegmentStatusType bsdsst WITH (NOLOCK)   
  ON tsst.SegmentStatusId = bsdsst.SegmentStatusId  
 AND tsst.SegmentStatusTypeId = bsdsst.SegmentStatusTypeId  
 AND ISNULL(bsdsst.IsAccepted, 0) = 0  
  WHERE bsdsst.SegmentStatusTypeId IS NULL  
    
  --select * from #TempSegmentStatusTypeTable  
  --select * from #SegmentStatusBackUp  
  --select * from TrackSegmentStatusType where SectionId=@SectionId  
   
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
  ,GETUTCDATE()  
  ,tsst.SegmentStatusTypeId  
  ,NULL AS ModifiedById  
  ,NULL AS ModifiedByUserFullName  
  ,NULL AS ModifiedDate  
  FROM #TempSegmentStatusTypeTable tsst  
    
 ---END:Main logic   
END 