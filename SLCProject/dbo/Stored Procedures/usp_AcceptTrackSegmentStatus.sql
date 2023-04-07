CREATE PROCEDURE [dbo].[usp_AcceptTrackSegmentStatus]                     
(                              
 @ProjectId INT,                               
 @CustomerId INT,                               
 @UserId INT,                        
 @UserFullName NVARCHAR(200),                                    
 @SectionId INT,                    
 @SegmentStatusId BIGINT,            
 @IsAcceptTrackStatusForBranch BIT=0,          
 @SegmentStatusTrackListJson NVARCHAR(MAX)=''          
)                              
AS                    
BEGIN                    
          
 DECLARE @SegmentStatusIdTbl TABLE (SegmentStatusId BIGINT);           
 --CONVERT STRING INTO TABLE                       
 IF(@SegmentStatusTrackListJson!='')                                                              
 INSERT INTO @SegmentStatusIdTbl (SegmentStatusId)                                                                  
 SELECT *                                                                  
 FROM dbo.fn_SplitString(@SegmentStatusTrackListJson, ',');             
                   
 IF(@SegmentStatusId <> 0)                    
 BEGIN                    
 if(@IsAcceptTrackStatusForBranch=0)            
 BEGIN               
 UPDATE TSST SET                    
 TSST.IsAccepted=1,                    
 TSST.InitialStatusSegmentStatusTypeId=NULL,        
 TSST.InitialStatus = 0,      
 TSST.ModifiedById=@UserId,                    
 TSST.ModifiedByUserFullName=@UserFullName,                    
 TSST.ModifiedDate=GETUTCDATE(),                
 TSST.IsSegmentStatusChangeBySelection=0                
 FROM                    
 TrackSegmentStatusType TSST WITH(NOLOCK)                    
 WHERE                    
 ProjectId = @ProjectId                     
 AND SectionId = @SectionId                     
 AND CustomerId = @CustomerId                     
 AND SegmentStatusId=@SegmentStatusId                    
 AND ISNULL(IsAccepted,0)=0                    
 END                
 ELSE             
 BEGIN            
          
  --SELECT TSST.*            
  UPDATE TSST SET                    
    TSST.IsAccepted=1,                    
    TSST.InitialStatusSegmentStatusTypeId=NULL,              
    TSST.InitialStatus = 0,      
    TSST.ModifiedById=@UserId,                    
    TSST.ModifiedByUserFullName=@UserFullName,                    
    TSST.ModifiedDate=GETUTCDATE(),                
    TSST.IsSegmentStatusChangeBySelection=0                 
  FROM                    
    TrackSegmentStatusType TSST WITH(NOLOCK)               
    INNER JOIN @SegmentStatusIdTbl TPSS                
    ON TSST.SegmentStatusId=TPSS.SegmentStatusId  OR TSST.SegmentStatusId = @SegmentStatusId            
    WHERE TSST.ProjectId = @ProjectId                     
    AND TSST.SectionId = @SectionId                     
    AND TSST.CustomerId = @CustomerId                     
    AND ISNULL(IsAccepted,0)=0            
              
 END            
 END                    
 ELSE                     
 BEGIN                 
             
 UPDATE TSST SET                    
 TSST.IsAccepted=1,                    
 TSST.InitialStatusSegmentStatusTypeId=NULL,          
 TSST.InitialStatus = 0,      
 TSST.ModifiedById=@UserId,                    
 TSST.ModifiedByUserFullName=@UserFullName,                    
 TSST.ModifiedDate=GETUTCDATE(),                
 TSST.IsSegmentStatusChangeBySelection=0                 
 FROM                    
 TrackSegmentStatusType TSST WITH(NOLOCK)                    
 WHERE                    
 ProjectId = @ProjectId                     
 AND SectionId = @SectionId                     
 AND CustomerId = @CustomerId                     
 AND ISNULL(IsAccepted,0)=0                    
                
  END                    
                    
END
GO


