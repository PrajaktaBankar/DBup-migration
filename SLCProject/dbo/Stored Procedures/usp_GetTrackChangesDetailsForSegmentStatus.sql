CREATE PROCEDURE usp_GetTrackChangesDetailsForSegmentStatus (                          
   @ProjectId INT,                          
   @CustomerId INT,                          
   @SectionId INT                          
) AS BEGIN                          
SELECT                          
   SegmentStatusId,                          
   SectionId,                          
   ProjectId,                          
   CustomerId,                          
   IsDeleted,                          
   SegmentStatusTypeId,                          
   IsParentSegmentStatusActive,                          
   SequenceNumber INTO #ProjectSegmentStatus                          
FROM                          
   ProjectSegmentStatus WITH(NOLOCK)                          
WHERE                          
   SectionId = @SectionId                          
   AND ProjectId = @ProjectId                          
   AND CustomerId = @CustomerId                          
SELECT                          
   (                          
      CASE                          
         WHEN (                          
            TSST.InitialStatus = 0                  
   and TSST.CurrentStatus = 1                   
         ) THEN 'AddedParagraph'                            
         ELSE 'DoNotTrack'                          
      END                          
   ) AS TrackChangeType,                        
   SequenceNumber,                          
   TSST.SegmentStatusId INTO #TempData                          
FROM                          
   TrackSegmentStatusType TSST WITH(NOLOCK)                          
   INNER JOIN #ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.SectionId=TSST.SectionId                          
   AND PSST.SegmentStatusId = TSST.SegmentStatusId                          
   AND isnull(TSST.IsAccepted, 0) = 0                          
   LEFT JOIN ProjectSection PS WITH(NOLOCK) ON PS.SectionId = TSST.SectionId                          
WHERE                          
   PSST.ProjectId = @ProjectId                          
   AND PSST.CustomerId = @CustomerId                          
   AND (                          
      PSST.IsDeleted IS NULL                          
      OR PSST.IsDeleted = 0                          
   )                          
   AND (                          
      PSST.SegmentStatusTypeId > 0                          
      AND PSST.SegmentStatusTypeId < 6                          
      AND PSST.IsParentSegmentStatusActive = 1                          
   )                          
UNION                          
SELECT                          
   (                          
      CASE                          
         WHEN (                          
            TSST.InitialStatus =1                        
            and TSST.CurrentStatus =0                       
         ) THEN 'RemovedParagraph'                            
         ELSE 'DoNotTrack'                          
      END                          
   ) AS TrackChangeType,                        
   SequenceNumber,                          
   TSST.SegmentStatusId                          
FROM                          
   TrackSegmentStatusType TSST WITH(NOLOCK)                          
   INNER JOIN #ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.SectionId=TSST.SectionId                          
   AND PSST.SegmentStatusId = TSST.SegmentStatusId                          
   AND isnull(TSST.IsAccepted, 0) = 0                          
   LEFT JOIN ProjectSection PS WITH(NOLOCK) ON PS.SectionId = TSST.SectionId                          
WHERE                          
   PSST.ProjectId = @ProjectId                          
   AND PSST.CustomerId = @CustomerId                          
   AND (                          
      PSST.IsDeleted IS NULL                          
      OR PSST.IsDeleted = 0                          
   )                          
   AND (                          
     TSST.SegmentStatusTrackId IS NOT NULL                          
      AND ISNULL(TSST.IsAccepted, 0) = 0                          
   )                          
   AND (                          
      TSST.InitialStatusSegmentStatusTypeId < 6                          
      AND PSST.SegmentStatusTypeId >= 6                          
      OR (                          
         TSST.InitialStatusSegmentStatusTypeId < 6                          
         AND PSST.SegmentStatusTypeId < 6                          
      )                          
  )                          
SELECT                          
   s.SegmentStatusId,                          
   IIF (s.ModifiedById IS NULL, s.UserId, s.ModifiedById) AS UserId,                          
   IIF (                          
      s.ModifiedByUserFullName IS NULL,                          
      s.UserFullName,                          
      s.ModifiedByUserFullName                          
   ) AS UserFullName,                          
   s.CreatedDate,                          
   s.SegmentStatusTypeId,                          
   s.PrevStatusSegmentStatusTypeId,                          
   s.InitialStatusSegmentStatusTypeId,                          
   PSST.SequenceNumber,                          
   InitialStatus,                          
   PSST.TrackChangeType,                          
   ISNULL(s.IsSegmentStatusChangeBySelection, 0) as IsSegmentStatusChangeBySelection                          
FROM                          
   TrackSegmentStatusType s WITH (NOLOCK)                          
   LEFT OUTER JOIN #TempData PSST WITH (NOLOCK)                          
   ON s.SegmentStatusId = PSST.SegmentStatusId                          
WHERE                          
   (                          
      s.SectionId = @SectionId                          
      AND s.ProjectId = @ProjectId                          
      AND s.CustomerId = @CustomerId                          
      AND ISNULL(s.IsAccepted, 0) = 0                          
  )                          
   AND (                          
      TrackChangeType not in ('DoNotTrack')                          
   )                      
   OR (                          
      s.SectionId = @SectionId                          
      AND s.ProjectId = @ProjectId                          
      AND s.CustomerId = @CustomerId                          
      AND ISNULL(s.IsAccepted, 0) = 0                          
      AND TrackChangeType IS NULL            
      AND ISNULL(s.IsSegmentStatusChangeBySelection, 0) = 1                          
   )                          
ORDER BY                          
   --s.SegmentStatusId                          
   PSST.SequenceNumber                          
END  
