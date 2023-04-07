--Excute it only server 3 db

Use [SLCProject_SqlSlcOp003]
GO

UPDATE  PSS SET PSS.IsDeleted = 0 
FROM ProjectSegmentStatus PSS With(NOLOCK)
WHERE PSS.SegmentStatusId  
IN(367812601,367812633,367812599,367812600) 