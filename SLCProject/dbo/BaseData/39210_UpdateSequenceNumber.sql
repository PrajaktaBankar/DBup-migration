/*
Customer Support 39210: SLC paragraphs are not in the correct order.

server :2

For reference 
mismatch sequence Number.

*/



DECLARE @SectionId int=7752; 
DROP TABLE IF EXISTS #tempProjectSegmentStatus

SELECT ROW_NUMBER() OVER (ORDER BY PSS.SequenceNumber)  AS RowNum,
PSS.SegmentStatusId,PSS.mSegmentStatusId, PSS.SequenceNumber as OldSequenceNumber,
MSS.SequenceNumber as NewSequenceNumber
INTO #tempProjectSegmentStatus
 FROM ProjectSegmentStatus PSS WITH (NOLOCK) 
LEFT OUTER JOIN SLCMaster..SegmentStatus MSS WITH (NOLOCK)
ON MSS.SegmentStatusId= PSS.mSegmentStatusId
WHERE PSS.SectionId=@SectionId
and  ISNULL(PSS.IsDeleted,0)=0
ORDER BY PSS.SequenceNumber

--SELECT * FROM #tempProjectSegmentStatus
--ORDER BY RowNum

DECLARE @r int = 1 , @RowCount int = (select COUNT(*) FROM #tempProjectSegmentStatus), @i int=0;
DECLARE @IncrementCounter int = 0 ,@IncreNewOldSeq decimal(18,4),@flag int =0, @OldSeq decimal (18,4), @NewSeq decimal(18,4);
DECLARE @SegmentStatusId int =0, @CurrentSeq decimal(18,4)=0.0000;


WHILE @r <= @RowCount
Begin
 
 select @OldSeq=OldSequenceNumber 
 ,@NewSeq=NewSequenceNumber
 ,@SegmentStatusId = SegmentStatusId
 from #tempProjectSegmentStatus
 WHERE RowNum=@r;
 
IF @OldSeq <> ISNULL(@NewSeq,0) 
  BEGIN
    IF ISNULL(@NewSeq,0) =0
	BEGIN

	  SELECT @IncreNewOldSeq =NewSequenceNumber from #tempProjectSegmentStatus
      WHERE RowNum=@r -1 ;

      UPDATE #tempProjectSegmentStatus
	  SET NewSequenceNumber = (ISNULL(@IncreNewOldSeq,0)+1)
	  where SegmentStatusId = @SegmentStatusId

		SET @IncrementCounter = @IncrementCounter + 1;
    End
	ELSE
	Begin
	  UPDATE #tempProjectSegmentStatus
	  SET NewSequenceNumber = (ISNULL(@NewSeq,0)+@IncrementCounter)
	  where SegmentStatusId = @SegmentStatusId
	   
	End;
  END;

  SET @r = @r + 1;
End;

--SELECT * FROM #tempProjectSegmentStatus
------WHERE RowNum=688
--ORDER BY RowNum

UPDATE PSS
SET SequenceNumber = TPSS.NewSequenceNumber
from ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN #tempProjectSegmentStatus TPSS
on PSS.SegmentStatusId = TPSS.SegmentStatusId
WHERE PSS.SectionId = @SectionId





