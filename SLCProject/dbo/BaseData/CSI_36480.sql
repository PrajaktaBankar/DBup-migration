USE SLCProject_SqlSlcOp002
GO

--SELECT PSS.SegmentStatusId, MSS.SegmentStatusId, PSS.IndentLevel, MSS.IndentLevel AS NewIndentLevel
--FROM ProjectSegmentStatus PSS WITH (NOLOCK)
--INNER JOIN  SLCMaster..SegmentStatus MSS WITH (NOLOCK)
--ON MSS.SegmentStatusId = PSS.mSegmentStatusId
--where PSS.SegmentStatusId IN(323601045,323600549,323599337,323600105,323601121)

UPDATE PSS
SET PSS.IndentLevel = MSS.IndentLevel
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN  SLCMaster..SegmentStatus MSS WITH (NOLOCK)
ON MSS.SegmentStatusId = PSS.mSegmentStatusId
where PSS.SegmentStatusId IN(323601045,323600549,323599337,323600105,323601121)