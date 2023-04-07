CREATE PROCEDURE [dbo].[usp_GetTrackedSegmentDetails] -- [Obsolete]  
(  
@ProjectId  int,  
@SectionId  int,  
@CustomerId int  
)  
AS  
BEGIN  
--  SELECT  
-- TPS1.SegmentId  
--   ,TPS1.AfterEdit  
--FROM TrackProjectSegment TPS1 WITH(NOLOCK)  
--LEFT OUTER JOIN TrackProjectSegment TPS2 WITH(NOLOCK)  
-- ON TPS2.SegmentId = TPS1.SegmentId  
--  AND TPS2.ChangedDate > TPS1.ChangedDate  
--WHERE TPS2.ChangedDate IS NULL  
--AND TPS1.ProjectId = @ProjectId  
--AND TPS1.SectionId = @SectionId  
--AND TPS1.CustomerId = @CustomerId  
--AND TPS1.IsDeleted <> 1  
  
SELECT  
 ps.SegmentId  
   ,'' AS AfterEdit  
FROM ProjectSegment ps WITH(NOLOCK)  
INNER JOIN ProjectSegmentStatus pss WITH(NOLOCK)  
 ON ps.SectionId = pss.SectionId  
  AND ps.SegmentStatusId = pss.SegmentStatusId  
  AND ps.SegmentId = pss.SegmentId  
  AND ps.ProjectId = pss.ProjectId  
  AND ps.CustomerId = pss.CustomerId  
WHERE ps.SectionId = @SectionId  
AND  ps.ProjectId = @ProjectId  
AND ps.CustomerId = @CustomerId  
AND ISNULL(ps.IsDeleted, 0) = 0  
AND ISNULL(pss.IsDeleted, 0) = 0  
AND PATINDEX('%ct="%', ps.SegmentDescription) > 0  
  
END  