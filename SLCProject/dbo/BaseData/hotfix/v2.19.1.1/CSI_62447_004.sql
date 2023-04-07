--Customer Support 62447: Track Changes not printing at all - 47303 _SqlSlcOp004

USE SLCProject
GO

DECLARE @SegmentD nvarchar(max) ='​{GT#3}''s Name:  ​<span class="GTEditTC" contenteditable="false" ct="GTEditTC" akgd="0" cid="6ca3b1c0-63f4-11ec-891e-81e88a7d281a" uid="16285" dt="1629322254000"><span class="del">XYZ Corporation</span>{GT#4}</span>​.'

UPDATE ProjectSegment
SET SegmentDescription = @SegmentD
WHERE SegmentStatusId=1325640836